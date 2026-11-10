# ChartRing

The Home donut with category icons and the ⋯ slot, labelled centre totals, budget bars (monthly total and per category), the balance bar and the period header.

- Arcs: `cat-NN`, largest first from 12 o'clock, 2 dp gaps. Icons are spaced evenly in user order; past ≈ 17 slots the last slot becomes ⋯.
- Centre: `label-sm` words "Income" / "Expenses" above `amount-md` totals.
- Budget bars: 8 dp (total) and 4 dp (category). Over budget = `error` text at weight 600 + a `warning` icon + a full `error` bar.
- The balance bar shows the period title under "Balance", so it reads as the *period* balance.
