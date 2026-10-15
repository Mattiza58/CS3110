  $ ../bin/main.exe --help > long.txt
  $ cat long.txt
  $ ../bin/main.exe -h > short.txt
  $ cmp long.txt short.txt
  $ ../bin/main.exe missing.csv bogus never.csv --cash invalid --help > early.txt
  $ cmp long.txt early.txt
  $ test ! -e never.csv
