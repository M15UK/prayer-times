# Third-party material

## Prayer icons (Android widgets)

The six icons on the "Prayer strip" widget are Google's Material Symbols
(Rounded style, weight 400, no fill, 24 px), from
[google/material-design-icons](https://github.com/google/material-design-icons)
(commit `10ecc14`), under the Apache License 2.0. A copy of the licence is in
[licenses/apache-2.0.txt](licenses/apache-2.0.txt).

| App file | Icon | Used for |
|---|---|---|
| `android/app/src/main/res/drawable/ic_prayer_fajr.xml` | `partly_cloudy_night` | Fajr |
| `android/app/src/main/res/drawable/ic_prayer_sunrise.xml` | `wb_twilight` | Sunrise |
| `android/app/src/main/res/drawable/ic_prayer_dhuhr.xml` | `sunny` | Dhuhr |
| `android/app/src/main/res/drawable/ic_prayer_asr.xml` | `partly_cloudy_day` | Asr |
| `android/app/src/main/res/drawable/ic_prayer_maghrib.xml` | `wb_twilight_2` | Maghrib |
| `android/app/src/main/res/drawable/ic_prayer_isha.xml` | `bedtime` | Isha |

Changes made: each file's `android:tint` line was removed (a widget can't
read the app theme's colour; the widget colours the icon itself), and a
one-line comment naming the icon and its licence was added at the top.
