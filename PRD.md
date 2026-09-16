# Daily Protein — Product Requirements Document

| | |
|---|---|
| **Product** | Daily Protein |
| **Platform** | Android (Flutter 3.41 / Dart 3.11) |
| **Version** | 1.0 |
| **Status** | Implemented |
| **Last updated** | 2026-09-16 |

---

## 1. Overview

### 1.1 Problem

People trying to hit a protein target have to do arithmetic constantly. "I ate
three eggs and 150 g of chicken — how much protein was that?" General nutrition
apps solve this with enormous food databases, but those databases are wrong for
home cooking, regional foods and whatever brand of paneer is actually in the
fridge. They also demand an account and a network connection to look anything up.

The user already knows what their food contains. What they lack is somewhere to
record it once and have the multiplication done for them thereafter.

### 1.2 Solution

A personal food catalogue plus a calculator. The user enters each food once with
its protein content. From then on, logging is picking a product and a quantity;
the app computes protein, and optionally calories and cost, automatically.

No accounts, no network, no database of foods the user doesn't eat.

### 1.3 Goals

| Goal | Measured by |
|---|---|
| Logging a repeat food takes under five seconds | Pick a product, set a quantity, confirm |
| The user never does protein arithmetic | Every quantity input shows the computed result live |
| The app is useful on day one with zero setup | Sensible defaults; no onboarding required |
| The user's data is theirs | Local-only storage, full JSON export |

### 1.4 Non-goals

Explicitly out of scope for v1.0:

- Public food database or barcode scanning
- Cloud sync, accounts, or multi-device
- Macros beyond protein and calories (no carbs, fat, micronutrients)
- Recipes or composite foods built from other products
- Social features, streaks, gamification, or notifications
- Water intake, weight, exercise, or any non-food tracking
- iOS, web, or desktop builds

---

## 2. Users

### 2.1 Primary user

Someone with a daily protein target — gym-goer, person on a high-protein diet,
someone recovering from illness, or a vegetarian watching intake. They eat a
fairly repetitive set of foods and know roughly what those foods contain. They
are not a nutritionist and do not want to be.

### 2.2 Secondary consideration

Price-sensitive users who want to know whether they are getting protein cheaply.
This is why price is captured at all, and why cost-per-gram is surfaced.

### 2.3 Assumptions

- The user is willing to spend a minute entering a product the first time.
- The user's foods repeat heavily week to week.
- The user has one device and does not need sync.
- Nutrition figures come from a package label, a search, or the user's own
  estimate — the app trusts whatever is entered.

---

## 3. Core concepts

### 3.1 Product

A food the user eats, entered once and reused. Fields:

| Field | Required | Notes |
|---|---|---|
| Name | Yes | Free text, e.g. "Egg", "Paneer", "Whey scoop" |
| Measure mode | Yes | Per unit, or per 100 g |
| Unit label | Per-unit only | "piece", "egg", "scoop", "glass". Defaults to "piece" |
| Protein (g) | Yes | Per unit or per 100 g, per the measure mode |
| Calories (kcal) | No | Same basis as protein |
| Price | No | Same basis as protein |

### 3.2 Measure mode

The central modelling decision. Foods divide into two kinds and forcing either
into the other's shape makes the app annoying:

- **Per unit** — countable things. One egg, one scoop, one glass. The user logs
  a count. `protein = value × count`.
- **Per 100 g** — weighed things. Chicken, paneer, rice. The user logs grams.
  `protein = value × grams / 100`.

The mode is chosen per product, so a catalogue mixes both freely.

### 3.3 Entry

One logged food on one day. Stores the product reference, the day, the quantity,
the meal, and the **computed** protein, calories and cost.

Nutrition is snapshotted at log time rather than recomputed from the product on
read. Rationale: if the user later corrects a product's protein value, their
past days should reflect what they actually believed at the time, not be
silently rewritten. This is a deliberate trade-off — the alternative (always
recompute) would make corrections retroactive, which is wrong for a log.

### 3.4 Day

Identified by a `yyyy-MM-dd` key. Chosen over timestamps so days sort
lexicographically, group trivially in SQL, and survive JSON export unchanged
regardless of timezone.

### 3.5 Meal

Breakfast, lunch, dinner, or snack. Purely organisational — meals group the
day's list and show a per-meal protein subtotal. Defaulted from the clock so
the user rarely has to set it.

