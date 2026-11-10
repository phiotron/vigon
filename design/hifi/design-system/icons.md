# Icons

Every icon is **Material Symbols Rounded**, weight 400, optical size 24, grade 0. Category icons use **FILL 1** in `on-cat` on their category colour. Action icons use **FILL 0** in `ink` or `ink-muted`. Status icons (✓ / ⚠ / lock) use FILL 1 so they read at 16–20 dp. Never use emoji.

## Category icons: 31 selectable keys (final glyphs)

The glyph is the Material Symbols ligature with the same name as the key, so keys and glyphs map **1 : 1** and nothing needs remapping. Five legacy keys (`local_grocery_store`, `phone_android`, `medical_services`, `card_giftcard`, `trending_up`) still render the glyph of the same name.

| # | Key = glyph | Default category |
|---|---|---|
| 1 | `restaurant` | Food (cat-13) |
| 2 | `local_cafe` | — |
| 3 | `directions_bus` | Transport (cat-06) |
| 4 | `two_wheeler` | — |
| 5 | `local_gas_station` | — |
| 6 | `home` | Home (cat-09) |
| 7 | `receipt_long` | Bills (cat-05) |
| 8 | `bolt` | — |
| 9 | `water_drop` | — |
| 10 | `wifi` | — |
| 11 | `shopping_bag` | Shopping (cat-02) |
| 12 | `checkroom` | — |
| 13 | `health_and_safety` | Health (cat-01) |
| 14 | `medication` | — |
| 15 | `movie` | Entertainment (cat-03) |
| 16 | `sports_esports` | — |
| 17 | `school` | Education (cat-08) |
| 18 | `menu_book` | — |
| 19 | `family_restroom` | Family (cat-15) |
| 20 | `child_care` | — |
| 21 | `pets` | — |
| 22 | `redeem` | Bonus (cat-12) |
| 23 | `payments` | Salary (cat-10) |
| 24 | `savings` | — |
| 25 | `work` | — |
| 26 | `flight` | — |
| 27 | `fitness_center` | — |
| 28 | `spa` | — |
| 29 | `volunteer_activism` | — |
| 30 | `build` | — |
| 31 | `more_horiz` | Other (cat-16), Other income (cat-16) |

`more_horiz` is the key of the default "Other" category, so the Home ⋯ slot uses the same glyph in a **different container**: a dashed outline instead of a filled disc. A different glyph for "Other" is listed on the Ideas page.

## Action and status icons

| Glyph | Where | Fill |
|---|---|---|
| `account_balance_wallet` | Home: account filter; Settings: Accounts; account rows; account picker | 0 |
| `receipt_long` | Home: Records | 0 |
| `settings` | Home: Settings | 0 |
| `chevron_left / chevron_right` | Period header; nav rows | 0 |
| `arrow_drop_down` | Period title; dropdowns; picker fields | 0 |
| `arrow_back` | Back (both platforms) | 0 |
| `close` | Close a full-height sheet; clear search | 0 |
| `search` | Entries: Search; search field | 0 |
| `search_off` | No search or currency match | 0 |
| `check` | Selected segment, chip, menu item, currency | 0 |
| `expand_more / expand_less` | Category rows; Hidden accounts; Show more | 0 |
| `drag_handle` | Categories reorder | 0 |
| `add` | FAB; + at 200 % | 0 |
| `remove` | − at 200 % | 0 |
| `swap_horiz` | Transfer action; transfer rows | 0 |
| `delete` | Delete in sheets and dialogs; swipe-delete | 0 |
| `delete_forever` | Settings: Delete all data | 0 |
| `visibility_off` | Hide account; Hidden accounts; Hide content when switching apps | 0 |
| `visibility` | Show again; password toggle (show) | 0 |
| `category` | Settings: Categories | 0 |
| `savings` | Settings: Monthly budget | 0 |
| `event_repeat` | Settings: Repeating records | 0 |
| `currency_exchange` | Settings: Currency | 0 |
| `view_week` | Settings: First day of week | 0 |
| `calendar_month` | Settings: Month starts on day | 0 |
| `lock` | Lock with PIN; Locked with PIN pill (filled); restore password dialog | 0 |
| `widgets` | Show amounts on widget | 0 |
| `notifications` | Daily reminder; reminder explain dialog | 0 |
| `schedule` | Reminder time; auto-backup "No backup yet" | 0 |
| `upload_file` | Export backup row and dialog | 0 |
| `settings_backup_restore` | Restore row and confirm | 0 |
| `table_view` | Export CSV | 0 |
| `backup` | Automatic backup; Back up now | 0 |
| `folder / folder_open` | Auto-backup folder line; Choose folder again | 0 |
| `check_circle` | Auto-backup OK | 1 |
| `error` | Auto-backup error | 1 |
| `warning` | Over budget / over limit; password warning | 1 |
| `info` | Hints (account, currency note, restore note) | 0 |
| `restart_alt` | Frequency-change hint | 0 |
| `stop_circle` | Stopped series pill | 1 |
| `update` | Widget "Open the app to update" | 1 |
| `ios_share` | Export button | 0 |
| `more_horiz` | ⋯ More categories slot (outlined, in a dashed ring) | 0 |

## Brand marks

- **App icon / logo**: `store/brand/icon-512.png` (D-009), used as is in the widget picker, iOS notifications, Recents and the widget brand row. Never redrawn.
- **Android small icon** (status bar, notification header): a monochrome silhouette of the two cards with the line and dot cut out. In the frames it is a redraw (ASSUMPTION A16); export the production version from the existing monochrome launcher layer (F-23).
