use Font::TTF::Defs :types, :Sfnt-Struct, :Sfnt-Table;

class Font::TTF::CMap does Sfnt-Table['cmap'] {
    class Index is repr('CStruct') does Sfnt-Struct {
        has uint16	$.version;          # Version number (Set to zero)
        has uint16  $.numberSubtables;      # Number of encoding subtables
    }

    class Subtable {
        class Encoding is repr('CStruct') does Sfnt-Struct {
            has uint16	$.platformID;   	# Platform identifier
            has uint16	$.platformSpecificID;	# Platform-specific encoding identifier
            has uint32	$.offset;       	# Offset of the mapping table
        }
        has Encoding $.encoding handles<platformID platformSpecificID offset>;
        has blob8 $.subbuf;
        has $.obj;
    }

    has Index $.index;
    has Subtable @.subtables handles<AT-POS Numeric elems>;
    
    multi method unpack(Font::TTF::CMap:U: |c) {
        self.new.unpack(|c);
    }
    multi method unpack(Font::TTF::CMap:D: buf8 $buf) {
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
