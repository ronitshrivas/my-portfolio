import 'package:innovator/core/config/api_config.dart';

/// A promotional banner shown at the top of the Shop / E-learning sections.
///
/// The backend (`GET /api/banners`) currently returns an empty list, so this
/// model parses defensively across the likely field names. `targetId` links to
/// a course (e-learning) or product (ecommerce) to open on tap.
class AppBanner {
  const AppBanner({
    required this.id,
    this.title,
    this.imageUrl,
    this.targetId,
    this.targetName,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String? title;
  final String? imageUrl;
  final String? targetId;
  final String? targetName;
  final bool isActive;
  final int sortOrder;

  bool get hasImage => (imageUrl ?? '').trim().isNotEmpty;

  /// [baseUrl] is the owning service host, used to resolve relative image paths
  /// and to rewrite images stored on an older port onto the live host.
  factory AppBanner.fromJson(Map<String, dynamic> json, {required String baseUrl}) {
    final rawImage = (json['image'] ??
            json['image_url'] ??
            json['imageUrl'] ??
            json['banner_image'] ??
            json['file'])
        ?.toString();

    final target = (json['course_id'] ??
            json['courseId'] ??
            json['product_id'] ??
            json['productId'] ??
            json['course'] ??
            json['product'] ??
            json['target_id'])
        ?.toString();

    final targetName = (json['course_title'] ??
            json['course_name'] ??
            json['product_name'] ??
            json['target_name'])
        ?.toString();

    return AppBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      imageUrl: _resolveImage(rawImage, baseUrl),
      targetId: (target != null && target.isNotEmpty) ? target : null,
      targetName: targetName,
      isActive: json['is_active'] != false && json['isActive'] != false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ??
          (json['sortOrder'] as num?)?.toInt() ??
          0,
    );
  }

  static String? _resolveImage(String? url, String baseUrl) {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    // Rewrite wrong-port absolute URLs on our host onto the live service host.
    if (uri != null && uri.hasScheme) {
      final liveUri = Uri.parse(baseUrl);
      if (uri.host == liveUri.host && uri.port != liveUri.port) {
        final tail = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
        final query = uri.hasQuery ? '?${uri.query}' : '';
        return '$baseUrl$tail$query';
      }
      return raw;
    }
    return '$baseUrl${raw.startsWith('/') ? '' : '/'}$raw';
  }
}

/// Parses a `GET /api/banners` payload (bare list or `{results:[...]}`),
/// keeping only active banners sorted by [AppBanner.sortOrder].
List<AppBanner> parseBanners(Object? raw, {required String baseUrl}) {
  Object? node = raw;
  if (node is Map) {
    node = node['results'] ?? node['data'] ?? node['items'] ?? node;
  }
  if (node is! List) return const [];
  final list = node
      .whereType<Map>()
      .map((e) => AppBanner.fromJson(Map<String, dynamic>.from(e), baseUrl: baseUrl))
      .where((b) => b.isActive)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return list;
}

/// Convenience hosts for the two banner-owning services.
class BannerHosts {
  BannerHosts._();
  static const elearning = ApiConfig.elearningBaseUrl;
  static const ecommerce = ApiConfig.ecommerceBaseUrl;
}
