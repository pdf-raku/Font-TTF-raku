use Test;
use Font::TTF;
use Font::TTF::Table::CMap;
use Font::TTF::Table::Header;
use Font::TTF::Table::GlyphIndex;
use Font::TTF::Table::MaxProfile;
use Font::TTF::Subset::Raw;
use File::Temp;
plan 44;

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $ttf .= new: :$fh;
my $maxp-checksum-in = $ttf.directories.first(*.tag eq 'maxp').checkSum;
my $maxp-buf = $ttf.buf('maxp');
is sfnt_checksum($maxp-buf, $maxp-buf.bytes), $maxp-checksum-in;

(my $filename, $fh) = tempfile;
$fh.write: $ttf.Blob;
$fh.close;

# read-read the file
$fh = $filename.IO.open(:r, :bin);
$ttf .= new: :$fh;

is $ttf.numTables, 17;
my $maxp-checksum-out = $ttf.directories.first(*.tag eq 'maxp').checkSum;

is $maxp-checksum-out, $maxp-checksum-in;

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
