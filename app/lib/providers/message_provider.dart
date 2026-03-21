import 'package:flutter/material.dart';

import 'package:omi/backend/schema/app.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/providers/app_provider.dart';

/// Stubbed out - no cloud messaging needed for fully offline app.
class MessageProvider extends ChangeNotifier {
  AppProvider? appProvider;
  List<ServerMessage> messages = [];

  bool isLoadingMessages = false;
  bool hasCachedMessages = false;
  bool isClearingChat = false;
  bool showTypingIndicator = false;
  bool sendingMessage = false;
  double aiStreamProgress = 1.0;
  bool agentThinkingAfterText = false;

  String firstTimeLoadingText = '';

  List<App> chatApps = [];
  bool isLoadingChatApps = false;

  void updateAppProvider(AppProvider p) {
    appProvider = p;
  }

  void startVmKeepalive() {
    // No-op: offline app
  }

  void stopVmKeepalive() {
    // No-op: offline app
  }

  void setChatApps(List<App> apps) {
    chatApps = apps;
    notifyListeners();
  }

  void removeChatApp(String appId) {
    chatApps.removeWhere((app) => app.id == appId);
    notifyListeners();
  }

  Future<void> fetchChatApps() async {
    // No-op: offline app
  }

  Future<void> refreshMessages({bool dropdownSelected = false}) async {
    // No-op: offline app
  }

  void setMessagesFromCache() {
    // No-op: offline app
  }

  void addMessage(ServerMessage message) {
    messages.insert(0, message);
    notifyListeners();
  }

  Future<void> sendInitialAppMessage(App app) async {
    // No-op: offline app
  }

  Future<void> clearChat() async {
    messages.clear();
    notifyListeners();
  }

  Future<void> preConnectAgent() async {
    // No-op: offline app
  }
}
