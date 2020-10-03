unit class Font::TTF::Table::CMap::Format4;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;

use Font::TTF::Table::CMap::Header16;
class Header
    is repr('CStruct')
    is Font::TTF::Table::CMap::Header16 {

    has uint16	$.segCountX2;           # 2 * segCount
    has uint16	$.searchRange;          # 2 * (2**FLOOR(log2(segCount)))
    has uint16	$.entrySelector;        # log2(searchRange/2)
    has uint16	$.rangeShift;           # (2 * segCount) - searchRange
    method segCount {
        $!segCountX2 div 2;
    }

    method init {
        $!searchRange = 2;
        $!entrySelector = 0;

        while $!searchRange < self.segCount {
            $!searchRange *= 2;
            $!entrySelector++;
        }
        $!searchRange *= 32;
        $!rangeShift = self.segCount * 16  -  $!searchRange;
        self;
    }
}

has Header $.header handles<format length language segCountX2 segCount searchRange entrySelector rangeShift>;

has CArray[uint16] $!endCode;          # [segCount] Ending character code for each segment, last = 0xFFFF.
has uint16 $!reservedPad;              # value should be zero
has CArray[uint16] $!startCode;        # [segCount] Starting character code for each segment
has CArray[int16]  $!idDelta;          # [segCount] Delta for all character codes in segment
has CArray[uint16] $!idRangeOffset;    # [segCount] Offset in bytes to glyph indexArray, or 0
has CArray[uint16] $!glyphIndexArray;  # [variable] Glyph index array

sub unpack-array($carray is rw, $buf, $offset, $bytes = $buf.bytes - $offset) {
    my $words = $bytes div 2;
    $carray .= new();
    $carray[$words - 1] = 0 if $words;
    mem-unpack($carray, $buf.subbuf($offset, $bytes), :endian(NetworkEndian))
}

multi submethod TWEAK(UInt:D :$segCount!, :@startCode!, :@endCode!, :@idDelta!, :@idRangeOffset!, :@glyphIndexArray!) {
    $!header .= new: :format(4), :segCountX2($segCount * 2);
    $!header.init;

    $!startCode .= new: @startCode;
    $!endCode .= new: @endCode;
    $!idDelta .= new: @idDelta;
    $!idRangeOffset .= new: @idRangeOffset;
    $!glyphIndexArray .= new: @glyphIndexArray;
}

multi submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    my UInt:D $seg-len = self.segCountX2;

    unpack-array($!endCode,         $buf, $offset, $seg-len);
    $offset += 2; # skip $!reservedPad
    unpack-array($!startCode,       $buf, $offset += $seg-len, $seg-len);
    unpack-array($!idDelta,         $buf, $offset += $seg-len, $seg-len);
    unpack-array($!idRangeOffset,   $buf, $offset += $seg-len, $seg-len);
    unpack-array($!glyphIndexArray, $buf, $offset += $seg-len);
}

method pack(buf8 $buf = buf8.new) {
    my $endian = NetworkEndian;

    $buf.reallocate($!header.packed-size); # skip header for now

    $buf.append: mem-pack($!endCode,         :$endian);
    $buf.append: (0,0); # padding
    $buf.append: mem-pack($!startCode,       :$endian);
    $buf.append: mem-pack($!idDelta,         :$endian);
    $buf.append: mem-pack($!idRangeOffset,   :$endian);
    $buf.append: mem-pack($!glyphIndexArray, :$endian);

    $!header.length = $buf.bytes;
    $buf.subbuf-rw(0, $!header.packed-size) = $!header.pack;

    $buf;
}
