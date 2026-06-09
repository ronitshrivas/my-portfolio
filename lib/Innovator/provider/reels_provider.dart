// ─── reels_provider.dart ─────────────────────────────────────────────────────
// Place at: lib/Innovator/provider/reels_provider.dart
// Uses: Deezer Public API — No API key, No server required
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// ─── ReelsMusicTrack ─────────────────────────────────────────────────────────

@immutable
class ReelsMusicTrack {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? albumArt;
  final int durationSeconds;
  final String genre;
  final String language;

  const ReelsMusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.albumArt,
    required this.durationSeconds,
    this.genre = '',
    this.language = '',
  });

  // ── Parse from Deezer /search response ──────────────────────────────────────
  factory ReelsMusicTrack.fromDeezer(Map<String, dynamic> json) {
    final preview = (json['preview'] as String? ?? '').trim();

    // Album art — prefer xl, fallback to big, then medium
    String? albumArt;
    final album = json['album'] as Map<String, dynamic>?;
    if (album != null) {
      albumArt =
          (album['cover_xl'] ??
                  album['cover_big'] ??
                  album['cover_medium'] ??
                  '')
              as String?;
      if (albumArt != null && albumArt.isEmpty) albumArt = null;
    }

    // Artist name
    final artistObj = json['artist'] as Map<String, dynamic>?;
    final artistName = _clean(artistObj?['name'] ?? 'Unknown Artist');

    // Title
    final title = _clean(json['title'] ?? json['title_short'] ?? 'Unknown');

    // Duration — Deezer gives full duration in seconds
    final duration = (json['duration'] as int? ?? 30);

    // Detect language from artist/title
    final lang = _detectLang(title, artistName);

    return ReelsMusicTrack(
      id: json['id']?.toString() ?? '',
      title: title,
      artist: artistName,
      audioUrl: preview, // 30-second preview MP3 — direct playable URL
      albumArt: albumArt,
      durationSeconds: duration > 30 ? 30 : duration, // preview is always 30s
      genre: _langToGenre(lang),
      language: lang,
    );
  }

  // ── Language detection based on known artist/title keywords ─────────────────
  static String _detectLang(String title, String artist) {
    final combined = '${title.toLowerCase()} ${artist.toLowerCase()}';

    const punjabiKeywords = [
      'ap dhillon',
      'sidhu moosewala',
      'diljit dosanjh',
      'imran khan',
      'hardy sandhu',
      'gurnam bhullar',
      'karan aujla',
      'shubh',
      'ikky',
      'parmish verma',
      'jasmine sandlas',
      'mankirt aulakh',
      'jass manak',
      'punjabi',
      'pendu',
      'chandigarh',
    ];
    const hindiKeywords = [
      'arijit singh',
      'jubin nautiyal',
      'neha kakkar',
      'atif aslam',
      'shreya ghoshal',
      'sonu nigam',
      'armaan malik',
      'badshah',
      'honey singh',
      'raftaar',
      'divine',
      'mc stan',
      'nucleya',
      'vishal mishra',
      'bollywood',
      'hindi',
      'filmi',
      'ishq',
      'pyaar',
      'dil',
    ];
    const tamilKeywords = [
      'anirudh',
      'sid sriram',
      'ar rahman',
      'harris jayaraj',
      'yuvan',
      'tamil',
      'kollywood',
    ];
    const teluguKeywords = [
      'devi sri prasad',
      'ss thaman',
      'telugu',
      'tollywood',
    ];
    const bengaliKeywords = ['bengali', 'bengal', 'kolkata'];
    const kannadaKeywords = ['kannada', 'sandalwood', 'arjun janya'];

    if (punjabiKeywords.any((k) => combined.contains(k))) return 'punjabi';
    if (hindiKeywords.any((k) => combined.contains(k))) return 'hindi';
    if (tamilKeywords.any((k) => combined.contains(k))) return 'tamil';
    if (teluguKeywords.any((k) => combined.contains(k))) return 'telugu';
    if (bengaliKeywords.any((k) => combined.contains(k))) return 'bengali';
    if (kannadaKeywords.any((k) => combined.contains(k))) return 'kannada';

    return 'english'; // default
  }

  static String _langToGenre(String lang) {
    switch (lang) {
      case 'hindi':
        return 'Hindi';
      case 'punjabi':
        return 'Punjabi';
      case 'tamil':
        return 'Tamil';
      case 'telugu':
        return 'Telugu';
      case 'english':
        return 'English';
      case 'kannada':
        return 'Kannada';
      case 'bengali':
        return 'Bengali';
      default:
        return lang.isNotEmpty
            ? '${lang[0].toUpperCase()}${lang.substring(1)}'
            : 'Other';
    }
  }

  static String _clean(dynamic raw) {
    return raw
        .toString()
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  String get durationString {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDuration => durationString;
}

typedef MusicTrack = ReelsMusicTrack;

// ─── ReelsState ───────────────────────────────────────────────────────────────

@immutable
class ReelsState {
  final String? videoPath;
  final String? recordedVideoPath;
  final ReelsMusicTrack? selectedMusic;
  final int selectedFilterIndex;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double fade;
  final bool isFrontCamera;
  final double recordingSpeed;
  final int maxDurationSeconds;
  final bool isFromGallery;
  final String? mergedVideoPath;

  const ReelsState({
    this.videoPath,
    this.recordedVideoPath,
    this.selectedMusic,
    this.selectedFilterIndex = 0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.warmth = 0.0,
    this.fade = 0.0,
    this.isFrontCamera = false,
    this.recordingSpeed = 1.0,
    this.maxDurationSeconds = 30,
    this.isFromGallery = false,
    this.mergedVideoPath,
  });

  ReelsState copyWith({
    String? videoPath,
    String? recordedVideoPath,
    ReelsMusicTrack? selectedMusic,
    bool clearMusic = false,
    int? selectedFilterIndex,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? fade,
    bool? isFrontCamera,
    double? recordingSpeed,
    int? maxDurationSeconds,
    bool? isFromGallery,
    String? mergedVideoPath,
  }) => ReelsState(
    videoPath: videoPath ?? this.videoPath,
    recordedVideoPath: recordedVideoPath ?? this.recordedVideoPath,
    selectedMusic: clearMusic ? null : (selectedMusic ?? this.selectedMusic),
    selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    warmth: warmth ?? this.warmth,
    fade: fade ?? this.fade,
    isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    recordingSpeed: recordingSpeed ?? this.recordingSpeed,
    maxDurationSeconds: maxDurationSeconds ?? this.maxDurationSeconds,
    isFromGallery: isFromGallery ?? this.isFromGallery,
    mergedVideoPath: mergedVideoPath ?? this.mergedVideoPath,
  );
}

// ─── ReelsNotifier ────────────────────────────────────────────────────────────

class ReelsNotifier extends StateNotifier<ReelsState> {
  ReelsNotifier() : super(const ReelsState());

  void setVideo(String path, {bool fromGallery = false}) =>
      state = state.copyWith(videoPath: path, isFromGallery: fromGallery);

  void setRecordedVideo(String path) =>
      state = state.copyWith(recordedVideoPath: path);

  void setMergedVideo(String path) =>
      state = state.copyWith(mergedVideoPath: path);

  void setMusic(ReelsMusicTrack track) =>
      state = state.copyWith(selectedMusic: track);

  void selectMusic(ReelsMusicTrack track) => setMusic(track);

  void clearMusic() => state = state.copyWith(clearMusic: true);

  void setFilter(int index) =>
      state = state.copyWith(selectedFilterIndex: index);

  void selectFilter(int index) => setFilter(index);

  void setBrightness(double v) => state = state.copyWith(brightness: v);
  void setContrast(double v) => state = state.copyWith(contrast: v);
  void setSaturation(double v) => state = state.copyWith(saturation: v);
  void setWarmth(double v) => state = state.copyWith(warmth: v);
  void setFade(double v) => state = state.copyWith(fade: v);

  void toggleCamera() =>
      state = state.copyWith(isFrontCamera: !state.isFrontCamera);

  void setSpeed(double speed) => state = state.copyWith(recordingSpeed: speed);

  void setMaxDuration(int seconds) =>
      state = state.copyWith(maxDurationSeconds: seconds);

  void reset() => state = const ReelsState();
}

// ─── Providers ────────────────────────────────────────────────────────────────

final reelsProvider = StateNotifierProvider<ReelsNotifier, ReelsState>(
  (ref) => ReelsNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
//  Deezer Public API
//  Base: https://api.deezer.com
//  Docs: https://developers.deezer.com/api
//
//  Official & Verified
//  No API key required
//  No server needed — works directly from Flutter
//  CORS enabled
//  Returns 30-second MP3 preview URLs (direct, playable)
//  Includes album art, artist name, duration
// ─────────────────────────────────────────────────────────────────────────────

const _deezerBase = 'https://api.deezer.com';

/// Fetch songs from Deezer by search query.
/// [index] = pagination offset (0, 25, 50 …)
Future<List<ReelsMusicTrack>> _fetchDeezerSearch(
  String query, {
  int index = 0,
  int limit = 25,
}) async {
  final uri = Uri.parse(
    '$_deezerBase/search?q=${Uri.encodeComponent(query)}'
    '&index=$index&limit=$limit&output=json',
  );
  final res = await http.get(uri).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) return [];
  final body = json.decode(res.body) as Map<String, dynamic>;
  final results = (body['data'] as List<dynamic>? ?? []);
  return results
      .map((e) => ReelsMusicTrack.fromDeezer(e as Map<String, dynamic>))
      .where((t) => t.audioUrl.isNotEmpty && t.id.isNotEmpty)
      .toList();
}

Future<List<ReelsMusicTrack>> _fetchDeezerChart({int limit = 50}) async {
  final uri = Uri.parse('$_deezerBase/chart/0/tracks?limit=$limit&output=json');
  final res = await http.get(uri).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) return [];
  final body = json.decode(res.body) as Map<String, dynamic>;
  final results = (body['data'] as List<dynamic>? ?? []);
  return results
      .map((e) => ReelsMusicTrack.fromDeezer(e as Map<String, dynamic>))
      .where((t) => t.audioUrl.isNotEmpty && t.id.isNotEmpty)
      .toList();
}

