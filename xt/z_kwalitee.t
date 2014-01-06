use strict;
use warnings;

use Test::More;

plan skip_all => 'This test is only run for the module author'
    unless -d '.git' || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

use File::Copy 'cp';
cp('MYMETA.yml','META.yml') if -e 'MYMETA.yml' and !-e 'META.yml';

eval { require Test::Kwalitee; Test::Kwalitee->import('tests' => ['-no_symlinks']) };
plan skip_all => "Test::Kwalitee needed for testing kwalitee"
    if $@;
