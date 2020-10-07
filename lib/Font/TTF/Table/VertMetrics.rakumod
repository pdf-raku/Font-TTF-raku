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

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-long-metrics) is default {
        my $offset := 4 * $gid;
        longVertMetric.unpack($!buf, :$offset);
    }

    multi method AT-POS(Int() $gid where 0 <= * <= $!num-glyphs) {
        my $offset := 2 * $!num-long-metrics + 2 * $gid;
        my $rv := shortVertMetric.unpack($!buf, :$offset);
        if $!num-long-metrics {
            # advanceHeight is inherited from last long metric
            my $advanceHeight  := self.AT-POS($!num-long-metrics - 1).advanceHeight;
            my $topSideBearing := $rv.topSideBearing;
            $rv := longVertMetric.new: :$advanceHeight, :$topSideBearing;
        }
        $rv;
    }

    constant VertHeader = Font::TTF::Table::VertHeader;
    constant MaxProfile = Font::TTF::Table::MaxProfile;

    multi submethod TWEAK(
        :$loader!,
        VertHeader:D :$vhea = VertHeader.load($loader),
        :@metrics! ) {
        my longVertMetric  @long;
        my shortVertMetric @short;
        with @metrics.first(shortVertMetric, :kv) {
            @long = @metrics.head($_);
            @short = @metrics[$_ .. *];
        }
        else {
            @long = @metrics;
        }

        # convert long metrics to short, if possible
        while @long >= 2 && do given @long.tail(2) { .[0].advanceHeight == .[1].advanceHeight } {
            given @long.pop {
                my $topSideBearing = .topSideBearing;
                @short.unshift: shortVertMetric.new: :$topSideBearing;
            }
        }

        $!num-glyphs = +@metrics;
        $!num-long-metrics = +@long;
        $!buf .= new;
        $!buf.append: .pack for @long;
        $!buf.append: .pack for @short;

        $loader.upd($vhea).numOfLongVerMetrics = $!num-long-metrics;
    }

    multi submethod TWEAK(
        :$loader,
        VertHeader:D :$vhea = VertHeader.load($loader),
        :$!buf              = $loader.buf(self.tag),
    ) {

        $!num-long-metrics = $vhea.numOfLongVerMetrics;
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
