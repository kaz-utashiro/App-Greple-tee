[![Actions Status](https://github.com/kaz-utashiro/App-Greple-tee/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/App-Greple-tee/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-tee.svg)](https://metacpan.org/release/App-Greple-tee)
# NAME

App::Greple::tee - module to replace matched text by the external command result

# SYNOPSIS

    greple -Mtee command -- ...
    greple -Mtee -E PAT1 command1 -- -Mtee -E PAT2 command2 -- ...

# VERSION

Version 2.00\_01

# DESCRIPTION

Greple's **-Mtee** module sends the matched parts of the text to the
given filter command, and replaces them with the result of the command.
The idea is derived from the command called **teip**.  It is like
passing only a part of the data through an external filter command.

The filter command follows the module declaration (`-Mtee`) and ends
with two dashes (`--`).  For example, the next command calls the
`tr` command with the arguments `a-z A-Z` for the matched words in
the data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

The above command converts all the matched words from lower case to
upper case.  This example itself is not so useful, because **greple**
can do the same thing more efficiently with the **--cm** option.

By default, the command is executed as a single process, and all the
matched data is sent to it together.  If the matched text does not
end with a newline, one is added before sending and removed after
receiving.  Input and output data are mapped line by line, so
the number of lines of input and output must be identical.

With the **--discrete** option, the command is called separately for
each matched area.  You can see the difference with the following
commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

With the **--discrete** option, the number of lines of input and output
does not have to be the same.

# OPTIONS

- **--discrete**

    Invokes a new command for each matched part.

- **--bulkmode**

    With the **--discrete** option, the command for each match is executed
    when the match is output.  The **--bulkmode** option executes all of
    them at once before the output.

    This option has no effect in the new form of ["MULTIPLE FILTERS"](#multiple-filters),
    where the filters are always executed for all the matches at once.

- **--crmode**

    This option replaces all newline characters in the middle of each
    block with carriage return characters.  Carriage returns contained in
    the result of executing the command are converted back to newline
    characters.  Thus, blocks consisting of multiple lines can be processed
    in batches without using the **--discrete** option.

    This works well with the **--crmode** option of the [ansifold](https://metacpan.org/pod/ansifold)
    command, which joins CR-separated text and outputs folded lines
    separated by CR.

- **--fillup**

    Combines a sequence of non-blank lines into a single line before
    passing them to the filter command.  Newline characters between
    full-width characters (Japanese, Chinese) are deleted, and other newline
    characters are replaced with spaces.  Korean (Hangul) is treated
    like ASCII text and joined with spaces.

- **--squeeze**

    Combines two or more consecutive newline characters into one.

- **--nofork**

    Executes a function given by `&function` in the **greple** process
    itself, without forking.  This is the default.  Use **--no-nofork** to
    execute it in a forked child process.  This option has no effect on
    external commands.  See ["FUNCTION CALL"](#function-call).

- **-ML** **--offload** _command_

    The equivalent of the **--offload** option of [teip(1)](http://man.he.net/man1/teip) is provided
    by another module, [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL) (**-ML**).

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    You can also use the **-ML** module to process only even-numbered lines
    as follows.

        greple -Mtee cat -n -- -ML 2::2

# MULTIPLE FILTERS

You can give **-Mtee** more than once, each with its own patterns and
filter.  Each filter is applied to the patterns given with it.

    -Mtee [ OPTIONS ] [ COMMAND [ ARGS ... ] ] --

Everything before the first non-option argument is an option of the
module, and the rest up to `--` is the command.  For example, the
next command folds the lines that match `PAT1` or `PAT2` with
**ansifold**, and formats each part that matches `PAT3` as a separate
table with **ansicolumn**.

    greple -Mtee --crmode -E PAT1 -E PAT2 '&ansifold' --crmode -w80 -- \
           -Mtee --discrete -E PAT3 '&ansicolumn' -t -- \
           file

To give a command which takes `--` itself, start the arguments of
**-Mtee** with a word of three or more dashes, and end them with the
same word instead of `--`:

    greple -Mtee --- nup --ac -w 100 -- --- PATTERN file

This needs [Getopt::EX::Config](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AConfig) 1.03 or later.

There are two forms.

- **Legacy form**

    When there is no pattern inside **-Mtee**, the command is applied to
    all the patterns that follow `--`, as before.  If it is given
    more than once, the last one takes effect.

- **New form**

    When there is a pattern inside **-Mtee**, the command is applied only to
    the patterns in that **-Mtee**.

Mixing the two forms is an error.  A **-Mtee** with nothing before
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

    Pattern.  It is taken as one pattern even if it includes spaces.

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

    An option provided by **Getopt::EX::Config**.  It changes the setting
    common to **all** the filters.

Giving other options, such as **--exclude**, is an error.  Write them
after `--`; they apply to all the filters.

## Priority of modes

The value of a mode is decided at run time in the following order.

1. The one specified inside **-Mtee** (**--crmode**, **--no-crmode**).
2. The one specified after `--`, or by **-Mtee::config(...)**.

## Special cases

- In the new form, **--need=1** is added automatically, so that a block
which includes any one of the patterns is processed (OR).  Specify
**--need** after `--` to override it; **--need=2** brings back AND.  The
legacy form works as before (AND).  Each **-Mtee**, and each alias
option that includes **-Mtee**, adds **--need=1** again, so put
**--need** after all of them.
- If the command is omitted (`-Mtee -E PAT --`), the pattern selects
text but the text is not changed.
- In the new form, a pattern outside **-Mtee** is an error.  So is
**--callback** outside **-Mtee**.
- In the new form, the first argument after `--` is not taken as a
pattern even if it is meant as one, because the patterns are already
given by options.  **greple** takes it as a file name.
- When the matches of different filters overlap, **greple** merges them
into one area and the filter of the match which starts first is
applied.

## LIMITATIONS

- `{DEFINE}` written directly inside **-Mtee** on the command line is
not expanded.  It is expanded inside an **option** definition.
- No other option can be written between **-Mtee** modules, because
**-M** must be at the head of the arguments.  Use an alias option to
combine **-Mtee** modules and other options.
- **--cm** is not independent for each filter.  If it is specified for
only some patterns, the colors of other patterns, including those in
other **-Mtee**, change because of the cyclic assignment by
**greple**.  Specify **--cm** for all the patterns when specifying
colors.
- When another module follows **-Mtee** (`-Mtee -E PAT cmd -- -Mcolors`),
the patterns are passed to **greple** through the **default** option of
the module, and the expansion of the option definition, such as
`$ENV{NAME}` and `__PACKAGE__`, applies to them.  They are not
escaped.
- Suppose there is a module whose **default** option includes a new
form **-Mtee**.  If it is loaded before a **-Mtee** which is followed by
another module, as in `-Mfoo -Mtee -E PAT cmd -- -Mcolors`, the
patterns are lost.  This is detected as an error ("passed twice or
lost").  Load such a module after **-Mtee**.

# CONFIGURATION

Module parameters can be set with the **Getopt::EX::Config** module using
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

The function must follow these requirements:

- Read the matched text from **STDIN**
- Print the converted result to **STDOUT**
- Arguments are passed via both `@ARGV` and `@_`

By default, the function is executed in the **greple** process
itself, without forking.  So, the values of global variables changed
by the function remain in the next call, and calling **exit** in the
function terminates **greple**.  With the **--no-nofork** option, the
function is executed in a forked child process.

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

Using a function call avoids the overhead of starting an external
process for each invocation, which can significantly improve
performance when used with the **--discrete** option.

# LEGACIES

The **--blocks** option has been removed.  It is no longer needed now that
the **--stretch** (**-S**) option has been implemented in **greple**.
Use the following instead.

    greple -Mtee cat -n -- --all -SE foo

# WHY NOT USE TEIP

First of all, whenever you can do it with the **teip** command, use
it. It is an excellent tool and much faster than **greple**.

Because **greple** is designed to process document files, it has many
features that are appropriate for it, such as match area controls. It
might be worth using **greple** to take advantage of those features.

Also, **teip** cannot handle multiple lines of data as a single unit,
while **greple** can execute individual commands on a data chunk
consisting of multiple lines.

# EXAMPLE

The next command finds the text blocks of the [perlpod(1)](http://man.he.net/man1/perlpod) style
document in a Perl module file.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

You can translate them with the DeepL service by combining the above
command with the **-Mtee** module calling the **deepl** command, like
this:

    greple -Mtee deepl text --to JA - -- --fillup ...

The dedicated module [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) is more effective
for this purpose, though.  In fact, the hint for implementing the
**tee** module came from the **xlate** module.

# EXAMPLE 2

The next command finds some indented parts in the LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

You can reformat these parts by using the **tee** module with the
**ansifold** command.  Using both **--crmode** options together allows
efficient processing of multi-line blocks:

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

Consider a situation where you want to grep for strings in lines
other than the header.  For example, you may want to search for Docker
image names in the output of the `docker image ls` command, but keep
the header line.  You can do it with the following command.

    greple -Mtee grep perl -- -ML 2: --discrete --all

The option `-ML 2:` takes the lines from the second line to the end,
and sends them to the `grep perl` command.  The option **--discrete**
is required because the number of lines changes, but since the
command is executed only once, there is no performance drawback.

If you try to do the same thing with the **teip** command,
`teip -l 2- -- grep` will give an error because the number of output
lines is less than the number of input lines, although the output
itself is correct.

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
