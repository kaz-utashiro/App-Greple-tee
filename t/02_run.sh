greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
greple -Mtee cat -n -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
greple -Mtee tr "[:lower:]" "[:upper:]" -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all
greple -Mtee tr "[:lower:]" "[:upper:]" -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --discrete
greple -Mtee tr "[:lower:]" "[:upper:]" -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup
greple -Mtee tr "[:lower:]" "[:upper:]" -- '^([A-Z].*\n)(.+\n)*' t/SAMPLE.txt --all --fillup --discrete
