Cash preserves $10,000.00 on all five supplied SPY dates. Check the complete
summary and the entire equity file.

  $ ../bin/main.exe ../data/small-spy-5days.csv cash cash.csv --cash 10000.00 2>cash.err
  Strategy: cash
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $10000.00
  Final holdings:
    none
  Final portfolio value: $10000.00
  Total return: 0.00%
  $ cat cash.err
  $ cat cash.csv
  date,value
  2008-09-15,10000.00
  2008-09-16,10000.00
  2008-09-17,10000.00
  2008-09-18,10000.00
  2008-09-19,10000.00

Buy-and-hold buys 95 shares for $9,937.95, leaving $62.05. Final value is
95 * $108.12 + $62.05 = $10,333.45; return is 3.3345%, displayed as 3.33%.

  $ ../bin/main.exe ../data/small-spy-5days.csv buy-and-hold hold.csv --cash 10000.00 --hold SPY 2>hold.err
  Strategy: buy-and-hold
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $62.05
  Final holdings:
    SPY: 95 shares
  Final portfolio value: $10333.45
  Total return: 3.33%
  $ cat hold.err
  $ cat hold.csv
  date,value
  2008-09-15,10000.00
  2008-09-16,10165.30
  2008-09-17,9712.15
  2008-09-18,9998.10
  2008-09-19,10333.45

Momentum buys 94 shares on September 16 at $106.35, leaving $3.10. It retains
that target for the remaining dates. Final value is $10,166.38; return is 1.6638%.

  $ ../bin/main.exe ../data/small-spy-5days.csv momentum momentum.csv --cash 10000.00 2>momentum.err
  Strategy: momentum
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $3.10
  Final holdings:
    SPY: 94 shares
  Final portfolio value: $10166.38
  Total return: 1.66%
  $ cat momentum.err
  $ cat momentum.csv
  date,value
  2008-09-15,10000.00
  2008-09-16,10000.00
  2008-09-17,9551.62
  2008-09-18,9834.56
  2008-09-19,10166.38

Options may precede and mix with positional arguments. Cash and momentum ignore
--hold, including a name absent from the market.

  $ ../bin/main.exe --cash 100.05 ../data/handout.csv --hold MISSING cash small.csv
  Strategy: cash
  Period: 2024-01-02 to 2024-01-04
  Initial cash: $100.05
  Final cash: $100.05
  Final holdings:
    none
  Final portfolio value: $100.05
  Total return: 0.00%
  $ cat small.csv
  date,value
  2024-01-02,100.05
  2024-01-03,100.05
  2024-01-04,100.05
  $ ../bin/main.exe ../data/handout.csv momentum negative.csv --cash 100.00 --hold MISSING
  Strategy: momentum
  Period: 2024-01-02 to 2024-01-04
  Initial cash: $100.00
  Final cash: $8.00
  Final holdings:
    BETA: 4 shares
  Final portfolio value: $92.00
  Total return: -8.00%
  $ cat negative.csv
  date,value
  2024-01-02,100.00
  2024-01-03,100.00
  2024-01-04,92.00

Buying a single share uses singular wording; an existing equity file is replaced.

  $ ../bin/main.exe ../data/handout.csv buy-and-hold negative.csv --cash 10.05 --hold ALFA
  Strategy: buy-and-hold
  Period: 2024-01-02 to 2024-01-04
  Initial cash: $10.05
  Final cash: $0.05
  Final holdings:
    ALFA: 1 share
  Final portfolio value: $11.05
  Total return: 9.95%
  $ cat negative.csv
  date,value
  2024-01-02,10.05
  2024-01-03,12.05
  2024-01-04,11.05

The minimum positive cash amount stays a plain two-decimal CSV value.

  $ ../bin/main.exe ../data/handout.csv cash cents.csv --cash 0.01
  Strategy: cash
  Period: 2024-01-02 to 2024-01-04
  Initial cash: $0.01
  Final cash: $0.01
  Final holdings:
    none
  Final portfolio value: $0.01
  Total return: 0.00%
  $ cat cents.csv
  date,value
  2024-01-02,0.01
  2024-01-03,0.01
  2024-01-04,0.01
