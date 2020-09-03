use Test;
use Font::TTF;
use Font::TTF::Head;
use Font::TTF::Hhea;
use NativeCall;
plan 17;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $font .= open($fh);

is $font.numTables, 17;

my Font::TTF::Head $head = $font.load('head');

is $head.version, 1;
is $head.fontRevision, 2;
is $head.checkSumAdjustment, 206572268;
is $head.magicNumber, 1594834165;
is $head.flags, 31;

my Font::TTF::Hhea $hhea = $font.load('hhea');
is $hhea.version, 1;
is $hhea.ascent, 1901;
is $hhea.descent, -483;
is $hhea.lineGap, 0;
is $hhea.advanceWidthMax, 2748;
is $hhea.minLeftSideBearing, -375;
is $hhea.minRightSideBearing, -375;
is $hhea.xMaxExtent, 2636;
is $hhea.caretSlopeRise, 1;
is $hhea.numOfLongHorMetrics, 256;

my Font::TTF::Vhea $vhea = $font.load('vhea');
is-deeply $vhea, Font::TTF::Vhea;

done-testing;