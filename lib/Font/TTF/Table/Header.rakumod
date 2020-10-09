use Font::TTF::Table;

class Font::TTF::Table::Header
    is rw
    is repr('CStruct')
    does Font::TTF::Table['head'] {

    use Font::TTF::Defs :types;

    HAS Fixed  $.version;
    HAS Fixed  $.fontRevision;
    has uint32 $.checkSumAdjustment;
    has uint32 $.magicNumber;
    has uint16 $.flags;
    has uint16 $.unitsPerEm;
    has longDateTime $.created;
    constant SfntEpochDiff = -2082844800;
    sub thaw-sfnt-date(Int $date) {
        DateTime.new: $date + SfntEpochDiff;
    }
    sub freeze-sfnt-date(Instant $inst) {
        my longDateTime $ = $inst.round - SfntEpochDiff;
    }
    method created {
        thaw-sfnt-date($!created);
    }
    has longDateTime $.modified;
    method modified is rw {
        Proxy.new(
            FETCH => {thaw-sfnt-date($!modified)},
            STORE => -> $, Instant $t {
                $!modified = freeze-sfnt-date($t);
            }
        );
    }
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

