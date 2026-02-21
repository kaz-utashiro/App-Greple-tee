use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib './t';
use Util;

my $has_ansifold = eval { require App::ansifold; 1 };

$ENV{HOME} = File::Spec->rel2abs('t/home');
$ENV{NO_COLOR} = '1';

my $sample = 't/SAMPLE.txt';

# Test that nofork (default) and fork (--no-nofork) produce the same result
# for &function calls.

SKIP: {
    skip "App::ansifold not installed", 3 unless $has_ansifold;

    # &ansifold with --discrete (each match processed individually)
    my $nofork = run(
	"-Mtee '&ansifold' -w 20 -- " .
	"'^([A-Z].*\\n)(.+\\n)*' $sample --all --discrete"
    )->stdout;
    my $fork = run(
	"-Mtee::config(nofork=0) '&ansifold' -w 20 -- " .
	"'^([A-Z].*\\n)(.+\\n)*' $sample --all --discrete"
    )->stdout;
    ok(length($nofork) > 0, "&ansifold nofork produces output");
    ok(length($fork) > 0, "&ansifold fork produces output");
    is($nofork, $fork, "&ansifold nofork and fork produce same result");
}

# Perl function call: uc via &function (inline code ref)
{
    my $nofork = run(
	"-Mtee perl -CSAD -pE '\$_=uc' -- " .
	"'^([A-Z].*\\n)(.+\\n)*' $sample --all --discrete"
    )->stdout;
    my $fork = run(
	"-Mtee::config(nofork=0) perl -CSAD -pE '\$_=uc' -- " .
	"'^([A-Z].*\\n)(.+\\n)*' $sample --all --discrete"
    )->stdout;
    is($nofork, $fork,
       "external command: nofork config does not affect fork behavior");
}

# cat -n: external command should work the same regardless of nofork setting
{
    my $nofork = run(
	"-Mtee cat -n -- " .
	"'^([A-Z].*\\n)(.+\\n)*' $sample --all"
    )->stdout;
    my $fork = run(
	"-Mtee::config(nofork=0) cat -n -- " .
	"'^([A-Z].*\\n)(.+\\n)*' $sample --all"
    )->stdout;
    is($nofork, $fork,
       "external command: nofork setting has no effect");
}

done_testing;
