/// How times are shown: as the phone shows them, or always 12- or 24-hour.
/// Saved by name, so never rename these.
enum ClockFormat {
  phone(null),
  twelveHour(false),
  twentyFourHour(true);

  const ClockFormat(this.forced24Hour);

  /// Null when following the phone.
  final bool? forced24Hour;

  /// Whether to show 24-hour times, given the phone's own setting.
  bool resolve({required bool phoneIs24Hour}) => forced24Hour ?? phoneIs24Hour;
}
