unit class Font::TTF::Table::CMap::Format0;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;

use Font::TTF::Table::CMap::Header16;

has Font::TTF::Table::CMap::Header16 $.header handles<format length language>;

has CArray[uint8] $!glyphIndexArray handles<AT-POS elems>;  # [variable] Glyph index array

multi submethod TWEAK(:@glyphIndexArray!) {
    $!header .= new;
    $!header.length = 262;
    $!glyphIndexArray .= new: @glyphIndexArray;
}

multi submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    $!glyphIndexArray .= new;
    $!glyphIndexArray[255] = 0;  # allocate
    mem-unpack($!glyphIndexArray, $buf.subbuf($offset), :endian(NetworkEndian));
}

method encode(UInt:D \c) {
    c < 256
        ?? $!glyphIndexArray[c]
        !! 0;
}

method pack(buf8 $buf = buf8.new) {
    $buf.reallocate(0);
    $!header.pack($buf);
    $buf.append: mem-pack($!glyphIndexArray, :endian(NetworkEndian));
    $buf;
}
