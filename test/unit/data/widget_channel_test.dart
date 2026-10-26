import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/widget_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.mesharialsadoun.prayer_times/widgets');
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => calls.add(call));
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('hands the payload to the Android widgets', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await publishToAndroidWidgets('{"v":1}');

    expect(calls.single.method, 'publish');
    expect(calls.single.arguments, '{"v":1}');
  });

  test('does nothing elsewhere: iOS has no widgets yet', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await publishToAndroidWidgets('{"v":1}');

    expect(calls, isEmpty);
  });
}
