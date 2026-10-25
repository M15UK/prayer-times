# Prayer Times

A prayer times app for Android and iOS that takes its times from official sources and always shows where each time came from. Calculated times are only a last resort, and they are clearly labelled.

Where the times come from, and the permission to use them, is written up in [docs/sources.md](docs/sources.md).

## Run it

```bash
flutter run
```

## Test it

```bash
flutter test
```

## Folders

| Folder | What lives there |
|---|---|
| `lib/main.dart` | The app's starting point |
| `lib/l10n/` | English and Arabic text (`.arb` files) and the code Flutter makes from them |
| `lib/data/timetable.dart` | The timetable format shared by our API and the app |
| `tool/build_api.dart` | Our daily job: fetches official timetables, checks them and writes our API files |
| `.github/workflows/api.yml` | Runs that job every day and publishes the files on GitHub Pages |
| `test/unit/` | Tests for logic with no screens |
| `test/widget/` | Tests that build screens and check what they show |
| `docs/` | Research and decisions |

## Our API

Each timetable is one file per source and year, for example:

`https://m15uk.github.io/prayer-times/v1/london/2026.json`

Times are local clock times (`HH:mm`) for the time zone named in the file.
