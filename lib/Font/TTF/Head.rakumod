use Font::TTF::Defs :types, :Sfnt-Table;

class Font::TTF::Head is repr('CStruct') does Sfnt-Table['head'] {
    HAS Fixed  $.version;
    HAS Fixed  $.fontRevision;
    has uint32 $.checkSumAdjustment;
    has uint32 $.magicNumber;
    has uint16 $.flags;
    has uint16 $.unitsPerEm;
    has longDateTime $.created;
    has longDateTime $.modified;
    has FWord  $.xMin;
    has FWord  $.yMin;
    has FWord  $.xMax;
    has FWord  $.yMax;
    has uint16 $.macStyle;
    has uint16 $.lowestRecPPEM;
    has int16  $.fontDirectionHint;
    has int16  $.indexToLocFormat;
    has int16  $.glyphDataFormat;
}

