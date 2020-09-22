unit class Font::TTF::Table::CMap::Generic;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;

class Header is repr('CStruct') does Sfnt-Struct {

    has uint16	$.format;        # Format number
    has uint16	$.length;        # Length of subtable in bytes
    has uint16	$.language;      # Language code
}

has Header $.header handles<format length language>;
has CArray[uint8] $.data;  # [variable] Unparsed bytes

submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    my UInt $bytes = $buf.bytes = $!header.length;
    $!data .= new;
    $!data[$bytes - 1] = 0 # allocate
        if $bytes;
    mem-unpack($!data, $buf.subbuf($offset, $bytes));
}

method pack(buf8 $buf = buf8.new) {
    $buf.reallocate(self.length);
    $!header.pack($buf);
    my UInt $offset = $!header.packed-size;
    my UInt $bytes = $buf.bytes - $!header.length;
    die "data/length mismatch (length ({self.length}) != data bytes ($bytes)"
        unless $!data.elems + $offset == self.length;
    mem-pack($!data, $buf.subbuf-rw($offset, $bytes));
}
