import 'package:flutter/material.dart';

import 'package:omi/utils/debugging/crash_reporter.dart';

/// Stubbed CrashlyticsManager - no Firebase Crashlytics for offline app.
class CrashlyticsManager implements CrashReporter {
  static final CrashlyticsManager _instance = CrashlyticsManager._internal();
  CrashlyticsManager._internal();

  static CrashlyticsManager get instance => _instance;

  static Future<void> init() async {
    // No-op: offline app
  }

  @override
  void identifyUser(String email, String name, String userId) {}

  @override
  void logInfo(String message) {}

  @override
  void logError(String message) {}

  @override
  void logWarn(String message) {}

  @override
  void logDebug(String message) {}

  @override
  void logVerbose(String message) {}

  @override
  void setUserAttribute(String key, String value) {}

  @override
  void setEnabled(bool isEnabled) {}

  @override
  Future<void> reportCrash(Object exception, StackTrace stackTrace, {Map<String, String>? userAttributes}) async {}

  @override
  NavigatorObserver? getNavigatorObserver() => null;

  @override
  bool get isSupported => false;
}
