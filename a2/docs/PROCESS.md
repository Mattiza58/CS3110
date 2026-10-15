# Development and Validation Record

## Milestone 1: Cash-only backtest

**Initial plan.** Read `data/handout.csv`, run the cash strategy with $100.00,
and write one unchanged portfolio value per input date. Check every dated state
with OUnit and inspect the executable's summary and equity CSV.

**Actual result.** Complete. `R7 validation / Cash / handout dated states` checks all
three dated states through `Backtest.run`. The executable was run with
`dune exec bin/main.exe -- data/handout.csv cash /tmp/cs3110-a2-cash-equity.csv --cash 100.00`;
its complete summary showed $100.00 final cash/value and no holdings. The output
file had the exact `date,value` header and $100.00 on all three dates. Cram also
checks Cash's complete five-day SPY summary and equity file.

## Milestone 2: Buy-and-hold backtest

**Initial plan.** Run buy-and-hold through the same engine, selecting a security
with `--hold`. Calculate expected purchases, leftover cash, holdings, and dated
values independently on `data/handout.csv` and a new tiny multi-security CSV.
Check those states with OUnit, including ordered rejection and sale/purchase cases
for portfolio accounting, then inspect the executable's report and equity CSV.

**Actual result.** Complete. Portfolio and Backtest tests check ordered rejection
and sale-funded purchases. Buy-and-hold's OUnit group checks every date on both
market files through the production engine. `test/reports.t` checks the complete
SPY report/equity file and a handout run with one share and five cents leftover.

## Milestone 3: Stateful strategy and complete reports

**Initial plan.** Implement momentum behind the shared strategy signature,
keeping its previous prices and target private. Predict and test every dated
state on the supplied handout and a new tiny file exercising ties, target changes,
and days without a positive increase. Run all three strategies on
`data/small-spy-5days.csv` with $10,000.00 and check their complete standard output
with Cram. Check representative command-line and missing-input-file errors.

**Actual result.** Complete. All three strategies implement the same signature
with abstract state. Momentum's OUnit group checks predicted dated states and
focused transitions. `test/reports.t` checks all three complete SPY summaries
and equity files; `test/errors.t` and `test/help.t` check command-line failures,
file errors, and generated help. All checks pass.

## Cash on the supplied tiny market file

With $100.00 initial cash, each of January 2, 3, and 4 has $100.00 cash, no
holdings, and $100.00 value. `R7 validation / Cash / handout dated states` checks
all three dates using the production `Backtest.run`, which calls the public
strategy operations and processes orders with Portfolio.

## Buy-and-hold predictions

On `data/handout.csv`, start with $100.05 and hold ALFA. Buy 10 shares at $10.00
on January 2 and retain $0.05 cash. The three dated values are $100.05, $120.05,
and $110.05, with unchanged holdings after the initial purchase.

On `data/strategy-tiny.csv`, start with $10.00 and hold ZED. Its complete input is:

```csv
date,ZED,ALFA,Q7
2024-02-26,3.00,5.00,8.00
2024-02-27,4.00,6.00,8.50
2024-02-28,3.50,5.50,8.00
2024-02-29,3.75,5.75,9.00
2024-03-01,4.00,7.00,10.00
2024-03-04,4.50,7.50,10.50
2024-03-05,5.00,7.75,10.75
2024-03-06,5.00,7.75,10.75
```

The first purchase is 3 ZED for $9.00, leaving $1.00 cash. Holdings and cash
remain unchanged; each value is $1.00 plus three times that day's ZED price:

| Date | Cash | Holdings | Value |
| --- | --- | --- | --- |
| 2024-02-26 | $1.00 | ZED 3 | $10.00 |
| 2024-02-27 | $1.00 | ZED 3 | $13.00 |
| 2024-02-28 | $1.00 | ZED 3 | $11.50 |
| 2024-02-29 | $1.00 | ZED 3 | $12.25 |
| 2024-03-01 | $1.00 | ZED 3 | $13.00 |
| 2024-03-04 | $1.00 | ZED 3 | $14.50 |
| 2024-03-05 | $1.00 | ZED 3 | $16.00 |
| 2024-03-06 | $1.00 | ZED 3 | $16.00 |

`R7 validation / Buy-and-hold` checks orders, cash, holdings, and value on every
date of both files, plus the budget fixture described below. The separate
`Strategies / Buy-and-hold` unit group checks missing/invalid `hold` options
and the unaffordable first-day transition directly.

## Stateful-strategy predictions

