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
done_testing;
