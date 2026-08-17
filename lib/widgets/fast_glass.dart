import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/media_cache.dart';

class FastGlass extends StatelessWidget {
  const FastGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.borderWidth = 1.0,
    this.opacity = .62,
    this.blur = false,
    this.blurSigma = 18,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;

  /// Surface fill opacity — raise for sheets that must stay readable.
  final double opacity;

  /// When true, blurs whatever is painted behind the surface (true glass).
  final bool blur;

  /// Backdrop blur strength — only used when [blur] is true.
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final content =
        padding == null ? child : Padding(padding: padding!, child: child);
    if (blur) {
      return RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCCFFFFFF), // ~80% white top (bright glass sheen)
                Color(
                  0x99FFFFFF,
                ), // ~60% white bottom (background reads through)
              ],
            ),
            border: Border.all(
              color: const Color(0xB3FFFFFF),
              width: borderWidth,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F1A1A2E),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: content,
        ),
      );
    }

    // Non-scrolling glass surfaces (sheets, pills) keep the translucent look.
    final decoration = BoxDecoration(
      borderRadius: borderRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (opacity + .10).clamp(0.0, 1.0)),
          Colors.white.withValues(alpha: (opacity - .06).clamp(0.0, 1.0)),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: .9),
        width: borderWidth,
      ),
    );
    return DecoratedBox(decoration: decoration, child: content);
  }
}

/// Cheap tap target — no spring physics, no ripple painters.
class FastTap extends StatelessWidget {
  const FastTap({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.borderRadius,
  });

  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content =
        borderRadius == null
            ? child
            : ClipRRect(borderRadius: borderRadius!, child: child);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }
}

/// Decodes [Image.asset] at a capped DPR so scroll stays light.
class FastAssetImage extends StatelessWidget {
  const FastAssetImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorColor,
  });

  final String asset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? errorColor;

  @override
  Widget build(BuildContext context) {
    // Cap decode resolution — 1.5× is sharp enough and much cheaper.
    final dpr = math.min(MediaQuery.devicePixelRatioOf(context), 1.5);
    final cacheW = width != null ? (width! * dpr).round() : null;
    final cacheH = height != null ? (height! * dpr).round() : null;

    final errorBox = ColoredBox(color: errorColor ?? const Color(0xFF1B1E28));

    Widget image;
    // Live catalog images are network URLs; local decor stays as assets.
    if (asset.startsWith('http://') || asset.startsWith('https://')) {
      image = CachedNetworkImage(
        imageUrl: asset,
        cacheManager: InnovatorMediaCache.instance,
        httpHeaders: InnovatorMediaCache.authHeaders(asset),
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        fadeInDuration: Duration.zero,
        placeholder: (_, __) => errorBox,
        errorWidget: (_, __, ___) => errorBox,
      );
    } else {
      image = Image.asset(
        asset,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheW,
        cacheHeight: cacheH,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        isAntiAlias: false,
        errorBuilder: (_, __, ___) => errorBox,
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class SlipperyScrollPhysics extends ClampingScrollPhysics {
  const SlipperyScrollPhysics({super.parent});

  @override
  SlipperyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlipperyScrollPhysics(parent: buildParent(ancestor));
  }
}

/// Pauses continuous [AnimationController]s while the user scrolls.
bool handleScrollAnimationPause(
  ScrollNotification notification,
  List<AnimationController> controllers,
) {
  // Only react to the outer vertical scroll, not nested rails.
  if (notification.depth != 0) return false;
  if (notification is ScrollStartNotification ||
      notification is ScrollUpdateNotification) {
    for (final c in controllers) {
      if (c.isAnimating) c.stop();
    }
  } else if (notification is ScrollEndNotification) {
    for (final c in controllers) {
      if (!c.isAnimating) c.repeat();
    }
  }
  return false;
}
