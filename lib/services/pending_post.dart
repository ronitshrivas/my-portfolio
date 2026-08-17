import 'dart:typed_data';

/// A post the user submitted that is uploading in the background, Instagram
/// style. Held by the app shell so the composer can close immediately and the
/// feed can show a "posting…" card while the upload runs.
class PendingPost {
  PendingPost({
    required this.content,
    required this.categoryIds,
    required this.media,
    this.status = PendingPostStatus.uploading,
  });

  final String content;
  final List<String> categoryIds;
  final List<({Uint8List bytes, String filename})> media;

  PendingPostStatus status;

  /// First image's bytes, for the posting-card thumbnail (null if text-only).
  Uint8List? get previewBytes => media.isNotEmpty ? media.first.bytes : null;
}

enum PendingPostStatus { uploading, failed }
