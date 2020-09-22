use Font::TTF::Table::Generic;

class Font::TTF::Table::HoriMetrics
    is Font::TTF::Table::Generic {

    use Font::TTF::Defs :Sfnt-Struct;
    use Font::TTF::Table::HoriHeader;
    use Font::TTF::Table::MaxProfile;
    use CStruct::Packing :&mem-unpack, :&mem-pack;
    use NativeCall;
    
    method tag {'hmtx'}

    has UInt $!num-glyphs;
    has UInt $.num-long-metrics;
    has buf8 $!buf;

    method elems { $!num-glyphs + 1}

    class longHoriMetric is repr('CStruct') does Sfnt-Struct {
        has uint16 $.advanceWidth;
        has uint16 $.leftSideBearing;
    }

    class shortHoriMetric is repr('CStruct') does Sfnt-Struct {
        has uint16 $.leftSideBearing;
    }

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-long-metrics) {
        my $offset := 4 * $gid;
        longHoriMetric.unpack($!buf, :$offset);
    }

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-glyphs) {
        my $offset := 2 * $!num-long-metrics + 2 * $gid;
        shortHoriMetric.unpack($!buf, :$offset);
    }

    constant HoriHeader = Font::TTF::Table::HoriHeader;
    constant MaxProfile = Font::TTF::Table::MaxProfile;

    submethod TWEAK(
        :$loader,
        HoriHeader:D :$hhea = HoriHeader.load($loader),
        MaxProfile:D :$maxp = MaxProfile.load($loader),
        :$!buf              = $loader.buf(self.tag),
    ) {

        $!num-glyphs = $maxp.numGlyphs;
        $!num-long-metrics = $hhea.numOfLongHorMetrics;
        self;
    }
    multi method pack { $!buf }
    multi method pack(buf8:D $buf) {
        $buf.reallocate(0);
        $buf.append: $!buf;
    }
}
