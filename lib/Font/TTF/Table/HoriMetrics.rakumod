use Font::TTF::Table::Generic;

class Font::TTF::Table::HoriMetrics
    is Font::TTF::Table::Generic {

    use Font::TTF::Defs :Sfnt-Struct;
    use Font::TTF::Table::HoriHeader;
    use Font::TTF::Table::MaxProfile;
    use Font::TTF::Subset;
    use CStruct::Packing :&mem-unpack, :&mem-pack;
    use NativeCall;
    
    method tag {'hmtx'}

    has UInt $!num-glyphs;
    has UInt $.num-long-metrics;
    method elems { $!num-glyphs + 1}

    has buf8 $!buf;

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
    method pack(buf8 $buf is rw) {
        $buf = $!buf;
    }
    method subset(Font::TTF::Subset $subset) {
        # todo: rewrite in C
        my $ss-num-glyphs = $subset.len;
        my $ss-num-long-metrics = 0;
        my $gid-map := $subset.gids;

        for 0 ..^ $ss-num-glyphs -> $ss-gid {
            my $gid = $gid-map[$ss-gid];
            if $gid >= $!num-long-metrics {
                # repack short metric
                my $from-offset := 2 * $!num-long-metrics + 2 * $gid;
                my $to-offset := 2 * $ss-num-long-metrics + 2 * $ss-gid;
                $!buf.subbuf-rw($to-offset, 2) = $!buf.subbuf($from-offset, 2)
                    unless $from-offset == $to-offset;
            }
            else {
                # repack long metric
                my $from-offset := 4 * $gid;
                my $to-offset := 4 * $ss-gid;
                $ss-num-long-metrics++;
                $!buf.subbuf-rw($to-offset, 4) = $!buf.subbuf($from-offset, 4)
                    unless $from-offset == $to-offset;
            }
        }
        $!num-glyphs = $ss-num-glyphs;
        $!num-long-metrics = $ss-num-long-metrics;
        $!buf.reallocate($!num-glyphs * 2  +  $!num-long-metrics * 2);
        self;
    }
}
