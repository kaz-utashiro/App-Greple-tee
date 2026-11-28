# NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果で置き換えるモジュール

# SYNOPSIS

    greple -Mtee command -- ...
    greple -Mtee -E PAT1 command1 -- -Mtee -E PAT2 command2 -- ...

# VERSION

Version 2.00\_01

# DESCRIPTION

Greple の **-Mtee** モジュールは、マッチしたテキスト部分を指定したフィルタコマンドに送り、そのコマンドの結果で置き換えます。アイデアは **teip** と呼ばれるコマンドに由来します。データの一部だけを外部フィルタコマンドに通すようなイメージです。

フィルタコマンドはモジュール宣言（`-Mtee`）に続けて記述し、二つのダッシュ（`--`）で終端します。例えば、次のコマンドはデータ中のマッチした単語に対して、コマンド `tr` を `a-z A-Z` の引数で呼び出します。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換します。実はこの例自体はあまり有用ではありません。というのも、**greple** 自身が **--cm** オプションで同様のことをより効率的に行えるからです。

デフォルトでは、コマンドは単一プロセスとして実行され、すべてのマッチしたデータはまとめてそのプロセスに送られます。マッチしたテキストが改行で終わっていなければ、送信前に改行が追加され、受信後に取り除かれます。入力と出力のデータは行単位で対応付けられるため、入力と出力の行数は一致していなければなりません。

**--discrete** オプションを使うと、マッチした各テキスト領域ごとに個別のコマンドが呼び出されます。違いは次のコマンド群で確認できます。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete** オプションを用いる場合、入力と出力の行数は一致している必要はありません。

# OPTIONS

- **--discrete**

    マッチした各部分ごとに新しいコマンドを個別に起動します。

