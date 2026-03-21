import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/backend/schema/structured.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/logger.dart';

class ConversationProvider extends ChangeNotifier {
  List<ServerConversation> conversations = [];
  List<ServerConversation> searchedConversations = [];
  Map<DateTime, List<ServerConversation>> groupedConversations = {};

  bool isLoadingConversations = false;
  bool showDiscardedConversations = false;
  bool showShortConversations = false;
  int shortConversationThreshold = 0;
  bool showStarredOnly = false;
  bool showDailySummaries = false;
  bool hasDailySummaries = false;
  DateTime? selectedDate;
  String? selectedFolderId;

  String previousQuery = '';
  int totalSearchPages = 1;
  int currentSearchPage = 1;

  Timer? _processingConversationWatchTimer;
  Timer? _refreshDebounceTimer;

  List<ServerConversation> processingConversations = [];

  Set<String> mergingConversationIds = {};
  bool isSelectionModeActive = false;
  Set<String> selectedConversationIds = {};

  bool isFetchingConversations = false;

  void resetGroupedConvos() {
    groupConversationsByDate();
  }

  void updateSpecificGroupedConvo(ServerConversation convo, DateTime date, int idx) {
    groupedConversations[date]![idx] = convo;
    notifyListeners();
  }

  Future<void> searchConversations(String query, {bool showShimmer = false}) async {
    // TODO: backend removed - search will be local in Task 6
    previousQuery = query;
    notifyListeners();
  }

  Future<void> searchMoreConversations() async {
    // TODO: backend removed
  }

  int groupedSearchConvoIndex(ServerConversation convo) {
    var convoDate = convo.startedAt ?? convo.createdAt;
    var date = DateTime(convoDate.year, convoDate.month, convoDate.day);
    if (groupedConversations.containsKey(date)) {
      return groupedConversations[date]!.indexWhere((element) => element.id == convo.id);
    }
    return -1;
  }

  void addProcessingConversation(ServerConversation conversation) {
    processingConversations.add(conversation);
    notifyListeners();
  }

  void removeProcessingConversation(String conversationId) {
    processingConversations.removeWhere((m) => m.id == conversationId);
    notifyListeners();
  }

