unit module Font::TTF::Defs;

use CStruct::Packing :Endian;

our $SFNT-LIB is export(:SFNT-LIB) = %?RESOURCES<libraries/sfnt>;

constant Sfnt-Struct is export(:Sfnt-Struct) = CStruct::Packing[NetworkEndian];

class Fixed is export(:types) is repr('CStruct') does Sfnt-Struct {
    has int32 $.val;
    method Numeric handles<gist Str Int value> {
        $!val / (2 ** 16);
    }
}

class shortFrac is export(:types) is repr('CStruct') does Sfnt-Struct {
    has int16 $!val;
    method Numeric handles<gist Str value> {
        $!val / (2 ** 14);
    }
}

constant FWord  is export(:types) = int16;
constant uFWord  is export(:types) = uint16;
constant longDateTime is export(:types) = int64;

# PlatformID and Encoding, as used in 'cmap' and 'name' tables

enum PlatformID is export(:PlatformID)  <UnicodePlatform MacintoshPlatform ReservedPlatform MicrosoftPlatform>;

# Microsoft embraced extensions
enum WinEncoding is export(:WinEncoding) (
    :WinEncSymbol(0),
    :WinEncodingBMP(1),
    :WinEncShift-JIS(2),
    :WinEncPRC(3),
    :WinEncBigFive(4),
    :WinEncJohab(5),
    :WinEncUCS_4(6)
);


