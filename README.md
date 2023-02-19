
# NAME

App::Greple::tee - Greple -Mtee module

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple's **-Mtee** module sends matched text part to the specified
command, and replace them by the output of the command.

Command is specifed as a following arguments after the module option
ending with `--`.  For example, next command call command `tr a-z
A-Z` for the matched word in the data.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Above command effectively convert all matched words from lower-case to
upper-case letter.  Actually this example is not useful because
**greple** can do the same thing more effectively with **--cm** option.

By default, the command is executed only once and all data is sent to
the same command.  Number of lines in the output must be same as in
input data.

Using **--discrete** option, individual command is called for each
matched part.  You can notice the difference by following commands.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

# OPTIONS

- **--discrete**

    Invoke new command for every matched part.

# SEE ALSO

- [https://github.com/greymd/teip](https://github.com/greymd/teip)

    This module is inspired by the command named **teip**.  Unlike **teip**
    command, this module does not have a performace advantage.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
