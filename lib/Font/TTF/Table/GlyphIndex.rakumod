use Font::TTF::Table::Generic;

class Font::TTF::Table::GlyphIndex
    is Font::TTF::Table::Generic {

    use Font::TTF::Defs :Sfnt-Struct;
    use Font::TTF::Table::Header;
    use Font::TTF::Table::MaxProfile;
    use CStruct::Packing :&mem-unpack, :&mem-pack;
    use NativeCall;
    
    method tag {'loca'}

    has UInt $.num-glyphs is rw;
    method elems { $!num-glyphs + 1}

    has CArray $.offsets;
    has UInt $!scale;

    method AT-POS(Int() $idx where 0 <= * <= $!num-glyphs) {
        $!offsets[$idx] * $!scale;
    }

    constant Header = Font::TTF::Table::Header;
    constant MaxProfile = Font::TTF::Table::MaxProfile;

    submethod TWEAK(
        :$loader,
        Header:D :$head     = Header.load($loader),
        MaxProfile:D :$maxp = MaxProfile.load($loader),
        Buf :$buf           = $loader.buf(self.tag),
    ) {

        $!num-glyphs = $maxp.numGlyphs;
        my $is-long := ? $head.indexToLocFormat;

        my CArray $class = $is-long
            ?? CArray[uint32]
            !! CArray[uint16];

        $!offsets = mem-unpack($class, $buf, :n($!num-glyphs+1), :endian(NetworkEndian));
        $!scale = $is-long ?? 1 !! 2;
        self;
    }
    method pack(buf8 $buf) {
        mem-pack($!offsets, :n($!num-glyphs+1), :endian(NetworkEndian));
    }
}
