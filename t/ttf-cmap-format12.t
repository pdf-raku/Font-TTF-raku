use Test;
use Font::TTF::Table::CMap::Format12 :GroupIndex;

plan 12;

my uint32 @groups[2;3] Z= (32, 32, 3,  44, 44, 15);

my Font::TTF::Table::CMap::Format12 $cmap .= new: :@groups;
is $cmap.groups[0;startCharCode], 32;
is $cmap.groups[1;startCharCode], 44;
is $cmap.groups[1;startGlyphCode], 15;
is $cmap.numGroups, 2;
is $cmap.length, 20;

my buf8 $buf = $cmap.pack; 
is-deeply $buf, buf8.new(
    0,12,
    0,0,0,20,
    0,0,
    0,0,0,2,
    0,0,0,32, 0,0,0,32, 0,0,0,3,
    0,0,0,44, 0,0,0,44, 0,0,0,15,
);

$cmap .= new: :$buf;
is $cmap.groups[0;startCharCode], 32;
is $cmap.groups[1;startCharCode], 44;
is $cmap.groups[1;startGlyphCode], 15;
is $cmap.numGroups, 2;
is $cmap.length, 20;

pass;