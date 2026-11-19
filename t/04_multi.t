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
done_testing;
