The Batteries-generated help lists both string-valued options. Both help flags
exit successfully, before semantic validation or opening input/output files.

  $ ../bin/main.exe --help > long.txt
  $ cat long.txt
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  options:
  
    Backtest cash, buy-and-hold, or momentum against historical prices.
  
    -h, --help            show this help message and exit
    --cash=DOLLARS        positive initial cash, e.g. 10000.00
    --hold=SYMBOL         security bought by buy-and-hold
  
  $ ../bin/main.exe -h > short.txt
  $ cmp long.txt short.txt
  $ ../bin/main.exe missing.csv bogus never.csv --cash invalid --help > early.txt
  $ cmp long.txt early.txt
  $ test ! -e never.csv
