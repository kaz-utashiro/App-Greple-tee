=encoding utf-8

=head1 NAME

App::Greple::tee - ενότητα για την αντικατάσταση του κειμένου που ταιριάζει με το αποτέλεσμα της εξωτερικής εντολής

=head1 SYNOPSIS

    greple -Mtee command -- ...

=head1 DESCRIPTION

Η ενότητα B<-Mtee> του Greple στέλνει το τμήμα του κειμένου που ταιριάζει με την εντολή φίλτρου που έχει δοθεί και τα αντικαθιστά με το αποτέλεσμα της εντολής. Η ιδέα προέρχεται από την εντολή που ονομάζεται B<teip>. Είναι σαν να παρακάμπτουμε μερικά δεδομένα στην εξωτερική εντολή φίλτρου.

Η εντολή φίλτρου ακολουθεί τη δήλωση της ενότητας (C<-Mtee>) και τερματίζεται με δύο παύλες (C<-->). Για παράδειγμα, η επόμενη εντολή καλεί την εντολή C<tr> με ορίσματα C<a-z A-Z> για την αντιστοιχισμένη λέξη στα δεδομένα.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Η παραπάνω εντολή μετατρέπει όλες τις λέξεις που ταιριάζουν από πεζά σε κεφαλαία. Στην πραγματικότητα αυτό το ίδιο το παράδειγμα δεν είναι τόσο χρήσιμο επειδή η B<greple> μπορεί να κάνει το ίδιο πράγμα πιο αποτελεσματικά με την επιλογή B<--cm>.

Από προεπιλογή, η εντολή εκτελείται ως μία μόνο διεργασία και όλα τα δεδομένα που ταιριάζουν αποστέλλονται σε αυτήν αναμεμειγμένα. Αν το κείμενο που ταιριάζει δεν τελειώνει με νέα γραμμή, προστίθεται πριν και αφαιρείται μετά. Τα δεδομένα αντιστοιχίζονται γραμμή προς γραμμή, οπότε ο αριθμός των γραμμών των δεδομένων εισόδου και εξόδου πρέπει να είναι ίδιος.

Χρησιμοποιώντας την επιλογή B<--discrete>, καλείται μεμονωμένη εντολή για κάθε αντιστοιχισμένο τμήμα. Μπορείτε να καταλάβετε τη διαφορά με τις ακόλουθες εντολές.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Οι γραμμές των δεδομένων εισόδου και εξόδου δεν χρειάζεται να είναι πανομοιότυπες όταν χρησιμοποιείται η επιλογή B<--discrete>.

=head1 VERSION

Version 0.9901

=head1 OPTIONS

=over 7

=item B<--discrete>

Κλήση νέας εντολής ξεχωριστά για κάθε αντιστοιχισμένο τμήμα.

=item B<--fillup>

Συνδυάζει μια ακολουθία μη κενών γραμμών σε μια ενιαία γραμμή προτού τις περάσει στην εντολή filter. Οι χαρακτήρες νέας γραμμής μεταξύ ευρέων χαρακτήρων διαγράφονται και οι υπόλοιποι χαρακτήρες νέας γραμμής αντικαθίστανται με κενά.

=item B<--blocks>

Κανονικά, η περιοχή που ταιριάζει με το καθορισμένο μοτίβο αναζήτησης αποστέλλεται στην εξωτερική εντολή. Εάν καθοριστεί αυτή η επιλογή, δεν θα υποβληθεί σε επεξεργασία η περιοχή που ταιριάζει, αλλά ολόκληρο το μπλοκ που την περιέχει.

Για παράδειγμα, για να στείλετε γραμμές που περιέχουν το μοτίβο C<foo> στην εξωτερική εντολή, πρέπει να καθορίσετε το μοτίβο που ταιριάζει σε ολόκληρη τη γραμμή:

    greple -Mtee cat -n -- '^.*foo.*\n' --all

Αλλά με την επιλογή B<--blocks>, μπορεί να γίνει απλά ως εξής:

    greple -Mtee cat -n -- foo --blocks

Με την επιλογή B<--blocks>, αυτή η ενότητα συμπεριφέρεται περισσότερο σαν την επιλογή B<-g> του L<teip(1)>. Διαφορετικά, η συμπεριφορά του είναι παρόμοια με αυτή του L<teip(1)> με την επιλογή B<-o>.

