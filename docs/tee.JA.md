# NAME

App::Greple::tee - マッチしたテキストを外部コマンドの結果に置き換えるモジュール

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Greple の **-Mtee** モジュールは、マッチしたテキスト部分を指定されたフィルタコマンドに送り、その結果で置き換えます。このアイデアは、**teip**というコマンドから派生したものです。これは、外部のフィルタコマンドに部分的なデータをバイパスするようなものです。

フィルタコマンドは、`--`で終わるモジュールオプションの後に続く引数で指定します。例えば、次のコマンドは、データ中の一致した単語に対して、`a-z A-Z` の引数でコマンド`tr`を呼び出します。

    greple -Mtee tr a-z A-Z -- '\w+' ...

このコマンドは、マッチした単語をすべて小文字から大文字に変換します。**greple**は**--cm**オプションでより効果的に同じことを行うことができるので、この例はあまり意味がありません。

デフォルトでは、このコマンドは一つのプロセスとして実行され、マッチした データはすべて混ぜて送られます。マッチしたテキストが改行で終わっていない場合は、その前に追加され、後に削除されます。データは一行ずつマップされるので、入力データと出力データの行数は同じでなければなりません。

**--discrete**オプションを使用すると、マッチした部分ごとにコマンドが呼び出されます。以下のコマンドを実行すると、その違いに気づくことができます。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

**--discrete**オプションを使用する場合、入出力データの行数は同一である必要はありません。

# OPTIONS

- **--discrete**

    マッチした部品ごとに新しいコマンドを呼び出す。

# WHY DO NOT USE TEIP

まず第一に、**teip**コマンドでできることは、いつでもそれを使ってください。これは優れたツールで、**greple**よりずっと速いです。

**greple**は文書ファイルの処理を目的としているため、マッチエリアの制御など、それに適した機能を多く持っています。それらの機能を活用するために、**greple**を使う価値はあるかもしれません。

また、**teip**は複数行のデータを1つの単位として扱うことができませんが、**greple**は複数行からなるデータチャンクに対して個別のコマンドを実行することが可能です。

# EXAMPLE

次のコマンドは，Perlモジュールファイルに含まれる[perlpod(1)](http://man.he.net/man1/perlpod)スタイルドキュメント内のテキストブロックを検索します。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

このように**-Mtee**モジュールで**deepl**コマンドを呼び出して上記のコマンドを実行すると、DeepLサービスによって翻訳することができます。

    greple -Mtee deepl text --to JA - -- --discrete ...

**deepl**は一行入力に適しているので、コマンド部分をこのように変更することができます。

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

ただし、この場合は専用モジュール [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) の方が効果的です。実は、**tee**モジュールの実装のヒントは**xlate**モジュールからきています。

# EXAMPLE 2

次に、LICENSE文書にインデントされた部分があります。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

この部分は**tee**モジュールと**ansifold**コマンドで整形することができます。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.
    

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)を使用します。

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
