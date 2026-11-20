=encoding utf-8

=head1 NAME

App::Greple::tee - module to replace matched text by the external command result

=head1 SYNOPSIS

    greple -Mtee command -- ...
    greple -Mtee -E PAT1 command1 -- -Mtee -E PAT2 command2 -- ...

=head1 VERSION

Version 2.00_00

=head1 DESCRIPTION

Greple's B<-Mtee> module sends matched text part to the given filter
command, and replace them by the command result.  The idea is derived
from the command called B<teip>.  It is like bypassing partial data to
the external filter command.

Filter command follows module declaration (C<-Mtee>) and terminates by
two dashes (C<-->).  For example, next command call command C<tr>
command with C<a-z A-Z> arguments for the matched word in the data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command convert all matched words from lower-case to upper-case.
Actually this example itself is not so useful because B<greple> can do
the same thing more effectively with B<--cm> option.

By default, the command is executed as a single process, and all
matched data is sent to the process mixed together.  If the matched
text does not end with newline, it is added before sending and removed
after receiving.  Input and output data are mapped line by line, so
the number of lines of input and output must be identical.

Using B<--discrete> option, individual command is called for each
matched text area.  You can tell the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Lines of input and output data do not have to be identical when used
with B<--discrete> option.

=head1 OPTIONS

=over 7

=item B<--discrete>

Invoke new command individually for every matched part.

=item B<--bulkmode>

With the <--discrete> option, each command is executed on demand.  The
<--bulkmode> option causes all conversions to be performed at once.

This option has no effect in the new form of L</MULTIPLE FILTERS>,
where the filters are always executed for all the matches at once.

=item B<--crmode>

This option replaces all newline characters in the middle of each
block with carriage return characters.  Carriage returns contained in
the result of executing the command are reverted back to the newline
character. Thus, blocks consisting of multiple lines can be processed
in batches without using the B<--discrete> option.

This works well with L<ansifold> command's B<--crmode> option, which
joins CR-separated text and outputs folded lines separated by CR.

=item B<--fillup>

Combine a sequence of non-blank lines into a single line before
passing them to the filter command.  Newline characters between wide
width characters (Japanese, Chinese) are deleted, and other newline
characters are replaced with spaces.  Korean (Hangul) is treated
like ASCII text and joined with space.

=item B<--squeeze>

Combines two or more consecutive newline characters into one.

=item B<-ML> B<--offload> I<command>

L<teip(1)>'s B<--offload> option is implemented in the different
module L<App::Greple::L> (B<-ML>).

    greple -Mtee cat -n -- -ML --offload 'seq 10 20'

You can also use the B<-ML> module to process only even-numbered lines
as follows.

    greple -Mtee cat -n -- -ML 2::2

=back

=head1 MULTIPLE FILTERS

Repeating B<-Mtee> with patterns inside it applies a different filter
to each set of patterns.

    -Mtee [ OPTIONS ] [ COMMAND [ ARGS ... ] ] --

Everything before the first non-option argument is an option of the
module, and the rest up to C<--> is the command.  For example, next
command folds the lines that match C<PAT1> or C<PAT2> with
B<ansifold>, and puts the lines that match C<PAT3> in columns with
B<ansicolumn>.

    greple -Mtee --crmode -E PAT1 -E PAT2 '&ansifold' --crmode -w80 -- \
           -Mtee --discrete -E PAT3 '&ansicolumn' -t -- \
           file

There are two forms.

=over 4

=item B<Legacy form>

When there is no pattern inside B<-Mtee>, the command is applied to
all the patterns that follow C<-->, as before.  If it is specified
twice, the last one is effective.

=item B<New form>

When there is a pattern inside B<-Mtee>, the command is applied only to
the patterns in that B<-Mtee>.

=back

Mixing the two forms is an error.  A B<-Mtee> without arguments up to
C<-->, such as the first half of C<-Mtee::config(...) -Mtee ...>, only
sets the configuration and counts as neither form.

The errors are detected when the first file is searched, before any
output.

=head2 Options inside -Mtee

=over 4

=item B<--discrete>, B<--bulkmode>, B<--crmode>, B<--fillup>, B<--squeeze>, B<--nofork>

