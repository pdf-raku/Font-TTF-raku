unit class Font::TTF::Table::CMap::Format0;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;

class Header is repr('CStruct') does Sfnt-Struct {

    has uint16	$.format;               # Format number is set to 0
    has uint16	$.length;               # Length of subtable in bytes
    has uint16	$.language;             # Language code (see above)
}

has Header $.header handles<format length language>;

has CArray[uint8] $.glyphIndexArray handles<AT-POS elems>;  # [variable] Glyph index array

submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    $!glyphIndexArray .= new;
    $!glyphIndexArray[255] = 0;  # allocate
    mem-unpack($!glyphIndexArray, $buf.subbuf($offset), :endian(NetworkEndian));
}

method pack(buf8 $buf = buf8.new) {
    $buf.reallocate(0);
    $!header.pack($buf);
    $buf.append: mem-pack($!glyphIndexArray, :endian(NetworkEndian));
    $buf;
}
