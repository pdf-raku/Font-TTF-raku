use Font::TTF::Table;

class Font::TTF::Table::Generic
    does Font::TTF::Table {

    has Str $.tag;
    has buf8 $.buf is rw;

    method load($loader) { $loader.load(self.tag, :class(self.WHAT)) }
}