Μην χρησιμοποιείτε το B<--blocks> με την επιλογή B<--all>, καθώς το μπλοκ θα είναι το σύνολο των δεδομένων.

=item B<--squeeze>

Συνδυάζει δύο ή περισσότερους διαδοχικούς χαρακτήρες νέας γραμμής σε έναν.

=back

=head1 WHY DO NOT USE TEIP

Πρώτα απ' όλα, όποτε μπορείτε να το κάνετε με την εντολή B<teip>, χρησιμοποιήστε την. Είναι ένα εξαιρετικό εργαλείο και πολύ πιο γρήγορο από την εντολή B<greple>.

Επειδή η B<greple> έχει σχεδιαστεί για να επεξεργάζεται αρχεία εγγράφων, έχει πολλά χαρακτηριστικά που είναι κατάλληλα για αυτήν, όπως τα στοιχεία ελέγχου της περιοχής αντιστοίχισης. Ίσως αξίζει να χρησιμοποιήσετε το B<greple> για να επωφεληθείτε από αυτά τα χαρακτηριστικά.

Επίσης, το B<teip> δεν μπορεί να χειριστεί πολλαπλές γραμμές δεδομένων ως ενιαία μονάδα, ενώ το B<greple> μπορεί να εκτελέσει μεμονωμένες εντολές σε ένα κομμάτι δεδομένων που αποτελείται από πολλαπλές γραμμές.

=head1 EXAMPLE

Η επόμενη εντολή θα βρει μπλοκ κειμένου μέσα σε έγγραφο στυλ L<perlpod(1)> που περιλαμβάνεται στο αρχείο μονάδας Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Μπορείτε να τα μεταφράσετε με την υπηρεσία DeepL εκτελώντας την παραπάνω εντολή σε συνδυασμό με την ενότητα B<-Mtee> η οποία καλεί την εντολή B<deepl> ως εξής:

    greple -Mtee deepl text --to JA - -- --fillup ...

Η ειδική ενότητα L<App::Greple::xlate::deepl> είναι όμως πιο αποτελεσματική για το σκοπό αυτό. Στην πραγματικότητα, η υπόδειξη της υλοποίησης του module B<tee> προήλθε από το module B<xlate>.

=head1 EXAMPLE 2

Η επόμενη εντολή θα βρει κάποιο εσοχές στο έγγραφο LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    
Μπορείτε να αναδιαμορφώσετε αυτό το τμήμα χρησιμοποιώντας την ενότητα B<tee> με την εντολή B<ansifold>:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Η χρήση της επιλογής C<--discrete> είναι χρονοβόρα. Έτσι, μπορείτε να χρησιμοποιήσετε την επιλογή C<--διαχωρισμένη '\r'> με την επιλογή C<ansifold> η οποία παράγει μία μόνο γραμμή χρησιμοποιώντας τον χαρακτήρα CR αντί για NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Στη συνέχεια, μετατρέψτε τον χαρακτήρα CR σε NL με την εντολή L<tr(1)> ή κάποια άλλη.

    ... | tr '\r' '\n'

=head1 EXAMPLE 3

Σκεφτείτε μια κατάσταση στην οποία θέλετε να αναζητήσετε με grep συμβολοσειρές από γραμμές που δεν έχουν κεφαλίδα. Για παράδειγμα, μπορεί να θέλετε να αναζητήσετε εικόνες από την εντολή C<docker image ls>, αλλά να αφήσετε τη γραμμή επικεφαλίδας. Μπορείτε να το κάνετε με την ακόλουθη εντολή.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Η επιλογή C<-Mline -L 2:> ανακτά τις προτελευταίες γραμμές και τις στέλνει στην εντολή C<grep perl>. Η επιλογή C<--discrete> είναι απαραίτητη, αλλά αυτή καλείται μόνο μία φορά, οπότε δεν υπάρχει μειονέκτημα στην απόδοση.

Σε αυτή την περίπτωση, η C<teip -l 2- -- grep> παράγει σφάλμα επειδή ο αριθμός των γραμμών στην έξοδο είναι μικρότερος από τον αριθμό των γραμμών εισόδου. Ωστόσο, το αποτέλεσμα είναι αρκετά ικανοποιητικό :)

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

Η επιλογή C<--fillup> μπορεί να μην λειτουργεί σωστά για κορεατικό κείμενο.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
