[![Actions Status](https://github.com/kaz-utashiro/App-Greple-tee/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/App-Greple-tee/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-tee.svg)](https://metacpan.org/release/App-Greple-tee)
# NAME

App::Greple::tee - module to replace matched text by the external command result

# SYNOPSIS

    greple -Mtee command -- ...
    greple -Mtee -E PAT1 command1 -- -Mtee -E PAT2 command2 -- ...

# VERSION

Version 2.00\_00

# DESCRIPTION

Greple's **-Mtee** module sends matched text part to the given filter
command, and replace them by the command result.  The idea is derived
from the command called **teip**.  It is like bypassing partial data to
the external filter command.

Filter command follows module declaration (`-Mtee`) and terminates by
two dashes (`--`).  For example, next command call command `tr`
command with `a-z A-Z` arguments for the matched word in the data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command convert all matched words from lower-case to upper-case.
Actually this example itself is not so useful because **greple** can do
the same thing more effectively with **--cm** option.

By default, the command is executed as a single process, and all
matched data is sent to the process mixed together.  If the matched
text does not end with newline, it is added before sending and removed
after receiving.  Input and output data are mapped line by line, so
the number of lines of input and output must be identical.

Using **--discrete** option, individual command is called for each
matched text area.  You can tell the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Lines of input and output data do not have to be identical when used
with **--discrete** option.

# OPTIONS

- **--discrete**

    Invoke new command individually for every matched part.

- **--bulkmode**

    With the <--discrete> option, each command is executed on demand.  The
    <--bulkmode> option causes all conversions to be performed at once.

    This option has no effect in the new form of ["MULTIPLE FILTERS"](#multiple-filters),
    where the filters are always executed for all the matches at once.

- **--crmode**

    This option replaces all newline characters in the middle of each
    block with carriage return characters.  Carriage returns contained in
    the result of executing the command are reverted back to the newline
    character. Thus, blocks consisting of multiple lines can be processed
    in batches without using the **--discrete** option.

    This works well with [ansifold](https://metacpan.org/pod/ansifold) command's **--crmode** option, which
    joins CR-separated text and outputs folded lines separated by CR.

- **--fillup**

    Combine a sequence of non-blank lines into a single line before
    passing them to the filter command.  Newline characters between wide
    width characters (Japanese, Chinese) are deleted, and other newline
    characters are replaced with spaces.  Korean (Hangul) is treated
    like ASCII text and joined with space.

- **--squeeze**

    Combines two or more consecutive newline characters into one.

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip)'s **--offload** option is implemented in the different
    module [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL) (**-ML**).

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    You can also use the **-ML** module to process only even-numbered lines
    as follows.

        greple -Mtee cat -n -- -ML 2::2

# MULTIPLE FILTERS

Repeating **-Mtee** with patterns inside it applies a different filter
to each set of patterns.

    -Mtee [ OPTIONS ] [ COMMAND [ ARGS ... ] ] --

Everything before the first non-option argument is an option of the
module, and the rest up to `--` is the command.  For example, next
command folds the lines that match `PAT1` or `PAT2` with
**ansifold**, and puts the lines that match `PAT3` in columns with
**ansicolumn**.

    greple -Mtee --crmode -E PAT1 -E PAT2 '&ansifold' --crmode -w80 -- \
           -Mtee --discrete -E PAT3 '&ansicolumn' -t -- \
           file

There are two forms.

- **Legacy form**

    When there is no pattern inside **-Mtee**, the command is applied to
    all the patterns that follow `--`, as before.  If it is specified
    twice, the last one is effective.

- **New form**

    When there is a pattern inside **-Mtee**, the command is applied only to
    the patterns in that **-Mtee**.

Mixing the two forms is an error.  A **-Mtee** without arguments up to
`--`, such as the first half of `-Mtee::config(...) -Mtee ...`, only
sets the configuration and counts as neither form.

The errors are detected when the first file is searched, before any
output.

## Options inside -Mtee

- **--discrete**, **--bulkmode**, **--crmode**, **--fillup**, **--squeeze**, **--nofork**

    Modes of the filter.  They can be negated with the **--no-** form, such
    as **--no-crmode**.

- **-E**, **--re**

    Regular expression pattern.

- **-e**

    Pattern.  It is one pattern even if it includes spaces.

- **--fe**

    Fixed string pattern.

- **--le**

    A single keyword, or a `&function`.  Giving several keywords
    separated by spaces is an error.

- **--cm**

    Passed to **greple** as is.  The color is not bound to the pattern but
    is assigned to the pattern numbers cyclically in the order specified
    (see ["LIMITATIONS"](#limitations)).

- **--config**

    A function of **Getopt::EX::Config**.  It changes the setting common to
    **all** the filters.

Other options such as **--exclude** are errors.  Write them after
`--`; they apply to all the filters.

## Priority of modes

The value of a mode is decided at run time in the following order.

1. The one specified inside the **-Mtee** (**--crmode**, **--no-crmode**).
2. The one specified after `--`, or by **-Mtee::config(...)**.

## Special cases

- In the new form, **--need=1** is added automatically, so that a block
which includes any one of the patterns is processed (OR).  Specify
**--need** after `--` to override it; **--need=2** brings back AND.  The
legacy form works as before (AND).  Put **--need** after all the
**-Mtee** and the alias options that include **-Mtee**, because each of
them adds **--need=1** again.
- If the command is omitted (`-Mtee -E PAT --`), the pattern selects
text but the text is not changed.
- In the new form, a pattern outside **-Mtee** is an error.  So is
**--callback** outside **-Mtee**.
- In the new form, a pattern given without an option after `--` is not
taken as a pattern, because there are patterns given by options.
**greple** takes it as a file name.
- When the matches of different filters overlap, **greple** merges them
into one area and the filter of the match which starts first is
applied.

## LIMITATIONS

- `{DEFINE}` written directly inside **-Mtee** on the command line is
not expanded.  It is expanded inside an **option** definition.
- No other option can be written between **-Mtee** modules, because
**-M** must be at the head of the arguments.  They can be combined
through an alias option.
- `--` cannot be included in the command arguments, as before.
- **--cm** is not independent for each filter.  If it is specified for
only some patterns, the colors of other patterns, including those in
other **-Mtee**, change by the cyclic assignment of **greple**.  Specify
**--cm** for all the patterns when specifying colors.
- When another module follows **-Mtee** (`-Mtee -E PAT cmd -- -Mcolors`),
the patterns are passed to **greple** through the **default** option of
the module, and the expansion of the option definition, such as
`$ENV{NAME}` and `__PACKAGE__`, applies to them.  Escaping them is
not attempted.
- If a module whose **default** option includes a new form **-Mtee** is
loaded before **-Mtee** followed by another module, such as
`-Mfoo -Mtee -E PAT cmd -- -Mcolors`, the patterns are lost, and it
is detected as an error ("passed twice or lost").  Load the module
after **-Mtee**.

# CONFIGURATION

Module parameters can be set with **Getopt::EX::Config** module using
the following syntax:

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

This is useful when combined with shell aliases or module files.

Available parameters are: **discrete**, **bulkmode**, **crmode**,
**fillup**, **squeeze**, **nofork**.

# FUNCTION CALL

Instead of an external command, you can call a Perl function by
prefixing the command name with `&`.

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

The function is executed in a forked child process, so it must follow
these requirements:

- Read matched text from **STDIN**
- Print converted result to **STDOUT**
- Arguments are passed via both `@ARGV` and `@_`

Any fully qualified function name can be used:

    greple -Mtee '&Your::Module::function' -- ...

The module is automatically loaded if not already loaded.

For convenience, the following short aliases are available:

- **&ansicolumn**

    Calls `App::ansicolumn::ansicolumn`.

- **&ansifold**

    Calls `App::ansifold::ansifold`.

- **&cat-v**

    Calls `App::cat::v->new->run(@_)`.

Using a function call avoids the overhead of forking an external
process for each invocation, which can significantly improve
performance when used with the **--discrete** option.

# LEGACIES

The **--blocks** option has been removed.  It is no longer needed now that
the **--stretch** (**-S**) option has been implemented in **greple**.
Use the following instead.

    greple -Mtee cat -n -- --all -SE foo

# WHY DO NOT USE TEIP

First of all, whenever you can do it with the **teip** command, use
it. It is an excellent tool and much faster than **greple**.

Because **greple** is designed to process document files, it has many
features that are appropriate for it, such as match area controls. It
might be worth using **greple** to take advantage of those features.

Also, **teip** cannot handle multiple lines of data as a single unit,
while **greple** can execute individual commands on a data chunk
consisting of multiple lines.

# EXAMPLE

Next command will find text blocks inside [perlpod(1)](http://man.he.net/man1/perlpod) style document
included in Perl module file.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

You can translate them by DeepL service by executing the above command
convined with **-Mtee** module which calls **deepl** command like this:

    greple -Mtee deepl text --to JA - -- --fillup ...

The dedicated module [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) is more effective
for this purpose, though.  In fact, the implementation hint of **tee**
module came from **xlate** module.

# EXAMPLE 2

Next command will find some indented part in LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

You can reformat this part by using **tee** module with **ansifold**
command.  Using both **--crmode** options together allows efficient
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

The **--discrete** option can also be used but will start multiple
processes, so it takes longer to execute.

# EXAMPLE 3

Consider a situation where you want to grep for strings from
non-header lines. For example, you may want to search for Docker image
names from the `docker image ls` command, but leave the header line.
You can do it by following command.

    greple -Mtee grep perl -- -ML 2: --discrete --all

Option `-ML 2:` retrieves the second to last lines and sends
them to the `grep perl` command.  The option --discrete is required
because the number of lines of input and output changes, but since the
command is only executed once, there is no performance drawback.

If you try to do the same thing with the **teip** command,
`teip -l 2- -- grep` will give an error because the number of output
lines is less than the number of input lines. However, there is no
problem with the result obtained.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold), [https://github.com/tecolicom/App-ansifold](https://github.com/tecolicom/App-ansifold)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
