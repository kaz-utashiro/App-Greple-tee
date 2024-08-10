=encoding utf-8

=head1 NAME

App::Greple::teeは、マッチしたテキストを外部コマンドの結果に置き換えるモジュールです。

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 VERSION

Version 0.9903

=head1 DESCRIPTION

Greple の B<-Mtee> モジュールは、マッチしたテキスト部分を指定されたフィルタコマンドに送り、その結果で置き換えます。このアイデアは、B<teip>というコマンドから派生したものです。これは、外部のフィルタコマンドに部分的なデータをバイパスするようなものです。

Filterコマンドはモジュール宣言(Mtee)に続き、2つのダッシュ(--)で終了します。例えば、次のコマンドは、データ中の一致した単語に対して、a-z A-Z の引数を持つコマンド tr コマンドを呼び出します。

    greple -Mtee tr a-z A-Z -- '\w+' ...

上記のコマンドは、マッチした単語をすべて小文字から大文字に変換します。B<greple>はB<--cm>オプションでより効果的に同じことができるので、実はこの例自体はあまり意味がありません。

デフォルトでは、コマンドは1つのプロセスとして実行され、マッチしたデータはすべて混在してプロセスに送られます。マッチしたテキストが改行で終わっていない場合は、送信前に追加され、受信後に削除されます。入力データと出力データは行ごとにマップされるので、入力と出力の行数は同じでなければなりません。

B<--discrete>オプションを使うと、マッチしたテキスト・エリアごとにコマンドが呼び出されます。この違いは以下のコマンドでわかります。

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

B<--discrete>オプションを使用する場合、入出力データの行数は同一である必要はありません。

=head1 OPTIONS

=over 7

=item B<--discrete>

一致した部品に対して、個別に新しいコマンドを起動します。

=item B<--bulkmode>

<--discrete>オプションをつけると、各コマンドはオンデマンドで実行される。このオプションは
<--bulkmode> option causes all conversions to be performed at once.

=item B<--crmode>

このオプションは、各ブロックの途中にある改行文字をすべてキャリッジリターン文字に置き換えます。コマンドの実行結果に含まれるキャリッジリターンは改行文字に戻されます。このように、複数行からなるブロックは、B<--discrete>オプションを使わずに一括して処理できます。

=item B<--fillup>

一連の空白でない行を1行にまとめてからフィルターコマンドに渡します。幅の広い文字の間の改行文字は削除され、その他の改行文字はスペースに置き換えられます。

=item B<--blocks>

通常、指定された検索パターンにマッチする領域が外部コマンドに送られます。このオプションが指定されると、マッチした領域ではなく、それを含むブロック全体が処理されます。

例えば、パターンC<foo>を含む行を外部コマンドに送るには、行全体にマッチするパターンを指定する必要があります。

    greple -Mtee cat -n -- '^.*foo.*\n' --all

しかし、B<--blocks> オプションを使えば、次のように簡単にできます。

    greple -Mtee cat -n -- foo --blocks

B<--blocks> オプションをつけると、このモジュールは L<teip(1)> の B<-g> オプションに似た挙動をします。B<--blocks> オプションを使うと、このモジュールはより L<teip(1)> の B<-g> オプションに近い動作をします。

B<--blocks> を B<--all> オプションと一緒に使用しないでください。

=item B<--squeeze>

語尾がない文については付け加えずにそのままにする。

=back

=head1 WHY DO NOT USE TEIP

まず第一に、B<teip>コマンドでできることは、いつでもそれを使ってください。これは優れたツールで、B<greple>よりずっと速いです。

B<greple>は文書ファイルの処理を目的としているため、マッチエリアの制御など、それに適した機能を多く持っています。それらの機能を活用するために、B<greple>を使う価値があるかもしれません。

また、B<teip>は複数行のデータを1つの単位として扱うことができませんが、B<greple>は複数行からなるデータチャンクに対して個別のコマンドを実行することが可能です。

=head1 EXAMPLE

次のコマンドは，Perlモジュールファイルに含まれるL<perlpod(1)>スタイルドキュメント内のテキストブロックを検索します。

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

このようにB<Mtee>モジュールと組み合わせてB<deepl>コマンドを呼び出すと、DeepLサービスによって翻訳できます。

    greple -Mtee deepl text --to JA - -- --fillup ...

ただし、この場合は専用モジュール L<App::Greple::xlate::deepl> の方が効果的です。実は、B<tee>モジュールの実装のヒントはB<xlate>モジュールからきています。

=head1 EXAMPLE 2

次に、LICENSE文書にインデントされた部分があります。

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.

      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.

この部分はB<tee>モジュールとB<ansifold>コマンドで整形できます。

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.

      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

discreteオプションは複数のプロセスを起動するので、プロセスの実行に時間がかかります。そのため、C<--separate ' \r'>オプションとC<ansifold>を併用すると、NLの代わりにCR文字を使って1行にできます。

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

その後、L<tr(1)>コマンドなどでCRをNLに変換します。

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

ヘッダ行以外から文字列を grep したい場合を考えてみましょう。例えば、C<docker image ls>コマンドからDockerイメージ名を検索したいが、ヘッダ行は残したいとします。以下のコマンドで可能です。

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

オプションC<-Mline -L 2:>は2行目から最後の行を検索し、C<grep perl>コマンドに送ります。入出力の行数が変わるので-discreteオプションが必要ですが、コマンドは一度しか実行されないので性能上の欠点はありません。

B<teip>コマンドで同じことをしようとすると、C<teip -l 2- -- grep>は出力行数が入力行数より少ないのでエラーになりますが、得られる結果に問題はありません。

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::tee

=head1 SEE ALSO

L<App::Greple::tee>は、L<https://github.com/kaz-utashiro/App-Greple-tee>で提供されています。

L<https://github.com/greymd/teip>

L<App::Greple>, L<https://github.com/kaz-utashiro/greple> です。

L<https://github.com/tecolicom/Greple>

L<App::Greple::xlate> は、App::Greple::xlate です。

=head1 BUGS

C<--fillup> オプションは、韓国語テキストを連結する際に、ハングル文字間の空白を削除します。

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
