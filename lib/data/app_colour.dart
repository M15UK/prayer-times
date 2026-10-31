import 'package:flutter/material.dart';

/// The Android 12+ widgets' colours (ARGB): the card, the pill behind the
/// next prayer, the text on that pill, and the prayer icons.
typedef WidgetColours = ({int card, int pill, int onPill, int icon});

/// The app's colour, chosen in Settings. Saved by name, so never rename
/// these. [wallpaper] uses the phone's own colours where Android offers
/// them (Android 12+); elsewhere it is teal.
enum AppColour {
  teal(Colors.teal),
  blue(Colors.blue),
  green(Colors.green),
  purple(Colors.purple),
  amber(Colors.amber),
  wallpaper(Colors.teal);

  const AppColour(this.seed);

  /// The colour the whole app grows from.
  final Color seed;

  /// The widgets' colours, or null where the widget decides: teal keeps its
  /// hand-picked colours, and wallpaper reads the phone's palette itself so
  /// it follows a new wallpaper without the app.
  WidgetColours? get widgetColours => switch (this) {
    teal || wallpaper => null,
    _ => _fromSeed(seed),
  };
}

// A very dark tone of the colour for the card (like the teal widgets), a
// very light one for the pill, and a soft one for the icons.
WidgetColours _fromSeed(Color seed) {
  final scheme = ColorScheme.fromSeed(seedColor: seed);
  return (
    card: scheme.onPrimaryFixed.toARGB32(),
    pill: scheme.primaryFixed.toARGB32(),
    onPill: scheme.onPrimaryFixed.toARGB32(),
    icon: scheme.primaryFixedDim.toARGB32(),
  );
}
