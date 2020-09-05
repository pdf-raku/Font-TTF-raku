class Font::TTF {

    use CStruct::Packing :Endian;
    use Font::TTF::Util;
    use Font::TTF::Defs :Sfnt-Struct;
    use Font::TTF::Head;
    use Font::TTF::Hhea;
    use Font::TTF::Maxp;
    use Font::TTF::OS2;
    use Font::TTF::PCLT;
    use Font::TTF::Post;
    use Font::TTF::Vhea;
    use NativeCall;

    class Offsets is repr('CStruct') does Sfnt-Struct {
        has uint32  $.ver;
        has uint16  $.numTables;
        has uint16  $.searchRange;
        has uint16  $.entrySelector;
        has uint16  $.rangeShift;
    }

    class Directory is repr('CStruct') does Sfnt-Struct {
        has uint32	$.tag; 	        # 4-byte identifier
        sub tag-decode(UInt:D $tag is copy) is export(:tag-decode) {
            my @chrs = (1..4).map: {
                my $chr = ($tag mod 256).chr;
                $tag div= 256;
                $chr;
            }
            @chrs.reverse.join;
        }

        sub tag-encode(Str:D $s --> UInt) is export {
            my uint32 $enc = 0;
            for $s.ords {
                $enc *= 256;
                $enc += $_;
            }
            $enc;
        }

        method tag {
            tag-decode($!tag);
        }

        has uint32	$.checkSum;	# checksum for this table
        has uint32	$.offset;	# offset from beginning of sfnt
        has uint32	$.length;	# length of this table in byte (actual length not padded length)
    }
    has IO::Handle $!fh;
    has Offsets $!offsets handles<numTables>;
    has %!position;
    has %!length;
    has Directory @!directories;
    has %!tables = %(
        :head(Font::TTF::Head),
        :hhea(Font::TTF::Hhea),
        :maxp(Font::TTF::Maxp),
        'OS/2' =>Font::TTF::OS2,
        :post(Font::TTF::Post),
        :PCLT(Font::TTF::PCLT),
        :vhea(Font::TTF::Vhea),
    );
    method tables {
        %!position.sort(*.value).map(*.key);
    }
        
    multi method open(Font::TTF:U: |c) {
        self.new.open(|c);
    }
    multi method open(Font::TTF:D: $!fh) {
        $!offsets .= read($!fh);
        die "can't handle this format" unless $!offsets.ver == 65536;

        for 1 .. $!offsets.numTables {
            my Directory $dir .= read($!fh);
            %!position{$dir.tag} = $dir.offset;
            @!directories.push: $dir;
        }

        self!setup-lengths();
        self;
    }

    method !setup-lengths {
        my $prev;
        for %!position.pairs.sort(*.value) {
            if $prev.defined {
                %!length{$prev.key} = .value - $prev.value;
            }
            $prev = $_;
        }
    }

    method load(Str $table where {%!tables{$_}:exists}) {
        without %!tables{$table} {
            with %!position{$table} -> $pos {
                $!fh.seek($pos, SeekFromBeginning);
                my $size = .packed-size;
                my $len = %!length{$table};
                if !$len || $len < $size {
                    # last or truncated record
                    my $buf = $!fh.read($len // $size);
                    $_ .= unpack($buf, :pad);
                }
                else {
                    $_ .= read($!fh, :pad);
                }
            }
        }
        %!tables{$table};
    }
}