// ─── Default Catalog Provider ────────────────────────────────────────────────
/// Loads a rich multi-language catalog on screen open.
/// Searches run in parallel for fast loading.
final reelsMusicProvider = FutureProvider<List<ReelsMusicTrack>>((ref) async {
  // ── Queries: Global + South Asian + Nepali ────────────────────────────────
  // Nepal uses primarily Hindi Bollywood, Nepali, English pop, and
  // some K-Pop. Queries are ordered by expected popularity in Nepal.
  const queries = [
    // ── Nepali (local trending) ───────────────────────────────────────────
    'nepali songs 2024',
    'nepali lok dohori',
    'nepali pop hits',
    'bartika eam rai',
    'paul shah nepali',
    'melina rai nepali',
    'prakash saput',
    '1974 AD nepali',
    'sugam pokhrel',
    'albatross band nepal',
    // ── Hindi Bollywood ───────────────────────────────────────────────────
    'arijit singh 2024',
    'bollywood hits 2024',
    'atif aslam',
    'jubin nautiyal',
    'neha kakkar',
    'vishal mishra',
    // ── Punjabi ───────────────────────────────────────────────────────────
    'ap dhillon',
    'karan aujla 2024',
    'diljit dosanjh',
    'shubh punjabi',
    // ── English Global Pop ────────────────────────────────────────────────
    'dua lipa',
    'the weeknd',
    'taylor swift',
    'ed sheeran',
    'charlie puth',
    // ── Hip-Hop / Rap ─────────────────────────────────────────────────────
    'mc stan',
    'divine hip hop india',
    'badshah',
    // ── Tamil / South ─────────────────────────────────────────────────────
    'anirudh ravichander',
    'sid sriram',
  ];

  final results = await Future.wait(
    queries.map(
      (q) => _fetchDeezerSearch(
        q,
        limit: 10,
      ).catchError((_) => <ReelsMusicTrack>[]),
    ),
  );

  // Also fetch Deezer chart (global trending right now)
  final chartTracks = await _fetchDeezerChart(
    limit: 50,
  ).catchError((_) => <ReelsMusicTrack>[]);

  // Flatten + deduplicate — chart tracks go first (they're most trending)
  final seen = <String>{};
  final all = <ReelsMusicTrack>[];

  // Chart first (most trending)
  for (final track in chartTracks) {
    if (seen.add(track.id)) all.add(track);
  }
  // Then search results
  for (final list in results) {
    for (final track in list) {
      if (seen.add(track.id)) all.add(track);
    }
  }

  return all;
});

