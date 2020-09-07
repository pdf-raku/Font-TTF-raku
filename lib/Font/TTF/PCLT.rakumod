use Font::TTF::Defs :types, :Sfnt-Struct, :Sfnt-Table;

class Font::TTF::PCLT is repr('CStruct') does Sfnt-Struct does Sfnt-Table['PCLT'] {
    HAS Fixed   $.version;
    has uint32   $.fontNumber;
    has uFWord   $.pitch;
    has uFWord   $.xHeight;
    has uFWord   $.style;
    has uFWord   $.typeFamily;
    has uFWord   $.capHeight;
    has uFWord   $.symbolSet;
    # todo
    my class TypeFace is repr('CStruct') {
        has uint8 ($!b1, $!b2, $!b3, $!b4, $!b5,
                     $!b6, $!b7, $!b8, $!b9, $!b10,
                     $!b11, $!b12, $!b13, $!b14, $!b15, $!b16
                    );
    }
    HAS TypeFace $!typeface;
    # todo
    my class CharComp is repr('CStruct') {
        has uint8 ($!b1, $!b2, $!b3, $!b4, $!b5,
                     $!b6, $!b7, $!b8
                    );
    }
    HAS CharComp $!characterComplement;
    # todo
    my class FileName is repr('CStruct') {
        has uint8 ($!b1, $!b2, $!b3, $!b4, $!b5, $!b6);
    }
    HAS FileName $!fileName;
    has int8     $.strokeWeight;
    has int8     $.widthType;
    has uint8    $.serifStyle;
    has uint8    $.reserved;
}
