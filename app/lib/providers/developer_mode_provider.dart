import 'package:flutter/material.dart';

import 'package:omi/backend/preferences.dart';
import 'package:omi/providers/base_provider.dart';

/// Stripped of backend webhook/agent calls for fully offline app.
/// Keeps local preference toggles that affect app behavior.
class DeveloperModeProvider extends BaseProvider {
  final TextEditingController webhookOnConversationCreated = TextEditingController();
  final TextEditingController webhookOnTranscriptReceived = TextEditingController();
  final TextEditingController webhookAudioBytes = TextEditingController();
  final TextEditingController webhookAudioBytesDelay = TextEditingController();
  final TextEditingController webhookWsAudioBytes = TextEditingController();
  final TextEditingController webhookDaySummary = TextEditingController();

  bool conversationEventsToggled = false;
  bool transcriptsToggled = false;
  bool audioBytesToggled = false;
  bool daySummaryToggled = false;

  bool savingSettingsLoading = false;

  bool loadingExportMemories = false;
  bool loadingImportMemories = false;

  bool followUpQuestionEnabled = false;
  bool transcriptionDiagnosticEnabled = false;
  bool autoCreateSpeakersEnabled = false;
  bool showGoalTrackerEnabled = true;
  bool showDailyScoreEnabled = true;
  bool showTasksEnabled = true;
  bool dailyReflectionEnabled = true;

  bool vadGateEnabled = false;
  bool claudeAgentEnabled = false;
  bool claudeAgentLoading = false;

  Future initialize() async {
    setIsLoading(true);
    final prefs = SharedPreferencesUtil();
    followUpQuestionEnabled = prefs.devModeJoanFollowUpEnabled;
    transcriptionDiagnosticEnabled = prefs.transcriptionDiagnosticEnabled;
    autoCreateSpeakersEnabled = prefs.autoCreateSpeakersEnabled;
    showGoalTrackerEnabled = prefs.showGoalTrackerEnabled;
    showDailyScoreEnabled = prefs.showDailyScoreEnabled;
    showTasksEnabled = prefs.showTasksEnabled;
    dailyReflectionEnabled = prefs.dailyReflectionEnabled;
    vadGateEnabled = prefs.vadGateEnabled;
    setIsLoading(false);
    notifyListeners();
  }

  void saveSettings() async {
    if (savingSettingsLoading) return;
    setIsLoading(true);
    final prefs = SharedPreferencesUtil();
    prefs.devModeJoanFollowUpEnabled = followUpQuestionEnabled;
    prefs.transcriptionDiagnosticEnabled = transcriptionDiagnosticEnabled;
    prefs.autoCreateSpeakersEnabled = autoCreateSpeakersEnabled;
    prefs.showGoalTrackerEnabled = showGoalTrackerEnabled;
    prefs.showDailyScoreEnabled = showDailyScoreEnabled;
    prefs.showTasksEnabled = showTasksEnabled;
    setIsLoading(false);
    notifyListeners();
  }

  void setIsLoading(bool value) {
    savingSettingsLoading = value;
    notifyListeners();
  }

  void onFollowUpQuestionChanged(var value) {
    followUpQuestionEnabled = value;
    notifyListeners();
  }

  void onTranscriptionDiagnosticChanged(var value) {
    transcriptionDiagnosticEnabled = value;
    notifyListeners();
  }

  void onAutoCreateSpeakersChanged(var value) {
    autoCreateSpeakersEnabled = value;
    notifyListeners();
  }

  void onShowGoalTrackerChanged(var value) {
    showGoalTrackerEnabled = value;
    SharedPreferencesUtil().showGoalTrackerEnabled = value;
    notifyListeners();
  }

  void onShowDailyScoreChanged(var value) {
    showDailyScoreEnabled = value;
    SharedPreferencesUtil().showDailyScoreEnabled = value;
    notifyListeners();
  }

  void onShowTasksChanged(var value) {
    showTasksEnabled = value;
    SharedPreferencesUtil().showTasksEnabled = value;
    notifyListeners();
  }

  void onDailyReflectionChanged(var value) {
    dailyReflectionEnabled = value;
    SharedPreferencesUtil().dailyReflectionEnabled = value;
    notifyListeners();
  }

  void onVadGateChanged(bool value) {
    vadGateEnabled = value;
    SharedPreferencesUtil().vadGateEnabled = value;
    notifyListeners();
  }

  Future<void> onClaudeAgentChanged(bool value) async {
    // No-op: offline app
  }

  void Function(bool)? get onConversationEventsToggled => (bool value) {
    conversationEventsToggled = value;
    notifyListeners();
  };

  void Function(bool)? get onTranscriptsToggled => (bool value) {
    transcriptsToggled = value;
    notifyListeners();
  };

  void Function(bool)? get onAudioBytesToggled => (bool value) {
    audioBytesToggled = value;
    notifyListeners();
  };

  void Function(bool)? get onDaySummaryToggled => (bool value) {
    daySummaryToggled = value;
    notifyListeners();
  };
}
