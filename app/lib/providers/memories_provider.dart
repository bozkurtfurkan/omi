import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:omi/backend/schema/memory.dart';
import 'package:omi/providers/connectivity_provider.dart';

/// Stubbed out - memories API removed for fully offline app.
class MemoriesProvider extends ChangeNotifier {
  List<Memory> _memories = [];
  bool _loading = true;
  ConnectivityProvider? _connectivityProvider;
  String _searchQuery = '';
  Set<MemoryCategory> _selectedCategories = {};

  List<Memory> get memories => _memories;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  Set<MemoryCategory> get selectedCategories => _selectedCategories;

  List<Memory> get filteredMemories {
    var result = _memories;
    if (_searchQuery.isNotEmpty) {
      result = result.where((m) => m.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedCategories.isNotEmpty) {
      result = result.where((m) => _selectedCategories.contains(m.category)).toList();
    }
    return result;
  }

  void setConnectivityProvider(ConnectivityProvider p) {
    _connectivityProvider = p;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleCategory(MemoryCategory category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  Future<void> loadMemories() async {
    // TODO: backend removed - will load from local DB
    _loading = false;
    notifyListeners();
  }

  Future<void> init() async {
    await loadMemories();
  }

  Future<bool> restoreLastDeletedMemory() async {
    // TODO: backend removed
    return false;
  }

  void confirmPendingDeletion() {
    // TODO: backend removed
  }

  Future<void> deleteAllMemories() async {
    _memories.clear();
    notifyListeners();
  }

  Future<void> deleteMemory(Memory memory) async {
    _memories.remove(memory);
    notifyListeners();
  }

  Future<void> updateMemory(Memory memory) async {
    // TODO: backend removed
    notifyListeners();
  }

  Future<void> createMemory(String content, {MemoryCategory? category}) async {
    // TODO: backend removed - will save to local DB
    notifyListeners();
  }
}
