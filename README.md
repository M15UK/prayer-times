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
| `lib/data/timetable.dart` | The timetable format shared by our API and the app, with its checks |
| `lib/data/timetable_repository.dart` | Downloads timetables and keeps a copy on the phone for offline use |
| `lib/data/prayer_clock.dart` | Turns clock times into real moments: next prayer and countdown, across clock changes |
| `lib/data/saved_setting.dart` | A user choice saved on the phone (Asr time, language) |
| `lib/l10n/app_language.dart` | The language options: the phone's language, English or Arabic |
| `lib/screens/` | The screens: today's times, and settings |
| `tool/build_api.dart` | Our daily job: fetches official timetables, checks them and writes our API files |
| `tool/fetch_umm_al_qura.dart` | Our yearly job: reads every Saudi city's official Umm al-Qura timetable |
| `api/` | The Saudi timetables that job fetched, published with the rest |
| `lib/data/calculated_timetable.dart` | Times calculated on the phone, only where no official timetable exists |
| `.github/workflows/api.yml` | Runs that job every day and publishes the files on GitHub Pages |
| `test/unit/` | Tests for logic with no screens |
| `test/widget/` | Tests that build screens and check what they show |
| `docs/` | Research and decisions |

## Our API

Each timetable is one file per place and year, for example:

| Place | File |
|---|---|
| London (London Unified Prayer Timetable, updated daily) | `https://m15uk.github.io/prayer-times/v1/london/2026.json` |
| A Saudi city (Umm al-Qura Calendar, fetched yearly) | `https://m15uk.github.io/prayer-times/v1/saudi/1001/2026.json` (1001 is Riyadh) |
| The list of Saudi cities, with Arabic and English names and coordinates | `https://m15uk.github.io/prayer-times/v1/saudi/cities.json` |

Times are local clock times (`HH:mm`) for the time zone named in the file.

The Saudi files live in `api/`, written by `tool/fetch_umm_al_qura.dart` (run yearly by `.github/workflows/umm_al_qura.yml`). The London files are built fresh every day. Each publish copies `api/` first and adds London on top.
