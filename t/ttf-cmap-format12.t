use Test;
use Font::TTF::Table::CMap;
use Font::TTF::Table::CMap::Format12 :GroupIndex;

plan 13;

my uint32 @groups[2;3] Z= (32, 32, 3,  44, 44, 15);

my Font::TTF::Table::CMap::Format12 $format .= new: :@groups;
is $format.groups[0;startCharCode], 32;
is $format.groups[1;startCharCode], 44;
is $format.groups[1;startGlyphCode], 15;
is $format.numGroups, 2;
is $format.length, 24;

my uint8 @subdata = [
    0,12,       # format 12
    0,0,        # (padding)
    0,0,0,24,   # length 24
    0,0,0,0,    # language
    0,0,0,2,    # 2 groups
    0,0,0,32, 0,0,0,32, 0,0,0,3,
    0,0,0,44, 0,0,0,44, 0,0,0,15,
];

my buf8 $buf = $format.pack;
is-deeply $buf, buf8.new(@subdata);

is $format.groups[0;startCharCode], 32;
is $format.groups[1;startCharCode], 44;
is $format.groups[1;startGlyphCode], 15;
is $format.numGroups, 2;
is $format.length, 24;

my  Font::TTF::Table::CMap $cmap .= new: :$format;

my buf8 $cmap-buf .= new(
   0, 0, # version
   0, 1, # numberSubtables
   0, 0, # platformID
   0, 4, # platformEncoding
   0, 0, 0, 12, # offset
);
$cmap-buf.append: @subdata;

is-deeply $cmap.pack, $cmap-buf;

pass;
