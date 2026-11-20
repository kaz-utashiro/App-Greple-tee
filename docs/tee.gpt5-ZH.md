# NAME

App::Greple::tee - 用外部命令结果替换匹配文本的模块

# SYNOPSIS

    greple -Mtee command -- ...
    greple -Mtee -E PAT1 command1 -- -Mtee -E PAT2 command2 -- ...

# VERSION

Version 2.00\_00

# DESCRIPTION

Greple 的 **-Mtee** 模块将匹配到的文本片段发送给指定的过滤命令，并用该命令的结果替换。这个想法源自名为 **teip** 的命令。它就像把部分数据旁路到外部过滤命令。

过滤命令紧跟在模块声明（`-Mtee`）之后，并以两个短横线（`--`）结束。例如，下面的命令对数据中匹配到的单词调用 `tr` 命令，并传入 `a-z A-Z` 参数。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上面的命令把所有匹配到的单词从小写转换为大写。事实上，这个例子本身不太实用，因为 **greple** 使用 **--cm** 选项可以更高效地完成同样的事情。

默认情况下，命令作为单个进程执行，所有匹配到的数据混合后发送到该进程。如果匹配文本不以换行结束，会在发送前补加换行并在接收后去除。输入与输出数据按行对应，因此输入与输出的行数必须相同。

使用 **--discrete** 选项时，会为每个匹配的文本区域单独调用命令。你可以通过以下命令分辨差异。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

与 **--discrete** 选项一起使用时，输入与输出数据的行数不必相同。

# OPTIONS

- **--discrete**

    为每个匹配到的部分单独启动新命令。

