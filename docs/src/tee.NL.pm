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

Standaard wordt de opdracht als een enkel proces uitgevoerd en worden alle gematchte gegevens door elkaar naar het proces gestuurd. Als de gematchte tekst niet eindigt met een newline, wordt deze toegevoegd voor het verzenden en verwijderd na het ontvangen. Invoer- en uitvoergegevens worden regel voor regel in kaart gebracht, dus het aantal regels invoer en uitvoer moet identiek zijn.

Met de optie B<--discrete> wordt voor elk gematcht tekstgebied een afzonderlijk commando aangeroepen. Je kunt het verschil zien aan de hand van de volgende opdrachten.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Bij gebruik van de optie B<--discreet> hoeven de regels invoer- en uitvoergegevens niet identiek te zijn.

=head1 VERSION

Version 0.9902

=head1 OPTIONS

=over 7

=item B<--discrete>

Roep nieuw commando individueel op voor elk onderdeel.

=item B<--fillup>

Combineer een reeks niet-blanke regels tot één regel voordat je ze doorgeeft aan de filteropdracht. Newline-tekens tussen tekens met een grote breedte worden verwijderd en andere newline-tekens worden vervangen door spaties.

=item B<--blocks>

Normaal gesproken wordt het gebied dat overeenkomt met het opgegeven zoekpatroon naar de externe opdracht gestuurd. Als deze optie is opgegeven, wordt niet het gebied dat overeenkomt, maar het hele blok dat het bevat, verwerkt.

Om bijvoorbeeld regels met het patroon C<foo> naar de externe opdracht te sturen, moet je het patroon opgeven dat overeenkomt met de hele regel:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Maar met de optie B<-blokken> kan het als volgt:

    greple -Mtee cat -n -- foo --blocks

Met de B<-blokken> optie gedraagt deze module zich meer als de B<-g> optie van L<teip(1)>. Anders is het gedrag gelijkaardig aan L<teip(1)> met de B<-o> optie.

Gebruik de B<-blokken> niet met de B<--all> optie, aangezien het blok dan de volledige gegevens zijn.

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

De --discrete optie zal meerdere processen starten, dus het proces zal langer duren om uit te voeren. Je kunt dus de optie C<--separate '\r'> gebruiken met C<ansifold>, die een enkele regel produceert met het karakter CR in plaats van NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Converteer vervolgens CR naar NL met L<tr(1)> of iets dergelijks.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Denk aan een situatie waarin je wilt grepen naar tekenreeksen buiten de kopregels. Bijvoorbeeld, je wilt zoeken naar Docker image namen van het C<docker image ls> commando, maar laat de header regel staan. Je kunt dit doen met het volgende commando.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

De optie C<-Mline -L 2:> haalt de voorlaatste regels op en stuurt ze naar het commando C<grep perl>. De optie --discrete is nodig omdat het aantal regels van invoer en uitvoer verandert, maar omdat het commando maar één keer wordt uitgevoerd, is er geen nadeel voor de prestaties.

Als je hetzelfde probeert te doen met het B<teip> commando, zal C<teip -l 2- -- grep> een foutmelding geven omdat het aantal uitvoerregels minder is dan het aantal invoerregels. Er is echter geen probleem met het verkregen resultaat.

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

De optie C<--fillup> verwijdert spaties tussen Hangul-tekens bij het aaneenschakelen van Koreaanse tekst.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
