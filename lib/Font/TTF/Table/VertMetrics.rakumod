use Font::TTF::Table::Generic;

class Font::TTF::Table::VertMetrics
    is Font::TTF::Table::Generic {

    use Font::TTF::Defs :Sfnt-Struct;
    use Font::TTF::Table::VertHeader;
    use Font::TTF::Table::MaxProfile;
    use CStruct::Packing :&mem-unpack, :&mem-pack;
    use NativeCall;

    method tag {'vmtx'}

    has UInt $!num-glyphs;
    has UInt $.num-long-metrics;
    has buf8 $!buf;

    method elems { $!num-glyphs + 1}

    class longVertMetric is repr('CStruct') does Sfnt-Struct {
        has uint16 $.advanceHeight;
        has uint16 $.topSideBearing;
    }

    class shortVertMetric is repr('CStruct') does Sfnt-Struct {
        has uint16 $.topSideBearing;
    }

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-long-metrics) {
        my $offset := 4 * $gid;
        longVertMetric.unpack($!buf, :$offset);
    }

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-glyphs) {
        my $offset := 2 * $!num-long-metrics + 2 * $gid;
        shortVertMetric.unpack($!buf, :$offset);
    }

    constant VertHeader = Font::TTF::Table::VertHeader;
    constant MaxProfile = Font::TTF::Table::MaxProfile;

    submethod TWEAK(
        :$loader,
        VertHeader:D :$vhea = VertHeader.load($loader),
        MaxProfile:D :$maxp = MaxProfile.load($loader),
        :$!buf              = $loader.buf(self.tag),
    ) {

        $!num-glyphs = $maxp.numGlyphs;
        $!num-long-metrics = $vhea.numOfLongVerMetrics;
        self;
    }
    multi method pack { $!buf }
    multi method pack(buf8:D $buf) {
        $buf.reallocate(0);
        $buf.append: $!buf;
    }
}