Modes of the filter.  They can be negated with the B<--no-> form, such
as B<--no-crmode>.

=item B<-E>, B<--re>

Regular expression pattern.

=item B<-e>

Pattern.  It is one pattern even if it includes spaces.

=item B<--fe>

Fixed string pattern.

=item B<--le>

A single keyword, or a C<&function>.  Giving several keywords
separated by spaces is an error.

=item B<--cm>

Passed to B<greple> as is.  The color is not bound to the pattern but
is assigned to the pattern numbers cyclically in the order specified
(see L</LIMITATIONS>).

=item B<--config>

A function of B<Getopt::EX::Config>.  It changes the setting common to
B<all> the filters.

=back

Other options such as B<--exclude> are errors.  Write them after
C<-->; they apply to all the filters.

=head2 Priority of modes

The value of a mode is decided at run time in the following order.

=over 4

=item 1.

The one specified inside the B<-Mtee> (B<--crmode>, B<--no-crmode>).

=item 2.

The one specified after C<-->, or by B<-Mtee::config(...)>.

=back

=head2 Special cases

=over 4

=item *

In the new form, B<--need=1> is added automatically, so that a block
which includes any one of the patterns is processed (OR).  Specify
B<--need> after C<--> to override it; B<--need=2> brings back AND.  The
legacy form works as before (AND).  Put B<--need> after all the
B<-Mtee> and the alias options that include B<-Mtee>, because each of
them adds B<--need=1> again.

=item *

If the command is omitted (C<-Mtee -E PAT -->), the pattern selects
text but the text is not changed.

=item *

In the new form, a pattern outside B<-Mtee> is an error.  So is
B<--callback> outside B<-Mtee>.

=item *

In the new form, a pattern given without an option after C<--> is not
taken as a pattern, because there are patterns given by options.
B<greple> takes it as a file name.

=item *

When the matches of different filters overlap, B<greple> merges them
into one area and the filter of the match which starts first is
applied.

=back

=head2 LIMITATIONS

=over 4

=item *

C<{DEFINE}> written directly inside B<-Mtee> on the command line is
not expanded.  It is expanded inside an B<option> definition.

=item *

No other option can be written between B<-Mtee> modules, because
B<-M> must be at the head of the arguments.  They can be combined
through an alias option.

=item *

C<--> cannot be included in the command arguments, as before.

=item *

B<--cm> is not independent for each filter.  If it is specified for
only some patterns, the colors of other patterns, including those in
other B<-Mtee>, change by the cyclic assignment of B<greple>.  Specify
B<--cm> for all the patterns when specifying colors.

=item *

When another module follows B<-Mtee> (C<-Mtee -E PAT cmd -- -Mcolors>),
the patterns are passed to B<greple> through the B<default> option of
the module, and the expansion of the option definition, such as
C<$ENV{NAME}> and C<__PACKAGE__>, applies to them.  Escaping them is
not attempted.

=item *

If a module whose B<default> option includes a new form B<-Mtee> is
loaded before B<-Mtee> followed by another module, such as
C<-Mfoo -Mtee -E PAT cmd -- -Mcolors>, the patterns are lost, and it
is detected as an error ("passed twice or lost").  Load the module
after B<-Mtee>.

=back

=head1 CONFIGURATION

Module parameters can be set with B<Getopt::EX::Config> module using
the following syntax:

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

This is useful when combined with shell aliases or module files.

Available parameters are: B<discrete>, B<bulkmode>, B<crmode>,
B<fillup>, B<squeeze>, B<nofork>.

=head1 FUNCTION CALL

Instead of an external command, you can call a Perl function by
prefixing the command name with C<&>.

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

The function is executed in a forked child process, so it must follow
these requirements:

=over 4

=item *

Read matched text from B<STDIN>

=item *

Print converted result to B<STDOUT>

=item *

Arguments are passed via both C<@ARGV> and C<@_>

=back

Any fully qualified function name can be used:

    greple -Mtee '&Your::Module::function' -- ...

The module is automatically loaded if not already loaded.

For convenience, the following short aliases are available:

=over 4

=item B<&ansicolumn>

Calls C<App::ansicolumn::ansicolumn>.

=item B<&ansifold>

