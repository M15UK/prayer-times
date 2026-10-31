import 'package:flutter/material.dart';

import 'package:prayer_times/data/app_colour.dart';

/// The app's look for [colour] in [brightness]. [wallpaper] is the phone's
/// own colour scheme, used for AppColour.wallpaper when the phone gives one
/// (Android 12+); otherwise that choice is teal.
ThemeData appTheme(
  AppColour colour,
  Brightness brightness,
  ColorScheme? wallpaper,
) => colour == AppColour.wallpaper && wallpaper != null
    ? ThemeData(colorScheme: wallpaper)
    : ThemeData(colorSchemeSeed: colour.seed, brightness: brightness);
