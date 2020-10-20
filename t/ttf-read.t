use Test;
plan 10;
use Font::TTF;
use Font::TTF::Table::CMap;
use Font::TTF::Table::CMap::Format0;
use Font::TTF::Table::CMap::Format4;
use Font::TTF::Table::Kern;
use Font::TTF::Table::Kern::Format1;
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


subtest 'head' => {
    plan 15;
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
}

subtest 'maxp' => {
    plan 15;
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
}

subtest 'hhea' => {
    plan 10;
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
}

subtest 'hmtx' => {
    plan 8;
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
}

my Font::TTF::Table::VertHeader $vhea .= load($ttf);
is-deeply $vhea, Font::TTF::Table::VertHeader;

subtest 'loca' => {
    plan 6;
    my Font::TTF::Table::GlyphIndex $locs .= load($ttf);
    is $locs.elems, $locs.num-glyphs+1;
    is $locs[0], 0;
    is $locs[1], 68;
    is $locs[5], 176;
    is $locs[267], 35412;
    is $locs[268], 35454;
}

subtest 'cmap' => {
    plan 22;
    my Font::TTF::Table::CMap $cmap .= load($ttf);
    is $cmap.elems, 2;

    is $cmap[0].platformID, 1;
    is $cmap[0].platformEncodingID, 0;
    is $cmap[0].subbuf.bytes, 262;
    my $subtable = $cmap[0].object;
    isa-ok $subtable, Font::TTF::Table::CMap::Format0;
    is $subtable.format, 0;
    is $subtable.length, 262;
    is $subtable[32], 3;  # space
    is $subtable[65], 36; # A
    is $subtable.encode(32), 3;
    is $subtable.encode(65), 36;

    is $cmap[1].platformID, 3;
    is $cmap[1].platformEncodingID, 1;
    is $cmap[1].subbuf.bytes, 574;
    $subtable = $cmap[1].object;
    isa-ok $subtable, Font::TTF::Table::CMap::Format4;
    is $subtable.format, 4;
    is $subtable.length, 574;
    is $subtable.segCount, 29;

    constant Tuple = Font::TTF::Table::CMap::Format4::Tuple;
    $subtable[0].&is-deeply: Tuple.new(endCode => 126, startCode => 32, idDelta => -29, idRangeOffset => 0);
    $subtable[1].&is-deeply: Tuple.new(endCode => 255, startCode => 160, idDelta => 0, idRangeOffset => 56);
    is $subtable.encode(32), 3;
    is $subtable.encode(65), 36;
}

subtest 'glyf' => {
    plan 1;
    my buf8 $glyph-buf = $ttf.glyph-buf(0);
    is-deeply $glyph-buf, buf8.new(0,2,0,102,254,150,4,102,5,164,0,3,0,7,0,26,64,12,4,251,0,6,251,1,8,5,127,2,4,0,47,196,212,236,49,0,16,212,236,212,236,48,19,17,33,17,37,33,17,33,102,4,0,252,115,3,27,252,229,254,150,7,14,248,242,114,6,41);
}

subtest 'kern' => {
    plan 11;
    my Font::TTF::Table::Kern $kern.= load($ttf);
    given $kern.index {
        is .version, 0;
        is .nTables, 1;
    }
    given $kern.subtables[0] {
        constant KernPair = Font::TTF::Table::Kern::Format1::KernPair;
        is .coverage, 1;
        is-deeply .format, 1;
        is .tupleIndex, 0;
        given .header {
            is-deeply .is-vertical, False;
            is-deeply .is-cross-stream, False;
            is-deeply .is-variation, False;
        }
        is .elems, 1940;
        .[0].&is-deeply: KernPair.new(:left(16), :right(36), :value(-45));
        .[1].&is-deeply: KernPair.new(:left(16), :right(37), :value(-73));
    }
}

done-testing;
