unit class Font::TTF::Table::CMap::Format12;

use Font::TTF::Defs :Sfnt-Struct;
use NativeCall;
use CStruct::Packing :Endian;
use Method::Also;

use Font::TTF::Table::CMap::Header32;
class Header
    is repr('CStruct')
    is Font::TTF::Table::CMap::Header32 {
    has uint32  $.numGroups is rw;
}

has Header $!header handles<format language>;

subset Groups of array[uint32] where .shape[1] ~~ 3;
has Groups $.groups handles<AT-POS>;  # [variable] Glyph index array
enum GroupIndex is export(:GroupIndex) <startCharCode endCharCode startGlyphCode>;
method elems is also<Numeric numGroups> { $!groups.elems }
method length { self.numGroups * 12  + $!header.packed-size; }

multi submethod TWEAK(buf8:D :$buf!) {
    $!header .= unpack($buf);
    my UInt $offset = $!header.packed-size;
    my CArray[uint32] $c .= new;
    $c[$!header.numGroups * 3 - 1] = 0;
    mem-unpack($c, $buf.subbuf($offset), :endian(NetworkEndian));
    $!groups := array[uint32].new: :shape[$!header.numGroups; 3];
    @$!groups Z= $c.list;
    $!groups;
}

multi submethod TWEAK( :$!groups!) {
    my $numGroups = self.numGroups;
    my $length = self.length;
    $!header .= new: :format(12), :$length, :language(0), :$numGroups;
}

method pack(buf8 $buf = buf8.new) {
    $buf.reallocate(0);
    $!header.length = self.length;
    $!header.numGroups = self.numGroups;
    $!header.pack($buf);
    my CArray[uint32] $c .= new: $!groups.list;
    $buf.append: mem-pack($c, :endian(NetworkEndian));
    $buf;
}
