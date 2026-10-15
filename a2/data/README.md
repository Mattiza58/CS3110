# A2 Market Data

The historical CSV files in this directory were created from the public domain [Huge
Stock Market Dataset][hsmd] (HSMD).

- `handout.csv` is the tiny fictional price dataset shown in the handout.

- `strategy-tiny.csv` is a fictional eight-date, three-security test fixture.
  Its prices exercise momentum ties, declining and flat days, target changes,
  and an unchanged target, and buy-and-hold with leftover cash.

- `strategy-budget.csv` is a fictional nine-date, two-security fixture for a
  $1.00 account. It checks an unaffordable first-day buy-and-hold purchase,
  momentum selling before an unaffordable switch, remembering that target as
  prices fall, a later target change, and a final loss.

- `small-spy-5days.csv` is a small historical price dataset: five consecutive trading
  dates of the SPY during the Lehman-collapse week (September 15–19, 2008). SPY
  is an exchange-traded fund that intends to correspond generally to the price
  and yield performance of the S&P 500 Index.

- `medium-tech-2007.csv` is a medium historical price dataset: the 251 shared trading dates in
  calendar year 2007 for AAPL, AMZN, CSCO, INTC, and MSFT. It provides the year
  immediately before the 2008 financial crisis.

- `large-dotcom-ca2000.csv` is a large historical price dataset: 748 shared trading
  dates from 1999 through 2001 for 20 companies. It includes technology
  companies (AAPL, AMZN, CSCO, HPQ, INTC, MSFT, and ORCL), health care,
  consumer, energy, finance, and industrial companies, so the dot-com collapse
  does not determine every security's result.

[hsmd]: https://www.kaggle.com/datasets/borismarjanovic/price-volume-data-for-all-us-stocks-etfs
