=encoding utf-8

=head1 NAME

App::Greple::tee - module om gematchte tekst te vervangen door het externe opdrachtresultaat

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Greple's B<-Mtee> module stuurt gematchte tekstdelen naar het gegeven filtercommando, en vervangt ze door het resultaat van het commando. Het idee is afgeleid van het commando B<teip>. Het is als het omzeilen van gedeeltelijke gegevens naar het externe filtercommando.

Het filtercommando volgt op de moduleverklaring (C<-Mtee>) en eindigt met twee streepjes (C<-->). Bijvoorbeeld, het volgende commando roept commando C<tr> op met C<a-z A-Z> argumenten voor het gezochte woord in de gegevens.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Bovenstaand commando zet alle overeenkomende woorden om van kleine letters naar hoofdletters. Eigenlijk is dit voorbeeld zelf niet zo nuttig omdat B<greple> hetzelfde effectiever kan doen met de optie B<--cm>.

Standaard wordt het commando uitgevoerd als een enkel proces, en alle gematchte gegevens worden erdoor gemengd. Als de gematchte tekst niet eindigt met een newline, wordt hij ervoor toegevoegd en erna verwijderd. De gegevens worden regel voor regel in kaart gebracht, dus het aantal regels invoer- en uitvoergegevens moet identiek zijn.

Met de optie B<--discreet> wordt voor elk gematcht onderdeel een afzonderlijk commando opgeroepen. U kunt het verschil zien aan de hand van de volgende commando's.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Bij gebruik van de optie B<--discreet> hoeven de regels invoer- en uitvoergegevens niet identiek te zijn.

=head1 VERSION

Version 0.9901

=head1 OPTIONS

=over 7

=item B<--discrete>

Roep nieuw commando individueel op voor elk onderdeel.

=item B<--fillup>

Combineer een reeks niet lege regels tot één regel voordat je ze doorgeeft aan de filteropdracht. Newline-tekens tussen brede tekens worden verwijderd en andere newline-tekens worden vervangen door spaties.

=item B<--blockmatch>

Normaal gesproken wordt het gebied dat overeenkomt met het opgegeven zoekpatroon naar de externe opdracht gestuurd. Als deze optie is opgegeven, wordt niet het gebied dat overeenkomt, maar het hele blok dat het bevat, verwerkt.

Om bijvoorbeeld regels met het patroon C<foo> naar de externe opdracht te sturen, moet je het patroon opgeven dat overeenkomt met de hele regel:

    greple -Mtee cat -n -- '^.*foo.*\n'

Maar met de optie B<--blockmatch> kan het als volgt eenvoudig:

    greple -Mtee cat -n -- foo

Met de B<--blockmatch> optie gedraagt deze module zich meer als de B<-g> optie van L<teip(1)>.

=item B<--squeeze>

Combineert twee of meer opeenvolgende newline-tekens tot één.

=back

=head1 WHY DO NOT USE TEIP

Allereerst, wanneer u het kunt doen met het commando B<-teip>, gebruik het. Het is een uitstekend hulpmiddel en veel sneller dan B<greple>.

Omdat B<greple> is ontworpen om documentbestanden te verwerken, heeft het veel functies die daarvoor geschikt zijn, zoals controles van het matchgebied. Het kan de moeite waard zijn om B<greple> te gebruiken om van die functies te profiteren.

Ook kan B<teip> niet omgaan met meerdere regels gegevens als een enkele eenheid, terwijl B<greple> individuele opdrachten kan uitvoeren op een gegevensbrok die uit meerdere regels bestaat.

=head1 EXAMPLE

Het volgende commando vindt tekstblokken in L<perlpod(1)> stijldocument opgenomen in het Perl-modulebestand.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

U kunt ze vertalen door DeepL service door het bovenstaande commando uit te voeren in combinatie met B<-Mtee> module die het commando B<deepl> als volgt oproept:

    greple -Mtee deepl text --to JA - -- --fillup ...

De speciale module L<App::Greple::xlate::deepl> is echter effectiever voor dit doel. In feite kwam de implementatiehint van de module B<tee> van de module B<xlate>.