Calls C<App::ansifold::ansifold>.

=item B<&cat-v>

Calls C<App::cat::v-E<gt>new-E<gt>run(@_)>.

=back

Using a function call avoids the overhead of forking an external
process for each invocation, which can significantly improve
performance when used with the B<--discrete> option.

=head1 LEGACIES

The B<--blocks> option has been removed.  It is no longer needed now that
the B<--stretch> (B<-S>) option has been implemented in B<greple>.
Use the following instead.

    greple -Mtee cat -n -- --all -SE foo

=head1 WHY DO NOT USE TEIP

First of all, whenever you can do it with the B<teip> command, use
it. It is an excellent tool and much faster than B<greple>.

Because B<greple> is designed to process document files, it has many
features that are appropriate for it, such as match area controls. It
might be worth using B<greple> to take advantage of those features.

Also, B<teip> cannot handle multiple lines of data as a single unit,
while B<greple> can execute individual commands on a data chunk
consisting of multiple lines.

=head1 EXAMPLE

Next command will find text blocks inside L<perlpod(1)> style document
included in Perl module file.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

You can translate them by DeepL service by executing the above command
convined with B<-Mtee> module which calls B<deepl> command like this:

    greple -Mtee deepl text --to JA - -- --fillup ...

The dedicated module L<App::Greple::xlate::deepl> is more effective
for this purpose, though.  In fact, the implementation hint of B<tee>
module came from B<xlate> module.

=head1 EXAMPLE 2

Next command will find some indented part in LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

You can reformat this part by using B<tee> module with B<ansifold>
command.  Using both B<--crmode> options together allows efficient
processing of multi-line blocks:

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

The B<--discrete> option can also be used but will start multiple
processes, so it takes longer to execute.

=head1 EXAMPLE 3

Consider a situation where you want to grep for strings from
non-header lines. For example, you may want to search for Docker image
names from the C<docker image ls> command, but leave the header line.
You can do it by following command.

    greple -Mtee grep perl -- -ML 2: --discrete --all

Option C<-ML 2:> retrieves the second to last lines and sends
them to the C<grep perl> command.  The option --discrete is required
because the number of lines of input and output changes, but since the
command is only executed once, there is no performance drawback.

If you try to do the same thing with the B<teip> command,
C<teip -l 2- -- grep> will give an error because the number of output
lines is less than the number of input lines. However, there is no
problem with the result obtained.

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>, L<https://github.com/kaz-utashiro/App-Greple-tee>

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple>

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate>

L<App::ansifold>, L<https://github.com/tecolicom/App-ansifold>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "2.00_00";

use v5.24;
use warnings;
use experimental 'refaliasing';
use List::Util qw(sum);
use Scalar::Util qw(refaddr blessed);
use Command::Run;
use Getopt::EX::Config;
use App::Greple::tee::Autoload qw(resolve);

my $config = Getopt::EX::Config->new(
    debug => 0,
    discrete => 0,
    fillup => 0,
    squeeze => 0,
    bulkmode => 0,
    crmode => 0,
    nofork => 1,
    use => '',
);
$config->configure('require_order');

\our $debug    = \$config->{debug};
\our $discrete = \$config->{discrete};
\our $fillup   = \$config->{fillup};
\our $squeeze  = \$config->{squeeze};
\our $bulkmode = \$config->{bulkmode};
\our $crmode   = \$config->{crmode};
\our $nofork   = \$config->{nofork};

my %MODE = (
    'discrete!' => 'discrete',
    'bulkmode!' => 'bulkmode',
    'crmode!'   => 'crmode',
    'fillup!'   => 'fillup',
    'squeeze!'  => 'squeeze',
    'nofork!'   => 'nofork',
);

my @filter;

# $own: total number of patterns given inside new form -Mtee
# $legacy: number of legacy form -Mtee (no patterns inside)
our $own = 0;
our $legacy = 0;
# options waiting to be inserted, and number of patterns among them
our @PEND;
our $pend_patterns = 0;
# argument list being processed when @PEND was left in default
our $pend_argv;

# --need=1 goes with the patterns of new form only
sub pending {
    ( $pend_patterns ? '--need=1' : () ), @PEND;
}

