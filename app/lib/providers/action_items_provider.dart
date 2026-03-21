import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:omi/backend/schema/schema.dart';

/// Stubbed out - action items API removed for fully offline app.
/// Will be backed by local DB in Task 6.
class ActionItemsProvider extends ChangeNotifier {
  List<ActionItemWithMetadata> _actionItems = [];

  bool _isLoading = false;
  bool _isFetching = false;
  bool _hasMore = false;
  bool _includeCompleted = true;
  bool _showCompletedView = false;
  bool _isSelectionMode = false;
  Set<String> _selectedItems = {};

  List<ActionItemWithMetadata> get actionItems => _actionItems;
  bool get isLoading => _isLoading;
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  bool get includeCompleted => _includeCompleted;
  bool get showCompletedView => _showCompletedView;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedItems => _selectedItems;
  int get selectedCount => _selectedItems.length;
  bool get hasSelection => _selectedItems.isNotEmpty;

  List<ActionItemWithMetadata> get incompleteItems => _actionItems.where((item) => item.completed == false).toList();
  List<ActionItemWithMetadata> get completedItems => _actionItems.where((item) => item.completed == true).toList();
  List<ActionItemWithMetadata> get todoItems => incompleteItems;
  List<ActionItemWithMetadata> get doneItems => completedItems;
  List<ActionItemWithMetadata> get snoozedItems => [];

  Future<void> fetchActionItems({bool showShimmer = false}) async {
    // TODO: backend removed - will load from local DB in Task 6
  }

  Future<void> loadMoreActionItems() async {
    // TODO: backend removed
  }

  Future<void> updateActionItemState(ActionItemWithMetadata item, bool newState) async {
    final index = _actionItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _actionItems[index] = _actionItems[index].copyWith(completed: newState);
      notifyListeners();
    }
  }

  Future<void> updateActionItemDescription(ActionItemWithMetadata item, String newDescription) async {
    final index = _actionItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _actionItems[index] = _actionItems[index].copyWith(description: newDescription);
      notifyListeners();
    }
  }

  Future<void> updateActionItemDueDate(ActionItemWithMetadata item, DateTime? dueDate) async {
    final index = _actionItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _actionItems[index] = _actionItems[index].copyWith(dueAt: dueDate);
      notifyListeners();
    }
  }

  Future<bool> deleteActionItem(ActionItemWithMetadata item) async {
    _actionItems.removeWhere((actionItem) => actionItem.id == item.id);
    notifyListeners();
    return true;
  }

  Future<ActionItemWithMetadata?> createActionItem({
    required String description,
    DateTime? dueAt,
    String? conversationId,
    bool completed = false,
  }) async {
    final item = ActionItemWithMetadata(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      completed: completed,
      dueAt: dueAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      conversationId: conversationId,
    );
    _actionItems.insert(0, item);
    notifyListeners();
    return item;
  }

  void toggleCompletedActionItems() {
    _includeCompleted = !_includeCompleted;
    notifyListeners();
  }

  void toggleShowCompletedView() {
    _showCompletedView = !_showCompletedView;
    notifyListeners();
  }

  void updateItemSortOrder(String id, int sortOrder) {
    notifyListeners();
  }

  void updateItemIndentLevel(String id, int indentLevel) {
    notifyListeners();
  }

  void batchUpdateSortOrders(Map<String, int> updates) {
    notifyListeners();
  }

  Future<void> refreshActionItems() async {}
  Future<void> forceRefreshActionItems() async {}
  Future<int> clearTodayDeadlinesForIncompleteTasks() async => 0;

  void startSelection() {
    _isSelectionMode = true;
    _selectedItems.clear();
    notifyListeners();
  }

  void endSelection() {
    _isSelectionMode = false;
    _selectedItems.clear();
    notifyListeners();
  }

  void toggleItemSelection(String itemId) {
    if (_selectedItems.contains(itemId)) {
      _selectedItems.remove(itemId);
    } else {
      _selectedItems.add(itemId);
    }
    notifyListeners();
  }

  void selectItem(String itemId) {
    _selectedItems.add(itemId);
    notifyListeners();
  }

  void deselectItem(String itemId) {
    _selectedItems.remove(itemId);
    notifyListeners();
  }

  void selectAllItems() {
    _selectedItems = _actionItems.map((i) => i.id).toSet();
    notifyListeners();
  }

  void selectAllItemsFromTab(int tabIndex) {
    notifyListeners();
  }

  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }

  bool isItemSelected(String itemId) => _selectedItems.contains(itemId);

  Future<bool> deleteSelectedItems() async {
    _actionItems.removeWhere((item) => _selectedItems.contains(item.id));
    _selectedItems.clear();
    _isSelectionMode = false;
    notifyListeners();
    return true;
  }

  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {}
  void clearDateRangeFilter() {}
}
