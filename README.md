# Daily Protein

An offline Android app for tracking daily protein intake. Add the foods you eat
once with their protein content, then log a quantity and the app does the maths:
2 eggs at 6 g each is 12 g, 150 g of chicken at 27 g per 100 g is 40.5 g.

## Features

- **Two ways to measure a product** — per piece/serving (eggs, scoops, glasses)
  or per 100 g (chicken, paneer, rice). Pick whichever fits the food.
- **Auto-calculated logging** — choose a product, type or tap a quantity, and
  the protein, calories and cost update live before you save.
- **Daily goal ring** — animated progress against your target, with an overflow
  arc when you go past it.
- **Optional calories and price** — leave them blank and they are simply
  ignored; fill them in and you get calorie totals, daily spend, and cost per
  gram of protein.
- **History and charts** — 7/14/30-day bar chart against your goal line, daily
  average, days-on-target count, and a per-day list you can tap to jump back.
- **Best value protein** — ranks your priced products by cost per gram.
- **Meals** — entries group into breakfast, lunch, dinner and snack, with the
  meal guessed from the time of day.
- **Light and dark themes** — teal accent, follows the system setting by default.
- **JSON export/import** — full backup to a file you choose, and restore from it.

## Architecture

Feature-based structure. Each feature owns its models, data layer and UI.

```
lib/
  core/                     shared foundation, no feature knowledge
    theme/                  THE single source of truth for styling
      app_colors.dart       every colour in the app
      app_spacing.dart      spacing and radius scale
      app_theme.dart        builds light + dark ThemeData from the above
    database/               sqflite connection and schema
    utils/                  date keys, number formatting
    widgets/                AppCard, EmptyState, StatTile, ProgressRing, ...
  features/
    home/                   today's dashboard
    log/                    food entries, the add/edit sheet
    products/               the product catalogue
    history/                charts, trends, value insights
    settings/               goals, theme, currency, backup
```

### Theming rule

`core/theme/app_colors.dart` is the only file that declares a raw `Color`.
Everything else reads from `Theme.of(context).colorScheme`, so changing the
brand colour in one place changes the whole app in both light and dark mode.
This is enforced by convention — to check it still holds:

```bash
grep -rn "Color(0x\|Colors\." lib/ --include="*.dart" | grep -v core/theme
```

That should print nothing.

### State

`provider` with three `ChangeNotifier` controllers created in `main.dart`:

- `SettingsController` — goals, theme mode, currency (SharedPreferences)
- `ProductController` — the product catalogue (SQLite)
- `LogController` — the currently viewed day, its entries and totals (SQLite)

### Data

SQLite via `sqflite`, two tables:

- `products` — name, measure mode, unit label, protein, optional calories/price
- `entries` — product reference, day, quantity, and the **calculated**
  protein/calories/cost

Entries snapshot their nutrition at log time, so editing a product's protein
later does not silently rewrite your history. Deleting a product cascades to
its entries, and the UI warns you how many will go.

## Running

```bash
flutter pub get
flutter run                      # on a connected device or emulator
flutter test                     # calculation unit tests
flutter analyze                  # should report no issues
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
```

## Tests

`test/protein_calculation_test.dart` covers the calculation core: per-unit and
per-100g scaling, optional field handling, entry snapshotting, day totals,
cost-per-gram, serialisation round-trips and number formatting.
