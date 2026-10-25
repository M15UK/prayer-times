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
| `test/widget/` | Tests that build screens and check what they show |
| `docs/` | Research and decisions |

More folders arrive as the app grows: `api/` for our daily timetable job, `lib/data/` for downloading and caching timetables, and `lib/screens/` for the screens.
