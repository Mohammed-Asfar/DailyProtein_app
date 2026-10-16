# Play Store listing

Copy each block into Play Console → Grow → Store presence → Main store listing.
Limits are Play's; `python store/check_listing.py` confirms each fits.

## App name (max 30)

```
Daily Protein: Protein Tracker
```

## Short description (max 80)

```
Track daily protein, calories and food cost. Offline, private, no account.
```

## Full description (max 4000)

```
Hit your protein goal every day, without an account, ads or an internet connection.

Daily Protein is a simple, private protein tracker. Add the foods you eat once with their protein content, then log how much you had. The app does the maths: 3 eggs, 150 g of chicken or a scoop of whey becomes grams of protein instantly.

WHY DAILY PROTEIN
• Built for speed: pick a food, set the amount, done
• Works completely offline. No account, no sign-in
• No ads, no tracking, no analytics
• Your data never leaves your phone

TRACK YOUR DAY
• Goal ring shows how close you are to today's protein target
• See calories and money spent alongside protein
• Meals group into breakfast, lunch, dinner and snack, guessed from the time
• Look back at any past day

FOODS YOUR WAY
• 21 common foods included to get you started, from eggs and paneer to lentils and whey
• Add your own foods with a photo or emoji
• Measure per piece (eggs, scoops, glasses) or per 100 g (chicken, rice)
• Calories and price are optional: fill them in only if you want them

SEE YOUR PROGRESS
• 7, 14 and 30 day charts against your goal line
• Daily average and how many days you hit your target
• Total spent and cost per gram of protein
• Best value protein: find which of your foods gives the most protein for your money

YOUR DATA, YOUR CONTROL
• Export a full backup to a file you choose, and restore it any time
• Delete everything from Settings whenever you like
• Light and dark themes

Daily Protein is for general tracking only and is not medical or nutritional advice.
```

## Other fields

| Field | Value |
|---|---|
| App category | Health & Fitness |
| Tags | Fitness tracking, Nutrition |
| Privacy policy URL | https://github.com/Mohammed-Asfar/DailyProtein_app/blob/main/PRIVACY.md |
| Contains ads | No |

## Data safety form

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not applicable (nothing is collected) |
| Do you provide a way for users to request that their data is deleted? | Data never leaves the device; Settings → Clear All Data deletes it |

Why "No" is accurate: the app requests no internet permission, so it cannot
send data anywhere. Data stored only on the device does not count as
collected under Play's definition.

## Content rating questionnaire

Category: **Utility, Productivity, Communication or Other**. Answer "No" to
violence, sexual content, language, controlled substances, gambling, user
interaction, sharing location and digital purchases. Expected rating:
Everyone / PEGI 3.

## Target audience

**18 and over** (or 13+). Choosing an age group that includes under-13s
brings in Google's Families policy requirements, which this app does not need.

## Graphics

All in `store/play/` after running the two commands in
`store/render_screens_test.dart`:

| Asset | File |
|---|---|
| App icon (512×512) | `icon_512.png` |
| Feature graphic (1024×500) | `feature_graphic.png` |
| Phone screenshots (1080×1920) | `1_today.png` … `4_settings.png` |