sub opt {
    my($f, $key) = @_;
    $f->{$key} // $config->{$key};
}

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
}

sub finalize {
    ($mod, $argv) = @_;
    my %f;
    my @emit;
    my $n = @filter;
    my $pattern = sub {
	my $opt = shift;
	sub {
	    push @emit, $opt, "$_[1]",
		'--callback', "&App::Greple::tee::callback(filter=$n)";
	    $f{patterns}++;
	};
    };
    my $before = @$argv;
    $config->deal_with($argv,
		       (map { $_ => \$f{$MODE{$_}} } keys %MODE),
		       'E|re=s' => $pattern->('--re'),
		       'e=s'    => $pattern->('-e'),
		       'fe=s'   => $pattern->('--fe'),
		       'le=s'   => do {
			   my $le = $pattern->('--le');
			   sub {
			       die "tee: --le inside -Mtee takes a single keyword or &function\n"
				   if $_[1] !~ /^&/ and $_[1] =~ /\s/;
			       goto &$le;
			   };
		       },
		       'cm=s'   => sub { push @emit, '--cm', "$_[1]" },
	);
    if (@$argv != $before) {
	$f{command} = [ $config->argv ];
	if ($f{patterns}) {
	    push @filter, \%f;
	    $own += $f{patterns};
	} else {
	    $legacy++;
	    @filter = (\%f);
	}
    }
    # Getopt::EX::Loader copies the default when it finishes an
    # argument list (the command line, or an alias expansion).  If
    # @PEND was left there while processing another list, it has been
    # copied already, and inserting it again would duplicate it.
    # (The exception, a default option of a module loaded before tee,
    # is detected in own_postgrep.)
    if (@PEND and refaddr $pend_argv != refaddr $argv) {
	@PEND = ();
	$pend_patterns = 0;
    }
    push @PEND, @emit;
    $pend_patterns += $f{patterns} // 0;
    if (@PEND and not (@$argv and $argv->[0] =~ /^-M/)) {
	splice @$argv, 0, 0, pending();
	@PEND = ();
	$pend_patterns = 0;
    }
    # keep the reference so that the address is not reused
    $pend_argv = @PEND ? $argv : undef;
    $mod->setopt(default => [
	'--postgrep', '&App::Greple::tee::postgrep',
	$legacy && !$own ? ( '--callback', '&App::Greple::tee::callback' ) : (),
	@PEND ? pending() : (),
    ]);
    state %used;
    for my $mod (grep { length and not $used{$_}++ } split /,/, $config->{use}) {
	eval "require $mod; $mod->import()";
	die $@ if $@;
    }
}

use Unicode::EastAsianWidth;

sub InConcatScript {
    return <<"END";
+App::Greple::tee::InFullwidth
-utf8::Hangul
END
}

sub InFullwidthPunctuation {
    return <<"END";
+App::Greple::tee::InFullwidth
&utf8::Punctuation
END
}

sub fillup_block {
    (my $s1, local $_, my $s2) = $_[0] =~ /\A(\s*)(.*?)(\s*)\z/s or die;
    s/(?<=\p{InFullwidthPunctuation})\n//g;
    s/(?<=\p{InConcatScript})\n(?=\p{InConcatScript})//g;
    s/[ ]*\n[ ]*/ /g;
    $s1 . $_ . $s2;
}

sub fillup_paragraphs {
    local *_ = @_ > 0 ? \$_[0] : \$_;
    s{^.+(?:\n.+)*}{ fillup_block ${^MATCH} }pmge;
}

sub call {
    my($f, $data) = @_;
    # resolve &function once, and keep one Command::Run object for the
    # filter: a new object makes new temporary files for every call
    my $command = $f->{_command} //= do {
	my @command = @{ $f->{command} // [] };
	$command[0] = resolve($1) if @command and $command[0] =~ /^&(.+)/;
	\@command;
    };
    @$command or return $data;
    if (opt($f, 'discrete') and opt($f, 'fillup')) {
	fillup_paragraphs $data;
    }
    my %run_opt = (stdin => $data);
    if (opt($f, 'nofork') and ref $command->[0] eq 'CODE') {
	$run_opt{nofork} = 1;
	$run_opt{raw} = 1;
    }
    my $exec = $f->{_exec} //= Command::Run->new;
    my $out = $exec->command(@$command)->with(%run_opt)->update->data // '';
    if (opt($f, 'squeeze')) {
	$out =~ s/\n\n+/\n/g;
    }
    $out;
}

