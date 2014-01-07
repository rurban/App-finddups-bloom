package App::finddups::bloom;

use strict;
use warnings;
use 5.008;
our $VERSION = '0.02';

# local::lib hack, dfw-specific only
# push @INC, "perl5/lib/perl5:perl5/lib/perl5/x86_64-linux-gnu-thread-multi";

=head1 NAME

App::finddups::bloom

=head1 SYNOPSIS

    use File::Find;
    use App::finddups::bloom;

    App::finddups::bloom::options('0' => 1);

    File::Find::find(\&App::finddups::bloom::wanted, $ARGV[0]);

=head1 DESCRIPTION

Finds and prints most file duplicates under the given directory via bloom filters.
Ignores symlinks and hardlinks.

=head1 OPTIONS

Options are passed to the module as hash to the subroutine C<options>.
The keys are:

=over 4

=item 0 - quote unprintable filename characters for xargs -0

=item bloomsize - expected number of files, defaults to 1_000_000;

=item bloomsize2 - expected number of duplicates, defaults to 2000;

=item bloomerr - wanted error rate, defaults to 0.01 i.e. 1%

=item maxcrc - maximal file content size which is checked

=item verbose - prints header and footer prefixed with #

=item help - prints short usage

=back

=cut

use Bloom::Faster ();
use Digest::CRC ();
use File::Find ();

my $maxcrc = 1024;
my $bloomsize = 1_000_000;
my $bloomsize2 = 2000;
my $bloomerr = 0.01;

my (%opts, %big, $buf);
my $s; # global crc buffer
# expected elements + error rate (not using options yet)
my $size = Bloom::Faster->new({'n' => $bloomsize, 'e' => $bloomerr});
# less expected same-size entries
my $hash = Bloom::Faster->new({'n' => $bloomsize, 'e' => $bloomerr});
my $hash2 = Bloom::Faster->new({'n' => $bloomsize2, 'e' => $bloomerr});
my $crc = Digest::CRC->new('type' => "crc32");

sub wanted {
  my ( $selfdir, $subdirs, $files ) = @_;
  for my $f (@$files) {
    if ($opts{'debug'}) {
      print "# ".$f;
      print " dir" if -d _;
      print " and link" if -l $f;
      print "\n";
    }
    next unless -f $f;
    next if -l $f; # skip symlinks and non-files
    if ($opts{'debug'}) {
      my $c = (stat($f))[3];
      print "# $c nlink\n" if $c > 1;
    }
    next if (stat($f))[3] > 1;   # also skip hardlinks not using a inode hash, the fs already stores nlinks
    my $s = -s $f;
    print "# $f $s " if $opts{'debug'};
    my $found = $size->add($s);        # only compare same filesizes
    my $c;
    print "# found size $s" if $opts{'debug'};
    open my $F,'<',$f or return;
    if (! $s) {
      $c = 0;
    } elsif ($s < $maxcrc) {
      my $o = $crc->addfile($F);
      $c = $o->digest;
    } else {
      print " read $maxcrc" if $opts{'debug'};
      if (!$found) { # if new size store the filename first
	$big{$size} = $f;
	$c = 0;
      } else { # same size found?
	sysread $F, $buf, $maxcrc; # then check the current hash
	my $o = $crc->add($buf);
	$c = $o->digest;

	my $old = $big{$size}; # update the wrong 1st hashes only when same size
	if ($old) {
	  open my $OLD,'<',$old;
	  sysread $OLD, $buf, $maxcrc;
	  my $o = $crc->add($buf);
	  $hash->add($o->digest);
	  $o = $crc->addfile($OLD);
	  $hash2->add($o->digest);
	  close $OLD;
	}
	$big{$size} = 0;
      }
    }
    print " and store hash ",$c if $opts{'debug'};
    if ($hash->add($c) and $found) {
	print " found same hash ",$c,"\n" if $opts{'debug'};
	if ($s >= $maxcrc) { # check big files
	  my $o = $crc->addfile($F);
	  unless ($hash2->add($o->digest)) {
	    print " but not same hash2 ",$o->digest,"\n" if $opts{'debug'};
	    next;
	  }
	  print " and same hash2 ",$o->digest,"\n" if $opts{'debug'};
	}
	if ($opts{0}) {
	  print B::cstring($f)."\000\n";
	} else {
	  print $f."\n";
	}
    } elsif ($opts{'debug'}) {
      print "\n";
    }
    close $F or next;
  }
  return 1;
}

sub options {
  %opts = @_;
  if ($opts{0}) {
    require B;
  }
  return;
}

END {
  if ($opts{'verbose'}) {
    print "\n#bloom filter stats: ", $size->key_count, " size keys, ", $size->capacity, " size capacity\n";
    print   "#                    ", $hash->key_count, " hash keys, ", $hash->capacity, " hash capacity\n";
    print   "#                    ", $hash2->key_count, " hash2 keys, ", $hash2->capacity, " hash2 capacity\n";
  }
}

1;

=head1 INTERNALS

This code doesn't follow the contest rules, as it doesn't store the source links. 
It only checks and prints duplicates, and therefore can use fast and memory efficient
Bloom filters.

The default accuracy is 99.99% for 1 million files which should satisfy all
practical purposes. And if you care for more run it a second time, combined with C<rm>.
It is fast because it uses bloom filters not hashes, hence the 99.99%
and not 100% and it doesn't print the source for the duplicates, only the
duplicates.

To remove the duplicates apply C<rm> to the list of entries, such as

    finddups-bloom -0 | xargs -0 rm

It needs between 20MB and 30MB memory, compared to 333MB with 
the reference perl5 code using perl hashes.

cloc: 57

    $ perlcritic finddups-bloom
    finddups-bloom source OK

sum critic violations --severity 1..5: 55

=head1 FUNCTIONS

=over 4

=item wanted

callback for L<Find::File>, implementing the module logic

=item options

store options hash from the script

=back

=head1 LICENSE

Written and copyright 2014 by Reini Urban rurban@cpanel.net
for the Dallas/Fort Worth Perl Mongers dfw dedup contest 2014
http://dfw.pm.org/

This program is free software; you can redistribute it and/or modify
it under the terms of Perl5, which is either:

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or

b) the "Artistic License" which comes with this kit.

=head1 SEE ALSO

L<finddups-bloom>

=cut
