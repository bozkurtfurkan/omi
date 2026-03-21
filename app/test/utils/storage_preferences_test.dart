import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omi/utils/storage_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveAudio defaults to false', () async {
    final prefs = await StoragePreferences.load();
    expect(prefs.saveAudio, false);
  });

  test('can persist saveAudio = true', () async {
    await StoragePreferences.setSaveAudio(true);
    final prefs = await StoragePreferences.load();
    expect(prefs.saveAudio, true);
  });
}
