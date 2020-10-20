use Font::TTF::Table::Generic;

class Font::TTF::Table::Kern
    is Font::TTF::Table::Generic {

    use Font::TTF::Table::Kern::Format1;
    use Font::TTF::Defs :types, :Sfnt-Struct;
    use CStruct::Packing :&mem-unpack, :&mem-pack;
    use NativeCall;

    method tag {'kern'}

    class Index16 is repr('CStruct') {...}
    class Index32 is repr('CStruct') {...}

    role Index does Sfnt-Struct {

        method delegate(buf8 $buf) {
            my Index $class := $buf.head(4).max
                ?? Index16
                !! Index32;
        }
    }

    class Index16 does Index {
        has uint16 $.version;
        has uint16 $.nTables;
    }

    class Index32 does Index {
        has uint32 $.version;
        has uint32 $.nTtables;
    }

    class Subtable {
        class Header is repr('CStruct') does Sfnt-Struct {
            has uint32 $.length;
            has uint16 $.coverage;

            enum KernFlags (
	        :kernVertical(0x8000),	# Set if table has vertical kerning values.
	        :kernCrossStream(0x4000),   # Set if table has cross-stream kerning values.
	        :kernVariation(0x2000),     # Set if table has variation kerning values.
	        :kernUnusedBits(0x1F00),    # Set to 0.
	        :kernFormatMask(0x00FF),    # Set the format of this subtable (0-3 currently defined).
            );

            method is-vertical     { ? ($.coverage +& kernVertical) }
            method is-cross-stream { ? ($.coverage +& kernCrossStream) }
            method is-variation    { ? ($.coverage +& kernVariation) }
            method format          { + ($.coverage +& kernFormatMask) }
        }
        has Header $.header handles<length coverage format>;
        has uint16 $.tupleIndex;
        has buf8 $.subbuf;

        method !delegate {
            given $!header.format  {
                when 1 {
                    Font::TTF::Table::Kern::Format1;
                }
                default {
                    die "todo Kern format $_";
##                    Font::TTF::Table::Kern::Generic;
                }
            }
        }
        has $.object;
        method object(Subtable:D:) handles<AT-POS elems> {
            $!object //= self!delegate.new: :$!subbuf;
        }
    }

    has Index $.index;
    has Subtable @.subtables handles<AT-POS Numeric elems>;

    multi submethod TWEAK(buf8:D :$buf!) {
        $!index = Index.delegate($buf).unpack($buf);
        my UInt $offset = $!index.packed-size;
        my UInt $num-tables = $!index.nTables;
        constant HeaderSize = Subtable::Header.packed-size;
        for 0 ..^ $num-tables {
            my Subtable::Header $header .= unpack($buf, :$offset);
            my uint16 $tupleIndex;
            if $header.is-variation {
                $tupleIndex = $buf.read-uint16(0, NetworkEndian);
                $offset += 2;
            }
            my $subbuf = $buf.subbuf($offset + HeaderSize, $header.length - HeaderSize);
            my Subtable $subtable .= new: :$header, :$subbuf, :$tupleIndex;
            @!subtables.push: $subtable;
            $offset += $header.length;
        }
    }
    method pack(buf8:D $buf = buf8.new) {
        ...
    }
}
