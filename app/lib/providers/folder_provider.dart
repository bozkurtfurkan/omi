import 'package:flutter/material.dart';

import 'package:omi/backend/schema/folder.dart';

/// Stubbed out - folder API removed for fully offline app.
class FolderProvider extends ChangeNotifier {
  List<Folder> _folders = [];
  String? _selectedFolderId;
  bool _isLoading = false;
  String? _error;

  List<Folder> get folders => _folders;
  String? get selectedFolderId => _selectedFolderId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFolders() async {
    // TODO: backend removed - will load from local DB
  }

  Future<void> createFolder(String name, {String? emoji}) async {
    // TODO: backend removed
  }

  Future<void> updateFolder(String folderId, {String? name, String? emoji}) async {
    // TODO: backend removed
  }

  Future<void> deleteFolder(String folderId) async {
    // TODO: backend removed
  }

  Future<void> moveConversationToFolder(String conversationId, String? folderId) async {
    // TODO: backend removed
  }

  Future<void> bulkMoveConversationsToFolder(List<String> conversationIds, String? folderId) async {
    // TODO: backend removed
  }

  Folder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
