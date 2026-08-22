import 'dart:typed_data';

/// A post the user submitted that is uploading in the background, Instagram
/// style. Held by the app shell so the composer can close immediately and the
/// feed can show a "posting…" card while the upload runs.
class PendingPost {
  PendingPost({
    required this.content,
    required this.categoryIds,
    required this.media,
    this.imagePreviewBytes,
    this.videoPreviewPath,
    this.status = PendingPostStatus.uploading,
  });

  final String content;
  final List<String> categoryIds;
  final List<({Uint8List bytes, String filename})> media;

  /// First IMAGE's bytes for the posting-card thumbnail (null if none).
  final Uint8List? imagePreviewBytes;

  /// First VIDEO's local path for a first-frame thumbnail (null if none).
  final String? videoPreviewPath;

  PendingPostStatus status;

  Uint8List? get previewBytes => imagePreviewBytes;
}

enum PendingPostStatus { uploading, failed }
