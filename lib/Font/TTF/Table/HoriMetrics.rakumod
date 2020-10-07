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

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-long-metrics) is default {
        my $offset := 4 * $gid;
        longHoriMetric.unpack($!buf, :$offset);
    }

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-glyphs) {
        my $offset := 2 * $!num-long-metrics + 2 * $gid;
        my $rv := shortHoriMetric.unpack($!buf, :$offset);
        if $!num-long-metrics {
            # advanceWidth is inherited from last long metric
            my $advanceWidth  := self.AT-POS($!num-long-metrics - 1).advanceWidth;
            my $leftSideBearing := $rv.leftSideBearing;
            $rv := longHoriMetric.new: :$advanceWidth, :$leftSideBearing;
        }
        $rv;
    }

    constant HoriHeader = Font::TTF::Table::HoriHeader;

    multi submethod TWEAK(
        :$loader!,
        HoriHeader:D :$hhea = HoriHeader.load($loader),
        :@metrics! ) {
        my longHoriMetric  @long;
        my shortHoriMetric @short;
        with @metrics.first(shortHoriMetric, :kv) {
            @long = @metrics.head($_);
            @short = @metrics[$_ .. *];
        }
        else {
            @long = @metrics;
        }

        # convert long metrics to short, if possible
        while @long >= 2 && do given @long.tail(2) { .[0].advanceWidth == .[1].advanceWidth } {
            given @long.pop {
                my $leftSideBearing = .leftSideBearing;
                @short.unshift: shortHoriMetric.new: :$leftSideBearing;
            }
        }

        $!num-glyphs = +@metrics;
        $!num-long-metrics = +@long;
        $!buf .= new;
        $!buf.append: .pack for @long;
        $!buf.append: .pack for @short;

        $loader.upd($hhea).numOfLongHorMetrics = $!num-long-metrics;
    }

    multi submethod TWEAK(
        :$loader!,
        HoriHeader:D :$hhea = HoriHeader.load($loader),
        :$!buf              = $loader.buf(self.tag),
    ) {

        $!num-long-metrics = $hhea.numOfLongHorMetrics;
        $!num-glyphs = do given $!buf.bytes div 2 {
            $_ - $!num-long-metrics
        }
    }
    multi method pack { $!buf }
    multi method pack(buf8:D $buf) {
        $buf.reallocate(0);
        $buf.append: $!buf;
    }
}