---

## 4. Functional requirements

### 4.1 Product management

| ID | Requirement |
|---|---|
| P-1 | User can create a product with name, measure mode, protein, and optional unit label, calories and price |
| P-2 | Protein is required and must be a non-negative number; name must be non-empty |
| P-3 | Calories and price are optional; blank means absent, not zero, and they are excluded from totals and derived metrics |
| P-4 | While entering a product, the form shows worked examples of the entered figure (1/2/3 units, or 50/100/200 g) |
| P-5 | User can edit any field of an existing product |
| P-6 | User can delete a product; deletion cascades to its entries |
| P-7 | Before deleting, the user is told how many logged entries will be removed |
| P-8 | User can search the catalogue by name, case-insensitive substring |
| P-9 | Products are listed alphabetically, case-insensitive |

### 4.2 Logging food

| ID | Requirement |
|---|---|
| L-1 | User picks a product, enters a quantity, and confirms to log it |
| L-2 | Protein updates live as the quantity changes, before saving |
| L-3 | Calories and cost also update live, shown only if the product has those values |
| L-4 | Quantity presets are offered: 1/2/3/4/6 for per-unit, 50/100/150/200/250 g for per-100 g |
| L-5 | Plus and minus buttons step the quantity by 1 (per-unit) or 25 g (per-100 g), never below zero |
| L-6 | Meal defaults from the clock: breakfast before 11:00, lunch before 16:00, dinner before 22:00, otherwise snack |
| L-7 | Save is disabled until a product is selected and quantity is greater than zero |
| L-8 | User can create a new product from inside the logging flow without losing their place |
| L-9 | User can edit a logged entry's product, quantity and meal |
| L-10 | User can delete an entry by swiping it left |
| L-11 | Deleting an entry offers Undo, which restores it fully |

### 4.3 Daily view

| ID | Requirement |
|---|---|
| D-1 | A ring shows protein consumed against the daily goal, animated on change |
| D-2 | The ring shows grams remaining, or "Goal reached" once the target is met |
| D-3 | Exceeding the goal draws a secondary inner arc rather than capping silently |
| D-4 | Calories and spend for the day are shown alongside |
| D-5 | Cost per gram of protein is shown when the day has both cost and protein |
| D-6 | Entries are grouped by meal, each group showing its protein subtotal |
| D-7 | User can step to the previous or next day, or pick a date |
| D-8 | Future days cannot be viewed or logged |
| D-9 | Today, yesterday and other days are labelled "Today", "Yesterday", and a formatted date respectively |
| D-10 | Pull-to-refresh reloads the day and catalogue |

### 4.4 History

| ID | Requirement |
|---|---|
| H-1 | Bar chart of daily protein over a selectable 7, 14 or 30-day window |
| H-2 | The goal is drawn as a dashed reference line; bars at or above it are fully saturated |
| H-3 | Tapping a bar shows that day's date and exact total |
| H-4 | Daily average across the window, counting untracked days as zero |
| H-5 | Count of days in the window that met the goal |
| H-6 | Total spend across the window, and blended cost per gram of protein |
| H-7 | Products ranked by cost per gram of protein, cheapest first, limited to three |
| H-8 | A list of every logged day with its total, progress bar, item count, calories and cost |
| H-9 | Tapping a day opens it in the daily view |

### 4.5 Settings

| ID | Requirement |
|---|---|
| S-1 | Daily protein goal is editable; default 120 g |
| S-2 | Daily calorie goal is editable; default 2000 kcal |
| S-3 | Currency symbol is selectable from ₹, $, €, £, ¥, AED; default ₹ |
| S-4 | Theme is selectable: light, dark, or follow system; default follow system |
| S-5 | Theme changes apply immediately across the whole app |
| S-6 | All preferences persist across restarts |

### 4.6 Backup

| ID | Requirement |
|---|---|
| B-1 | User can export all products and entries to a JSON file at a location they choose |
| B-2 | User can import a backup, replacing all current data |
| B-3 | Import warns that it is destructive and suggests exporting first |
| B-4 | Import rejects files that are not Daily Protein backups, with a clear message |
| B-5 | Import is transactional — a malformed file leaves existing data untouched |
| B-6 | User can clear all data, behind a confirmation dialog |
| B-7 | Cancelling any backup operation is silent, with no error shown |

---

## 5. Calculation rules

