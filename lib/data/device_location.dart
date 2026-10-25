/// The only code that talks to the phone's location and time zone. It has
/// no logic of its own, so everything else can be tested with fakes. The
/// exact position never leaves the phone (only the nearest official
/// place's timetable is downloaded).
library;

import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';

import 'package:prayer_times/data/place.dart';

/// Long enough for a first approximate fix, short enough not to keep the
/// user waiting.
const _fixTimeout = Duration(seconds: 10);

/// The phone's approximate (city-level) position, asking permission first
/// if needed. Null if permission is refused, location is switched off, or
/// no fix comes in time and the phone remembers none.
Future<GeoPoint?> approximatePosition() async {
  try {
    return await _approximatePosition();
  } on LocationServiceDisabledException {
    return null; // switched off while waiting for a fix
  } on PermissionDeniedException {
    return null;
  } on PermissionRequestInProgressException {
    return null;
  } on ActivityMissingException {
    return null;
  } on PositionUpdateException {
    return null;
  }
}

Future<GeoPoint?> _approximatePosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  final current = await Geolocator.checkPermission();
  final permission = current == LocationPermission.denied
      ? await Geolocator.requestPermission()
      : current;
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  final position =
      await _freshPosition() ?? await Geolocator.getLastKnownPosition();
  return position == null
      ? null
      : (latitude: position.latitude, longitude: position.longitude);
}

/// A fresh low-accuracy fix, or null if none comes in time.
Future<Position?> _freshPosition() async {
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: _fixTimeout,
      ),
    );
  } on TimeoutException {
    return null; // fall back to the last position the phone remembers
  }
}

/// The phone's IANA time zone, e.g. "Europe/London".
Future<String> phoneTimeZoneName() async =>
    (await FlutterTimezone.getLocalTimezone()).identifier;
