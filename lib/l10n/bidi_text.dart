/// Keeping English names and signed numbers the right way round inside
/// Arabic (right-to-left) text.
library;

// Unicode isolate marks (U+2068, U+2069): they keep an English name in one
// piece inside Arabic text, so its closing ")" stays put, and keep a "+2"
// or "18.5°" from being shown as "2+" or "°18.5".
final _isolateStart = String.fromCharCode(0x2068);
final _isolateEnd = String.fromCharCode(0x2069);

/// [text] shown in its own direction, whatever the text around it.
String isolated(String text) => '$_isolateStart$text$_isolateEnd';

/// "+2", "−3" (a true minus sign) or "0", kept the right way round.
String signedMinutes(int minutes) => isolated(switch (minutes) {
  > 0 => '+$minutes',
  < 0 => '−${-minutes}',
  _ => '0',
});

/// "18°" or "18.5°", kept the right way round.
String degrees(double angle) =>
    isolated('${angle == angle.roundToDouble() ? angle.round() : angle}°');
