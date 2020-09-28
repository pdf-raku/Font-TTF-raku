use Font::TTF::Defs :Sfnt-Struct;
class Font::TTF::Table::CMap::Header16
    is repr('CStruct')
    does Sfnt-Struct {
    has uint16	$.format;
    has uint16	$.length is rw;
    has uint16  $.language;
}
