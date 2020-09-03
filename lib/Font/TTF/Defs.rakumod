unit module Font::TTF::Defs;

use CStruct::Packing :Endian;

constant Sfnt-Struct is export(:Sfnt-Struct) = CStruct::Packing[NetworkEndian];

class fixed is export(:types) is repr('CStruct') does Sfnt-Struct {
    has int32 $.val;
    method Numeric handles<gist Str Int value> {
        $!val / (2 ** 16);
    }
}

class shortfrac is export(:types) is repr('CStruct') does Sfnt-Struct {
    has int16 $!val;
    method Numeric handles<gist Str value> {
        $!val / (2 ** 14);
    }
}

constant fword  is export(:types) = int16;
constant longdt is export(:types) = int64;

