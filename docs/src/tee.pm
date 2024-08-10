=encoding utf-8

=head1 NAME

App::Greple::tee - module to replace matched text by the external command result

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 VERSION

Version 0.9903

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

=item B<--crmode>

This option replaces all newline characters in the middle of each
block with carriage return characters.  Carriage returns contained in
the result of executing the command are reverted back to the newline
character. Thus, blocks consisting of multiple lines can be processed
in batches without using the B<--discrete> option.

=item B<--fillup>

Combine a sequence of non-blank lines into a single line before
passing them to the filter command.  Newline characters between wide
width characters are deleted, and other newline characters are
replaced with spaces.

=item B<--blocks>

Normally, the area matching the specified search pattern is sent to
the external command. If this option is specified, not the matched
area but the entire block containing it will be processed.

For example, to send lines containing the pattern C<foo> to the
external command, you need to specify the pattern which matches to
entire line:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

But with the B<--blocks> option, it can be done as simply as follows:

    greple -Mtee cat -n -- foo --blocks

With B<--blocks> option, this module behave more like L<teip(1)>'s
B<-g> option.  Otherwise, the behavior is similar to L<teip(1)> with
the B<-o> option.

Do not use the B<--blocks> with the B<--all> option, since the block
will be the entire data.

=item B<--squeeze>

Combines two or more consecutive newline characters into one.

=back

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

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

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
command:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

The --discrete option will start multiple processes, so the process
will take longer to execute.  So you can use C<--separate '\r'> option
with C<ansifold> which produce single line using CR character instead
of NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Then convert CR char to NL after by L<tr(1)> command or some.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Consider a situation where you want to grep for strings from
non-header lines. For example, you may want to search for Docker image
names from the C<docker image ls> command, but leave the header line.
You can do it by following command.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Option C<-Mline -L 2:> retrieves the second to last lines and sends
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

=head1 BUGS

The C<--fillup> option will remove spaces between Hangul characters when 
concatenating Korean text.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
