use Test;
use Font::TTF;
use Font::TTF::Head;
use Font::TTF::Hhea;
use Font::TTF::Maxp;
use Font::TTF::OS2;
use Font::TTF::PCLT;
use NativeCall;
plan 50;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $ttf .= open($fh);

is $ttf.numTables, 17;

my Font::TTF::Head $head = $ttf.load('head');

is $head.version, 1;
is $head.fontRevision, 2;
is $head.checkSumAdjustment, 206572268;
is $head.magicNumber, 1594834165;
is $head.flags, 31;

my Font::TTF::Hhea $hhea = $ttf.load('hhea');
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

my Font::TTF::Vhea $vhea = $ttf.load('vhea');
is-deeply $vhea, Font::TTF::Vhea;

my Font::TTF::OS2 $os2 = $ttf.load('OS/2');
is $os2.version, 1;
is $os2.xAvgCharWidth, 1038;
is $os2.usWeightClass, 400;
is $os2.usWidthClass, 5;

my Font::TTF::PCLT $pclt = $ttf.load('PCLT');

is $pclt.version, 1;
is $pclt.pitch, 651;
is $pclt.xHeight, 1120;
is $pclt.capHeight, 1493;
is $pclt.strokeWeight, 0;
is $pclt.serifStyle, 64;

my Font::TTF::Post $post = $ttf.load('post');
is $post.format, 2;
is $post.italicAngle, 0;
is $post.underlinePosition, -213;
is $post.underlineThickness, 143;
is $post.minMemType42, 0;
is $post.maxMemType42, 0;
is $post.minMemType1, 0;
is $post.maxMemType1, 0;

my Font::TTF::Maxp $maxp = $ttf.load('maxp');
is $maxp.version, 1;
is $maxp.numGlyphs, 268;
is $maxp.maxPoints, 77;
is $maxp.maxContours, 7;
is $maxp.maxComponentPoints, 66;
is $maxp.maxComponentContours, 4;
is $maxp.maxZones, 2;
is $maxp.maxTwilightPoints, 16;
is $maxp.maxStorage, 64;
is $maxp.maxFunctionDefs, 7;
is $maxp.maxInstructionDefs, 0;
is $maxp.maxStackElements, 1045;
is $maxp.maxSizeOfInstructions, 1384;
is $maxp.maxComponentElements, 3;
todo "investigate";
is $maxp.maxComponentDepth, 1;

done-testing;