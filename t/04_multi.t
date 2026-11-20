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
subtest 'crmode with discrete' => sub {
    my $r = greple('-Mtee', '--discrete', '--crmode', '-E', '(?s)a\nb\n', 'perl', '-pE', 's/\r/+/g', '--',
                   '--filter')->setstdin("a\nb\n")->run;
    is($r->stdout, "a+b\n", '--crmode works with --discrete inside -Mtee');
    $r = greple('-Mtee', '-E', '(?s)a\nb\n', 'perl', '-pE', 's/\r/+/g', '--',
                '--discrete', '--crmode', '--filter')->setstdin("a\nb\n")->run;
    is($r->stdout, "a+b\n", '--crmode works with --discrete given after --');
};
subtest 'fillup and squeeze per filter' => sub {
    my $r = greple('-Mtee', '--fillup', '-E', '(?s)a\nb\n', 'cat', '--',
                   '-Mtee', '-E', '(?s)c\nd\n', 'cat', '--', '--filter')->setstdin("a\nb\n\nc\nd\n")->run;
    is($r->stdout, "a b\n\nc\nd\n", '--fillup only for the first filter');
    $r = greple('-Mtee', '--discrete', '--squeeze', '-E', '(?s)a\n\n\nb\n', 'cat', '--',
                '-Mtee', '--discrete', '-E', '(?s)c\n\n\nd\n', 'cat', '--', '--filter')->setstdin("a\n\n\nb\nc\n\n\nd\n")->run;
    is($r->stdout, "a\nb\nc\n\n\nd\n", '--squeeze only for the first filter');
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
subtest 'errors' => sub {
    my @case = (
        [ "-Mtee -E foo $UP -- -E qux $IN",                       qr/outside/i, 'pattern outside -Mtee' ],
        [ "-Mtee -E foo $UP -- --callback 'sub{}' $IN",           qr/callback/i, '--callback outside -Mtee' ],
        [ "-Mtee $UP -- -Mtee -E qux $LT -- -E foo $IN",           qr/mix/i,     'legacy and new mixed' ],
        [ "-Mtee -E qux $LT -- -Mtee $UP -- -E foo $IN",           qr/mix/i,     'new and legacy mixed' ],
        [ "-Mtee --le 'foo qux' $UP -- $IN",                       qr/le/,       '--le with several keywords' ],
        [ "-Mtee --exclude foo -E qux $UP -- $IN",                 qr/Unknown option: exclude/, 'unknown option inside -Mtee' ],
    );
    for (@case) {
        my($cmd, $re, $name) = @$_;
        my($o, $st) = tee($cmd);
        isnt($st, 0, "$name: fails");
        like($o, $re, "$name: message");
        unlike($o, qr/FOO|<qux/, "$name: no output before error");
    }
    my($o, $st) = tee("-Mtee --le foo $UP -- $IN");
    is($st, 0, '--le with one keyword is accepted');
    ($o, $st) = tee("-Mtee $UP -- -Mtee $LT -- foo $IN");
    is($o, "<foo only\n<foo and qux\n", 'legacy twice: last wins');
};
my $ALL = "FOO only\n<qux only\nFOO and <qux\nnone\n";
subtest 'aliases' => sub {
    is((tee("-Mteetest --up --lt --filter $IN"))[0], $ALL, 'alias a b');
    is((tee("-Mteetest --lt --up --filter $IN"))[0], $ALL, 'alias b a');
    is((tee("-Mteetest --mix --filter $IN"))[0], $ALL, 'two -Mtee in one alias');
    is((tee("-Mtee::config(discrete=1) -Mteetest --up --filter $IN"))[0], "FOO only\nqux only\nFOO and qux\nnone\n", 'config-only -Mtee then alias');
    is((tee("-Mteetest -Mtee::config(discrete=1) --up --filter $IN"))[0], "FOO only\nqux only\nFOO and qux\nnone\n", 'alias module then config-only -Mtee');
    is((tee("-Mtee -E foo $UP -- -Mteetest --lt --filter $IN"))[0], $ALL, 'new form -Mtee then module and alias');
    is((tee("-Mtee -E foo $UP -- -Mteetest --lt --need=2 $IN"))[0], "FOO and <qux\n", 'same with --need=2 (patterns are not duplicated)');
    like((tee("-Mtee -E foo 'cat -n' -- -Mteetest --lt --filter $IN"))[0], qr/\A\s+1\tfoo only\n<qux only\n\s+2\tfoo and <qux\nnone\n\z/, 'same with bundled filter (each region sent once)');
    is((tee("-Mteetest --upm --lt --filter $IN"))[0], $ALL, 'alias ending with another module, then alias');
    is((tee("-Mteetest --upm --lt --need=2 $IN"))[0], "FOO and <qux\n", 'same with --need=2');
    is((tee("-Mteetest --lt --upm --filter $IN"))[0], $ALL, 'same in reverse order');
};
subtest 'config-only -Mtee' => sub {
    is((tee("-Mtee::config(discrete=1) foo $IN"))[0], "foo only\nfoo and qux\n", 'config-only -Mtee with patterns after it');
};
SKIP: {
    skip 'App::Greple::colors not installed', 1 unless eval { require App::Greple::colors };
    subtest 'other modules' => sub {
        is((tee("$TWO -Mcolors --filter $IN"))[0], $ALL, 'followed by another module');
        is((tee("-Mtee -E foo $UP -- -Mcolors -Mtee -E qux $LT -- --filter $IN"))[0], $ALL, 'module between -Mtee');
        is((tee("-Mtee -E foo $UP -- -Mcolors --filter $IN"))[0], "FOO only\nqux only\nFOO and qux\nnone\n", 'single -Mtee then module');
    };
}
subtest 'greple options' => sub {
    is((tee("-Mtee -E FOO $UP -- -i --filter $IN"))[0], "FOO only\nqux only\nFOO and qux\nnone\n", '-i applies');
    is((tee("$TWO --filter --exclude 'foo and.*' $IN"))[0], "FOO only\n<qux only\nfoo and qux\nnone\n", '--exclude applies to all');
    is((tee("$TWO --filter --inside '^.*only\\n' $IN"))[0], "FOO only\n<qux only\nfoo and qux\nnone\n", '--inside applies to all');
    like((tee("-Mtee --cm R -E foo $UP -- -Mtee --cm B -E qux $LT -- --filter $IN"))[0], qr/FOO/, '--cm passes through');
    local $ENV{NO_COLOR};
    delete $ENV{NO_COLOR};
    my($o) = tee("-Mtee --cm R -E foo $UP -- -Mtee --cm B -E qux $LT -- --color=always --filter $IN");
    like($o, qr/\e\[31mFOO/, '--cm R colors the first filter');
    like($o, qr/\e\[34m<qux/, '--cm B colors the second filter');
};
done_testing;