Implemented only the default one-day momentum rule. It stores the previous
price row and selected target privately. It compares absolute cent increases,
breaks ties by header order, and switches only to a different positive-gain
target. A switch sells all holdings before buying as many target shares as cash
plus those proceeds permits. No positive gain retains the target without orders.
An unaffordable target is still remembered, and every step records current prices.

On `data/handout.csv`, start with $100.00. January 2 makes no orders. On January
3, ALFA's $2.00 gain wins: buy 8 shares for $96.00. On January 4, BETA's $1.00
gain wins: sell 8 ALFA for $88.00 and use $92.00 buying power to buy 4 BETA
for $84.00.

| Date | Cash | Holdings | Value |
| --- | --- | --- | --- |
| 2024-01-02 | $100.00 | none | $100.00 |
| 2024-01-03 | $4.00 | ALFA 8 | $100.00 |
| 2024-01-04 | $8.00 | BETA 4 | $92.00 |

On the new tiny file shown above, start with $10.00. ZED wins the February 27
tie because it appears first. February 28 declines across all securities, so no
orders are made. Q7 wins February 29, ALFA wins March 1, and ZED wins the
March 4 tie. March 5 keeps the existing ZED target; March 6 has no gains.

| Date | Orders in sequence | Cash | Holdings | Value |
| --- | --- | --- | --- | --- |
| 2024-02-26 | none | $10.00 | none | $10.00 |
| 2024-02-27 | buy 2 ZED | $2.00 | ZED 2 | $10.00 |
| 2024-02-28 | none | $2.00 | ZED 2 | $9.00 |
| 2024-02-29 | sell 2 ZED; buy 1 Q7 | $0.50 | Q7 1 | $9.50 |
| 2024-03-01 | sell 1 Q7; buy 1 ALFA | $3.50 | ALFA 1 | $10.50 |
| 2024-03-04 | sell 1 ALFA; buy 2 ZED | $2.00 | ZED 2 | $11.00 |
| 2024-03-05 | none | $2.00 | ZED 2 | $12.00 |
| 2024-03-06 | none | $2.00 | ZED 2 | $12.00 |

`R7 validation / Momentum` checks every dated order and portfolio state on both
files, plus the budget fixture below. Focused `Strategies / Momentum` tests
also distinguish absolute gains from percentage gains,
preserve header-order ties even if observations list securities differently,
check price updates on declining days, check sales without an affordable new
purchase, verify remembered unaffordable targets, and replay earlier states to
check immutable deterministic transitions.

## Command-line report check

`test/reports.t` checks complete standard output and every equity-file row for
all three runs on `data/small-spy-5days.csv`, each starting with $10,000.00.

| Strategy | Final cash | Final holdings | Final value | Displayed return |
| --- | --- | --- | --- | --- |
| cash | $10000.00 | none | $10000.00 | 0.00% |
| buy-and-hold | $62.05 | SPY 95 | $10333.45 | 3.33% |
| momentum | $3.10 | SPY 94 | $10166.38 | 1.66% |

Buy-and-hold buys 95 shares at $104.61 for $9937.95, retaining $62.05. Its
five values are $10000.00, $10165.30, $9712.15, $9998.10, and $10333.45. The
final gain of $333.45 is a 3.3345% return, rounded to two decimal places.

Momentum records the first day without orders. The September 16 gain selects
SPY: 94 shares at $106.35 cost $9996.90, leaving $3.10. It retains that target
through the remaining dates. Its five values are $10000.00, $10000.00, $9551.62,
$9834.56, and $10166.38. The final gain is $166.38, a 1.6638% return. Cash
keeps the initial amount on all dates. These expected numbers were calculated
from share quantities and the input prices independently of the implementation;
a separate integer-arithmetic calculation also confirmed them.

## Consequential revisions

The end-to-end goals are unchanged. The temporary strategy test driver was
replaced with calls to the production Backtest engine, preserving the original
independent expected dated states. Command parsing, reports, and terminal/file
output now complete the planned path. Money parsing was tightened when adding
command-line validation so signed, underscored, malformed, and overflowing
amounts cannot reach the accounting code; valid market prices are unaffected.

## Market reader validation

Implemented `Market.load`, `Market.securities`, and `Market.rows`. The market
representation and parsing helpers are hidden by `market.mli`. Each row pairs
its date with security/price associations in header order. Prices are integer
cents, parsed by the existing Money module. File errors return `Error` messages
containing the filename; Main now prints the message and exits unsuccessfully,
as checked by Cram. As permitted by R1, the reader assumes valid input
contents rather than performing full calendar or CSV-format validation.

