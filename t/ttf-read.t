use Test;
use Font::TTF;
use Font::TTF::Head;
use NativeCall;
plan 6;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $font .= open($fh);

is $font.numTables, 17;

my Font::TTF::Head $head = $font.load('head');

is $head.version, 1;
is $head.fontRevision, 2;
is $head.checkSumAdjustment, 206572268;
is $head.magicNumber, 1594834165;
is $head.flags, 31;
done-testing;