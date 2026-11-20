use strict; use warnings; use utf8;
use Test::More;
use File::Spec;
use lib './t';
use Util;
$ENV{HOME} = File::Spec->rel2abs('t/home');
$ENV{NO_COLOR} = '1';
$ENV{PERL5LIB} = join ':', File::Spec->rel2abs('t/lib'), $ENV{PERL5LIB} // ();
my $IN = 't/multi.txt';
open STDIN, '<', '/dev/null' or die "/dev/null: $!";
sub tee { my $r = run(join ' ', @_); ($r->stdout, $r->status) }
my $UP = q(tr a-z A-Z);
my $LT = q(sed 's/^/</');

# greple now interprets --blocks as its own --block option (takes the next argument as pattern;
# stdin comes from /dev/null so greple does not wait on it).
subtest 'blocks removed' => sub {
    my($out, $st) = tee("-Mtee cat -n -- foo --blocks $IN");
    isnt($st, 0, '--blocks is an error');
    unlike($out, qr/^\s+\d+\t/m, '--blocks no longer processes blocks with tee');
};

my $PARA = q('^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all);
subtest 'legacy parsing' => sub {
    my($d)  = tee("-Mtee cat -n -- $PARA --discrete");
    my($nd) = tee("-Mtee cat -n -- $PARA");
    isnt($d, $nd, 'precondition: --discrete changes the output');
    is((tee("-Mtee --discrete cat -n -- $PARA"))[0], $d, 'mode inside -Mtee works like after --');
    is((tee("-Mtee --no-discrete cat -n -- $PARA --discrete"))[0], $nd, '--no-discrete inside -Mtee overrides global');
    is((tee("-Mtee -- foo $IN"))[0], "foo only\nfoo and qux\n", 'legacy empty command selects only');
    my $r = greple('-Mtee', 'perl', '-pE', 's/^\h+/X/', '--', '-E', '^\h+a\n', '--filter')->setstdin("  a\n")->run;
    is($r->stdout, "Xa\n", 'argument with \h is passed as is');
};
my $TWO = "-Mtee -E foo $UP -- -Mtee -E qux $LT --";
subtest 'two filters' => sub {
    my($o) = tee("$TWO --filter $IN");
    is($o, "FOO only\n<qux only\nFOO and <qux\nnone\n", 'each pattern gets its filter (OR)');
    ($o) = tee("-Mtee -E qux $LT -- -Mtee -E foo $UP -- --filter $IN");
    is($o, "FOO only\n<qux only\nFOO and <qux\nnone\n", 'order swapped');
    ($o) = tee("$TWO $IN");
    is($o, "FOO only\n<qux only\nFOO and <qux\n", '--need=1 is implied');
    ($o) = tee("$TWO --need=2 $IN");
    is($o, "FOO and <qux\n", 'user --need overrides');
    ($o) = tee("$TWO -h --filter $IN $IN");
    is($o, "FOO only\n<qux only\nFOO and <qux\nnone\n" x 2, 'multiple files');
};
subtest 'three filters, several patterns' => sub {
    my($o) = tee("-Mtee -E foo -E none $UP -- -Mtee -E qux $LT -- -Mtee -E only 'sed s/o/0/g' -- --filter $IN");
    is($o, "FOO 0nly\n<qux 0nly\nFOO and <qux\nNONE\n", 'patterns grouped per filter');
};
subtest 'empty command' => sub {
    my($o) = tee("-Mtee -E foo $UP -- -Mtee -E qux -- $IN");
    is($o, "FOO only\nqux only\nFOO and qux\n", 'empty command selects without change');
};
my $ONLY = q('^.*only\n');
my $REST = q('^.*and.*\n|^none\n');
subtest 'per-filter modes' => sub {
    my($o) = tee("-Mtee --discrete -E $ONLY 'cat -n' -- -Mtee -E $REST 'cat -n' -- --filter $IN");
    like($o, qr/\A\s+1\tfoo only\n\s+1\tqux only\n\s+1\tfoo and qux\n\s+2\tnone\n\z/, 'discrete for the first filter, bundled for the second');
    ($o) = tee("-Mtee -E $ONLY 'cat -n' -- -Mtee --discrete -E $REST 'cat -n' -- --filter $IN");
    like($o, qr/\A\s+1\tfoo only\n\s+2\tqux only\n\s+1\tfoo and qux\n\s+1\tnone\n\z/, 'discrete does not leak to the other filter');
    ($o) = tee("-Mtee -E $ONLY 'cat -n' -- -Mtee --no-discrete -E $REST 'cat -n' -- --discrete --filter $IN");
    like($o, qr/\A\s+1\tfoo only\n\s+1\tqux only\n\s+1\tfoo and qux\n\s+2\tnone\n\z/, '--no-discrete overrides global --discrete');
    ($o) = tee("-Mtee::config(discrete=1) -E $ONLY 'cat -n' -- --filter $IN");
    like($o, qr/\A\s+1\tfoo only\n\s+1\tqux only\n/, 'inherits ::config');
    ($o) = tee("-Mtee::config(discrete=1) -Mtee -E $ONLY 'cat -n' -- --filter $IN");
    like($o, qr/\A\s+1\tfoo only\n\s+1\tqux only\n/, 'config-only -Mtee followed by new form');
};
subtest 'crmode' => sub {
    my $r = greple('-Mtee', '--crmode', '-E', '(?s)a\nb\n', 'perl', '-pE', 's/\r/+/g', '--',
                   '-Mtee', '-E', 'foo', 'tr', 'a-z', 'A-Z', '--', '--filter')->setstdin("a\nb\nfoo\n")->run;
    is($r->stdout, "a+b\nFOO\n", 'crmode only for the first filter');
};
subtest 'overlap and adjacency' => sub {
    my($o) = tee("-Mtee -E 'foo and' $UP -- -Mtee -E 'and qux' $LT -- --filter $IN");
    is((split /\n/, $o)[2], 'FOO AND QUX', 'overlap: merged region goes to the filter of the earlier match');
    ($o) = tee("-Mtee -E foo $UP -- -Mtee -E ' and' $LT -- --filter $IN");
    is((split /\n/, $o)[2], 'FOO< and qux', 'adjacent: both filters applied');
};
subtest 'no trailing newline' => sub {
    my $r = greple('-Mtee', '-E', 'qux\z', 'tr', 'a-z', 'A-Z', '--',
                   '-Mtee', '-E', 'foo', 'sed', 's/^/</', '--', '--filter')->setstdin("foo\nqux")->run;
    is($r->stdout, "<foo\nQUX\n", 'match at EOF without newline (greple adds the final newline itself)');
};
subtest '&function filter' => sub {
    plan skip_all => 'App::ansifold not installed' unless eval { require App::ansifold; 1 };
    my($o) = tee("-Mtee --discrete -E 'foo and qux' '&ansifold' -w4 -- -Mtee -E none $UP -- --filter $IN");
    is($o, "foo only\nqux only\nfoo \nand \nqux\nNONE\n", '&function works per filter');
};
subtest 'legacy with --cm' => sub {
    my($o) = tee("-Mtee --cm R $UP -- -E foo -E qux $IN");
    is($o, "FOO and QUX\n", '--cm alone keeps legacy form (AND selection)');
    ($o) = tee("-Mtee --cm R $UP -- -Mcolors -E foo -E qux $IN");
    is($o, "FOO and QUX\n", 'same when another module follows');
    local $ENV{NO_COLOR};
    delete $ENV{NO_COLOR};
    ($o) = tee("-Mtee --cm R $UP -- -E foo -E qux --color=always $IN");
    like($o, qr/\e\[31mFOO/, '--cm is passed to greple');
    ($o) = tee("-Mtee --cm R $UP -- -Mcolors -E foo -E qux --color=always $IN");
    like($o, qr/\e\[31mFOO/, '--cm is passed to greple when another module follows');
};
done_testing;
