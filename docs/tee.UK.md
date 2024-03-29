# NAME

App::Greple::tee - модуль для заміни знайденого тексту на результат зовнішньої команди

# SYNOPSIS

    greple -Mtee command -- ...

# DESCRIPTION

Модуль **-Mtee** у Greple надсилає частину тексту, що відповідає заданій команді фільтрації, і замінює її на результат команди. Ідея походить від команди з назвою **teip**. Це схоже на пересилання частини даних до зовнішньої команди фільтрації.

Команда фільтрації слідує за оголошенням модуля (`-Mtee`) і завершується двома тире (`--`). Наприклад, наступна команда викликає команду `tr` з аргументами `a-z A-Z` для знайденого слова у даних.

    greple -Mtee tr a-z A-Z -- '\w+' ...

Наведена вище команда перетворює всі знайдені слова з малих літер у великі. Насправді цей приклад не дуже корисний, оскільки **greple** може зробити те саме ефективніше за допомогою опції **--cm**.

За замовчуванням команда виконується як окремий процес, і всі знайдені дані надсилаються до процесу вперемішку. Якщо знайдений текст не закінчується новим рядком, він додається перед надсиланням і видаляється після отримання. Вхідні та вихідні дані зіставляються рядок за рядком, тому кількість рядків вхідних та вихідних даних має бути однаковою.

Використовуючи опцію **--discrete**, для кожної області тексту, що зіставляється, викликається окрема команда. Ви можете визначити різницю за допомогою наступних команд.

    greple -Mtee cat -n -- copyright LICENSE
    greple -Mtee cat -n -- copyright LICENSE --discrete

При використанні опції **--discrete** рядки вхідних і вихідних даних не обов'язково повинні бути однаковими.

# VERSION

Version 0.9902

# OPTIONS

- **--discrete**

    Викликати нову команду окремо для кожної знайденої частини.

- **--fillup**

    Об'єднайте послідовність непорожніх рядків в один рядок, перш ніж передавати їх команді фільтрації. Символи переведення рядка між символами великої ширини буде вилучено, а інші символи переведення рядка буде замінено на пробіли.

- **--blocks**

    Зазвичай зовнішній команді надсилається область, що відповідає заданому шаблону пошуку. Якщо вказати цю опцію, то буде оброблено не область, а весь блок, що її містить.

    Наприклад, щоб надіслати зовнішній команді рядки, що містять шаблон `foo`, потрібно вказати шаблон, який збігається з усім рядком:

        greple -Mtee cat -n -- '^.*foo.*\n' --all

    Але з опцією **--blocks** це можна зробити так само просто:

        greple -Mtee cat -n -- foo --blocks

    З опцією **--blocks** цей модуль поводитиметься більш подібно до [teip(1)](http://man.he.net/man1/teip) з опцією **-g**. В іншому випадку поведінка подібна до поведінки [teip(1)](http://man.he.net/man1/teip) з опцією **-o**.

    Не використовуйте **--blocks** з опцією **--all**, оскільки блоком будуть всі дані.

- **--squeeze**

    Об'єднує два або більше символів нового рядка, що йдуть підряд, в один.

# WHY DO NOT USE TEIP

Перш за все, якщо ви можете зробити це за допомогою команди **teip**, використовуйте її. Вона є чудовим інструментом і працює набагато швидше, ніж **greple**.

Оскільки **greple** призначено для обробки файлів документів, вона має багато можливостей, які підходять для неї, наприклад, елементи керування областями збігів. Можливо, варто скористатися перевагами **greple**, щоб скористатися цими можливостями.

Крім того, **teip** не може обробляти декілька рядків даних як єдине ціле, тоді як **greple** може виконувати окремі команди над фрагментом даних, що складається з декількох рядків.

# EXAMPLE

Наступна команда знайде текстові блоки у документі стилю [perlpod(1)](http://man.he.net/man1/perlpod), включеному до файлу модуля Perl.

    greple --inside '^=(?s:.*?)(^=cut|\z)' --re '^(\w.+\n)+' tee.pm

Ви можете перекласти їх за допомогою сервісу DeepL, виконавши наведену вище команду, узгоджену з модулем **-Mtee**, який викликає команду **deepl** таким чином:

    greple -Mtee deepl text --to JA - -- --fillup ...

Однак для цієї мети ефективніше використовувати спеціальний модуль [App::Greple::xlate::deepl](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate%3A%3Adeepl). Насправді, підказка щодо реалізації модуля **tee** прийшла з модуля **xlate**.

# EXAMPLE 2

Наступна команда знайде у документі LICENSE частину з відступами.

    greple --re '^[ ]{2}[a-z][)] .+\n([ ]{5}.+\n)*' -C LICENSE

      a) distribute a Standard Version of the executables and library files,
         together with instructions (in the manual page or equivalent) on where to
         get the Standard Version.
    
      b) accompany the distribution with the machine-readable source of the Package
         with your modifications.
    

Ви можете переформатувати цю частину за допомогою модуля **tee** з командою **ansifold**:

    greple -Mtee ansifold -rsw40 --prefix '     ' -- --discrete --re ...

      a) distribute a Standard Version of
         the executables and library files,
         together with instructions (in the
         manual page or equivalent) on where
         to get the Standard Version.
    
      b) accompany the distribution with the
         machine-readable source of the
         Package with your modifications.

Параметр --discrete запускає декілька процесів, тому процес виконуватиметься довше. Тому ви можете скористатися опцією `--separate '\r'` з `ansifold`, яка створить один рядок з використанням символу CR замість NL.

    greple -Mtee ansifold -rsw40 --prefix '     ' --separate '\r' --

Потім перетворіть CR символ на NL за допомогою команди [tr(1)](http://man.he.net/man1/tr) або іншої.

    ... | tr '\r' '\n'

# EXAMPLE 3

Розглянемо ситуацію, у якій вам потрібно шукати рядки з рядків, що не є заголовками. Наприклад, ви можете шукати назви образів Docker за допомогою команди `docker image ls`, але залишити заголовний рядок. Це можна зробити за допомогою наступної команди.

    greple -Mtee grep perl -- -Mline -L 2: --discrete --all

Параметр `-Mline -L 2:` витягує передостанні рядки і надсилає їх команді `grep perl`. Опція --discrete необхідна, оскільки змінюється кількість рядків вводу і виводу, але оскільки команда виконується лише один раз, це не впливає на продуктивність.

Якщо ви спробуєте зробити те саме за допомогою команди **teip**, `teip -l 2- -- grep` видасть помилку, оскільки кількість рядків виводу менша за кількість рядків вводу. Втім, з отриманим результатом немає жодних проблем.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::tee

# SEE ALSO

[App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee), [https://github.com/kaz-utashiro/App-Greple-tee](https://github.com/kaz-utashiro/App-Greple-tee)

[https://github.com/greymd/teip](https://github.com/greymd/teip)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/tecolicom/Greple](https://github.com/tecolicom/Greple)

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate).

# BUGS

Опція `--fillup` видалить пробіли між символами ханґульської абетки при конкатенації корейського тексту.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
