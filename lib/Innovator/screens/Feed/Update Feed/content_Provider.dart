// Content_provider.dart
// Separate updatePost() and deletePost() actions for the new API.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:innovator/Innovator/screens/Feed/Update%20Feed/API_Service.dart';
import 'package:innovator/Innovator/screens/Feed/Update%20Feed/Content_model.dart';

class ContentProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  List<ContentModel> _contents = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String _error = '';

  // ── Getters ────────────────────────────────────────────────────────────────
  List<ContentModel> get contents => List.unmodifiable(_contents);
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String get error => _error;
  bool get hasError => _error.isNotEmpty;

  // ── Seed / replace the full list (call after feed fetch) ───────────────────
  void setContents(List<ContentModel> items) {
    _contents = List.from(items);
    notifyListeners();
  }

  void addContents(List<ContentModel> items) {
    _contents.addAll(items);
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE POST
  // Calls PATCH /api/posts/<id>/ with content text + optional media file.
  // Optimistically updates the local list; rolls back on failure.
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> updatePost(
    String postId,
    String newContent, {
    File? mediaFile,
    BuildContext? context,
  }) async {
    _setUpdating(true);

    // ── Optimistic update ────────────────────────────────────────────────
    final idx = _contents.indexWhere((c) => c.id == postId);
    String? previousContent;
    if (idx != -1) {
      previousContent = _contents[idx].content;
      _contents[idx].content = newContent;
      notifyListeners();
    }

    try {
      final success = await ApiService.updateContent(
        postId,
        newContent,
        mediaFile: mediaFile,
        context: context,
      );

      if (success) {
        // Mark updated timestamp locally
        if (idx != -1) {
          _contents[idx] = _contents[idx].copyWith(content: newContent);
        }
        _setUpdating(false);
        return true;
      } else {
        // Roll back optimistic change
        if (idx != -1 && previousContent != null) {
          _contents[idx].content = previousContent;
        }
        _error = 'Failed to update post.';
        _setUpdating(false);
        return false;
      }
    } catch (e) {
      // Roll back
      if (idx != -1 && previousContent != null) {
        _contents[idx].content = previousContent;
      }
      _error = e.toString();
      _setUpdating(false);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE POST
  // Calls DELETE /api/posts/<id>/.
  // Removes from the local list on success.
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> deletePost(String postId, {BuildContext? context}) async {
    _setDeleting(true);

    try {
      final success = await ApiService.deleteFiles(postId, context: context);

      if (success) {
        _contents.removeWhere((c) => c.id == postId);
        _setDeleting(false);
        return true;
      } else {
        _error = 'Failed to delete post.';
        _setDeleting(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setDeleting(false);
      return false;
    }
  }

  // ── Backward-compat wrappers (keep existing callers working) ──────────────

  /// Legacy alias — calls [updatePost] without a media file.
  Future<bool> updateContentStatus(
    String id,
    String newStatus, {
    BuildContext? context,
  }) => updatePost(id, newStatus, context: context);

  /// Legacy alias — calls [deletePost].
  Future<bool> deleteFiles(String postId, {BuildContext? context}) =>
      deletePost(postId, context: context);

  // ── Private helpers ────────────────────────────────────────────────────────
  void _setUpdating(bool v) {
    _isUpdating = v;
    _isLoading = v;
    notifyListeners();
  }

  void _setDeleting(bool v) {
    _isDeleting = v;
    _isLoading = v;
    notifyListeners();
  }
}
