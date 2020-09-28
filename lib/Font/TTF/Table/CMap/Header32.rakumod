use Font::TTF::Defs :Sfnt-Struct;
class Font::TTF::Table::CMap::Header32
    is repr('CStruct')
    does Sfnt-Struct {
    has uint16	$.format;
    has uint32	$.length is rw;
    has uint16  $.language;
}
