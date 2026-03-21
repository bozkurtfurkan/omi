import 'dart:async';

import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/app.dart';
import 'package:omi/providers/base_provider.dart';
import 'package:omi/utils/logger.dart';

/// Stripped of backend API calls for fully offline app.
/// App/plugin management will be local-only.
class AppProvider extends BaseProvider {
  List<App> apps = [];
  List<App> popularApps = [];
  List<Map<String, dynamic>> groupedApps = [];
  bool filterChat = true;
  bool filterMemories = true;
  bool filterExternal = true;
  String searchQuery = '';
  bool isSearching = false;

  String selectedChatAppId = 'no_selected';
  App? getSelectedApp() => null;

  Future<void> initialize() async {
    // TODO: backend removed - will load from local storage
  }

  Future<void> getApps() async {
    // TODO: backend removed
  }

  Future<bool> enableApp(String appId) async {
    // TODO: backend removed
    return false;
  }

  Future<bool> disableApp(String appId) async {
    // TODO: backend removed
    return false;
  }

  void setSelectedChatApp(String appId) {
    selectedChatAppId = appId;
    SharedPreferencesUtil().selectedChatAppId = appId;
    notifyListeners();
  }

  void clearSearchQuery() {
    searchQuery = '';
    isSearching = false;
    notifyListeners();
  }

  void setApps(List<App> newApps) {
    apps = newApps;
    notifyListeners();
  }

  bool isAppEnabled(String appId) {
    return apps.any((app) => app.id == appId && app.enabled);
  }

  bool isAppOwner(String appId) {
    return apps.any((app) => app.id == appId && app.isOwner(SharedPreferencesUtil().uid));
  }

  int getEnabledAppsCount() {
    return apps.where((app) => app.enabled).length;
  }

  Future<void> getPopularApps() async {
    // TODO: backend removed
  }

  void setAppsFromCache() {
    // TODO: backend removed
  }
}
