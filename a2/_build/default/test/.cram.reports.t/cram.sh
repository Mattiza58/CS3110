  $ ../bin/main.exe ../data/small-spy-5days.csv cash cash.csv --cash 10000.00 2>cash.err
  $ cat cash.err
  $ cat cash.csv
  $ ../bin/main.exe ../data/small-spy-5days.csv buy-and-hold hold.csv --cash 10000.00 --hold SPY 2>hold.err
  $ cat hold.err
  $ cat hold.csv
  $ ../bin/main.exe ../data/small-spy-5days.csv momentum momentum.csv --cash 10000.00 2>momentum.err
  $ cat momentum.err
  $ cat momentum.csv
  $ ../bin/main.exe --cash 100.05 ../data/handout.csv --hold MISSING cash small.csv
  $ cat small.csv
  $ ../bin/main.exe ../data/handout.csv momentum negative.csv --cash 100.00 --hold MISSING
  $ cat negative.csv
  $ ../bin/main.exe ../data/handout.csv buy-and-hold negative.csv --cash 10.05 --hold ALFA
  $ cat negative.csv
  $ ../bin/main.exe ../data/handout.csv cash cents.csv --cash 0.01
  $ cat cents.csv
