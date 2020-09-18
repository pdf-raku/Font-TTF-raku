unit module Font::TTF::Raw;

use Font::TTF::Defs :$SFNT-LIB;
use NativeCall;

sub sfnt_checksum(Blob, size_t --> uint32)
    is export is native($SFNT-LIB) {*}

