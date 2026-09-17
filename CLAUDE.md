# Daily Protein — working rules

Offline Android protein tracker. Flutter 3.41 / Dart 3.11, `provider` +
`ChangeNotifier`, `sqflite`.

---

## 1. Commits

**Never add co-author or attribution lines.** No `Co-Authored-By`, no
"Generated with…" footer, in commit messages or PR descriptions.

Commit split by feature, not one lump. Use `db:`, `feat:`, `fix:`, `ui:`,
`test:`, `docs:` prefixes.

Message bodies record **why**, not what — the diff already says what. Worth
writing down: a non-obvious trade-off, a constraint that forced the approach,
a bug whose cause differed from its symptom.

Do not commit or push unless asked. Never commit `build/`, `.apk`, keystores
or anything with credentials.

---

## 2. Colour and theme: one source of truth

`lib/core/theme/app_colors.dart` is the **only** file allowed to declare a
raw `Color`. Everything else reads from `Theme.of(context).colorScheme`, or
from `AppIconColors.of(context)` for per-row icon tints.

`lib/core/theme/app_spacing.dart` plays the same role for spacing and radii.
No loose magic numbers for padding or corners.

Verify before committing — this must print nothing:

```bash
grep -rnE "Color\(0x|Colors\.[a-z]" lib/ --include="*.dart" | grep -v core/theme
```

`AppIconColors` is the theme-resolving helper, not a raw colour — the word
boundary above keeps it out of the results.

### Both themes are first class

Light and dark each get their own values; neither is derived from the other.
A colour that works on a dark ground often fails on white — the accent
`#F59E0B` reaches only 2.15:1 there. When that happens, add a light variant
rather than compromising the dark one.

### Contrast is checked, not eyeballed

Before shipping a colour pairing, compute the WCAG ratio against the surface
it actually paints on, composing any translucent tint over its background
first. Targets: **4.5:1** for text, **3:1** for icons and other UI marks.

`test/theme_palette_test.dart` and `test/settings_icon_contrast_test.dart`
enforce this. Extend them when adding a colour.

---

## 3. Feature-based structure

```
lib/
  core/            shared foundation, knows nothing about any feature
    theme/         app_colors, app_spacing, app_theme
    database/      connection and schema
    services/      image storage and similar
    utils/         date keys, number formatting
    widgets/       AppCard, EmptyState, StatTile, ProgressRing, …
  features/
    home/ log/ products/ history/ settings/
      models/      plain data classes
      data/        repositories (SQL) and controllers (ChangeNotifier)
      screens/     full pages
      widgets/     parts used only by this feature
```

**Dependency rule:** `features/*` may import from `core/*`. `core/*` must
never import from `features/*`. Cross-feature imports are allowed only for a
genuine dependency — the log feature imports the product model because an
entry references a product.

A widget used by two features moves to `core/widgets/`. A widget used by one
stays in that feature.

### Layers

```
Screen      reads state via context.watch, calls methods via context.read
Controller  ChangeNotifier; in-memory state, updates optimistically
Repository  SQL, maps rows to models
AppDatabase owns the single sqflite connection
```

Controllers update their in-memory lists after a write rather than
re-querying, so the UI does not flash on every change.

---

## 4. Database changes

The schema has a version and an `onUpgrade`. **Both must be updated together**
— a change to `onCreate` without a matching migration step silently wipes
existing installs on upgrade.

- Bump `AppDatabase.schemaVersion`
- Add a `if (from < N)` block in `_upgrade`
- New columns are nullable, so existing rows survive
- Seed data comes from one shared helper called by both paths, so a fresh
  install and an upgrade cannot drift apart

---

## 5. Verifying work

Before saying something is done:

```bash
flutter analyze   # must report no issues
flutter test      # must pass
```

### Measure, do not guess

Layout bugs get measured. Several bugs in this project survived a first fix
because the fix was aimed at an assumed cause:

- Chart labels "did not overlap" because the test measured widget boxes,
  which are padded and wider than the glyphs. Measure painted text with a
  `TextPainter`.
- A button was assumed to be stretching; it was 418px of content on a 369px
  screen. The label was too long, not the constraints.
- An axis font size set via `labelSmall?.copyWith(fontSize: …)` did nothing,
  because `labelSmall` resolved to null and `?.` swallowed it.

### A test must be able to fail

After writing a regression test, break the fix and confirm the test fails
with a useful message. A test that passes both ways is worse than none.

### UI is not verified by tests alone

`flutter analyze` and a passing suite have repeatedly been clean while the
screen was visibly wrong. Say plainly what has and has not been run on a
device, and do not describe a screen as verified when only its logic is.

---

## 6. Code style

- `flutter_lints`, explicit types on declarations, trailing commas
- `const` wherever possible
- Comments explain **why**, not what. A comment restating the code is noise;
  one explaining a non-obvious constraint earns its place
- Doc-comment public classes and any method whose behaviour is not obvious
  from its name
- British spelling in comments and identifiers (`colour`), matching the
  existing code

---

## 7. Product rules worth preserving

These are decisions, not accidents. Changing them is a product call.

- **Entries snapshot their nutrition** at log time. Editing a product later
  does not rewrite past days.
- **Optional means absent, not zero.** A product with no price is excluded
  from cost-per-gram rather than counted as free.
- **Averages count untracked days as zero.** An average over only the logged
  days would flatter the user.
- **No future days.** They cannot be viewed or logged.
- **Photos are copied into app storage**, never referenced in place, so a
  cleared gallery cannot break them.
- **Backups exclude photo paths**, which are not portable between devices.

See `PRD.md` for the full specification.
