import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurandakimesaj/data/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TtsService meal okuma hızı normalden biraz yavaş (0.3 < rate < 0.5)',
      () async {
    double? capturedRate;
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'setSpeechRate') {
        capturedRate = (call.arguments as num).toDouble();
      }
      return 1;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await TtsService().init();

    expect(capturedRate, isNotNull, reason: 'setSpeechRate çağrılmadı');
    expect(capturedRate!, greaterThan(0.3));
    expect(capturedRate!, lessThan(0.5));
  });
}
