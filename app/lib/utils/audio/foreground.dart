// flutter_foreground_task removed — not needed for offline build
class ForegroundUtil {
  static Future<void> initializeForegroundTask() async {}
  static Future<void> startForegroundTask() async {}
  static Future<void> stopForegroundTask() async {}
  static Future<bool> get isIgnoringBatteryOptimizations async => true;
}
