# NAME

App::Greple::tee - ενότητα για την αντικατάσταση του κειμένου που ταιριάζει με το αποτέλεσμα της εξωτερικής εντολής

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Η ενότητα **-Mtee** του Greple στέλνει το τμήμα του κειμένου που ταιριάζει με την εντολή φίλτρου που έχει δοθεί και τα αντικαθιστά με το αποτέλεσμα της εντολής. Η ιδέα προέρχεται από την εντολή που ονομάζεται **teip**. Είναι σαν να παρακάμπτουμε μερικά δεδομένα στην εξωτερική εντολή φίλτρου.

Η εντολή φίλτρου ακολουθεί τη δήλωση της ενότητας (`-Mtee`) και τερματίζεται με δύο παύλες (`--`). Για παράδειγμα, η επόμενη εντολή καλεί την εντολή `tr` με ορίσματα `a-z A-Z` για την αντιστοιχισμένη λέξη στα δεδομένα.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Η παραπάνω εντολή μετατρέπει όλες τις λέξεις που ταιριάζουν από πεζά σε κεφαλαία. Στην πραγματικότητα αυτό το ίδιο το παράδειγμα δεν είναι τόσο χρήσιμο επειδή η **greple** μπορεί να κάνει το ίδιο πράγμα πιο αποτελεσματικά με την επιλογή **--cm**.

Από προεπιλογή, η εντολή εκτελείται ως μία μόνο διεργασία και όλα τα δεδομένα που ταιριάζουν αποστέλλονται σε αυτήν αναμεμειγμένα. Αν το κείμενο που ταιριάζει δεν τελειώνει με νέα γραμμή, προστίθεται πριν και αφαιρείται μετά. Τα δεδομένα αντιστοιχίζονται γραμμή προς γραμμή, οπότε ο αριθμός των γραμμών των δεδομένων εισόδου και εξόδου πρέπει να είναι ίδιος.

Χρησιμοποιώντας την επιλογή **--discrete**, καλείται μεμονωμένη εντολή για κάθε αντιστοιχισμένο τμήμα. Μπορείτε να καταλάβετε τη διαφορά με τις ακόλουθες εντολές.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

Οι γραμμές των δεδομένων εισόδου και εξόδου δεν χρειάζεται να είναι πανομοιότυπες όταν χρησιμοποιείται η επιλογή **--discrete**.

# OPTIONS

- **--discrete**

    Κλήση νέας εντολής ξεχωριστά για κάθε αντιστοιχισμένο τμήμα.

# WHY DO NOT USE TEIP

Πρώτα απ' όλα, όποτε μπορείτε να το κάνετε με την εντολή **teip**, χρησιμοποιήστε την. Είναι ένα εξαιρετικό εργαλείο και πολύ πιο γρήγορο από την εντολή **greple**.

Επειδή η **greple** έχει σχεδιαστεί για να επεξεργάζεται αρχεία εγγράφων, έχει πολλά χαρακτηριστικά που είναι κατάλληλα για αυτήν, όπως τα στοιχεία ελέγχου της περιοχής αντιστοίχισης. Ίσως αξίζει να χρησιμοποιήσετε το **greple** για να επωφεληθείτε από αυτά τα χαρακτηριστικά.

Επίσης, το **teip** δεν μπορεί να χειριστεί πολλαπλές γραμμές δεδομένων ως ενιαία μονάδα, ενώ το **greple** μπορεί να εκτελέσει μεμονωμένες εντολές σε ένα κομμάτι δεδομένων που αποτελείται από πολλαπλές γραμμές.

# EXAMPLE

Η επόμενη εντολή θα βρει μπλοκ κειμένου μέσα σε έγγραφο στυλ [perlpod(1)](http://man.he.net/man1/perlpod) που περιλαμβάνεται στο αρχείο μονάδας Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Μπορείτε να τα μεταφράσετε με την υπηρεσία DeepL εκτελώντας την παραπάνω εντολή σε συνδυασμό με την ενότητα **-Mtee** η οποία καλεί την εντολή **deepl** ως εξής:

    greple -Mtee deepl text --to JA - -- --discrete ...

Επειδή η **deepl** λειτουργεί καλύτερα για εισαγωγή μίας γραμμής, μπορείτε να αλλάξετε το μέρος της εντολής ως εξής:

    sh -c 'perl -00pE "s/\s+/ /g" | deepl text --to JA -'

Η ειδική ενότητα [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl) είναι όμως πιο αποτελεσματική για το σκοπό αυτό. Στην πραγματικότητα, η υπόδειξη της υλοποίησης του module **tee** προήλθε από το module **xlate**.

# EXAMPLE 2

Η επόμενη εντολή θα βρει κάποιο εσοχές στο έγγραφο LICENSE.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Μπορείτε να αναδιαμορφώσετε αυτό το τμήμα χρησιμοποιώντας την ενότητα **tee** με την εντολή **ansifold**:

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

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
