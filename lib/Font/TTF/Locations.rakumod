use Font::TTF::Defs :Sfnt-Struct, :Sfnt-Table;
use Array::Agnostic;

class Font::TTF::Locations does Sfnt-Table['loca'] {

    use Font::TTF::Header;
    use Font::TTF::MaxProfile;
    use CStruct::Packing;
    use NativeCall;
    
    has UInt $.num-glyphs;

    role Offset does Sfnt-Struct {
    }
    has CArray $.offsets handles<elems AT-POS>;

    class OffsetShort is repr('CStruct') does Offset {
        has uint16 $.word;
        method byte { $!word * 2 }
    }

    class OffsetLong  is repr('CStruct') does Offset {
        has uint32 $.byte;
    }

    multi method unpack(Font::TTF::Locations:U: |c) {
        self.new.unpack(|c);
    }
    multi method unpack(Font::TTF::Locations:D: buf8 $buf, :$loader) {
        my Font::TTF::Header:D $head .= load($loader);
        my Font::TTF::MaxProfile:D $maxp .= load($loader);

        $!num-glyphs = $maxp.numGlyphs;

        my $class = ? $head.indexToLocFormat
            ?? OffsetLong
            !! OffsetShort;

        my Buf $locs-buf = $loader.read(self.tag);
        $!offsets = $class.unpack-array($locs-buf, $!num-glyphs+1);
        self;
    }
    method pack(buf8 $buf) {
        ...
    }
}
