  $ ../bin/main.exe missing.csv cash out.csv --cash 0.00 >stdout.txt 2>stderr.txt
  $ cat stdout.txt
  $ cat stderr.txt
  $ test ! -e out.csv
  $ ../bin/main.exe missing.csv cash out.csv --cash 10.0
  $ ../bin/main.exe missing.csv bogus out.csv --cash 10.00
  $ ../bin/main.exe missing.csv cash out.csv
  $ ../bin/main.exe missing.csv cash --cash 10.00
  $ ../bin/main.exe missing.csv cash out.csv extra --cash 10.00
  $ ../bin/main.exe missing.csv cash out.csv --unknown 10.00
  $ ../bin/main.exe missing.csv cash out.csv --cash
  $ ../bin/main.exe ../data/handout.csv buy-and-hold out.csv --cash 100.00 --hold
  $ echo preserved > sentinel.csv
  $ ../bin/main.exe ../data/handout.csv buy-and-hold sentinel.csv --cash 100.00
  $ ../bin/main.exe ../data/handout.csv buy-and-hold sentinel.csv --cash 100.00 --hold alfa
  $ cat sentinel.csv
  $ ../bin/main.exe missing.csv cash out.csv --cash 100.00
  $ ../bin/main.exe ../data/handout.csv cash missing-dir/out.csv --cash 100.00 >stdout.txt 2>stderr.txt
  $ cat stdout.txt
  $ cat stderr.txt
