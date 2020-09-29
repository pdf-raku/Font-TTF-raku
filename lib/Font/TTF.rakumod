unit class Font::TTF;

use CStruct::Packing :Endian;
use Font::TTF::Defs :Sfnt-Struct;
use Font::TTF::Raw;
use Font::TTF::Table;
use Font::TTF::Table::CMap;
use Font::TTF::Table::Header;
use Font::TTF::Table::HoriHeader;
use Font::TTF::Table::HoriMetrics;
use Font::TTF::Table::VertHeader;
use Font::TTF::Table::VertMetrics;
use Font::TTF::Table::GlyphIndex;
use Font::TTF::Table::OS2;
use Font::TTF::Table::PCLT;
use Font::TTF::Table::MaxProfile;
use Font::TTF::Table::Generic;
use NativeCall;
use Method::Also;

class Offsets is repr('CStruct') does Sfnt-Struct {
    has uint32  $.ver;
    has uint16  $.numTables;
    has uint16  $.searchRange;
    has uint16  $.entrySelector;
    has uint16  $.rangeShift;

    method init {
        $!searchRange = 2;
        $!entrySelector = 0;

        while $!searchRange < $!numTables {
            $!searchRange *= 2;
            $!entrySelector++;
        }
        $!searchRange *= 32;
        $!rangeShift = $!numTables * 16  -  $!searchRange;
        self;
    }

}

class Directory is repr('CStruct') does Sfnt-Struct {
    has uint32	$.tag; 	        # 4-byte identifier
    has uint32	$.checkSum;	# checksum for this table
    has uint32	$.offset;	# offset from beginning of sfnt
    has uint32	$.length;	# length of this table in byte (actual length not padded length)

    sub tag-decode(UInt:D $tag is copy) is export(:tag-decode) {
        my @chrs = (1..4).map: {
            my $chr = ($tag mod 256).chr;
            $tag div= 256;
            $chr;
        }
        @chrs.reverse.join.trim;
    }

    sub tag-encode(Str:D $s --> UInt) is export {
        my uint32 $enc = 0;
        for $s.ords {
            $enc *= 256;
            $enc += $_;
        }
        $enc ~= ' ' while $enc.chars < 4;
        $enc;
    }

    method tag-encoded { $!tag }
    method tag {
        tag-decode($!tag);
    }
}
has IO::Handle:D $.fh is required;
has Offsets $!offsets handles<numTables>;
has UInt %!tag-idx;

our @Tables = [
    Font::TTF::Table::CMap, Font::TTF::Table::Header,
    Font::TTF::Table::HoriHeader, Font::TTF::Table::HoriMetrics,
    Font::TTF::Table::GlyphIndex, Font::TTF::Table::MaxProfile,
    Font::TTF::Table::VertHeader, Font::TTF::Table::VertMetrics,
    Font::TTF::Table::PCLT, Font::TTF::Table::OS2,
];
has %!tables = @Tables.map: { .tag => $_ };
has Directory @.directories;
has UInt @.lengths;
has Buf @.bufs;

method tags {
    @!directories.grep(*.defined)>>.tag;
}

submethod TWEAK {
    $!fh.seek(0, SeekFromBeginning);
    $!offsets .= read($!fh);
    for 0 ..^ $!offsets.numTables {
        my Directory $dir .= read($!fh);
        %!tag-idx{$dir.tag} = $_;
        @!directories.push: $dir;
    }

    self!setup-lengths();
    self;
}

method !setup-lengths {
    my $prev;
    for @!directories.sort(*.offset) -> $dir {
        with $prev {
            my $offset = $dir.offset;
            my $idx = %!tag-idx{$prev.tag};
            @!lengths[$idx] = $offset - $prev.offset;
        }
        $prev = $dir;
    }
}

