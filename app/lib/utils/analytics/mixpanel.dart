/// Stubbed MixpanelManager - all analytics calls are no-ops for offline app.
class MixpanelManager {
  static final MixpanelManager _instance = MixpanelManager._internal();

  factory MixpanelManager() => _instance;
  MixpanelManager._internal();

  static Future<void> init() async {}

  // Use noSuchMethod to handle any remaining calls as no-ops
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  // All analytics methods - no-ops for offline app.
  // Methods use permissive signatures to match all calling patterns.
  void track(String eventName, {Map<String, dynamic>? properties}) {}
  void setUserProperty(String key, dynamic value) {}
  void identifyUser() {}
  void optInTracking() {}
  void optOutTracking() {}
  void startTimingEvent(String eventName) {}
  void onboardingDeviceConnected() {}
  void onboardingCompleted() {}
  void onboardingStepCompleted(String step) {}
  void pageOpened(String name) {}
  void phoneMicRecordingStarted() {}
  void phoneMicRecordingStopped() {}
  void showDiscardedMemoriesToggled(bool value) {}
  void settingsSaved({bool hasWebhookConversationCreated = false, bool hasWebhookTranscriptReceived = false}) {}
  void conversationCreated(dynamic conversation) {}
  void conversationMergeSelectionModeEntered() {}
  void conversationMergeSelectionModeExited() {}
  void conversationSelectedForMerge(String id, int count) {}
  void conversationMergeInitiated(List<String> ids) {}
  void conversationMergeFailed(List<String> ids) {}
  void conversationMergeCompleted(String mergedId, List<String> removedIds) {}
  void deviceConnected() {}
  void deviceDisconnected() {}
  void setUserAttribute(String key, dynamic value) {}

