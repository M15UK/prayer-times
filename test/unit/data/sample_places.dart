import 'package:prayer_times/data/place.dart';

/// Riyadh, as parsePlaces makes it from the official city list.
const riyadh = Place(
  id: 'saudi-1001',
  timetablePath: 'saudi/1001',
  nameEn: 'Riyadh',
  nameAr: 'الرياض',
  latitude: 24.67,
  longitude: 46.69,
  timeZone: 'Asia/Riyadh',
);

/// A short place list for screen tests, in the app's order.
const samplePlaces = [eastLondonMosque, london, riyadh];
