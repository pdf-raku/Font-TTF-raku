use Font::TTF::Defs :types, :Sfnt-Struct;

class Font::TTF::Head is repr('CStruct') does Sfnt-Struct {
    HAS fixed  $.version;
    HAS fixed  $.fontRevision;
    has uint32 $.checkSumAdjustment;
    has uint32 $.magicNumber;
    has uint16 $.flags;
    has uint16 $.unitsPerEm;
    has longdt $.created;
    has longdt $.modified;
    has fword  $.xMin;
    has fword  $.yMin;
    has fword  $.xMax;
    has fword  $.yMax;
    has uint16 $.macStyle;
    has uint16 $.lowestRecPPEM;
    has int16  $.fontDirectionHint;
    has int16  $.indexToLocFormat;
    has int16  $.glyphDataFormat;
}