Validation: `dune build` succeeded and `dune test` passed all seven tests in the
`Market CSV loading` OUnit group. The tests check every handout and SPY row
against explicit expected cents, load the medium file (251 dates, 5 securities)
and large file (748 dates, 20 securities), and check a missing-file error. Two
temporary CSVs additionally check nonalphabetical security order, one-cent and
fractional-dollar prices, gaps between dates, CRLF line endings, and a single
row without a final newline. These tests exercise only the public interface;
they do not establish the later accounting, strategy, or reporting milestones.

## Order and portfolio validation

Order defines whole-share buy/sell requests, execution outcomes, and four
rejection reasons. Its public variants let strategies propose orders without
owning accounting logic. Portfolio hides its cash/holdings representation behind
`portfolio.mli` and exposes immutable transitions, read accessors, and valuation.
All monetary calculations use integer cents. Holdings are unique and positive;
selling the final share removes the holding. Valuation reports a missing price
as an error rather than silently excluding a held security.

Validation: `dune build` succeeded and all 18 tests in `Portfolio accounting`
passed, alongside the seven existing Market tests. The tests cover positive
initial cash, buying and accumulating shares, partial and complete sales, each
rejection reason for both applicable directions, processing later orders after
rejections, sale proceeds funding later purchases, reversed order effects, empty
order lists, missing valuation prices, and unchanged earlier portfolio snapshots.

The Market integration test checks each dated state of the Accounting Reference:
cash/holdings/value are 7000 cents / ALFA 3 / 10000 cents, then 4200 / ALFA 2 and
BETA 2 / 10600, then 6300 / ALFA 2 and BETA 1 / 10600.

A separate hand-calculated example starts with 10003 cents. At ZED=333 and
Q7=1250 cents, buying 10 ZED leaves 6673 cash and value 10003. At ZED=400 and
Q7=1000, selling 3 ZED and buying 7 Q7 leaves 873 cash, 7 shares of each,
and value 10673. At ZED=250 and Q7=1400, buying 4 ZED is rejected; selling
2 Q7 leaves 3673 cash, ZED 7 and Q7 5, and value 12423. These predictions are
literal expected values in the tests and do not use Portfolio to calculate them.

## Strategy interface and validation

`Strategy.S` exposes only an abstract `state`, `name`, `init`, and `step`.
`Strategy.Cash`, `Strategy.Buy_and_hold`, and `Strategy.Momentum` are separate
ordinary nested modules explicitly sealed at that signature in the implementation
and interface. Cash uses private unit state; buy-and-hold uses a waiting/done
state; momentum retains header order, one previous price row, and its target.
There are no functors, first-class modules, I/O, or Portfolio calls in Strategy.

Initialization receives security names, initial cash, and option strings, with
no prices. Each step receives one current observation and proposes orders
without executing them. There is no market handle or operation to retrieve
another row. The production Backtest engine passes the current row and uses
only the common signature's operations for every strategy. An observation's
type alone cannot enforce which date a caller supplies; the engine's behavior
is checked by observation assertions and a future-price regression test.

Validation: `dune build` succeeded, formatting checks passed, and `dune test`
passed all 41 tests at the strategy implementation milestone: 7 Market,
18 Portfolio, and 16 Strategy. After adding Backtest, the dated-state tests
now pass ordinary `init`/`step` functions to the production engine, which carries
abstract state without inspecting it. Expected dated states above remain
explicit test literals.

## Backtest implementation and R2 validation

`Backtest.run` is a shared loop independent of strategy rules. It takes `name`,
`init`, and `step` from a module sealed with `Strategy.S`, using ordinary
function arguments without functors, first-class modules, or strategy-name
branches. It initializes a positive-cash, empty-holdings portfolio and strategy,
then processes every Market row in file order. Each observation contains only
that row's date/prices and the portfolio before orders. The next private strategy
state is carried to the next date without inspection.

All execution and rejection decisions remain in Portfolio. Orders process in
sequence at the current closing prices; rejected orders leave the portfolio
unchanged and later orders still execute. The engine then records a read-only
snapshot containing the resulting portfolio, current-date value, proposed orders,
and corresponding outcomes. Earlier portfolio snapshots remain immutable.

The read-only completed result includes the strategy name, initial cash and date,
final date and portfolio, final value, percentage return, and ordered history.
The final portfolio's cash and holdings use Portfolio's existing accessors.
Monetary calculations use integer cents; the return converts the gain and initial
cash to floats before division, then multiplies by 100. Report formats this
structured result; Backtest performs no file or terminal I/O.

Validation at the Backtest milestone: `dune build`, `dune test`, and formatting
checks passed for all 53 OUnit tests: 7 Market, 18 Portfolio, 16 Strategy, and
12 Backtest. The five dated-state
strategy scenarios now exercise the production engine. Backtest's additional
tests cover:

