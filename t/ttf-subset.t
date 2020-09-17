use Test;
plan 9;
use Font::TTF::Subset;
use Font::TTF;
use Font::FreeType;
use Font::FreeType::Face;
use NativeCall;

my @charset = "Hello, World!".ords.unique.sort;

my Font::FreeType $freetype .= new;
my Font::FreeType::Face $face = $freetype.face('t/fonts/DejaVuSans.ttf');

my $fh = "t/fonts/Vera.ttf".IO.open(:r, :bin);

my Font::TTF:D $ttf .= new: :$fh;
my Font::TTF::Subset $subset .= new: :$face, :@charset;

$ttf.subset($subset);

my $maxp = $ttf.load('maxp');
is $maxp.numGlyphs, 11;

my $loca = $ttf.load('loca');
is $loca.elems, 12;
is $loca[10], 1352;

my $hhea = $ttf.load('hhea');
is $hhea.numOfLongHorMetrics, 11;

my $hmtx = $ttf.load('hmtx');
is $hmtx.elems, 12;
is $hmtx.num-long-metrics, 11;


todo "rebuild other tables", 5;

flunk('cmap');
flunk('name');
flunk('kern');

done-testing();