The behavioural contract of the app. All of these are covered by unit tests in
`test/protein_calculation_test.dart`.

### 5.1 Scaling

```
Per unit:    result = value × quantity
Per 100 g:   result = value × quantity / 100
```

Applied identically to protein, calories and cost.

| Product | Quantity | Protein |
|---|---|---|
| Egg, 6 g per piece | 2 pieces | 12 g |
| Egg, 6 g per piece | 0 pieces | 0 g |
| Chicken, 27 g per 100 g | 150 g | 40.5 g |
| Chicken, 27 g per 100 g | 100 g | 27 g |
| Chicken, 27 g per 100 g | 50 g | 13.5 g |

### 5.2 Absent optional values

A product with no calories or no price contributes **zero**, not null, to a
logged entry. Totals therefore never break. But the product's own
`costPerGramProtein` stays null, so an unpriced product is excluded from the
best-value ranking rather than appearing as free.

### 5.3 Derived metrics

```
costPerGramProtein = price / protein       — null if price absent or protein ≤ 0
day.costPerGram    = day.cost / day.protein — null if either is ≤ 0
average            = Σ protein over window / number of days in window
```

Untracked days count as zero in the average, deliberately. An average over only
the days the user remembered to log would flatter them and misrepresent intake.

### 5.4 Display

Trailing zeros are trimmed: `12.0` renders as "12", `12.5` as "12.5",
`40.50` as "40.5". Calories render with no decimals; money with two.

---

## 6. Design

### 6.1 Direction

Teal accent on a near-neutral ground. Calm rather than shouty — this is a
utility the user opens several times a day, not a motivational product. Generous
tap targets, large numerals for the figures that matter, and no decoration that
doesn't carry information.

### 6.2 Theming rule

`lib/core/theme/app_colors.dart` is the single source of truth for colour and is
the only file in the application permitted to declare a raw `Color`. Every other
file reads from `Theme.of(context).colorScheme`.

Consequence: changing the brand colour in one place changes the entire app in
both light and dark mode, and no widget can drift out of sync with the theme.

Verified by:

```bash
grep -rn "Color(0x\|Colors\." lib/ --include="*.dart" | grep -v core/theme
```

This must return nothing.

`app_spacing.dart` plays the same role for spacing and corner radii.

### 6.3 Both themes

Light and dark are first-class, not one derived from the other. Each has its own
surface, outline and text values tuned for its ground. The user picks light,
dark or system; system is the default.

### 6.4 Navigation

Four destinations in a bottom bar, held in an `IndexedStack` so each keeps its
scroll position and state when the user switches away and back:

1. **Today** — the ring, stats, and the day's entries
2. **History** — chart, trends, value insights, all logged days
3. **Products** — the catalogue
4. **Settings** — goals, appearance, backup

---

## 7. Technical design

### 7.1 Stack

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter 3.41, Material 3 | Single codebase, native performance |
| State | `provider` + `ChangeNotifier` | Proportionate to the app's size; no codegen |
| Database | `sqflite` | Aggregation in SQL, which the history screen needs |
| Preferences | `shared_preferences` | Right tool for a handful of scalars |
| Charts | `fl_chart` | Themeable, no styling assumptions to fight |
| Files | `file_picker` | System save/open dialogs; no storage permissions needed |
| Dates | `intl` | Locale-aware formatting |

### 7.2 Structure

Feature-based. Each feature owns its models, data access and UI. `core/` holds
what is genuinely shared and knows nothing about any feature.

```
lib/
  main.dart                 provider wiring, app entry
  app.dart                  MaterialApp, bottom-nav shell, startup loading
  core/
    theme/                  app_colors, app_spacing, app_theme
    database/               app_database — connection and schema
    utils/                  date_utils (day keys), formatters (numbers)
    widgets/                AppCard, EmptyState, StatTile, SectionHeader,
                            ProgressRing
  features/
    home/                   screens/home_screen, widgets/day_switcher
    log/                    models/food_entry, data/{entry_repository,
                            log_controller}, screens/add_food_sheet,
                            widgets/entry_tile
    products/               models/product, data/{product_repository,
                            product_controller}, screens/{products_screen,
                            product_form_screen}, widgets/product_tile
    history/                screens/history_screen, widgets/weekly_chart
    settings/               data/{settings_repository, settings_controller,
                            backup_service}, screens/settings_screen
```