- The Accounting Reference's exact orders, outcomes, observations, and every dated
  state. Its final cash is 6300 cents, holdings are ALFA 2 and BETA 1, value is
  10600 cents, and return is 6.00%.
- All four rejection reasons through the engine, continuation after rejected
  orders, and carry-forward to later dates.
- Selling 10 ALFA on January 3 funds 6 BETA purchases, giving a final value of
  12600 cents and 26.00% return. Reversing those January 3 orders rejects the
  purchase and leaves 12000 cents cash, no holdings, and 20.00% return.
- One-date runs and exact-cent fractional returns: 3 shares bought at 300 cents
  with 1000 initial cents leave 100 cents cash. Prices of 301 and 299 on the
  next date give 1003/997 final cents and +0.30%/-0.30% returns respectively.
- Nonpositive initial cash is rejected before strategy initialization, and invalid
  strategy options return errors identifying the strategy.
- Changing only the final row leaves earlier orders, outcomes, and dated states
  unchanged. Separate runs initialize fresh private state.
- Cash on all 748 dates of the large historical file remains constant with no
  holdings, orders, or outcomes.

## Command, report, and main validation (R5 and R6)

Command follows the added command-line parsing guide: `BatOptParse` creates the
parser and string-valued `cash`/`hold` options, `parse_argv` is called once, and
`Opt.opt` retrieves their values. Exactly three positional arguments, a known
strategy, and positive cash with exactly two decimal places are checked before
opening the market. Argument failures use `OptParser.error`; Batteries owns
unknown-option, missing-value, and generated help behavior. After loading, the
selected strategy validates `hold` against market security names.

Money owns decimal parsing/formatting. It accepts only digit-based two-decimal
amounts within the integer-cent range; Command separately requires positivity.
Formatting uses integer division/remainder, preserving cents exactly. Report
renders all summary text and writes recorded dated values with the CSV package,
without recomputing trades or valuations. Main selects a sealed strategy's common
operations, coordinates loading/simulation/writing, and prints the summary only
after the equity write succeeds. Errors go to standard error and exit with status
1. Interfaces hide parsing helpers and prevent clients from constructing invalid
Command values.

Validation at the R5/R6 milestone: `dune build` and `dune test` passed, with
56 OUnit tests and all three Cram files passing. Formatting checks passed.
The new OUnit cases cover strict
money syntax and range, exact cent formatting, and a complete summary with
multiple holdings in alphabetical order and singular/plural share labels.
`test/reports.t` checks full summaries and CSV contents, including negative
returns, cents left unspent, option placement, irrelevant `hold` options for
Cash/Momentum, and overwriting an existing equity file. `test/errors.t` checks
argument counts, strategy names, missing/invalid cash, unknown options, missing
option values, missing/unknown held securities, and input/output file errors.
It verifies an invalid strategy request preserves an existing output file and
that a write failure prints no success summary. `test/help.t` checks both help
flags, their complete generated output, and successful early exit before file
access or semantic validation. The documented `dune exec` command shape was
also exercised directly on the handout file.

## R7 completion and requirement map

The required dated-state scenarios now live together in `test/test_validation.ml`.
They use only Market, Backtest, and Portfolio's public interfaces, with strategy
operations taken from the sealed modules. Expected orders, cash, holdings, and
values are independently calculated literals. The assertion helper does not
simulate expected trades. It checks the row count, date, orders, outcomes, cash,
holdings, and value separately on every date, then checks the final summary
against the last expected state. Failure messages identify the strategy, date,
field, and expected/actual money or holdings.

| Requirement | Executable evidence | Expected-result explanation |
| --- | --- | --- |
| R7.1: Cash | `R7 validation / Cash / handout dated states` | $100.00 cash/value, no shares on every supplied tiny-file date |
| R7.1: Buy-and-hold | `R7 validation / Buy-and-hold` (three cases) | Handout and new multi-date files; purchases, leftover cash, changing values, and no retry after an unaffordable first date |
| R7.1: Stateful strategy | `R7 validation / Momentum` (three cases) | Handout and new multi-date files; previous-price state, tie-breaking, target changes, retained targets, sale-funded purchases, and losses |
| R7.2: Complete command-line reports | `test/reports.t` | All three SPY runs with $10,000.00; complete standard output and exact equity CSVs |
| R7.3: Written validation evidence | This document's cash, buy-and-hold, momentum, SPY, and budget-fixture sections; `data/README.md` | Input files, independent arithmetic, predicted dated states, and explanations of what each scenario exercises |

