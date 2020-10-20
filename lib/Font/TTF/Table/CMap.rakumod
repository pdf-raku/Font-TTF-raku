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

    class Index is repr('CStruct') does Sfnt-Struct {
        has uint16 $.version;          # Version number (Set to zero)
        has uint16 $.numberSubtables;  # Number of encoding subtables
    }

    class Subtable {
        class Encoding is repr('CStruct') does Sfnt-Struct {
            has uint16	$.platformID;   	# Platform identifier
            has uint16	$.platformEncodingID;	# Platform-specific encoding identifier
            has uint32	$.offset is rw;       	# Offset of the mapping table
        }
        has Encoding $.encoding handles<platformID platformEncodingID offset pack>;
        has buf8 $.subbuf;
        method subbuf {
            $!subbuf //= self.object.buf;
        }
        method !delegate(UInt:D $_) {
            when 262 {
                # actually format 0 (2 bytes) + length 262 (2 bytes)
                Font::TTF::Table::CMap::Format0;
            }
            when 4 {
                Font::TTF::Table::CMap::Format4;
            }
            when 12 {
                Font::TTF::Table::CMap::Format12;
            }
            default {
                warn "todo CMap format $_";
                Font::TTF::Table::CMap::Generic;
            }
        }
        has $.object;
        method object(Subtable:D:) handles<AT-POS elems> {
            $!object //= do {
                # Peek at the first two fields, which are always
                # format and length
                my UInt $format = $!subbuf.read-uint16(0, NetworkEndian)
                    || $!subbuf.read-uint32(0, NetworkEndian);

                my $class = self!delegate($format);
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

    multi submethod TWEAK( :@tables! ) {
        # wrap formats
        $!index .= new: :version(0), :numberSubtables(+@tables);

        for @tables -> $object {
            my Subtable::Encoding $encoding = do given $object {
                when Font::TTF::Table::CMap::Format0 {
                    Subtable::Encoding.new(:platformID(1), :platformEncodingID(0));
                }
                when Font::TTF::Table::CMap::Format4 {
                    Subtable::Encoding.new(:platformID(3), :platformEncodingID(1));
                }
                when Font::TTF::Table::CMap::Format12 {
                    Subtable::Encoding.new(:platformID(0), :platformEncodingID(4));
                }
                default {
                    fail "unable to pack CMap subtable {.WHAT.raku}";
                }
            }
            @!subtables.push: Subtable.new: :$encoding, :$object;
        }
    }

    method pack(buf8 $buf = buf8.new) {
        my $header-size = $!index.packed-size +  Subtable::Encoding.packed-size * @!subtables.elems;
        my buf8 $data-buf .= new;

        $buf.reallocate(0);
        $!index.pack($buf);

        for @!subtables {
            .offset = $header-size + $data-buf.bytes;
            $buf.append: .pack;
            $data-buf.append: .object.pack;
        }

        $buf.append: $data-buf;
    }
}
