import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The line to the Android widgets (MainActivity.kt listens on it).
const _channel = MethodChannel('com.mesharialsadoun.prayer_times/widgets');

/// Hands the widget payload to the Android widgets, which save it and redraw.
/// iOS has no widgets yet.
Future<void> publishToAndroidWidgets(String json) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await _channel.invokeMethod<void>('publish', json);
}
