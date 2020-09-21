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
    method segCount { $!segCountX2 div 2 }
}

has Header $.header handles<format length language segCountX2 segCount searchRange entrySelector rangeShift>;

has CArray[uint16] $.endCode;          # [segCount] Ending character code for each segment, last = 0xFFFF.
has uint16 $!reservedPad;       	# value should be zero
has CArray[uint16]$.startCode;        # [segCount] Starting character code for each segment
has CArray[uint16] $.idDelta;          # [segCount] Delta for all character codes in segment
has CArray[uint16] $.idRangeOffset;    # [segCount] Offset in bytes to glyph indexArray, or 0
has CArray[uint16] $.glyphIndexArray;  # [variable] Glyph index array

sub unpack-array($carray is rw, $buf, $offset, $bytes = $buf.bytes - $offset) {
    my $words = $bytes div 2;
    $carray .= new();
    $carray[$words] = 0;
    mem-unpack($carray, $buf.subbuf($offset, $bytes), :endian(NetworkEndian))
}

submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    my UInt:D $heap-len = self.length - $offset;
    my UInt:D $seg-len = self.segCountX2;
    unpack-array($!endCode,         $buf, $offset, $seg-len);
    $offset++; # skip $!reservedPad
    unpack-array($!startCode,       $buf, $offset += $seg-len, $seg-len);
    unpack-array($!idDelta,         $buf, $offset += $seg-len, $seg-len);
    unpack-array($!idRangeOffset,   $buf, $offset += $seg-len, $seg-len);
    unpack-array($!glyphIndexArray, $buf, $offset += $seg-len);
}
