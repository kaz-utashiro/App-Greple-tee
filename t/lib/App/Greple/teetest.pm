package App::Greple::teetest;
1;
__DATA__
define {FOO} fo+
option --up  -Mtee -E {FOO} tr a-z A-Z --
option --lt  -Mtee -E qux sed s/^/</ --
option --mix -Mtee -E foo tr a-z A-Z -- -Mtee -E qux sed s/^/</ --
