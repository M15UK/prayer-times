/// Fetches the official Umm al-Qura prayer timetables for every Saudi city
/// from ummulqura.org.sa (with KACST's permission, see docs/sources.md),
/// checks them and writes them in our format:
/// - `<outDir>/v1/saudi/cities.json`
/// - `<outDir>/v1/saudi/<cityId>/<year>.json` (this year and next)
///
/// The site calculates its tables in the browser, so a hidden Chrome opens
/// each city's page and reads the table, just as a person would.
///
/// Run:  dart run tool/fetch_umm_al_qura.dart [outDir] [cityId ...]
/// Uses the test-only Chrome version the puppeteer package pins (downloaded
/// to .local-chrome), the same one the Riyadh check was made with, unless
/// CHROME_PATH names another.
library;

import 'dart:convert';
import 'dart:io';

import 'package:puppeteer/puppeteer.dart';

import 'package:prayer_times/data/http_get.dart';
import 'package:prayer_times/data/timetable.dart';

import 'build_api.dart' show checkFullYear;

const _site = 'https://www.ummulqura.org.sa';

/// The credit agreed with KACST.
const _sourceName = 'Umm al-Qura Calendar';

const _pageTimeout = Duration(seconds: 60);

/// A pause between cities, to go easy on their website.
const _pauseBetweenCities = Duration(seconds: 2);

/// What the job needs to know about a city to read its page.
typedef UmmAlQuraCity = ({int id, String nameEn});

Future<void> main(List<String> args) async {
  final outDir = args.isEmpty ? 'api' : args.first;
  final onlyIds = args.skip(1).map(int.parse).toSet();
  final response = await httpGet(Uri.parse('$_site/assets/data/cities.json'));
  if (response.status != HttpStatus.ok) {
    throw HttpException('HTTP ${response.status} for the city list');
  }
  final cities = parseUmmAlQuraCities(jsonDecode(response.body));
  await _writeJson('$outDir/v1/saudi/cities.json', cities);

  final years = [DateTime.now().year, DateTime.now().year + 1];
  final browser = await puppeteer.launch(
    executablePath:
        Platform.environment['CHROME_PATH'] ??
        (await downloadChrome(cachePath: '.local-chrome')).executablePath,
  );
  try {
    final page = await browser.newPage();
    for (final city in cities) {
      final id = city['id'] as int;
      if (onlyIds.isNotEmpty && !onlyIds.contains(id)) continue;
      final nameEn = city['nameEn'] as String;
      for (final year in years) {
        final rows = await _readYearTable(page, (id: id, nameEn: nameEn), year);
        await _writeYear(outDir, id, year, parseUmmAlQuraYear(rows, year));
      }
      stdout.writeln('$nameEn ($id): ${years.join(' and ')} written');
      await Future<void>.delayed(_pauseBetweenCities);
    }
  } finally {
    await browser.close();
  }
}

/// The address the site uses for a city: "Al 'Is" → "al-is".
String citySlug(String nameEn) =>
    nameEn.trim().toLowerCase().replaceAll("'", '').replaceAll(' ', '-');

final _twelveHour = RegExp(r'^(0[1-9]|1[0-2]):([0-5]\d) (AM|PM)$');

/// The page's 12-hour times in 24-hour form: "06:47 PM" → "18:47".
String to24Hour(String time) {
  final match = _twelveHour.firstMatch(time);
  if (match == null) throw FormatException('Not a 12-hour time: "$time"');
  final [hourText, minute, period] = match.groups([1, 2, 3]);
  final hour = int.parse(hourText ?? '') % 12 + (period == 'PM' ? 12 : 0);
  return '${hour.toString().padLeft(2, '0')}:$minute';
}

const _months = {
  'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, //
  'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
};
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', //
  'Sunday',
];
final _gregorianDate = RegExp(r'^([A-Z][a-z]{2}) (\d{1,2})$');

/// Reads the day rows of the site's yearly table (Day, Gregorian date,
/// Hijri date, then the six times) and skips heading rows.
///
/// Throws [FormatException] if anything looks wrong, so bad data is never
/// published.
Map<String, DayTimes> parseUmmAlQuraYear(List<List<String>> rows, int year) =>
    Map.fromEntries(
      rows
          .where((row) => row.length == 9 && _gregorianDate.hasMatch(row[1]))
          .map((row) => _parseDayRow(row, year)),
    );

MapEntry<String, DayTimes> _parseDayRow(List<String> row, int year) {
  final [weekday, gregorian, _, ...times] = row;
  final [monthName, dayText] = gregorian.split(' ');
  final iso =
      '$year-${(_months[monthName] ?? 0).toString().padLeft(2, '0')}'
      '-${dayText.padLeft(2, '0')}';
  if (!isIsoDate(iso)) throw FormatException('Not a real date: $gregorian');
  // A table for another year would have different weekdays. Only the first
  // word counts: the page adds a "Today" badge to the current day.
  final expected = _weekdays[DateTime.parse(iso).weekday - 1];
  if (weekday.split(' ').first != expected) {
    throw FormatException('$iso is a $expected, not $weekday: wrong year?');
  }
  final start = {
    for (final (index, prayer) in Prayer.values.indexed)
      prayer: to24Hour(times[index]),
  };
  if (!startTimesInOrder(start)) {
    throw FormatException('$iso: times out of order: $start');
  }
  return MapEntry(iso, DayTimes(start: start));
}

