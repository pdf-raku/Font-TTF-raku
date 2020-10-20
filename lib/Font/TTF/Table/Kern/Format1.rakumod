unit class Font::TTF::Table::Kern::Format1;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;

class KernPair is repr('CStruct') does Sfnt-Struct {
    has uint16 $.left;
    has uint16 $.right;
    has int16  $.value;
}

class Header is repr('CStruct') does Sfnt-Struct {
    has uint16	$.nPairs;	# The number of kerning pairs in this subtable.
    has uint16	$.searchRange;	# The largest power of two less than or equal to the value of nPairs, multiplied by the size in bytes of an entry in the subtable.
    has uint16	$.entrySelector;	# This is calculated as log2 of the largest power of two less than or equal to the value of nPairs. This value indicates how many iterations of the search loop have to be made. For example, in a list of eight items, there would be three iterations of the loop.
    has uint16	$.rangeShift;	# The value of nPairs minus the largest power of two less than or equal to nPairs. This is multiplied by the size in bytes of an entry in the table.
}

constant RecSize = KernPair.packed-size;
has Header $.header;
has buf8 $!data;

submethod TWEAK(buf8:D :subbuf($buf)!) {
    $!header .= unpack($buf);
    $!data = $buf.subbuf(Header.packed-size);
}

method elems { $!header.nPairs }

method AT-POS(UInt:D $i) {
    my $offset = $i * RecSize;
    KernPair.unpack($!data, :$offset);
}
