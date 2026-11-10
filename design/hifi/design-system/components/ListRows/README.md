# ListRows

List rows: expandable category, record, swipe-delete, search result with highlight, section header, collapsible section and hidden-account row.

- Amounts end on one right edge: category rows have a chevron, child rows a 24 dp gutter (§10.1 #12).
- Rows are at least 56 dp, or 72 dp for two lines; text never truncates the amount.
- Swipe left reveals `swipe-delete` with an `error` bin. The non-gesture alternative is to open the row and tap Delete.
- At ≥ 130 %, amounts move under the titles.
