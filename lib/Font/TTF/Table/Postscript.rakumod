use Font::TTF::Defs :types, :Sfnt-Struct, :Sfnt-Table;

class Font::TTF::Postscript is repr('CStruct') does Sfnt-Struct does Sfnt-Table['post'] {
    HAS Fixed	$.format;	# Format of this table
    HAS Fixed	$.italicAngle;	# Italic angle in degrees
    has FWord	$.underlinePosition;	# Underline position
    has FWord	$.underlineThickness;	# Underline thickness
    has uint32	$.isFixedPitch;	# Font is monospaced; set to 1 if the font is monospaced and 0 otherwise (N.B., to maintain compatibility with older versions of the TrueType spec, accept any non-zero value as meaning that the font is monospaced)
    has uint32	$.minMemType42;	# Minimum memory usage when a TrueType font is downloaded as a Type 42 font
    has uint32	$.maxMemType42;	# Maximum memory usage when a TrueType font is downloaded as a Type 42 font
    has uint32	$.minMemType1;	# Minimum memory usage when a TrueType font is downloaded as a Type 1 font
    has uint32	$.maxMemType1;	# Maximum memory usage when a TrueType font is downloaded as a Type 1 font
}