final reelsTrendingProvider = FutureProvider<List<ReelsMusicTrack>>((
  ref,
) async {
  return _fetchDeezerChart(limit: 100).catchError((_) => <ReelsMusicTrack>[]);
});

final reelsNepaliProvider = FutureProvider<List<ReelsMusicTrack>>((ref) async {
  const nepaliQueries = [
    'nepali songs',
    'nepali pop',
    'bartika eam rai',
    'paul shah',
    'melina rai',
    'sugam pokhrel',
    'prakash saput',
    '1974 AD',
    'albatross nepal',
    'loot nepali movie',
    'kabaddi nepali',
    'nepali lok',
  ];
  final results = await Future.wait(
    nepaliQueries.map(
      (q) => _fetchDeezerSearch(
        q,
        limit: 12,
      ).catchError((_) => <ReelsMusicTrack>[]),
    ),
  );
  final seen = <String>{};
  final all = <ReelsMusicTrack>[];
  for (final list in results) {
    for (final track in list) {
      if (seen.add(track.id)) all.add(track);
    }
  }
  return all;
});

final reelsMusicSearchProvider =
    FutureProvider.family<List<ReelsMusicTrack>, String>((ref, query) async {
      if (query.trim().isEmpty) {
        return ref.watch(reelsMusicProvider).value ?? [];
      }
      return _fetchDeezerSearch(query.trim(), limit: 30);
    });