Dependency rule: `features/*` may import from `core/*`. Cross-feature imports
are allowed only where a genuine dependency exists — the log feature imports the
product model, because an entry references a product.

### 7.3 Layers

```
Screen  ─ reads state via context.watch, calls methods via context.read
   │
Controller ─ ChangeNotifier, holds in-memory state, updates optimistically
   │
Repository ─ SQL, maps rows to models
   │
AppDatabase ─ owns the single sqflite connection
```

Controllers update their in-memory lists directly after a write rather than
re-querying, so the UI does not flash on every add or delete.

### 7.4 Schema

```sql
CREATE TABLE products (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT    NOT NULL,
  measure_mode  TEXT    NOT NULL,   -- 'perUnit' | 'per100g'
  unit_label    TEXT    NOT NULL,
  protein       REAL    NOT NULL,
  calories      REAL,               -- nullable: optional
  price         REAL,               -- nullable: optional
  created_at    INTEGER NOT NULL
);

CREATE TABLE entries (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  date       TEXT    NOT NULL,      -- 'yyyy-MM-dd'
  quantity   REAL    NOT NULL,
  protein    REAL    NOT NULL,      -- computed at log time
  calories   REAL    NOT NULL,
  cost       REAL    NOT NULL,
  meal       TEXT    NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
);

CREATE INDEX idx_entries_date ON entries (date);
```

`PRAGMA foreign_keys = ON` is set on every connection, so the cascade is
enforced by the database rather than by application code.

Nullable `calories` and `price` on products, `NOT NULL` on entries: the product
records "unknown", the entry records a settled number.

### 7.5 Backup format

```json
{
  "format": "daily_protein_backup",
  "version": 1,
  "exported_at": "2026-09-16T10:30:00.000",
  "products": [ /* raw product rows, ids preserved */ ],
  "entries":  [ /* raw entry rows, ids preserved */ ]
}
```

Import validates the `format` tag, then replaces all data inside a single
transaction. Each row is round-tripped through its model class on the way in, so
a malformed row throws and rolls the whole transaction back rather than writing
corrupt data.

---

## 8. Quality

### 8.1 Current state

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 16/16 passing |
| `flutter build apk --release` | Builds, 50 MB |
| Raw colours outside `core/theme` | None |

### 8.2 Test coverage

`test/protein_calculation_test.dart` covers the calculation core:

- Per-unit scaling, including zero
- Per-100 g scaling at, above and below 100 g
- Optional calories and price treated as zero in entries but null in derived metrics
- Zero-protein products excluded from cost-per-gram
- Entry snapshotting and quantity labelling
- Day totals and cost per gram, including the null cases
- Product serialisation round-trip, including nulls
- Number formatting and trailing-zero trimming

### 8.3 Known gaps

- **No widget or integration tests.** The UI is unexercised by automated tests
  and has not been run on a device or emulator. Logic is verified; presentation
  is not.
- **No schema migration path.** The database is at version 1 with no `onUpgrade`
  handler. A v2 schema change will need one written before release.
- **Backup is not versioned in practice.** The format carries a version field
  but the importer does not branch on it. Fine for v1; needs attention when the
  format changes.
- **Release build is unsigned.** Uses the debug signing config, so it is not
  Play-Store-ready as-is.

---

## 9. Future work

Ordered roughly by value against effort. None of these are committed.

1. **Composite products / recipes** — define a dish once from other products.
   The most-requested feature for an app like this, and the largest modelling
   change.
2. **Widget tests** for the calculation-critical screens, closing the gap in 8.3.
3. **Schema migrations** before any v2 data change ships.
4. **Copy a previous day** — duplicate yesterday's log for repetitive eaters.
5. **Additional macros** — carbs and fat, following the same optional-field
   pattern as calories.
6. **Home screen widget** showing the ring, with a shortcut to log food.
7. **Reminders** if the user has not logged by a chosen time.
8. **iOS build** — the codebase is portable; only `file_picker` behaviour and
   the Android-specific manifest would need review.

---

## 10. Open questions

| Question | Current answer | Revisit when |
|---|---|---|
| Should editing a product update past entries? | No — entries are snapshots (§3.3) | A user reports it as surprising |
| Should untracked days count as zero in the average? | Yes — honesty over flattery (§5.3) | User feedback suggests it demotivates |
| Is four bottom-nav destinations too many? | No — each is used daily | Usage shows one is dead weight |
