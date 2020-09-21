use Font::TTF::Table::Generic;

class Font::TTF::Table::CMap
    is Font::TTF::Table::Generic {

    use Font::TTF::Defs :types, :Sfnt-Struct;
    use Font::TTF::Table::CMap::Format0;
    use Font::TTF::Table::CMap::Format4;
    use Font::TTF::Table::CMap::Generic;

    method tag {'cmap'}

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
        has Encoding $.encoding handles<platformID platformEncodingID offset>;
        class FormatHeader is repr('CStruct') does Sfnt-Struct {
            has uint16	$.format;
            has uint16	$.length;
            has uint16  $.language;
        }
        has buf8 $.subbuf is required;
        has $!object;
        multi method load(Subtable:U:) { self }
        multi method load(Subtable:D:) {
            $!object //= do {
                # Peek at the first two fields, which are aloways
                # format and length
                my FormatHeader:D $hdr .= unpack($!subbuf);

                my $class = do given $hdr.format {
                    when 0 {
                        Font::TTF::Table::CMap::Format0;
                    }
                    when 4 {
                        Font::TTF::Table::CMap::Format4;
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
    
    submethod TWEAK {
        my $buf := self.buf;
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
                !! $buf.elems - $offset;

            my Blob:D $subbuf := $buf.subbuf($offset, $len);
            Subtable.new: :$encoding, :$subbuf;
        }

        self;
    }

    method pack(|) {...}
}
