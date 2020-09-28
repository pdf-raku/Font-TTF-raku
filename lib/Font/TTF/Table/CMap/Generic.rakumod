unit class Font::TTF::Table::CMap::Generic;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;
use Font::TTF::Table::CMap::Header16;
use Font::TTF::Table::CMap::Header32;

has $.header handles<format length language>;
has CArray[uint8] $.data;  # [variable] Unparsed bytes

submethod TWEAK(buf8:D :$buf!) {
    my uint16 $format = $buf.read-uint16(0, NetworkEndian);

    my $class := $format >= 8
        ?? Font::TTF::Table::CMap::Header32
        !! Font::TTF::Table::CMap::Header16;

    $!header = $class.unpack($buf);
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