- **--bulkmode**

    **--discrete** オプションでは、各マッチに対するコマンドはマッチが出力されるときに実行されます。**--bulkmode** オプションでは、出力前にすべてを一括で実行します。

    このオプションは、["MULTIPLE FILTERS"](#multiple-filters) の新形式では効果がありません。新形式ではフィルターは常にすべてのマッチに対して一度に実行されます。

- **--crmode**

    このオプションは、各ブロックの途中にあるすべての改行文字をキャリッジリターンに置き換えます。コマンド実行結果に含まれるキャリッジリターンは改行文字に戻されます。これにより、**--discrete** オプションを使わずとも、複数行から成るブロックをバッチ処理できます。

    これは [ansifold](https://metacpan.org/pod/ansifold) コマンドの **--crmode** オプションと相性がよく、CR 区切りのテキストを結合し、CR で区切られた折り畳み行を出力します。

- **--fillup**

    フィルタコマンドに渡す前に、連続する非空行を1行にまとめます。全角文字（日本語、中国語）の間の改行は削除し、その他の改行は空白に置き換えます。韓国語（ハングル）は ASCII テキスト同様に空白で連結します。

- **--squeeze**

    連続する2つ以上の改行を1つにまとめます。

- **--nofork**

    `&function` で指定した関数を、フォークせずに **greple** プロセス自身で実行します。これがデフォルトです。フォークした子プロセスで実行するには **--no-nofork** を使用します。このオプションは外部コマンドには影響しません。["FUNCTION CALL"](#function-call) を参照してください。

- **-ML** **--offload** _command_

    [teip(1)](http://man.he.net/man1/teip) の **--offload** オプションに相当する機能は、別モジュール [App::Greple::L](https://metacpan.org/pod/App%3A%3AGreple%3A%3AL)（**-ML**）で提供されています。

        greple -Mtee cat -n -- -ML --offload 'seq 10 20'

    **-ML** モジュールを使って、次のように偶数行のみを処理することもできます。

        greple -Mtee cat -n -- -ML 2::2

# MULTIPLE FILTERS

**-Mtee** は複数回指定でき、それぞれに独自のパターンとフィルタを指定できます。各フィルタは、それとともに指定されたパターンに適用されます。

    -Mtee [ OPTIONS ] [ COMMAND [ ARGS ... ] ] --

最初の非オプション引数より前はすべてモジュールのオプションであり、残りの `--` までがコマンドです。たとえば次のコマンドは、`PAT1` または `PAT2` に一致する行を **ansifold** で折り返し、`PAT3` に一致する各部分を **ansicolumn** で個別の表として整形します。

    greple -Mtee --crmode -E PAT1 -E PAT2 '&ansifold' --crmode -w80 -- \
           -Mtee --discrete -E PAT3 '&ansicolumn' -t -- \
           file

`--` 自体を受け取るコマンドを指定するには、**-Mtee** の引数を3つ以上のダッシュからなる語で開始し、`--` の代わりに同じ語で終了します。

    greple -Mtee --- nup --ac -w 100 -- --- PATTERN file

これには [Getopt::EX::Config](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AConfig) 1.03以降が必要です。

形式は2つあります。

- **Legacy form**

    **-Mtee** 内にパターンがない場合、従来どおり `--` に続くすべてのパターンにコマンドが適用されます。複数回指定した場合は、最後のものが有効です。

- **New form**

    **-Mtee** 内にパターンがある場合、コマンドはその **-Mtee** 内のパターンにのみ適用されます。

2つの形式を混在させるとエラーになります。`-Mtee::config(...) -Mtee ...` の前半のように、`--` より前に何もない **-Mtee** は設定のみを行い、どちらの形式にも数えられません。

エラーは、出力が行われる前の最初のファイルの検索時に検出されます。

## Options inside -Mtee

- **--discrete**, **--bulkmode**, **--crmode**, **--fillup**, **--squeeze**, **--nofork**

    フィルタのモードです。**--no-crmode** のように、**--no-** 形式で否定できます。

- **-E**, **--re**

    正規表現パターン。

- **-e**

    パターン。空白を含んでいても1つのパターンとして扱われます。

- **--fe**

    固定文字列パターン。

- **--le**

    単一のキーワード、または `&function`。空白で区切った複数のキーワードを指定するとエラーになります。

- **--cm**

    そのまま **greple** に渡されます。色はパターンに結び付けられるのではなく、指定された順にパターン番号へ循環的に割り当てられます（["LIMITATIONS"](#limitations) を参照）。

- **--config**

    **Getopt::EX::Config** が提供するオプションです。**すべて**のフィルタに共通する設定を変更します。

**--exclude** などのほかのオプションを指定するとエラーになります。`--` の後に記述してください。これらはすべてのフィルタに適用されます。

## Priority of modes

モードの値は、実行時に次の順序で決定されます。

1. **-Mtee** 内で指定したもの（**--crmode**、**--no-crmode**）。
2. `--` の後、または **-Mtee::config(...)** で指定したもの。

## Special cases

- 新形式では、いずれか1つのパターンを含むブロックが処理されるように（OR）、**--need=1** が自動的に追加されます。これを上書きするには `--` の後で **--need** を指定します。**--need=2** を指定すると AND に戻ります。旧形式は従来どおり（AND）動作します。各 **-Mtee** および **-Mtee** を含む各エイリアスオプションが再び **--need=1** を追加するため、**--need** はそのすべての後に置いてください。
- コマンドを省略した場合（`-Mtee -E PAT --`）、パターンはテキストを選択しますが、テキストは変更されません。
- 新形式では、**-Mtee** の外にあるパターンはエラーです。**-Mtee** の外にある **--callback** も同様です。
- 新形式では、`--` の後の最初の引数は、パターンとして意図されていても、パターンがすでにオプションで指定されているためパターンとして扱われません。**greple** はそれをファイル名として扱います。
- 異なるフィルタの一致箇所が重なった場合、**greple** はそれらを1つの領域に結合し、先に開始する一致のフィルタを適用します。

## LIMITATIONS

- コマンドラインで **-Mtee** 内に直接記述した `{DEFINE}` は展開されません。**option** 定義内では展開されます。
- **-M** は引数の先頭になければならないため、**-Mtee** モジュールの間にほかのオプションを記述することはできません。エイリアスオプションを使用して **-Mtee** モジュールとほかのオプションを組み合わせます。
- **--cm** はフィルタごとに独立していません。一部のパターンにだけ指定すると、他の **-Mtee** 内のものを含む他のパターンの色が、**greple** の循環割り当てによって変化します。色を指定する際は、すべてのパターンに **--cm** を指定してください。
- 別のモジュールが **-Mtee** に続く場合（`-Mtee -E PAT cmd -- -Mcolors`）、パターンはモジュールの **default** オプションを介して **greple** に渡され、`$ENV{NAME}` や `__PACKAGE__` などのオプション定義の展開がそれらに適用されます。これらをエスケープする処理は行われません。
- **default** オプションに新形式の **-Mtee** を含むモジュールが、`-Mfoo -Mtee -E PAT cmd -- -Mcolors` のように、別のモジュールが続く **-Mtee** より前に読み込まれると、パターンが失われ、エラー（「passed twice or lost」）として検出されます。モジュールは **-Mtee** の後に読み込んでください。

# CONFIGURATION

モジュールのパラメータは、次の文法で **Getopt::EX::Config** モジュールにより設定できます。

    greple -Mtee::config(discrete) ...
    greple -Mtee::config(fillup,crmode) ...

これはシェルのエイリアスやモジュールファイルと組み合わせると便利です。

利用可能なパラメータは次のとおりです: **discrete**、**bulkmode**、**crmode**、**fillup**、**squeeze**、**nofork**。

# FUNCTION CALL

外部コマンドの代わりに、コマンド名の前に`&`を付けることでPerl関数を呼び出せます。

    greple -Mtee '&App::ansifold::ansifold' -w40 -- ...

関数は次の要件に従う必要があります:

- 一致したテキストを**STDIN**から読み込む
- 変換結果を**STDOUT**へ出力する
- 引数は`@ARGV`および`@_`の両方で渡される

デフォルトでは、関数はフォークせずに**greple**プロセス自体で実行されます。したがって、関数によって変更されたグローバル変数の値は次回の呼び出しにも残り、関数内で**exit**を呼び出すと**greple**が終了します。**--no-nofork**オプションを指定すると、関数はフォークされた子プロセスで実行されます。

任意の完全修飾関数名を使用できます:

    greple -Mtee '&Your::Module::function' -- ...

モジュールは未ロードの場合、自動的にロードされます。

便宜のため、以下の短いエイリアスが利用可能です:

- **&ansicolumn**

    `App::ansicolumn::ansicolumn`を呼び出します。

- **&ansifold**

    `App::ansifold::ansifold`を呼び出します。

- **&cat-v**

    `App::cat::v->new->run(@_)`を呼び出します。

関数呼び出しを使用すると、呼び出しごとに外部プロセスを起動するオーバーヘッドを回避でき、**--discrete**オプションと併用した場合にパフォーマンスを大幅に向上させることができます。

# LEGACIES

**--blocks** オプションは削除されました。**greple** に **--stretch**（**-S**）オプションが実装されたため、もはや不要です。代わりに次を使用してください。

    greple -Mtee cat -n -- --all -SE foo

# WHY NOT USE TEIP

まず何より、**teip** コマンドで実現できる場合はそれを使ってください。優れたツールであり、**greple** よりもはるかに高速です。

**greple** は文書ファイルの処理を目的に設計されているため、マッチ領域の制御など、それに適した多くの機能を備えています。それらの機能を活用するために **greple** を使う価値はあります。

また、**teip** は複数行のデータをひとつの単位として扱えませんが、**greple** は複数行からなるデータチャンクに対して個別のコマンドを実行できます。

# EXAMPLE

次のコマンドは、Perl モジュールファイル内の [perlpod(1)](http://man.he.net/man1/perlpod) 形式ドキュメントのテキストブロックを見つけます。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^([\w\pP].+\n)+' tee.pm

上記コマンドに **deepl** コマンドを呼び出す **-Mtee** モジュールを組み合わせることで、DeepL サービスで翻訳できます。使い方は次のとおりです:

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この目的には専用モジュール [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) のほうが効果的です。実際、**tee** モジュールの実装のヒントは **xlate** モジュールから得られました。

# EXAMPLE 2

次のコマンドは、LICENSE ドキュメント内のいくつかのインデントされた部分を見つけます。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

これらの部分は、**tee** モジュールと **ansifold** コマンドを使って再整形できます。両方の **--crmode** オプションを併用すると、複数行ブロックを効率よく処理できます:

    greple -Mtee ansifold -sw40 --prefix '     ' --crmode -- --crmode --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

**--discrete** オプションも使用できますが、複数のプロセスを起動するため、実行に時間がかかります。

# EXAMPLE 3

ヘッダー行以外の行から文字列を grep したい状況を考えてみます。例えば、`docker image ls` コマンドの出力から Docker イメージ名を検索したいが、ヘッダー行は残したい場合です。以下のコマンドで実現できます。

    greple -Mtee grep perl -- -ML 2: --discrete --all

オプション `-ML 2:` は、2行目から最後までを取り出して `grep perl` コマンドに送ります。行数が変わるため **--discrete** オプションが必要ですが、コマンドは一度しか実行されないので性能上のデメリットはありません。

同じことを **teip** コマンドでやろうとすると、`teip -l 2- -- grep` は出力行数が入力行数より少ないためエラーになります。ただし、得られる結果自体に問題はありません。

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
