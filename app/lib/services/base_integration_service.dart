import 'package:flutter/material.dart';

import 'package:omi/backend/preferences.dart';
import 'package:omi/utils/logger.dart';

/// Stubbed - no backend integrations for offline app.
abstract class BaseIntegrationService {
  final String appKey;
  final String prefKey;

  BaseIntegrationService({required this.appKey, required this.prefKey});

  bool get isAuthenticated {
    return SharedPreferencesUtil().getBool(prefKey) ?? false;
  }

  Future<void> refreshConnectionStatus() async {
    await checkConnection();
  }

  Future<bool> authenticate() async {
    // No-op: offline app
    Logger.debug('Integration authenticate stub for $appKey');
    return false;
  }

  Future<bool> checkConnection() async {
    // No-op: offline app
    return false;
  }

  Future<bool> disconnect() async {
    // No-op: offline app
    await SharedPreferencesUtil().saveBool(prefKey, false);
    return true;
  }
}
