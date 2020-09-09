use Font::TTF::Defs :types, :Sfnt-Struct, :Sfnt-Table;

class Font::TTF::CMap does Sfnt-Table['cmap'] {
    class Index is repr('CStruct') does Sfnt-Struct {
        has uint16	$.version;          # Version number (Set to zero)
        has uint16  $.numberSubtables;      # Number of encoding subtables
    }
    has Index $.index;

    class Subtable is repr('CStruct') does Sfnt-Struct {
        has uint16	$.platformID;   	# Platform identifier
        has uint16	$.platformSpecificID;	# Platform-specific encoding identifier
        has uint32	$.offset;       	# Offset of the mapping table
    }
    has Subtable @.subtables handles<AT-POS Numeric elems>;
    
    multi method unpack(Font::TTF::CMap:U: |c) {
        self.new.unpack(|c);
    }
    multi method unpack(Font::TTF::CMap:D: buf8 $buf, :$loader) {
        $!index .= unpack($buf);
        my UInt $offset = $!index.packed-size;
        my UInt $subtable-size = Subtable.packed-size;
        my UInt $num-tables = $!index.numberSubtables;

        for 0 ..^ $num-tables {
            @!subtables.push: Subtable.unpack($buf, :$offset);
            $offset += $subtable-size;
        }
        self;
    }
    method pack(|) {...}
}
