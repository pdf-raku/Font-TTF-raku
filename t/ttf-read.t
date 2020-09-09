use Test;
use Font::TTF;
use Font::TTF::CMap;
use Font::TTF::Header;
use Font::TTF::HoriHeader;
use Font::TTF::Locations;
use Font::TTF::MaxProfile;
use Font::TTF::OS2;
use Font::TTF::PCLT;
use Font::TTF::Postscript;
use Font::TTF::VertHeader;
use NativeCall;
plan 75;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $ttf .= open($fh);

is $ttf.numTables, 17;

my Font::TTF::Header $head .= load($ttf);

is $head.version, 1;
is $head.fontRevision, 2;
is $head.checkSumAdjustment, 206572268;
is $head.magicNumber, 1594834165;
is $head.flags, 31;
is $head.created, '2003-04-09T15:46:00Z';
is $head.modified, '2003-04-16T01:51:13Z';
is $head.fontDirectionHint, 1;
is $head.glyphDataFormat, 0;
is $head.lowestRecPPEM, 8;
is $head.unitsPerEm, 2048;
is $head.xMax, 2636;
is $head.xMin, -375;
is $head.yMax, 1901;
is $head.yMin, -483;

my Font::TTF::HoriHeader $hhea .= load($ttf);
is $hhea.version, 1;
is $hhea.ascent, 1901;
is $hhea.descent, -483;
is $hhea.lineGap, 0;
is $hhea.advanceWidthMax, 2748;
is $hhea.minLeftSideBearing, -375;
is $hhea.minRightSideBearing, -375;
is $hhea.xMaxExtent, 2636;
is $hhea.caretSlopeRise, 1;
is $hhea.numOfLongHorMetrics, 268;

my Font::TTF::VertHeader $vhea .= load($ttf);
is-deeply $vhea, Font::TTF::VertHeader;

my Font::TTF::OS2 $os2 .= load($ttf);
is $os2.version, 1;
is $os2.xAvgCharWidth, 1038;
is $os2.usWeightClass, 400;
is $os2.usWidthClass, 5;
is $os2.ySubscriptXSize, 1351;
is $os2.ySubscriptYSize, 1228;
is $os2.achVendID, "Bits";
is $os2.panose.bSerifStyle, 11;
is-deeply $os2.panose.Blob, Buf[uint8].new(2,11,6,3,3,8,4,2,2,4);

my Font::TTF::PCLT $pclt .= load($ttf);

is $pclt.version, 1;
is $pclt.pitch, 651;
is $pclt.xHeight, 1120;
is $pclt.capHeight, 1493;
is $pclt.strokeWeight, 0;
is $pclt.serifStyle, 64;
is $pclt.typeface, 'VeraSans';
is $pclt.fileName, '628R00';

my Font::TTF::Postscript $post .= load($ttf);
is $post.format, 2;
is $post.italicAngle, 0;
is $post.underlinePosition, -213;
is $post.underlineThickness, 143;
is $post.minMemType42, 0;
is $post.maxMemType42, 0;
is $post.minMemType1, 0;
is $post.maxMemType1, 0;

my Font::TTF::MaxProfile $maxp .= load($ttf);
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
is $maxp.maxComponentDepth, 1;

my Font::TTF::Locations $locs .= load($ttf);
is $locs.elems, $locs.num-glyphs+1;
is $locs[0].byte, 0;
is $locs[1].byte, 68;
is $locs[5].byte, 176;
is $locs[268].byte, 35454;

my Font::TTF::CMap $cmap .= load($ttf);
is $cmap.elems, 2;
is $cmap[0].platformID, 1;
is $cmap[1].platformID, 3;

done-testing;
