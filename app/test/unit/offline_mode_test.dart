import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omi/backend/preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('offlineModeEnabled', () {
    test('defaults to false', () async {
      await SharedPreferencesUtil.init();
      expect(SharedPreferencesUtil().offlineModeEnabled, false);
    });

    test('persists true after setOfflineModeEnabled(true)', () async {
      await SharedPreferencesUtil.init();
      await SharedPreferencesUtil().setOfflineModeEnabled(true);
      expect(SharedPreferencesUtil().offlineModeEnabled, true);
    });

    test('persists false after setOfflineModeEnabled(false)', () async {
      await SharedPreferencesUtil.init();
      await SharedPreferencesUtil().setOfflineModeEnabled(true);
      await SharedPreferencesUtil().setOfflineModeEnabled(false);
      expect(SharedPreferencesUtil().offlineModeEnabled, false);
    });
  });
}