`test/reports.t` now redirects each required SPY run's standard error to a
separate file and checks that it is empty. Thus the complete expected summary
must actually appear on standard output. This catches accidentally printing
a successful summary to standard error, which a test comparing combined
streams could miss. An additional one-cent Cash run checks that the actual
CSV writer preserves plain `0.01` values, without quoting or dollar signs.

### Budget fixture predictions

`data/strategy-budget.csv` adds previously unused security names, WREN and LYNX,
and starts both strategies with $1.00. Its complete input is:

```csv
date,WREN,LYNX
2024-04-01,0.40,5.00
2024-04-02,0.50,5.00
2024-04-03,0.50,10.00
2024-04-04,0.50,0.75
2024-04-05,0.50,0.80
2024-04-08,0.40,0.70
2024-04-09,0.60,0.75
2024-04-10,0.60,0.75
2024-04-11,0.30,0.60
```

Buy-and-hold selects LYNX. The first $5.00 price is unaffordable, so every one of
the nine dates has $1.00 cash, no holdings or orders, and $1.00 value. In
particular, it does not retry on April 4 when LYNX falls below $1.00.

Momentum first records prices. WREN's ten-cent increase on April 2 buys two
shares at fifty cents, using the entire dollar. On April 3, LYNX's $5.00 gain
selects a different target: selling both WREN shares restores $1.00, which
cannot buy LYNX at $10.00. That target is still remembered. The April 4 decline
does not change it, and April 5's positive LYNX increase must not trigger a
purchase even though a share is now affordable. April 8 declines again. On
April 9, WREN's twenty-cent increase beats LYNX's five cents, so the target
changes and one WREN share is bought at sixty cents. April 10 is flat and
April 11 declines, leaving the share held. Final value is forty cents cash
plus a thirty-cent share, or seventy cents.

| Date | Momentum orders | Cash | Holdings | Value |
| --- | --- | --- | --- | --- |
| 2024-04-01 | none | $1.00 | none | $1.00 |
| 2024-04-02 | buy 2 WREN | $0.00 | WREN 2 | $1.00 |
| 2024-04-03 | sell 2 WREN | $1.00 | none | $1.00 |
| 2024-04-04 | none | $1.00 | none | $1.00 |
| 2024-04-05 | none | $1.00 | none | $1.00 |
| 2024-04-08 | none | $1.00 | none | $1.00 |
| 2024-04-09 | buy 1 WREN | $0.40 | WREN 1 | $1.00 |
| 2024-04-10 | none | $0.40 | WREN 1 | $1.00 |
| 2024-04-11 | none | $0.40 | WREN 1 | $0.70 |

### Why these examples provide useful evidence

- Cash detects unwanted orders, altered starting cash, or missing/extra dates.
- Handout buy-and-hold leaves five cents, exposing rounding and whole-share
  mistakes; later price changes expose valuing holdings at their purchase price.
- The eight-date tiny file uses header order different from alphabetical order,
  ties, declining and flat days, changing targets, and an unchanged winner. It
  catches alphabetical tie-breaking, premature liquidation, unnecessary
  rebalancing, and failure to use sale proceeds.
- The budget file distinguishes remembering a selected target from remembering
  a successful purchase. It catches retrying an unaffordable target, retaining
  old holdings when switching to an unaffordable target, and incorrectly
  treating a later affordable price as a new first-day buy-and-hold opportunity.
- SPY Cram tests connect argument parsing, strategy selection, simulation,
  formatted summaries, and file output. Complete-output comparison catches
  missing fields and unwanted extra output; dated OUnit checks localize
  accounting/state errors that a final summary alone could conceal.

These examples establish the specified scenarios, supplemented by focused
Portfolio/Strategy/Backtest tests for rejection order, immutable snapshots,
price-memory updates after declining days, fractional positive/negative returns,
and changed future prices. They are finite
examples rather than an exhaustive proof for every market file. Malformed market
contents remain outside the assignment's required input contract.

### Final validation run

From the `a2` project root, `dune build` and `dune test --force` succeeded.
Forcing the test run reran every OUnit and Cram target rather than relying on
cached results. All 58 OUnit cases and all three Cram files passed:

| OUnit executable | Cases |
| --- | --- |
| `test_a2` (Market) | 7 |
| `test_portfolio` | 18 |
| `test_strategy` (focused transitions) | 11 |
| `test_validation` (R7 dated scenarios) | 7 |
| `test_backtest` | 12 |
| `test_report` (Money and Report) | 3 |

The Cram files are `reports.t`, `errors.t`, and `help.t`. Test fixtures are
declared in `test/dune` so Dune makes them available in its test sandbox.
All OCaml sources pass the project's `ocamlformat` configuration. No production
implementation changes were needed to pass the R7 audit.