multi method buf(Str $tag) {
    with %!tag-idx{$tag} -> $idx {
        @!bufs[$idx] //= do with %!tables{$tag} {
            .pack;
        } // do {
            given @!directories[$idx] {
                with @!lengths[$idx] -> $max-len {
                    die "length for '$tag' {.length} > $max-len"
                        if .length > $max-len;
                }
                my $offset = .offset;
                $!fh.seek($offset, SeekFromBeginning);
                $!fh.read(.length);
            }
        }
    }
    else {
        buf8;
    }
}

multi method buf { self.Blob }

#| add or update a table buffer
multi method upd(Blob $buf, Str:D :$tag!) {
    $_ .= WHAT with %!tables{$tag}; # invalidate object
    my $idx = (%!tag-idx{$tag} //= +%!tag-idx);
    @!bufs[$idx] = $buf;
}

#| add or update a table object
multi method upd(Font::TTF::Table $obj) {
    my $tag = $obj.tag;
    my $idx = (%!tag-idx{$tag} //= +%!tag-idx);
    @!bufs[$idx] = Nil;  # invalidate buffer
    %!tables{$tag} = $obj;
}

multi method load(Str $tag) {
    self.load: %!tables{$tag}:exists
        ?? %!tables{$tag}
        !! Font::TTF::Table::Generic;
}

multi method load(Font::TTF::Table:D $obj) {
    $obj
}

multi method load(Font::TTF::Table:U $class) {
    my $tag = $class.tag;
    my $rv = $class;
    with self.buf($tag) -> Blob $buf {
        $rv .= new: :$buf, :$tag, :loader(self);
    }
    $rv;
}

constant Alignment = nativesizeof(long);

multi sub byte-align(UInt $bytes is rw) {
    if $bytes %% Alignment {
        $bytes;
    }
    else {
        my \padding = Alignment - $bytes % Alignment;
        $bytes += padding;
    }
}

multi sub byte-align(buf8 $buf) {
    my $bytes := $buf.bytes;
    unless $bytes %% Alignment {
        my \padding = Alignment - $bytes % Alignment;
        $buf.append: 0 xx padding;
    }
    $buf;
}

method pack returns Blob is also<Blob> {
    # copy or rebuild tables. Preserve input order
    my class ManifestItem {
        has Directory:D $.dir-in is required;
        has Blob:D $.buf is required;
        has Directory $.dir-out is rw;
    }
    my ManifestItem @manifest;

    for @!directories -> $dir-in {
        my $tag := $dir-in.tag;
        given self.buf($tag) -> $buf {
            @manifest.push: ManifestItem.new: :$dir-in, :$buf;
        }
    }

    @manifest .= sort(*.dir-in.tag);

    my uint32  $ver = $!offsets.ver;
    my uint32  $numTables = +@manifest;
    my Offsets:D $offsets .= new(:$ver, :$numTables).init;
    my $buf = $offsets.pack;
    my $offset = Offsets.packed-size  +  $offsets.numTables * Directory.packed-size;

    for @manifest {
        my $dir = .dir-in;
        my $tag-str = $dir.tag;
        my uint32 $tag = $dir.tag-encoded;
        my uint32 $checkSum = sfnt_checksum(.buf, .buf.bytes);
        my $subbuf = $dir.pack;
        my uint32 $length = .buf.bytes;
        .dir-out = Directory.new: :$offset, :$tag, :$tag-str, :$length, :$checkSum;
        $buf.append: .dir-out.pack;
        $offset += $length;
        byte-align($offset);
    }
    for @manifest {
        $buf.append: .buf;
        byte-align($buf);
    }
    $buf;
}

method glyph-buf(UInt:D $gid --> buf8:D) {
    given  self.loca {
        my UInt:D $start := .[$gid];
        my UInt:D $end   := .[$gid+1];
        my UInt:D $len   := $end - $start;

        self.buf('glyf').subbuf($start, $len);
    }
}

method head {
    self.load: 'head';
}

multi method FALLBACK(Font::TTF:D: $tag where {%!tables{$_}:exists}) {
    self.load: $tag;
}

