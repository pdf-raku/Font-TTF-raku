use Test;
plan 9;
use Font::TTF;
use Font::TTF::Table::CMap;
use Font::TTF::Table::CMap::Format0;
use Font::TTF::Table::CMap::Format4;
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

sub padded($buf) {
    $buf.push: 0 until $buf.elems %% 4;
    $buf;
}            

my $buf = $ttf.buf('head');
my Font::TTF::Table::Header $head .= load($ttf);
is-deeply padded($head.pack), padded($buf);

$buf = $ttf.buf('maxp');
my Font::TTF::Table::MaxProfile $maxp .= load($ttf);
is-deeply $maxp.pack, $buf;

$buf = $ttf.buf('hhea');
my Font::TTF::Table::HoriHeader $hhea .= load($ttf);
is-deeply padded($hhea.pack), padded($buf);

$buf = $ttf.buf('hmtx');
my Font::TTF::Table::HoriMetrics $hmtx .= load($ttf);
is-deeply $hmtx.pack, $buf;

$buf = $ttf.buf('loca');
my Font::TTF::Table::GlyphIndex $locs .= load($ttf);
is-deeply padded($locs.pack), padded($buf);

$buf = $ttf.buf('cmap');
my Font::TTF::Table::CMap $cmap .= load($ttf);
is-deeply $cmap[0].object.pack, $cmap[0].subbuf;
is-deeply $cmap[1].object.pack, $cmap[1].subbuf;
is-deeply $cmap.pack, $buf;

done-testing;