- **--bulkmode**

    使用 **--discrete** 选项时，每个匹配项的命令会在输出匹配项时执行。**--bulkmode** 选项会在输出前一次性执行所有命令。

    在 ["MULTIPLE FILTERS"](#multiple-filters) 的新形式中，此选项无效，因为筛选器始终会一次性对所有匹配项执行。

- **--crmode**

    该选项会将每个块中间的所有换行符替换为回车符。执行命令得到的结果中包含的回车符会还原为换行符。这样就可以在不使用 **--discrete** 选项的情况下批量处理由多行组成的块。

    这与 [ansifold](https://metacpan.org/pod/ansifold) 命令的 **--crmode** 选项配合良好，该选项将以 CR 分隔的文本合并，并输出以 CR 分隔的折行。

- **--fillup**

    在传给过滤命令之前，将连续的非空行合并为一行。全角字符（中文、日文）之间的换行会被删除，其他换行会被替换为空格。韩文（谚文/Hangul）按 ASCII 文本处理，以空格连接。

- **--squeeze**

    将两个或更多连续的换行合并为一个。

- **--nofork**

    在 **greple** 进程本身中执行由 `&function` 指定的函数，而不创建子进程（参见 ["FUNCTION CALL"](#function-call)）。这是默认设置。使用 **--no-nofork** 可在创建的子进程中执行它。此选项对外部命令无效。

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip) 的 **--offload** 选项的等效功能由另一个模块 [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL)（**-ML**）提供。

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    你也可以使用 **-ML** 模块如下只处理偶数行。

        greple -Mtee cat -n -- -ML 2::2

# MULTIPLE FILTERS

可以多次指定 **-Mtee**，每次都有自己的模式和过滤器。每个过滤器都应用于与其一起指定的模式。

    -Mtee [ OPTIONS ] [ COMMAND [ ARGS ... ] ] --

第一个非选项参数之前的所有内容都是模块选项，其余直到 `--` 为止的是命令。例如，以下命令使用 **ansifold** 折叠匹配 `PAT1` 或 `PAT2` 的行，并使用 **ansicolumn** 将匹配 `PAT3` 的行格式化为表格。

    greple -Mtee --crmode -E PAT1 -E PAT2 '&ansifold' --crmode -w80 -- \
           -Mtee --discrete -E PAT3 '&ansicolumn' -t -- \
           file

有两种形式。

- **Legacy form**

    当 **-Mtee** 中没有模式时，命令会像以前一样应用于 `--` 之后的所有模式。如果给出多次，则最后一个生效。

- **New form**

    当 **-Mtee** 中有模式时，命令只应用于该 **-Mtee** 中的模式。

混用这两种形式会导致错误。`--` 之前没有任何内容的 **-Mtee**，例如 `-Mtee::config(...) -Mtee ...` 的前半部分，只设置配置，且不属于任何一种形式。

错误会在搜索第一个文件时、任何输出之前被检测到。

## Options inside -Mtee

- **--discrete**, **--bulkmode**, **--crmode**, **--fillup**, **--squeeze**, **--nofork**

    过滤器的模式。可使用 **--no-** 形式将其否定，例如 **--no-crmode**。

- **-E**, **--re**

    正则表达式模式。

- **-e**

    模式。即使包含空格，也会被视为一个模式。

- **--fe**

    固定字符串模式。

- **--le**

    单个关键字，或一个 `&function`。给出多个以空格分隔的关键字会导致错误。

- **--cm**

    原样传递给 **greple**。颜色不绑定到模式，而是按指定顺序循环分配给模式编号（参见 ["LIMITATIONS"](#limitations)）。

- **--config**

    由 **Getopt::EX::Config** 提供的一个选项。它会更改 **所有** 过滤器共用的设置。

给出其他选项（如 **--exclude**）会导致错误。请将它们写在 `--` 之后；它们会应用于所有过滤器。

## Priority of modes

模式的值在运行时按以下顺序决定。

1. 在 **-Mtee** 内指定的值（**--crmode**、**--no-crmode**）。
2. 在 `--` 之后指定的值，或由 **-Mtee::config(...)** 指定的值。

## Special cases

- 在新形式中，会自动添加 **--need=1**，因此会处理包含任一模式的块（OR）。在 `--` 之后指定 **--need** 可覆盖它；**--need=2** 会恢复 AND。旧形式仍按原来的方式工作（AND）。每个 **-Mtee** 以及每个包含 **-Mtee** 的别名选项都会再次添加 **--need=1**，因此请将 **--need** 放在它们全部之后。
- 如果省略命令（`-Mtee -E PAT --`），模式会选择文本，但不会更改文本。
- 在新形式中，**-Mtee** 外的模式会导致错误。**-Mtee** 外的 **--callback** 也是如此。
- 在新形式中，`--` 之后的第一个参数即使本意是模式，也不会被视为模式，因为模式已通过选项给出。**greple** 会将其视为文件名。
- 当不同过滤器的匹配区域重叠时，**greple** 会将它们合并为一个区域，并应用最先开始的匹配所对应的过滤器。

## LIMITATIONS

- 直接在命令行的 **-Mtee** 内编写的 `{DEFINE}` 不会展开。在 **option** 定义内则会展开。
- 不能在 **-Mtee** 模块之间写入其他选项，因为 **-M** 必须位于参数开头。使用别名选项将 **-Mtee** 模块与其他选项组合。
- 与以前一样，命令参数中不能包含 `--`。
- **--cm** 并非对每个过滤器独立。如果仅为部分模式指定它，包括其他 **-Mtee** 中的模式在内的其他模式颜色会因 **greple** 的循环分配而改变。指定颜色时，请为所有模式指定 **--cm**。
- 当另一个模块位于 **-Mtee** 之后时（`-Mtee -E PAT cmd -- -Mcolors`），模式会通过该模块的 **default** 选项传递给 **greple**，并且选项定义中的扩展（如 `$ENV{NAME}` 和 `__PACKAGE__`）会应用于这些模式。它们不会被转义。
- 假设存在某个 **default** 选项包含新形式 **-Mtee** 的模块。如果它在 **-Mtee** 后跟另一个模块之前加载，例如 `-Mfoo -Mtee -E PAT cmd -- -Mcolors`，模式会丢失。这会被检测为错误（“重复传递或丢失”）。请在 **-Mtee** 之后加载此类模块。

# CONFIGURATION

模块参数可使用 **Getopt::EX::Config** 模块按以下语法设置：

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

这在与 shell 别名或模块文件结合时很有用。

可用参数有：**discrete**、**bulkmode**、**crmode**、**fillup**、**squeeze**、**nofork**。

# FUNCTION CALL

您可以通过在命令名前加上 `&` 来调用 Perl 函数，而不是外部命令。

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

该函数必须遵循以下要求：

- 从 **STDIN** 读取匹配的文本
- 将转换后的结果打印到 **STDOUT**
- 参数通过 `@ARGV` 和 `@_` 同时传递

默认情况下，函数在 **greple** 进程本身中执行，不会 fork。因此，函数更改的全局变量值会保留到下一次调用，并且在函数中调用 **exit** 会终止 **greple**。使用 **--no-nofork** 选项时，函数会在 fork 出来的子进程中执行。

可以使用任何完全限定的函数名：

    greple -Mtee '&Your::Module::function' -- ...

如果模块尚未加载，将自动加载。

为方便起见，提供以下简短别名：

- **&ansicolumn**

    调用 `App::ansicolumn::ansicolumn`。

- **&ansifold**

    调用 `App::ansifold::ansifold`。

- **&cat-v**

    调用 `App::cat::v->new->run(@_)`。

使用函数调用可避免每次调用都启动外部进程所带来的开销，当与 **--discrete** 选项一起使用时，可显著提升性能。

# LEGACIES

**--blocks** 选项已被移除。由于 **greple** 中已实现 **--stretch**（**-S**）选项，它已不再需要。请改用以下方式。

    greple -Mtee cat -n -- --all -SE foo

# WHY NOT USE TEIP

首先，只要可以用 **teip** 命令做到，就用它。它是一个优秀且比 **greple** 快得多的工具。

由于 **greple** 旨在处理文档文件，它具有许多适用于此目的的功能，例如匹配区域控制。为了利用这些功能，使用 **greple** 也许是值得的。

此外，**teip** 不能将多行数据作为一个单元处理，而 **greple** 可以对由多行组成的数据块执行单独的命令。

# EXAMPLE

下面的命令将会在包含于 Perl 模块文件中的 [perlpod(1)](http://man.he.net/man1/perlpod) 风格文档里查找文本区块。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

你可以将上面的命令与调用 **deepl** 命令的 **-Mtee** 模块组合执行，通过 DeepL 服务翻译它们，如下所示：

    greple -Mtee deepl text --to JA - -- --fillup ...

不过，专用模块 [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) 在此目的上更有效。实际上，**tee** 模块的实现提示来自 **xlate** 模块。

# EXAMPLE 2

下面的命令将在 LICENSE 文档中找到一些缩进部分。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

你可以用带有 **ansifold** 命令的 **tee** 模块来重新格式化这些部分。两个 **--crmode** 选项一起使用可以高效处理多行区块：

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

**--discrete** 选项也可以使用，但会启动多个进程，因此执行时间更长。

# EXAMPLE 3

考虑一种情况：你想从表头以外的行中 grep 字符串。例如，你可能想在 `docker image ls` 命令的输出中搜索 Docker 镜像名称，但保留表头行。可以用下面的命令实现。

    greple -Mtee grep perl -- -ML 2: --discrete --all

选项 `-ML 2:` 取出从第二行到末尾的内容，并将其发送到 `grep perl` 命令。由于行数发生变化，需要使用 **--discrete** 选项，但因为命令只执行一次，所以没有性能上的劣势。

如果尝试用 **teip** 命令做同样的事情，`teip -l 2- -- grep` 会报错，因为输出行数少于输入行数，尽管输出结果本身是正确的。

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
