BEGIN { print "1..1\n"; $/ = ""; }
my $s = `$^X script/finddups-bloom t/dedup`;
chomp $s;
print "ok 1\n" if $s eq "t/dedup/t2/f2";
