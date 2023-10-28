use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;
use open IO => ':utf8';

use lib './t';
use Util;

use Text::ParseWords qw(shellwords);
use Getopt::Long 'Configure';
Configure qw(bundling no_getopt_compat no_ignore_case);
GetOptions(\my %opt,
           'data-section',	# produce data section
           'example',		# show command execution example
           'show',		# show test
           'number|n=i',	# select test number
) or die;

use File::Spec;
$ENV{HOME} = File::Spec->rel2abs('t/home');

use Data::Section::Simple qw(get_data_section);
my $expected = get_data_section;

use File::Slurper 'read_lines';
my $sh = $0 =~ s/\.t/.sh/r;
my @command = read_lines $sh or die;

if ($opt{show}) {
    for (keys @command) {
	printf "%4d: %s\n", $_, $command[$_];
    }
    exit;
}

if (defined(my $n = $opt{number})) {
    die "$n: invalid number\n" if $n > $#command;
    @command = $command[$n];
}

for (@command) {
    my @command = shellwords $_;
    shift @command if $command[0] eq 'greple';
    my $result = run(@command)->stdout;
    if ($opt{example}) {
	printf "\$ %s\n", $_;
	print $result;
    }
    elsif ($opt{'data-section'}) {
	printf "\@\@ %s\n", $_;
	print $result;
    }
    else {
	is($result, $expected->{$_}, $_);
    }
}

exit if %opt;

done_testing;

__DATA__

@@ greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
     1	The quick brown fox
     2	jumps over the lazy dog.
     3	1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

     4	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     5	Sylvia wagt quick den Jux bei Pforzheim.

     6	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     7	Le cœur déçu mais l'âme plutôt naïve,
     8	Louÿs rêva de crapaüter en canoë au delà des îles,
     9	près du mälströn où brûlent les novæ.

    10	El veloz murciélago hindú comía feliz cardillo y kiwi.
    11	La cigüeña tocaba el saxofón detrás del palenque de paja.
@@ greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
     1	The quick brown fox
     2	jumps over the lazy dog.
     3	1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

     1	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     1	Sylvia wagt quick den Jux bei Pforzheim.

     1	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     1	Le cœur déçu mais l'âme plutôt naïve,
     2	Louÿs rêva de crapaüter en canoë au delà des îles,
     3	près du mälströn où brûlent les novæ.

     1	El veloz murciélago hindú comía feliz cardillo y kiwi.
     2	La cigüeña tocaba el saxofón detrás del palenque de paja.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '\S+' t/SAMPLE.txt --all
THE QUICK BROWN FOX
JUMPS OVER THE LAZY DOG.
1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE,
LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES,
PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI.
LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
THE QUICK BROWN FOX
JUMPS OVER THE LAZY DOG.
1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE,
LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES,
PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI.
LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
THE QUICK BROWN FOX
JUMPS OVER THE LAZY DOG.
1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE,
LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES,
PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI.
LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. 1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE, LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES, PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI. LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee perl -CSAD -pE '$_=uc' -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup --discrete
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. 1234567890

いろはにほへとちりぬるを
わかよたれそつねならむ
うゐのおくやまけふこえて
あさきゆめみしゑひもせすん

色は匂へど散りぬるを
我が世誰そ常ならむ
有為の奥山今日越えて
浅き夢見じ酔ひもせず.

MA LA VOLPE COL SUO BALZO HA RAGGIUNTO IL QUIETO FIDO.

SYLVIA WAGT QUICK DEN JUX BEI PFORZHEIM.

VICTOR JAGT ZWÖLF BOXKÄMPFER QUER ÜBER DEN GROSSEN SYLTER DEICH.

LE CŒUR DÉÇU MAIS L'ÂME PLUTÔT NAÏVE, LOUŸS RÊVA DE CRAPAÜTER EN CANOË AU DELÀ DES ÎLES, PRÈS DU MÄLSTRÖN OÙ BRÛLENT LES NOVÆ.

EL VELOZ MURCIÉLAGO HINDÚ COMÍA FELIZ CARDILLO Y KIWI. LA CIGÜEÑA TOCABA EL SAXOFÓN DETRÁS DEL PALENQUE DE PAJA.
@@ greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup
     1	The quick brown fox jumps over the lazy dog. 1234567890

     2	いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせすん

     3	色は匂へど散りぬるを我が世誰そ常ならむ有為の奥山今日越えて浅き夢見じ酔ひもせず.

     4	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     5	Sylvia wagt quick den Jux bei Pforzheim.

     6	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     7	Le cœur déçu mais l'âme plutôt naïve, Louÿs rêva de crapaüter en canoë au delà des îles, près du mälströn où brûlent les novæ.

     8	El veloz murciélago hindú comía feliz cardillo y kiwi. La cigüeña tocaba el saxofón detrás del palenque de paja.
@@ greple -Mtee cat -n -- '^(.+\n)+' t/SAMPLE.txt --all --fillup --discrete
     1	The quick brown fox jumps over the lazy dog. 1234567890

     1	いろはにほへとちりぬるをわかよたれそつねならむうゐのおくやまけふこえてあさきゆめみしゑひもせすん

     1	色は匂へど散りぬるを我が世誰そ常ならむ有為の奥山今日越えて浅き夢見じ酔ひもせず.

     1	Ma la volpe col suo balzo ha raggiunto il quieto Fido.

     1	Sylvia wagt quick den Jux bei Pforzheim.

     1	Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.

     1	Le cœur déçu mais l'âme plutôt naïve, Louÿs rêva de crapaüter en canoë au delà des îles, près du mälströn où brûlent les novæ.

     1	El veloz murciélago hindú comía feliz cardillo y kiwi. La cigüeña tocaba el saxofón detrás del palenque de paja.
