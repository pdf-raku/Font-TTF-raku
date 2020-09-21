unit class Font::TTF::Table::CMap::Format4;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;

class Header is repr('CStruct') does Sfnt-Struct {

    has uint16	$.format;               # Format number is set to 4
    has uint16	$.length;               # Length of subtable in bytes
    has uint16	$.language;             # Language code (see above)
    has uint16	$.segCountX2;           # 2 * segCount
    has uint16	$.searchRange;          # 2 * (2**FLOOR(log2(segCount)))
    has uint16	$.entrySelector;        # log2(searchRange/2)
    has uint16	$.rangeShift;           # (2 * segCount) - searchRange 
}

has Header $.header handles<format length language segCountX2 searchRange entrySelector rangeShift>;

has CArray[uint8] $!heap;
# pointers into the heap
has Pointer $.endCode;          # [segCount] Ending character code for each segment, last = 0xFFFF.
has uint16  $!reservedPad;       	# value should be zero
has Pointer $.startCode;        # [segCount] Starting character code for each segment
has Pointer $.idDelta;          # [segCount] Delta for all character codes in segment
has Pointer $.idRangeOffset;    # [segCount] Offset in bytes to glyph indexArray, or 0
has Pointer $.glyphIndexArray;  # [variable] Glyph index array

method tag {'cmap'}

submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    my UInt:D $heap-len = self.length - $offset;
    my UInt:D $seg-len = self.segCountX2;
    $!heap .= new;
    $!heap[$heap-len] = 0; # allocate
    mem-unpack($!heap, $buf.subbuf($offset, $heap-len), :endian(NetworkEndian));
    my UInt:D $addr = +nativecast(Pointer[uint16], $!heap);
    $!endCode = Pointer[uint16].new($addr);
    $addr += nativesizeof(uint16); # skip $!reservedPad
    $!startCode       = Pointer[uint16].new($addr += $seg-len);
    $!idDelta         = Pointer[uint16].new($addr += $seg-len);
    $!idRangeOffset   = Pointer[uint16].new($addr += $seg-len);
    $!glyphIndexArray = Pointer[uint16].new($addr);
}
