Argument errors occur before trying to open the nonexistent market. The parser
prints usage and a specific error, with no standard output or output CSV.

  $ ../bin/main.exe missing.csv cash out.csv --cash 0.00 >stdout.txt 2>stderr.txt
  [1]
  $ cat stdout.txt
  $ cat stderr.txt
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: --cash must be a positive amount with exactly two decimal places (e.g. 10000.00)
  $ test ! -e out.csv
  $ ../bin/main.exe missing.csv cash out.csv --cash 10.0
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: --cash must be a positive amount with exactly two decimal places (e.g. 10000.00)
  [1]
  $ ../bin/main.exe missing.csv bogus out.csv --cash 10.00
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: Unknown strategy "bogus"; choose cash, buy-and-hold, or momentum
  [1]
  $ ../bin/main.exe missing.csv cash out.csv
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: Missing required --cash DOLLARS
  [1]
  $ ../bin/main.exe missing.csv cash --cash 10.00
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: Expected exactly three positional arguments: MARKET.csv STRATEGY EQUITY.csv
  [1]
  $ ../bin/main.exe missing.csv cash out.csv extra --cash 10.00
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: Expected exactly three positional arguments: MARKET.csv STRATEGY EQUITY.csv
  [1]

Batteries itself handles unknown options and options without a value.

  $ ../bin/main.exe missing.csv cash out.csv --unknown 10.00
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: option '--unknown': no such option
  [1]
  $ ../bin/main.exe missing.csv cash out.csv --cash
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: option '--cash': missing required arguments
  [1]
  $ ../bin/main.exe ../data/handout.csv buy-and-hold out.csv --cash 100.00 --hold
  usage: main.exe MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]
  
  main.exe: option '--hold': missing required arguments
  [1]

Market-dependent validation happens after loading. Invalid requests do not
overwrite an existing output file.

  $ echo preserved > sentinel.csv
  $ ../bin/main.exe ../data/handout.csv buy-and-hold sentinel.csv --cash 100.00
  Error: buy-and-hold: Buy-and-hold requires --hold SYMBOL
  [1]
  $ ../bin/main.exe ../data/handout.csv buy-and-hold sentinel.csv --cash 100.00 --hold alfa
  Error: buy-and-hold: Unknown --hold security "alfa"
  [1]
  $ cat sentinel.csv
  preserved

File errors are useful messages and unsuccessful exits, without uncaught
exceptions. A write error produces no success summary.

  $ ../bin/main.exe missing.csv cash out.csv --cash 100.00
  Error: Cannot load market file "missing.csv": missing.csv: No such file or directory
  [1]
  $ ../bin/main.exe ../data/handout.csv cash missing-dir/out.csv --cash 100.00 >stdout.txt 2>stderr.txt
  [1]
  $ cat stdout.txt
  $ cat stderr.txt
  Error: Cannot write equity file "missing-dir/out.csv": missing-dir/out.csv: No such file or directory
