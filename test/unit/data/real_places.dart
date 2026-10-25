import 'dart:convert';
import 'dart:io';

import 'package:prayer_times/data/place.dart';

/// Every place the app offers, from the real city list it bundles.
List<Place> realPlaces() => parsePlaces(
  jsonDecode(File('api/v1/saudi/cities.json').readAsStringSync()),
);