sub bundle_call {
    my $f = shift;
    if (opt($f, 'fillup')) {
	fillup_paragraphs for @_;
    }
    my @chop = grep { $_[$_] =~ s/(?<!\n)\z/\n/ } keys @_;
    my @lines = map { int tr/\n/\n/ } @_;
    my $lines = sum @lines;
    my $out = call $f, join '', @_;
    my @out = $out =~ /.*\n/g;
    if (@out < $lines) {
	die "Unexpected short response:\n\n$out\n";
    } elsif (@out > $lines) {
	warn "Unexpected long response:\n\n$out\n";
    }
    my @ret = map { join '', splice @out, 0, $_ } @lines;
    chop for @ret[@chop];
    return @ret;
}

# run the filter for the blocks, and return the results
sub run_filter {
    my($f, @block) = @_;
    my $cr = opt($f, 'crmode');
    if ($cr) { s/\n(?!\z)/\r/g for @block }
    my @r = opt($f, 'discrete')
	? map { call $f, $_ } @block
	: bundle_call $f, @block;
    if ($cr) { s/\r/\n/g for @r }
    @r;
}

my @bundle;
my %out;
my $last_grep;

sub postgrep {
    my $grep = shift;
    return own_postgrep($grep) if $own;
    my $f = $filter[0] //= {};
    return if opt($f, 'discrete') and not opt($f, 'bulkmode');
    @bundle = my @block = ();
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	push @block, map { $grep->cut(@$_) } @match;
    }
    @bundle = run_filter($f, @block) if @block;
}

# new form: process the matches of each filter, keyed by match start
sub own_postgrep {
    my $grep = shift;
    # postgrep may be called more than once for the same grep object
    # (through alias options).  Keep the reference so that the address
    # is not reused by the next object.
    return if $last_grep and refaddr $last_grep == refaddr $grep;
    $last_grep = $grep;
    die "tee: cannot mix -Mtee with and without patterns\n" if $legacy;
    my @callback = @{ $grep->{callback} // [] };
    die "tee: --callback given outside -Mtee is not supported with patterns inside -Mtee\n"
	if grep { not defined filter_id($_) } @callback;
    die "tee: pattern given outside -Mtee (put every pattern inside -Mtee ... --)\n"
	if $grep->{pattern}->patterns != @callback;
    die "tee: patterns inside -Mtee are passed twice or lost (check the order of modules and aliases)\n"
	if @callback != $own;
    %out = ();
    my(%start, %block);
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    my $n = filter_id($m->[3]) // next;
	    push @{$start{$n}}, $m->[0];
	    push @{$block{$n}}, $grep->cut(@$m[0,1]);
	}
    }
    for my $n (keys %block) {
	my $f = $filter[$n] // die "tee: unknown filter $n\n";
	my @block = @{$block{$n}};
	@out{@{$start{$n}}} =
	    @{ $f->{command} // [] } ? run_filter($f, @block) : @block;
    }
}

# filter number of tee's own new form callback, without calling it
sub filter_id {
    my $cb = shift;
    blessed $cb and $cb->isa('Getopt::EX::Func') or return undef;
    my($name, %arg) = @$cb;
    return undef if ref $name or $name ne __PACKAGE__ . '::callback';
    my $n = $arg{filter} // return undef;
    return undef unless $n =~ /^\d+\z/ and $filter[$n];
    $n;
}

sub callback {
    my %arg = @_;
    if (exists $arg{filter}) {
	return $out{$arg{start}};
    }
    my $f = $filter[0] //= {};
    if (opt($f, 'discrete') and not opt($f, 'bulkmode')) {
	call $f, $arg{match};
    }
    else {
	shift @bundle // die;
    }
}

1;

__DATA__

builtin tee-debug $debug
builtin discrete! $discrete
builtin bulkmode! $bulkmode
builtin crmode!   $crmode
builtin fillup!   $fillup
builtin squeeze   $squeeze
builtin nofork!   $nofork

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