  void onConversationTap(String conversationId) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    if (conversations[idx].isNew) {
      conversations[idx].isNew = false;
      groupConversationsByDate();
    }
  }

  void toggleDiscardConversations() {
    showDiscardedConversations = !showDiscardedConversations;
    groupedConversations = {};
    notifyListeners();
    fetchConversations();
    MixpanelManager().showDiscardedMemoriesToggled(showDiscardedConversations);
  }

  void toggleShortConversations() {
    showShortConversations = !showShortConversations;
    groupedConversations = {};
    notifyListeners();
    fetchConversations();
  }

  void setShortConversationThreshold(int seconds) {
    shortConversationThreshold = seconds;
    groupedConversations = {};
    notifyListeners();
    fetchConversations();
  }

  void toggleStarredFilter() {
    showStarredOnly = !showStarredOnly;
    if (showStarredOnly) {
      showDailySummaries = false;
    }
    groupedConversations = {};
    notifyListeners();
    fetchConversations();
  }

  void toggleDailySummaries() {
    showDailySummaries = !showDailySummaries;
    if (showDailySummaries) {
      showStarredOnly = false;
      selectedFolderId = null;
    }
    notifyListeners();
  }

  Future<void> checkHasDailySummaries() async {
    // TODO: backend removed
    hasDailySummaries = false;
    notifyListeners();
  }

  Future<void> filterByFolder(String? folderId) async {
    if (selectedFolderId == folderId) return;
    selectedFolderId = folderId;
    showDailySummaries = false;
    previousQuery = "";
    searchedConversations = [];
    groupedConversations = {};
    notifyListeners();
    await fetchConversations();
  }

  void setLoadingConversations(bool value) {
    isLoadingConversations = value;
    notifyListeners();
  }

  Future refreshConversations() async {
    // TODO: backend removed - will load from local DB in Task 6
  }

  Future forceRefreshConversations() async {
    // TODO: backend removed
  }

  Future fetchConversations() async {
    // TODO: backend removed - will load from local DB in Task 6
    setLoadingConversations(true);
    // For now, conversations list is empty until local DB is set up
    setLoadingConversations(false);
    _groupConversationsByDateWithoutNotify();
    notifyListeners();
  }

  Future getInitialConversations() async {
    await fetchConversations();
  }

  List<ServerConversation> _filterOutConvos(List<ServerConversation> convos) {
    return convos.where((convo) {
      if (!showDiscardedConversations && convo.discarded) return false;
      if (!showShortConversations) {
        final durationSeconds = convo.getDurationInSeconds();
        if (durationSeconds < shortConversationThreshold) return false;
      }
      if (showStarredOnly && !convo.starred) return false;
      if (selectedDate != null) {
        var effectiveDate = convo.startedAt ?? convo.createdAt;
        var convoDate = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
        var filterDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        if (convoDate != filterDate) return false;
      }
      if (selectedFolderId != null && convo.folderId != selectedFolderId) return false;
      return true;
    }).toList();
  }

  Future<void> filterConversationsByDate(DateTime date) async {
    selectedDate = date;
    groupedConversations = {};
    notifyListeners();
    await fetchConversations();
  }

  Future<void> clearDateFilter() async {
    selectedDate = null;
    groupedConversations = {};
    notifyListeners();
    await fetchConversations();
  }

  void _groupConversationsByDateWithoutNotify() {
    groupedConversations = {};
    for (var conversation in _filterOutConvos(conversations)) {
      var effectiveDate = conversation.startedAt ?? conversation.createdAt;
      var date = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
      if (!groupedConversations.containsKey(date)) {
        groupedConversations[date] = [];
      }
      groupedConversations[date]?.add(conversation);
    }
    for (final date in groupedConversations.keys) {
      groupedConversations[date]?.sort((a, b) => (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt));
    }
  }

  void groupConversationsByDate() {
    _groupConversationsByDateWithoutNotify();
    notifyListeners();
  }

  void groupSearchConvosByDate() {
    groupedConversations = {};
    for (var conversation in _filterOutConvos(searchedConversations)) {
      var effectiveDate = conversation.startedAt ?? conversation.createdAt;
      var date = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
      if (!groupedConversations.containsKey(date)) {
        groupedConversations[date] = [];
      }
      groupedConversations[date]?.add(conversation);
    }
    for (final date in groupedConversations.keys) {
      groupedConversations[date]?.sort((a, b) => (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt));
    }
    notifyListeners();
  }

  void updateActionItemState(String convoId, bool state, int i, DateTime date) {
    conversations.firstWhere((element) => element.id == convoId).structured.actionItems[i].completed = state;
    groupedConversations[date]!.firstWhere((element) => element.id == convoId).structured.actionItems[i].completed =
        state;
    notifyListeners();
  }

  Future getMoreConversationsFromServer() async {
    // TODO: backend removed
  }

  Future<void> addConversation(ServerConversation conversation) async {
    conversations.insert(0, conversation);
    _groupConversationsByDateWithoutNotify();
    notifyListeners();
  }

  void upsertConversation(ServerConversation conversation) {
    int idx = conversations.indexWhere((m) => m.id == conversation.id);
    if (idx < 0) {
      addConversation(conversation);
    } else {
      updateConversation(conversation, idx);
    }
  }

  void updateConversationInSortedList(ServerConversation conversation) {
    var effectiveDate = conversation.startedAt ?? conversation.createdAt;
    var date = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
    if (groupedConversations.containsKey(date)) {
      int idx = groupedConversations[date]!.indexWhere((element) => element.id == conversation.id);
      if (idx != -1) {
        groupedConversations[date]![idx] = conversation;
      }
    }
    notifyListeners();
  }

  (int, DateTime) addConversationWithDateGrouped(ServerConversation conversation) {
    conversations.insert(0, conversation);
    conversations.sort((a, b) => (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt));
    int idx;
    var effectiveDate = conversation.startedAt ?? conversation.createdAt;
    var memDate = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
    if (groupedConversations.containsKey(memDate)) {
      var convoEffectiveDate = conversation.startedAt ?? conversation.createdAt;
      idx = groupedConversations[memDate]!.indexWhere(
        (element) => (element.startedAt ?? element.createdAt).isBefore(convoEffectiveDate),
      );
      if (idx == -1) {
        groupedConversations[memDate]!.insert(0, conversation);
        idx = 0;
      } else {
        groupedConversations[memDate]!.insert(idx, conversation);
      }
    } else {
      groupedConversations[memDate] = [conversation];
      groupedConversations = Map.fromEntries(
        groupedConversations.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
      );
      idx = 0;
    }
    return (idx, memDate);
  }

  void updateConversation(ServerConversation conversation, [int? index]) {
    if (index != null) {
      conversations[index] = conversation;
    } else {
      int i = conversations.indexWhere((element) => element.id == conversation.id);
      if (i != -1) {
        conversations[i] = conversation;
      }
    }
    conversations.sort((a, b) => (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt));
    _groupConversationsByDateWithoutNotify();
    notifyListeners();
  }

  Map<String, ServerConversation> memoriesToDelete = {};
  String? lastDeletedConversationId;
  Map<String, DateTime> deleteTimestamps = {};

  void deleteConversationLocally(ServerConversation conversation, int index, DateTime date) {
    memoriesToDelete[conversation.id] = conversation;
    lastDeletedConversationId = conversation.id;
    deleteTimestamps[conversation.id] = DateTime.now();
    conversations.removeWhere((element) => element.id == conversation.id);
    groupedConversations[date]!.removeAt(index);
    if (groupedConversations[date]!.isEmpty) {
      groupedConversations.remove(date);
    }
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (memoriesToDelete.containsKey(conversation.id) && lastDeletedConversationId == conversation.id) {
        _finalizeDelete(conversation.id);
      }
    });
  }

  void _finalizeDelete(String conversationId) {
    // TODO: backend removed - will delete from local DB in Task 6
    memoriesToDelete.remove(conversationId);
    deleteTimestamps.remove(conversationId);
    if (lastDeletedConversationId == conversationId) {
      lastDeletedConversationId = null;
    }
  }

  void undoDeletedConversation(ServerConversation conversation) {
    if (!conversations.any((e) => e.id == conversation.id)) {
      conversations.add(conversation);
      conversations.sort((a, b) => (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt));
      _groupConversationsByDateWithoutNotify();
    }
    memoriesToDelete.remove(conversation.id);
    deleteTimestamps.remove(conversation.id);
    if (lastDeletedConversationId == conversation.id) {
      lastDeletedConversationId = null;
    }
    notifyListeners();
  }

  void deleteConversation(ServerConversation conversation) {
    conversations.removeWhere((element) => element.id == conversation.id);
    searchedConversations.removeWhere((element) => element.id == conversation.id);
    // TODO: backend removed - will delete from local DB in Task 6
    groupConversationsByDate();
  }

  @override
  void dispose() {
    _processingConversationWatchTimer?.cancel();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  void updateSearchedConvoDetails(dynamic conversation) {
    // TODO: backend removed
    notifyListeners();
  }

  void setIsFetchingConversations(bool value) {
    isFetchingConversations = value;
    notifyListeners();
  }

  Map<ServerConversation, List<ActionItem>> get conversationsWithActiveActionItems {
    final Map<ServerConversation, List<ActionItem>> result = {};
    for (final convo in conversations) {
      if (convo.discarded && !showDiscardedConversations) continue;
      final activeItems = convo.structured.actionItems.where((item) => !item.deleted).toList();
      if (activeItems.isNotEmpty) {
        result[convo] = activeItems;
      }
    }
    return result;
  }

  Future<void> updateGlobalActionItemState(
    ServerConversation conversation,
    String actionItemDescription,
    bool newState,
  ) async {
    final convoId = conversation.id;

    final originalConvoIndex = conversations.indexWhere((c) => c.id == convoId);
    if (originalConvoIndex != -1) {
      final itemIndex = conversations[originalConvoIndex].structured.actionItems.indexWhere(
        (item) => item.description == actionItemDescription,
      );
      if (itemIndex != -1) {
        conversations[originalConvoIndex].structured.actionItems[itemIndex].completed = newState;
      }
    }

    var effectiveDate = conversation.startedAt ?? conversation.createdAt;
    var dateKey = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
    if (groupedConversations.containsKey(dateKey)) {
      final groupIndex = groupedConversations[dateKey]!.indexWhere((c) => c.id == convoId);
      if (groupIndex != -1) {
        final itemIndex = groupedConversations[dateKey]![groupIndex].structured.actionItems.indexWhere(
          (item) => item.description == actionItemDescription,
        );
        if (itemIndex != -1) {
          groupedConversations[dateKey]![groupIndex].structured.actionItems[itemIndex].completed = newState;
        }
      }
    }
    // TODO: backend removed - will persist to local DB in Task 6
    notifyListeners();
  }

  void updateActionItemDescriptionInConversation(String conversationId, int itemIndex, String newDescription) {
    final convoIndex = conversations.indexWhere((c) => c.id == conversationId);
    if (convoIndex != -1 && conversations[convoIndex].structured.actionItems.length > itemIndex) {
      conversations[convoIndex].structured.actionItems[itemIndex].description = newDescription;
    }

    groupedConversations.forEach((date, convoList) {
      final groupIndex = convoList.indexWhere((c) => c.id == conversationId);
      if (groupIndex != -1 && convoList[groupIndex].structured.actionItems.length > itemIndex) {
        convoList[groupIndex].structured.actionItems[itemIndex].description = newDescription;
      }
    });

    notifyListeners();
  }

  Future<void> deleteActionItemAndUpdateLocally(String conversationId, int itemIndex, ActionItem actionItem) async {
    // TODO: backend removed - will persist to local DB in Task 6

    final convoIndex = conversations.indexWhere((c) => c.id == conversationId);
    if (convoIndex != -1 && conversations[convoIndex].structured.actionItems.length > itemIndex) {
      conversations[convoIndex].structured.actionItems.removeAt(itemIndex);
    }

    groupedConversations.forEach((date, convoList) {
      final groupConvoIndex = convoList.indexWhere((c) => c.id == conversationId);
      if (groupConvoIndex != -1 && convoList[groupConvoIndex].structured.actionItems.length > itemIndex) {
        convoList[groupConvoIndex].structured.actionItems.removeAt(itemIndex);
      }
    });

    notifyListeners();
  }

  (DateTime, int)? getConversationDateAndIndex(ServerConversation conversation) {
    final effectiveDate = conversation.startedAt ?? conversation.createdAt;
    final date = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
    final list = groupedConversations[date];
    if (list == null) return null;
    final idx = list.indexWhere((e) => e.id == conversation.id);
    if (idx == -1) return null;
    return (date, idx);
  }

  int getConversationIndexById(String id, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final list = groupedConversations[normalizedDate] ?? [];
    return list.indexWhere((c) => c.id == id);
  }

  ({ServerConversation conversation, DateTime date})? getAdjacentConversation(
    String currentConversationId,
    DateTime currentDate,
    int direction,
  ) {
    if (groupedConversations.isEmpty) return null;
    final sortedDates = groupedConversations.keys.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return null;
    final normalizedDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final dateIndex = sortedDates.indexWhere(
      (d) => d.year == normalizedDate.year && d.month == normalizedDate.month && d.day == normalizedDate.day,
    );
    if (dateIndex == -1) return null;
    final currentDayList = groupedConversations[sortedDates[dateIndex]] ?? [];
    final convoIndexInDay = currentDayList.indexWhere((c) => c.id == currentConversationId);
    if (convoIndexInDay == -1) return null;

    if (direction == 1) {
      if (convoIndexInDay < currentDayList.length - 1) {
        return (conversation: currentDayList[convoIndexInDay + 1], date: sortedDates[dateIndex]);
      } else if (dateIndex < sortedDates.length - 1) {
        final nextDate = sortedDates[dateIndex + 1];
        final nextDayList = groupedConversations[nextDate] ?? [];
        if (nextDayList.isNotEmpty) return (conversation: nextDayList.first, date: nextDate);
      }
    } else if (direction == -1) {
      if (convoIndexInDay > 0) {
        return (conversation: currentDayList[convoIndexInDay - 1], date: sortedDates[dateIndex]);
      } else if (dateIndex > 0) {
        final prevDate = sortedDates[dateIndex - 1];
        final prevDayList = groupedConversations[prevDate] ?? [];
        if (prevDayList.isNotEmpty) return (conversation: prevDayList.last, date: prevDate);
      }
    }
    return null;
  }

  void updateSyncedConversation(ServerConversation conversation) {
    updateConversationInSortedList(conversation);
    notifyListeners();
  }

  bool isConversationMerging(String conversationId) {
    return mergingConversationIds.contains(conversationId);
  }

  void enterSelectionMode() {
    isSelectionModeActive = true;
    selectedConversationIds.clear();
    notifyListeners();
  }

  void exitSelectionMode() {
    isSelectionModeActive = false;
    selectedConversationIds.clear();
    notifyListeners();
  }

  List<String> markSelectedAsMergingAndExit() {
    final idsToMerge = selectedConversationIds.toList();
    mergingConversationIds.addAll(idsToMerge);
    isSelectionModeActive = false;
    selectedConversationIds.clear();
    notifyListeners();
    return idsToMerge;
  }

  void toggleConversationSelection(String conversationId) {
    if (isConversationMerging(conversationId)) return;
    if (selectedConversationIds.contains(conversationId)) {
      selectedConversationIds.remove(conversationId);
      if (selectedConversationIds.isEmpty) isSelectionModeActive = false;
    } else {
      selectedConversationIds.add(conversationId);
    }
    notifyListeners();
  }

  bool isConversationSelected(String conversationId) {
    return selectedConversationIds.contains(conversationId);
  }

  List<ServerConversation> get selectedConversations {
    final selected = conversations.where((c) => selectedConversationIds.contains(c.id)).toList();
    selected.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return selected;
  }

  bool isConversationEligibleForMerge(String conversationId) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return false;
    final convo = conversations[idx];
    if (convo.isLocked) return false;
    if (mergingConversationIds.contains(conversationId)) return false;
    return true;
  }

  bool get canMerge => selectedConversationIds.length >= 2;

  Future<void> onMergeCompleted(String mergedConversationId, List<String> removedConversationIds) async {
    mergingConversationIds.remove(mergedConversationId);
    for (final id in removedConversationIds) {
      mergingConversationIds.remove(id);
    }
    for (final id in removedConversationIds) {
      conversations.removeWhere((c) => c.id == id);
    }
    _groupConversationsByDateWithoutNotify();
    notifyListeners();
  }
}
