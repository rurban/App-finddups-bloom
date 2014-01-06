BEGIN { print "1..1\n"; $/ = ""; }
die "ok 1  #skip MSWin32 tests\n" if $^O eq 'MSWin32';

my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
my $s = `$X -Mblib script/finddups-bloom t/dedup`;
chomp $s;
print "ok 1\n" if $s eq "t/dedup/t2/f2";