class ReelFilter {
  final String name;
  final List<double> matrix;
  final int previewColor;

  const ReelFilter({
    required this.name,
    required this.matrix,
    this.previewColor = 0xFFAAAAAA,
  });
}

const List<ReelFilter> reelsFilters = [
  ReelFilter(
    name: 'Normal',
    previewColor: 0xFFBBBBBB,
    matrix: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
  ),
  ReelFilter(
    name: 'Clarendon',
    previewColor: 0xFF7EA8CC,
    matrix: [
      1.2,
      0,
      0,
      0,
      -25,
      0,
      1.1,
      0,
      0,
      -15,
      0,
      0,
      1.3,
      0,
      -10,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Moon',
    previewColor: 0xFF888FAA,
    matrix: [
      0.21,
      0.72,
      0.07,
      0,
      20,
      0.21,
      0.72,
      0.07,
      0,
      20,
      0.21,
      0.72,
      0.07,
      0,
      40,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Lark',
    previewColor: 0xFFDDE8F0,
    matrix: [
      0.9,
      0.1,
      0,
      0,
      25,
      0,
      0.92,
      0.08,
      0,
      18,
      0.05,
      0,
      0.88,
      0,
      12,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Reyes',
    previewColor: 0xFFD4B898,
    matrix: [
      1.0,
      0.05,
      0,
      0,
      35,
      0,
      0.95,
      0.05,
      0,
      25,
      0,
      0,
      0.80,
      0,
      15,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Juno',
    previewColor: 0xFF78B8A0,
    matrix: [
      0.9,
      0.1,
      0,
      0,
      0,
      0,
      1.0,
      0.08,
      0,
      5,
      0.05,
      0,
      0.85,
      0,
      8,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Slumber',
    previewColor: 0xFFCCA86A,
    matrix: [
      1.1,
      0.05,
      0,
      0,
      15,
      0,
      0.92,
      0.03,
      0,
      5,
      0,
      0,
      0.72,
      0,
      -5,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Crema',
    previewColor: 0xFFD9C3A8,
    matrix: [
      1.05,
      0.05,
      0,
      0,
      20,
      0.03,
      0.90,
      0.02,
      0,
      15,
      0,
      0.02,
      0.82,
      0,
      10,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Ludwig',
    previewColor: 0xFFCBB050,
    matrix: [
      1.05,
      0.08,
      0,
      0,
      15,
      0,
      1.0,
      0.06,
      0,
      5,
      0,
      0,
      0.78,
      0,
      -8,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Aden',
    previewColor: 0xFFB8A8C8,
    matrix: [
      0.85,
      0.12,
      0.03,
      0,
      18,
      0.05,
      0.85,
      0.10,
      0,
      12,
      0.08,
      0.05,
      0.80,
      0,
      22,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Perpetua',
    previewColor: 0xFF88B880,
    matrix: [
      0.88,
      0.10,
      0,
      0,
      0,
      0.05,
      0.95,
      0.06,
      0,
      5,
      0,
      0.08,
      0.85,
      0,
      10,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Valencia',
    previewColor: 0xFFCC8870,
    matrix: [
      1.12,
      0.10,
      0,
      0,
      5,
      0.05,
      1.0,
      0,
      0,
      0,
      0,
      0,
      0.75,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Gingham',
    previewColor: 0xFFD8CC94,
    matrix: [
      0.95,
      0.06,
      0,
      0,
      25,
      0,
      0.90,
      0.06,
      0,
      20,
      0,
      0,
      0.75,
      0,
      18,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Lo-fi',
    previewColor: 0xFF5A3080,
    matrix: [
      1.35,
      0,
      0,
      0,
      -35,
      0,
      1.20,
      0,
      0,
      -22,
      0,
      0,
      1.35,
      0,
      -28,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
  ReelFilter(
    name: 'Drama',
    previewColor: 0xFF202842,
    matrix: [
      1.4,
      0,
      0,
      0,
      -50,
      0,
      1.28,
      0,
      0,
      -38,
      0,
      0,
      1.45,
      0,
      -42,
      0,
      0,
      0,
      1,
      0,
    ],
  ),
];

final List<ReelFilter> kReelFilters = reelsFilters;

// ─── Color Matrix Helper ──────────────────────────────────────────────────────

List<double> buildAdjustedMatrix({
  required List<double> base,
  required double brightness,
  required double warmth,
  required double fade,
}) {
  List<double> m = List<double>.from(base);

  // Brightness offset
  final bv = brightness * 255;
  m[4] = (m[4] + bv).clamp(-255.0, 255.0);
  m[9] = (m[9] + bv).clamp(-255.0, 255.0);
  m[14] = (m[14] + bv).clamp(-255.0, 255.0);

  // Warmth (red up, blue down)
  final wv = warmth * 40;
  m[4] = (m[4] + wv).clamp(-255.0, 255.0);
  m[14] = (m[14] - wv).clamp(-255.0, 255.0);

  // Fade (lift all channels)
  final fv = fade * 100;
  m[4] = (m[4] + fv).clamp(-255.0, 255.0);
  m[9] = (m[9] + fv).clamp(-255.0, 255.0);
  m[14] = (m[14] + fv).clamp(-255.0, 255.0);

  return m;
}