  void announcementDismissed({dynamic announcementId}) {}
  void announcementShown({dynamic announcementId}) {}
  void audioPlaybackPaused({dynamic conversationId, dynamic positionSeconds}) {}
  void audioPlaybackSeeked({dynamic conversationId, dynamic toPositionSeconds, dynamic seekPositionSeconds}) {}
  void audioPlaybackStarted({dynamic conversationId, dynamic positionSeconds, dynamic segmentStartSeconds}) {}
  void audioShareCompleted({dynamic conversationId, dynamic audioFileCount, dynamic wasCombined, dynamic durationSeconds}) {}
  void audioShareFailed({dynamic conversationId, dynamic errorMessage}) {}
  void audioShareStarted({dynamic conversationId, dynamic audioFileCount}) {}
  void batteryIndicatorClicked({dynamic source}) {}
  void bottomNavigationTabClicked([dynamic tab]) {}
  void calendarFilterApplied({dynamic date}) {}
  void calendarFilterCleared() {}
  void checkedActionItem({dynamic conversationId, dynamic priority}) {}
  void connectDevicePageOpened() {}
  void connectFriendClicked() {}
  void connectionGuideDeviceTapped({dynamic source}) {}
  void connectionGuideDismissed() {}
  void connectionGuideOpened() {}
  void connectionGuideReportIssue() {}
  void conversationDetailFolderChipClicked({dynamic conversationId, dynamic folderId, dynamic folderName}) {}
  void conversationDetailSearchClicked() {}
  void conversationDetailSearchQueryEntered({dynamic conversationId, dynamic query, dynamic resultsCount, dynamic activeTab}) {}
  void conversationDetailTabChanged([dynamic tab]) {}
  void conversationDisplaySettingsOpened() {}
  void conversationListItemClicked([dynamic conversation]) {}
  void conversationListItemClickedWithTimeDifference([dynamic conversation, dynamic hoursSinceConversation]) {}
  void conversationMovedToFolder({dynamic conversationId, dynamic fromFolderId, dynamic toFolderId, dynamic folderName}) {}
  void conversationOpenedFromSearch({dynamic conversationId, dynamic searchQuery, dynamic conversationIndexInResults, dynamic conversationIndex}) {}
  void conversationShared({dynamic conversation, dynamic shareMethod}) {}
  void conversationStarToggled({dynamic conversation, dynamic starred, dynamic source}) {}
  void conversationSwipedToDelete({dynamic conversationId}) {}
  void conversationThreeDotsMenuActionSelected({dynamic conversationId, dynamic action}) {}
  void conversationThreeDotsMenuOpened({dynamic conversationId}) {}
  void conversationVisibilityChanged({dynamic conversationId, dynamic fromVisibility, dynamic toVisibility, dynamic isPublic}) {}
  void copiedConversationDetails({dynamic conversationId}) {}
  void createFolderButtonClicked() {}
  void dailySummaryNotificationOpened() {}
  void deletedActionItem({dynamic conversationId, dynamic priority}) {}
  void disconnectFriendClicked() {}
  void editSegmentTextCancelled({dynamic conversationId}) {}
  void editSegmentTextSaved({dynamic conversationId}) {}
  void editSegmentTextStarted({dynamic conversationId}) {}
  void exportMemories() {}
  void folderContextMenuOpened({dynamic folderId, dynamic folderName}) {}
  void folderDeleted({dynamic folderId, dynamic folderName, dynamic conversationCount}) {}
  void folderSelected({dynamic folderId, dynamic folderName, dynamic conversationCount}) {}
  Map<String, dynamic> getConversationEventProperties([dynamic conversation]) => {};
  void memoriesManagementSheetOpened() {}
  void memoriesPageCreateMemoryBtn() {}
  void memoryListItemClicked([dynamic memory]) {}
  void memorySearchCleared([dynamic resultCount]) {}
  void memorySearched([dynamic query, dynamic resultCount]) {}
  void omiDoubleTap({dynamic feature}) {}
  void onboardingUserAcquisitionSource([dynamic source]) {}
  void paywallOpened({dynamic source}) {}
  void quickTemplateCreated({dynamic conversationId, dynamic appName}) {}
  void reProcessConversation([dynamic conversation]) {}
  void recapTabOpened() {}
  void searchBarFocused() {}
  void searchQueryCleared() {}
  void searchQueryEntered([dynamic query]) {}
  void setPeopleValues([dynamic people]) {}
  void setUserProperties([dynamic user]) {}
  void shareToContactsSelected({dynamic conversationId}) {}
  void shareToContactsSheetOpened({dynamic conversationId}) {}
  void shareToContactsSmsOpened({dynamic conversationId}) {}
  void shortConversationThresholdChanged({dynamic enabled}) {}
  void showDiscardedConversationsToggled([dynamic value]) {}
  void showShortConversationsToggled([dynamic value]) {}
  void starredFilterToggled([dynamic value]) {}
  void summarizedAppCreateTemplateClicked({dynamic conversationId, dynamic currentSummarizedAppId}) {}
  void summarizedAppEnableAppsClicked({dynamic conversationId, dynamic currentSummarizedAppId}) {}
  void summarizedAppSelected({dynamic conversationId, dynamic selectedAppId, dynamic previousAppId}) {}
  void summarizedAppSheetViewed({dynamic conversationId, dynamic currentSummarizedAppId}) {}
  void tagSheetOpened({dynamic conversationId, dynamic summaryId}) {}
  void taggedSegment({dynamic conversationId}) {}
  void transcriptSegmentTapped({dynamic conversationId}) {}
  void transcriptionProviderSelected({dynamic provider}) {}
  void transcriptionSourceSelected({dynamic source}) {}
  void uncheckedActionItem({dynamic conversationId, dynamic priority}) {}
  void useWithoutDeviceOnboardingFindDevices() {}
}

/// Stub AnalyticsManager for files that import it
class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._internal();
  factory AnalyticsManager() => _instance;
  AnalyticsManager._internal();

  void setUserAttribute(String key, dynamic value) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
