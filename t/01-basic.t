use Test;
plan 3;
use Font::TTF::Subset;
use NativeCall;

my $fh = 't/fonts/DejaVuSans.ttf'.IO.open;
my @charset = "Hello, World!".ords.unique.sort;

my Font::TTF::Subset $subset .= new: :$fh, :@charset;
is $subset.len, 11;
is $subset.charset[1], 32;
is $subset.gids[1], 3;

done-testing();
