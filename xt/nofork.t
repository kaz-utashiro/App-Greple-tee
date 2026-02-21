use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';
use Benchmark qw(timethese :hireswallclock);
use Getopt::Long qw(GetOptions);

GetOptions(\my %opt, 'count|n=i') or die;
$opt{count} //= 100;

use lib './t';
use Util;

BEGIN {
    eval { require App::ansifold }
	or plan skip_all => 'App::ansifold not installed';
}

$ENV{HOME} = File::Spec->rel2abs('t/home');
$ENV{NO_COLOR} = '1';

my $sample = 't/SAMPLE.txt';
my $pattern = q{'^([A-Z].*\n)(.+\n)*'};

my $n = $opt{count};
diag "";
diag "Benchmark: &ansifold -w 20, --discrete, $n iterations";

my $result = timethese($n, {
    'nofork' => sub {
	run("-Mtee '&ansifold' -w 20 -- $pattern $sample --all --discrete");
    },
    'fork' => sub {
	run("-Mtee::config(nofork=0) '&ansifold' -w 20 -- $pattern $sample --all --discrete");
    },
});

my $nofork_time = $result->{nofork}[0];
my $fork_time   = $result->{fork}[0];
my $ratio = $nofork_time > 0 ? $fork_time / $nofork_time : 0;
diag sprintf "nofork/fork ratio: %.2fx", $ratio;
cmp_ok($ratio, '>', 1.0, "nofork is faster than fork");

done_testing;
