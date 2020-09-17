use Test;
plan 61;
use Font::TTF;
use Font::TTF::Table::CMap;
use Font::TTF::Table::Header;
use Font::TTF::Table::HoriHeader;
use Font::TTF::Table::HoriMetrics;
use Font::TTF::Table::GlyphIndex;
use Font::TTF::Table::MaxProfile;
use Font::TTF::Table::VertHeader;
use NativeCall;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $ttf .= new: :$fh;

is $ttf.numTables, 17;

my Font::TTF::Table::Header $head .= load($ttf);

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

my Font::TTF::Table::MaxProfile $maxp .= load($ttf);
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

my Font::TTF::Table::HoriHeader $hhea .= load($ttf);
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

my Font::TTF::Table::HoriMetrics $hmtx .= load($ttf);
is $hmtx.elems, 269;
is $hmtx.num-long-metrics, 268;
constant notdef = 0;
is $hmtx[notdef].advanceWidth, 1229;
is $hmtx[notdef].leftSideBearing, 102;
constant null = 1;
is $hmtx[null].advanceWidth, 0;
is $hmtx[null].leftSideBearing, 0;
constant space = 2;
is $hmtx[space].advanceWidth, 651;
is $hmtx[space].leftSideBearing, 0;

my Font::TTF::Table::VertHeader $vhea .= load($ttf);
is-deeply $vhea, Font::TTF::Table::VertHeader;

my Font::TTF::Table::GlyphIndex $locs .= load($ttf);
is $locs.elems, $locs.num-glyphs+1;
is $locs[0], 0;
is $locs[1], 68;
is $locs[5], 176;
is $locs[267], 35412;
is $locs[268], 35454;

my Font::TTF::Table::CMap $cmap .= load($ttf);
is $cmap.elems, 2;

is $cmap[0].platformID, 1;
is $cmap[0].subbuf.bytes, 262;

is $cmap[1].platformID, 3;
is $cmap[1].subbuf.bytes, 574;

done-testing;