=head1 EXAMPLE 2

Het volgende commando vindt een ingesprongen deel in het LICENSE document.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
U kunt dit deel opnieuw formatteren door de module B<tee> te gebruiken met het commando B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Het gebruik van de optie C<--discrete> is tijdrovend. Dus je kunt de optie C<--separate '\r'> gebruiken met C<ansifold> die een enkele regel produceert met CR-karakters in plaats van NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Converteer vervolgens CR naar NL met L<tr(1)> of iets dergelijks.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Overweeg een situatie waarin je wilt grepen naar tekenreeksen buiten de koptekstregels. Bijvoorbeeld, je wilt zoeken naar afbeeldingen van het C<docker image ls> commando, maar laat de header regel staan. Je kunt dit doen met het volgende commando.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Optie C<-Mline -L 2:> haalt de voorlaatste regels op en stuurt ze naar het commando C<grep perl>. Optie C<--discrete> is vereist, maar deze wordt maar één keer aangeroepen, dus er is geen prestatieverlies.

In dit geval geeft C<teip -l 2- -- grep> een foutmelding omdat het aantal regels in de uitvoer minder is dan de invoer. Het resultaat is echter heel bevredigend :)

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

De optie C<-fillup> werkt mogelijk niet correct voor Koreaanse tekst.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package App::Greple::tee;

our $VERSION = "0.9901";

use v5.14;
use warnings;
use Carp;
use List::Util qw(sum first);
use Text::ParseWords qw(shellwords);
use App::cdif::Command;
use Data::Dumper;

our $command;
our $blockmatch;
our $discrete;
our $fillup;
our $debug;
our $squeeze;

my($mod, $argv);

sub initialize {
    ($mod, $argv) = @_;
    if (defined (my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	if (my @command = splice @$argv, 0, $i) {
	    $command = \@command;
	}
	shift @$argv eq '--' or die;
    }
}

use Unicode::EastAsianWidth;

sub fillup_block {
    (my $s1, local $_, my $s2) = $_[0] =~ /\A(\s*)(.*?)(\s*)\z/s or die;
    s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//g;
    s/\s+/ /g;
    $s1 . $_ . $s2;
}

sub fillup_paragraphs {
    local *_ = @_ > 0 ? \$_[0] : \$_;
    s{^.+(?:\n.+)*}{ fillup_block ${^MATCH} }pmge;
}

sub call {
    my $data = shift;
    $command // return $data;
    state $exec = App::cdif::Command->new;
    if ($discrete and $fillup) {
	fillup_paragraphs $data;
    }
    if (ref $command ne 'ARRAY') {
	$command = [ shellwords $command ];
    }
    my $out = $exec->command($command)->setstdin($data)->update->data // '';
    if ($squeeze) {
	$out =~ s/\n\n+/\n/g;
    }
    $out;
}

sub bundle_call {
    if ($fillup) {
	fillup_paragraphs for @_;
    }
    my @chop = grep { $_[$_] =~ s/(?<!\n)\z/\n/ } keys @_;
    my @lines = map { int tr/\n/\n/ } @_;
    my $lines = sum @lines;
    my $out = call join '', @_;
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

my @bundle;

sub postgrep {
    my $grep = shift;
    if ($blockmatch) {
	$grep->{RESULT} = [
	    [ [ 0, length ],
	      map {
		  [ $_->[0][0], $_->[0][1], 0, $grep->{callback}->[0] ]
	      } $grep->result
	    ] ];
    }
    return if $discrete;
    @bundle = my @block = ();
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    push @block, $grep->cut(@$m);
	}
    }
    @bundle = bundle_call @block if @block;
}

sub callback {
    if ($discrete) {
	call { @_ }->{match};
    }
    else {
	shift @bundle // die;
    }
}

1;

__DATA__

builtin --blockmatch $blockmatch
builtin --discrete!  $discrete
builtin --fillup!    $fillup
builtin --debug      $debug
builtin --squeeze    $squeeze

option default \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback

option --tee-each --discrete

#  LocalWords:  greple tee teip DeepL deepl perl xlate
