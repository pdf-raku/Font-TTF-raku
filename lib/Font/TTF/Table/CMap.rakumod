use Font::TTF::Table::Generic;

class Font::TTF::Table::CMap
    is Font::TTF::Table::Generic {

    use Font::TTF::Defs :types, :Sfnt-Struct;
    use Font::TTF::Table::CMap::Format0;
    use Font::TTF::Table::CMap::Format4;
    use Font::TTF::Table::CMap::Format12;
    use Font::TTF::Table::CMap::Generic;
    use CStruct::Packing :Endian;

    method tag {'cmap'}

    method buf { callsame() //= self.pack }

    class Index is repr('CStruct') does Sfnt-Struct {
        has uint16 $.version;          # Version number (Set to zero)
        has uint16 $.numberSubtables;  # Number of encoding subtables
    }

    class Subtable {
        class Encoding is repr('CStruct') does Sfnt-Struct {
            has uint16	$.platformID;   	# Platform identifier
            has uint16	$.platformEncodingID;	# Platform-specific encoding identifier
            has uint32	$.offset;       	# Offset of the mapping table
        }
        has Encoding $.encoding handles<platformID platformEncodingID offset pack>;
        has buf8 $.subbuf;
        method subbuf {
            $!subbuf //= self.object.buf;
        }
        has $.object;
        method object(Subtable:D:) {
            $!object //= do {
                # Peek at the first two fields, which are always
                # format and length
                my UInt $format = $!subbuf.read-uint16(0, NetworkEndian);
                unless $format {
                    # format header can be 2 or 4 bit. format 0 always has
                    # length 262; otherwise assume 4-bit format.
                    unless 262 == $!subbuf.read-uint16(2, NetworkEndian) {
                        $format = $!subbuf.read-uint32(0, NetworkEndian);
                    }
                }

                my $class = do given $format {
                    when 0 {
                        Font::TTF::Table::CMap::Format0;
                    }
                    when 4 {
                        Font::TTF::Table::CMap::Format4;
                    }
                    when 12 {
                        Font::TTF::Table::CMap::Format12;
                    }
                    default {
                        warn "todo format $_";
                        Font::TTF::Table::CMap::Generic;
                    }
                }
                $class.new: :buf($!subbuf);
            }
        }
    }

    has Index $.index;
    has Subtable @.subtables handles<AT-POS Numeric elems>;
    
    multi submethod TWEAK(:$buf!) {
        $!index .= unpack($buf);
        my UInt $offset = $!index.packed-size;
        my UInt $encoding-size = Subtable::Encoding.packed-size;
        my UInt $num-tables = $!index.numberSubtables;
        my Subtable::Encoding @encodings;

        for 0 ..^ $num-tables {
            @encodings.push: Subtable::Encoding.unpack($buf, :$offset);
            $offset += $encoding-size;
        }

        @encodings .= sort: *.offset;

        @!subtables = @encodings.pairs.map: {
            my Subtable::Encoding $encoding = .value;
            my UInt $n := .key + 1;
            my UInt $offset := $encoding.offset;
            my UInt $len := $n < +@encodings
                ?? @encodings[.key + 1].offset - $offset
                !! $buf.bytes - $offset;

            my Blob:D $subbuf := $buf.subbuf($offset, $len);
            Subtable.new: :$encoding, :$subbuf;
        }

        self;
    }

    # handle simple case of building a single type-12 encoding table
    multi submethod TWEAK(Font::TTF::Table::CMap::Format12 :format($object)!) {
        # wrap formats
        $!index .= new: :version(0), :numberSubtables(1);
        my $offset = $!index.packed-size + Subtable::Encoding.packed-size;
        my Subtable::Encoding $encoding .= new: :platformId(0), :platformEncodingID(4), :$offset;

        @!subtables = [ Subtable.new: :$encoding, :$object, ];
    }
    method pack(buf8 $buf = buf8.new) {
        $buf.reallocate(0);
        $!index.pack($buf);
        $buf.append(.pack)
            for @!subtables;
        $buf.append(.object.pack)
            for @!subtables;
        $buf;
    }
}