/// Throws unless the page is about [city]. An unknown address quietly
/// shows Makkah instead ("Prayer times in Mecca"), which must never be
/// saved under another city.
void checkCityHeading(String heading, UmmAlQuraCity city) {
  final expected = 'prayer times in ${city.nameEn.toLowerCase()},';
  if (!heading.toLowerCase().startsWith(expected)) {
    throw FormatException(
      'Expected ${city.nameEn}, but the page shows '
      '"$heading"',
    );
  }
}

/// The official city list, reduced to what the app needs. Throws
/// [FormatException] if any city lacks an id, names or coordinates.
List<Map<String, Object>> parseUmmAlQuraCities(Object? json) {
  if (json is! List || json.isEmpty) {
    throw const FormatException('Expected a list of cities');
  }
  return [
    for (final city in json)
      if (city case {
        'id': final int id,
        'name_en': final String nameEn,
        'name_ar': final String nameAr,
        'latitude': final num latitude,
        'longitude': final num longitude,
      })
        {
          'id': id,
          'nameEn': nameEn,
          'nameAr': nameAr,
          'latitude': latitude.toDouble(),
          'longitude': longitude.toDouble(),
        }
      else
        throw FormatException('City without id, names or coordinates: $city'),
  ];
}

Future<void> _writeYear(
  String outDir,
  int cityId,
  int year,
  Map<String, DayTimes> days,
) async {
  checkFullYear(year, days.keys);
  final timetable = Timetable(
    sourceId: 'umm-al-qura',
    sourceName: _sourceName,
    timeZone: 'Asia/Riyadh', // all of Saudi Arabia, no clock changes
    days: days,
  );
  await _writeJson('$outDir/v1/saudi/$cityId/$year.json', timetable.toJson());
}

Future<void> _writeJson(String path, Object data) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(data));
}

/// Opens [city]'s page, asks for the Gregorian [year] in the year view, and
/// returns the table's rows as text.
Future<List<List<String>>> _readYearTable(
  Page page,
  UmmAlQuraCity city,
  int year,
) async {
  await page.goto(
    '$_site/en/prayer-times/${citySlug(city.nameEn)}',
    wait: Until.domContentLoaded,
  );
  await page.waitForFunction(
    _jsHasButton,
    args: ['Change Location and View Options'],
    timeout: _pageTimeout,
  );
  checkCityHeading(await _heading(page), city);
  for (final label in [
    'Change Location and View Options',
    'Gregorian',
    'Year',
  ]) {
    await _click(page, label);
  }
  await _clickOrFail(page, _jsOpenYearList, [], 'the year list');
  await _clickOrFail(page, _jsClickOption, ['$year'], 'year $year');
  await _click(page, 'Show prayer times');
  await page.waitForFunction(
    r'() => document.querySelectorAll("table tr").length > 365',
    timeout: _pageTimeout,
  );
  // Again after the table appears, in case the panel showed another city.
  checkCityHeading(await _heading(page), city);
  final rows = await page.evaluate<List<dynamic>>(_jsTableRows);
  return [
    for (final row in rows) [for (final cell in row as List<dynamic>) '$cell'],
  ];
}

Future<String> _heading(Page page) async =>
    await page.evaluate<String?>(_jsHeading) ?? '';

Future<void> _click(Page page, String label) =>
    _clickOrFail(page, _jsClickText, [label], '"$label"');

/// Runs [script], which clicks something and returns whether it found it.
/// Throws if not: the page has changed and this job needs updating.
Future<void> _clickOrFail(
  Page page,
  String script,
  List<Object> args,
  String what,
) async {
  final clicked = await page.evaluate<bool>(script, args: args);
  if (!clicked) {
    throw FormatException(
      'No $what on the page: has ummulqura.org.sa changed?',
    );
  }
  await Future<void>.delayed(const Duration(milliseconds: 500));
}

// JavaScript run inside the page. "Visible" means it has a box on screen
// (getClientRects), which also works inside the pinned options panel.
const _jsHasButton = r'''(label) => [...document.querySelectorAll("button")]
  .some(b => b.innerText && b.innerText.trim() === label)''';

const _jsHeading = r'''() => [...document.querySelectorAll("h1, h2, h3")]
  .map(e => e.innerText.trim()).find(t => /^Prayer times in/i.test(t)) || null''';

/// Clicks the innermost visible element whose text is exactly the label.
const _jsClickText = r'''(label) => {
  const all = [...document.querySelectorAll(
    'button, [role="button"], label, span, div, a, li')].reverse();
  const match = all.find(e => e.getClientRects().length > 0 &&
    e.innerText && e.innerText.trim() === label);
  if (!match) return false;
  match.click();
  return true;
}''';

/// Opens the "Gregorian year" drop-down (its label is the year, e.g. 2026).
const _jsOpenYearList = r'''() => {
  const box = [...document.querySelectorAll('[role="combobox"]')]
    .find(e => e.getClientRects().length > 0 &&
      /^\d{4}$/.test((e.getAttribute("aria-label") || "").trim()));
  if (!box) return false;
  box.click();
  return true;
}''';

const _jsClickOption = r'''(label) => {
  const option = [...document.querySelectorAll('[role="option"]')]
    .find(o => o.innerText.trim() === label);
  if (!option) return false;
  option.click();
  return true;
}''';

const _jsTableRows = r'''() => [...document.querySelectorAll("table tr")]
  .map(r => [...r.cells].map(c => c.innerText.trim().replace(/\s+/g, " ")))''';
