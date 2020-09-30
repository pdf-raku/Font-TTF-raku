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
    has uint32	$.length;	# length of this table in bytes (actual length not padded length)

    sub tag-decode(UInt:D $tag is copy) is export(:tag-decode) {
        my @chrs = (1..4).map: {
            my $chr = ($tag mod 256).chr;
            $tag div= 256;
            $chr;
        }
        @chrs.reverse.join.trim;
    }

    our sub tag-encode(Str:D $s --> UInt) {
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
class TableProxy is rw {
    has $.loader is required;
    has Str $.tag is required;
    has Directory $.dir;
    has buf8 $.buf;
    has $.obj = Font::TTF::Table::Generic.new: :$!tag, :$!buf;
    method buf is rw {
        Proxy.new(
            FETCH => { $!buf //= .pack with $!obj; $!buf },
            STORE => -> $, $!buf { $_ = .WHAT with $!obj }
        );
    }
    method obj is rw {
        Proxy.new(
            FETCH => {
                $!obj //= $!obj.new: :$!tag, :buf($_), :$!loader
                    with $!buf;
                $!obj;
            },
            STORE => -> $, $!obj { $_ = .WHAT with $!buf }
        );
    }
    method live {
        ($!obj // $!buf // $!dir).defined
    }
}
has IO::Handle:D $.fh is required;
has Offsets $!offsets handles<numTables>;

our @KnownTables = [
    Font::TTF::Table::CMap, Font::TTF::Table::Header,
    Font::TTF::Table::HoriHeader, Font::TTF::Table::HoriMetrics,
    Font::TTF::Table::GlyphIndex, Font::TTF::Table::MaxProfile,
    Font::TTF::Table::VertHeader, Font::TTF::Table::VertMetrics,
    Font::TTF::Table::PCLT, Font::TTF::Table::OS2,
];
has TableProxy %!tables = @KnownTables.map: -> $obj {
    my $tag = $obj.tag;
    $tag => TableProxy.new: :$obj, :$tag, :loader(self);
};

method tags {
    %!tables.values.grep(*.live)>>.tag.sort;
}

method directory($tag) { .dir with %!tables{$tag} }

method delete($tag) {
    with %!tables{$tag} {
        .buf = buf8;
        .dir = Directory;
    }
}

submethod TWEAK {
    my Directory @dirs;
    $!fh.seek(0, SeekFromBeginning);
    $!offsets .= read($!fh);

    for 0 ..^ $!offsets.numTables {
        my Directory $dir .= read($!fh);
        my $tag = $dir.tag;
        with %!tables{$tag} {
            .dir = $dir;
        }
        else {
            $_ .= new: :$dir, :$tag, :loader(self);
        }
        @dirs.push: $dir;
    }

    self!check-lengths(@dirs);
}

method !check-lengths(@dirs) {
    my $prev;
    for @dirs.sort(*.offset) -> $dir {
        with $prev {
            my $offset = $dir.offset;
            my $table = %!tables{$prev.tag};
            my $max-len = $dir.offset - $prev.offset;
            die "length for '{.tag}' {.length} > $max-len"
                if .length > $max-len;
        }
        $prev = $dir;
    }
}

multi method buf(Str $tag) {
    with %!tables{$tag} -> $table {
        $table.buf //= do with $table.dir {
            $!fh.seek(.offset, SeekFromBeginning);
            $!fh.read(.length);
        } // buf8;
    }
    else {
        buf8;
    }
}

multi method buf { self.Blob }

#| add or update a table buffer
multi method upd(Blob $buf, Str:D :$tag!) {
    with %!tables{$tag} {
        .buf = $buf;
    }
    else {
        $_ .= new: :$buf;
    }
}

#| add or update a table object
multi method upd(Font::TTF::Table $obj) {
    with %!tables{$obj.tag} {
        .obj = $obj;
    }
    else {
        $_ .= new: :$obj;
    }
}

multi method load(Str $tag) {
    my $buf = self.buf($tag);
    %!tables{$tag}.obj;
}

multi method load(Font::TTF::Table:U $class) {
    ...
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
    my class ManifestItem {
        has Str:D $.tag is required;
        has Blob:D $.buf is required;
    }
    my ManifestItem @manifest;
    for self.tags -> $tag {
        given self.buf($tag) -> $buf {
            @manifest.push: ManifestItem.new: :$tag, :$buf;
        }
    }

    @manifest .= sort(*.tag);

    my uint32  $ver = $!offsets.ver;
    my uint32  $numTables = +@manifest;
    my Offsets:D $offsets .= new(:$ver, :$numTables).init;
    my $buf = $offsets.pack;
    my $offset = Offsets.packed-size  +  $offsets.numTables * Directory.packed-size;

    for @manifest {
        my $tag-str = .tag;
        my uint32 $tag = Directory::tag-encode($tag-str);
        my uint32 $length = .buf.bytes;
        my uint32 $checkSum = sfnt_checksum(.buf, $length);
        my Directory $dir .= new: :$offset, :$tag, :$tag-str, :$length, :$checkSum;
        $buf.append: $dir.pack;
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

