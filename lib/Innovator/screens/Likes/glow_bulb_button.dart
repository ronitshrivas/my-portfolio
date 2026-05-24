// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
// import 'package:innovator/Innovator/screens/Likes/hive_reaction_queue.dart';
// import 'dart:developer' as developer;
// import 'dart:math' as math;

// class GlowBulbButton extends StatefulWidget {
//   final String contentId;
//   final bool initialLikeStatus;
//   final ContentLikeService likeService;
//   final Function(bool)? onLikeToggled;
//   final String? initialReactionType;
//   final bool showLabel;
//   final int initialCount;
//   final bool isReel;

//   const GlowBulbButton({
//     Key? key,
//     required this.contentId,
//     required this.initialLikeStatus,
//     required this.likeService,
//     this.onLikeToggled,
//     this.initialReactionType,
//     this.showLabel = false,
//     this.initialCount = 0,
//     this.isReel = false,
//   }) : super(key: key);

//   @override
//   State<GlowBulbButton> createState() => _GlowBulbButtonState();
// }

// class _GlowBulbButtonState extends State<GlowBulbButton>
//     with TickerProviderStateMixin {
//   bool _isLiked = false;
//   bool _isApiInFlight = false;
//   bool _isSyncing = false;
//   late int _count;

//   // 1. Smooth color lerp: 0.0 = off, 1.0 = on
//   late AnimationController _colorCtrl;
//   late Animation<double> _colorAnim;

//   // 2. Scale pop on every tap
//   late AnimationController _bounceCtrl;
//   late Animation<double> _bounceAnim;

//   // 3. Ripple ring — fires once on like, stays hidden on unlike
//   late AnimationController _rippleCtrl;
//   late Animation<double> _rippleAnim;

//   // 4. Sparks — compact burst on like
//   late AnimationController _sparkCtrl;
//   late Animation<double> _sparkAnim;

//   @override
//   void initState() {
//     super.initState();

//     HiveReactionQueue.instance.setService(widget.likeService);
//     _isLiked = widget.initialLikeStatus;
//     _count = widget.initialCount;

//     // Color transition — forward = light up, reverse = dim
//     _colorCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 220),
//     );
//     _colorAnim = CurvedAnimation(parent: _colorCtrl, curve: Curves.easeInOut);
//     if (_isLiked) _colorCtrl.value = 1.0;

//     // Scale pop
//     _bounceCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 280),
//     );
//     _bounceAnim = TweenSequence([
//       TweenSequenceItem(
//         tween: Tween<double>(
//           begin: 1.0,
//           end: 1.28,
//         ).chain(CurveTween(curve: Curves.easeOut)),
//         weight: 35,
//       ),
//       TweenSequenceItem(
//         tween: Tween<double>(
//           begin: 1.28,
//           end: 0.90,
//         ).chain(CurveTween(curve: Curves.easeInOut)),
//         weight: 30,
//       ),
//       TweenSequenceItem(
//         tween: Tween<double>(
//           begin: 0.90,
//           end: 1.0,
//         ).chain(CurveTween(curve: Curves.easeOut)),
//         weight: 35,
//       ),
//     ]).animate(_bounceCtrl);

//     // Ripple ring (like only)
//     _rippleCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 480),
//     );
//     _rippleAnim = CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut);

//     // Sparks (like only)
//     _sparkCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 420),
//     );
//     _sparkAnim = CurvedAnimation(parent: _sparkCtrl, curve: Curves.easeOut);

//     HiveReactionQueue.instance.addListener(widget.contentId, _onSyncResult);
//   }

//   @override
//   void dispose() {
//     HiveReactionQueue.instance.removeListener(widget.contentId);
//     _colorCtrl.dispose();
//     _bounceCtrl.dispose();
//     _rippleCtrl.dispose();
//     _sparkCtrl.dispose();
//     super.dispose();
//   }

//   void _onSyncResult(
//     String contentId,
//     bool succeeded,
//     ReactionType? reactionType,
//     ReactionType? previousType,
//   ) {
//     if (!mounted) return;
//     if (succeeded) {
//       setState(() {
//         _isSyncing = false;
//         _isLiked = reactionType != null;
//       });
//     } else {
//       final wasLiked = previousType != null;
//       setState(() {
//         _isSyncing = false;
//         if (_isLiked && !wasLiked) _count = (_count - 1).clamp(0, 999999);
//         if (!_isLiked && wasLiked) _count = _count + 1;
//         _isLiked = wasLiked;
//       });
//       // Snap color back
//       if (wasLiked) {
//         _colorCtrl.animateTo(1.0, duration: const Duration(milliseconds: 150));
//       } else {
//         _colorCtrl.animateTo(0.0, duration: const Duration(milliseconds: 150));
//       }
//       widget.onLikeToggled?.call(_isLiked);
//     }
//   }

//   Future<bool> _isOnline() async {
//     try {
//       final results = await Connectivity().checkConnectivity();
//       return results.any(
//         (r) =>
//             r == ConnectivityResult.wifi ||
//             r == ConnectivityResult.mobile ||
//             r == ConnectivityResult.ethernet,
//       );
//     } catch (_) {
//       return false;
//     }
//   }

//   Future<void> _handleTap() async {
//     if (_isApiInFlight || _isSyncing) return;
//     HapticFeedback.lightImpact();

//     final newLiked = !_isLiked;
//     final previous = _isLiked ? ReactionType.like : null;

//     setState(() {
//       _isLiked = newLiked;
//       _count = newLiked ? _count + 1 : (_count - 1).clamp(0, 999999);
//     });

//     // Always bounce
//     _bounceCtrl.forward(from: 0);

//     if (newLiked) {
//       // Light up: color, ripple, sparks
//       _colorCtrl.animateTo(1.0, duration: const Duration(milliseconds: 220));
//       _rippleCtrl.forward(from: 0);
//       _sparkCtrl.forward(from: 0);
//     } else {
//       // Dim: color only — no celebratory effects on unlike
//       _colorCtrl.animateTo(0.0, duration: const Duration(milliseconds: 180));
//     }

//     widget.onLikeToggled?.call(_isLiked);
//     _isApiInFlight = true;

//     try {
//       final online = await _isOnline();
//       final type = newLiked ? ReactionType.like : null;

//       if (!online) {
//         await HiveReactionQueue.instance.enqueue(
//           contentId: widget.contentId,
//           type: type,
//           isReel: widget.isReel,
//           previousType: previous,
//         );
//         return;
//       }

//       final result =
//           widget.isReel
//               ? await widget.likeService.reactReel(
//                 widget.contentId,
//                 ReactionType.like,
//               )
//               : await widget.likeService.reactPost(
//                 widget.contentId,
//                 ReactionType.like,
//               );

//       if (result.success) {
//         await HiveReactionQueue.instance.dequeue(widget.contentId);
//         developer.log('[GlowBulb] ✓ confirmed ${widget.contentId}');
//       } else {
//         _revertState(previous, type);
//       }
//     } on NonRetryableException catch (e) {
//       developer.log('[GlowBulb] Non-retryable (${e.statusCode})');
//       _revertState(previous, newLiked ? ReactionType.like : null);
//       await HiveReactionQueue.instance.dequeue(widget.contentId);
//     } catch (e) {
//       developer.log('[GlowBulb] queuing: $e');
//       await HiveReactionQueue.instance.enqueue(
//         contentId: widget.contentId,
//         type: newLiked ? ReactionType.like : null,
//         isReel: widget.isReel,
//         previousType: previous,
//       );
//     } finally {
//       if (mounted) setState(() => _isApiInFlight = false);
//     }
//   }

//   void _revertState(ReactionType? previous, ReactionType? attempted) {
//     if (!mounted) return;
//     setState(() {
//       if (attempted != null && previous == null) {
//         _count = (_count - 1).clamp(0, 999999);
//       } else if (attempted == null && previous != null) {
//         _count = _count + 1;
//       }
//       _isLiked = previous != null;
//     });
//     if (_isLiked) {
//       _colorCtrl.animateTo(1.0, duration: const Duration(milliseconds: 150));
//     } else {
//       _colorCtrl.animateTo(0.0, duration: const Duration(milliseconds: 150));
//     }
//     widget.onLikeToggled?.call(_isLiked);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _handleTap,
//       behavior: HitTestBehavior.opaque,
//       child: AnimatedBuilder(
//         animation: Listenable.merge([
//           _bounceAnim,
//           _colorAnim,
//           _rippleAnim,
//           _sparkAnim,
//         ]),
//         builder: (context, _) {
//           final t = _colorAnim.value; // 0.0 = off, 1.0 = on

//           return Transform.scale(
//             scale: _bounceAnim.value,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Fixed-size container — same footprint as comment icon (25×25)
//                   SizedBox(
//                     width: 25,
//                     height: 25,
//                     child: Stack(
//                       alignment: Alignment.center,
//                       clipBehavior: Clip.none,
//                       children: [
//                         // ── Ripple ring (on like) ──────────────────────────
//                         if (_rippleAnim.value > 0 && _rippleAnim.value < 1)
//                           CustomPaint(
//                             size: const Size(38, 38),
//                             painter: _RipplePainter(
//                               progress: _rippleAnim.value,
//                             ),
//                           ),

//                         // ── Spark particles (on like) ──────────────────────
//                         if (_sparkAnim.value > 0 && _sparkAnim.value < 1)
//                           ..._buildSparks(),

//                         // ── Bulb — color driven by _colorAnim ──────────────
//                         CustomPaint(
//                           size: const Size(22, 22),
//                           painter: _BulbPainter(intensity: t),
//                         ),

//                         // ── Syncing micro-dot ──────────────────────────────
//                         if (_isSyncing)
//                           Positioned(
//                             top: 1,
//                             right: 1,
//                             child: SizedBox(
//                               width: 6,
//                               height: 6,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 1.0,
//                                 color:
//                                     t > 0.5
//                                         ? const Color(0xFFFFB300)
//                                         : Colors.grey.shade400,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),

//                   if (widget.showLabel) ...[
//                     const SizedBox(width: 5),
//                     AnimatedDefaultTextStyle(
//                       duration: const Duration(milliseconds: 200),
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color:
//                             t > 0.5
//                                 ? const Color(0xFFF59E0B)
//                                 : Colors.grey.shade700,
//                       ),
//                       child: Text(
//                         _count > 0
//                             ? (_isLiked ? 'Liked · $_count' : 'Like · $_count')
//                             : (_isLiked ? 'Liked' : 'Like'),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   List<Widget> _buildSparks() {
//     final progress = _sparkAnim.value;
//     final sparks = <Widget>[];
//     const colors = [
//       Color(0xFFFFD700),
//       Color(0xFFFFA726),
//       Color(0xFFFFF176),
//       Color(0xFFFFB300),
//       Color(0xFFFF8F00),
//       Color(0xFFFFF59D),
//     ];

//     for (int i = 0; i < 6; i++) {
//       // Offset angle slightly so sparks don't line up with the base
//       final angle = (i / 6) * 2 * math.pi - math.pi / 2;
//       // Max travel = 11px from center (tight, within the 38px ripple area)
//       final dist = 11.0 * Curves.easeOut.transform(progress);
//       final dx = math.cos(angle) * dist;
//       final dy = math.sin(angle) * dist;
//       final opacity = (1.0 - progress * 1.1).clamp(0.0, 1.0);
//       final dotSize = (3.5 * (1.0 - progress)).clamp(0.5, 3.5);

//       sparks.add(
//         Positioned(
//           left: 12.5 + dx - dotSize / 2,
//           top: 12.5 + dy - dotSize / 2,
//           child: Opacity(
//             opacity: opacity,
//             child: Container(
//               width: dotSize,
//               height: dotSize,
//               decoration: BoxDecoration(
//                 color: colors[i % colors.length],
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//     return sparks;
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  Ripple ring — expands outward and fades, drawn behind the bulb
// // ─────────────────────────────────────────────────────────────────────────────
// class _RipplePainter extends CustomPainter {
//   final double progress; // 0.0 → 1.0

//   const _RipplePainter({required this.progress});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     // Ring starts at 9px radius (just around the bulb), expands to 19px
//     final radius = 9.0 + (19.0 - 9.0) * progress;
//     // Opacity: fades from 0.55 to 0 as it expands
//     final opacity = (0.55 * (1.0 - progress)).clamp(0.0, 1.0);
//     // Stroke thins from 2.0 to 0.5 as ring expands
//     final strokeW = 2.0 - 1.5 * progress;

//     canvas.drawCircle(
//       center,
//       radius,
//       Paint()
//         ..color = const Color(0xFFFFA726).withOpacity(opacity)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeW,
//     );
//   }

//   @override
//   bool shouldRepaint(_RipplePainter old) => old.progress != progress;
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  Bulb painter — intensity 0.0 = grey/off, 1.0 = warm amber/on
// //  Inner radial glow is drawn entirely on canvas (no BoxShadow)
// // ─────────────────────────────────────────────────────────────────────────────
// class _BulbPainter extends CustomPainter {
//   final double intensity; // 0.0 → 1.0

//   const _BulbPainter({required this.intensity});

//   // Lerp helper
//   Color _lerp(Color a, Color b) => Color.lerp(a, b, intensity)!;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final w = size.width;
//     final h = size.height;

//     // ── Color palette (off → on) ──────────────────────────────────────────
//     final bulbFill = _lerp(const Color(0xFFF0F0F0), const Color(0xFFFFF9C4));
//     final bulbStroke = _lerp(const Color(0xFFBDBDBD), const Color(0xFFF59E0B));
//     final filCol = _lerp(const Color(0xFF9E9E9E), const Color(0xFFF59E0B));
//     final baseCol = _lerp(const Color(0xFFBDBDBD), const Color(0xFFD97706));
//     final base2Col = _lerp(const Color(0xFF9E9E9E), const Color(0xFFB45309));

//     // ── Bulb glass path ───────────────────────────────────────────────────
//     final bulbPath =
//         Path()
//           ..moveTo(w * 0.50, h * 0.03)
//           ..cubicTo(w * 0.20, h * 0.03, w * 0.02, h * 0.28, w * 0.02, h * 0.50)
//           ..cubicTo(w * 0.02, h * 0.65, w * 0.18, h * 0.75, w * 0.30, h * 0.79)
//           ..lineTo(w * 0.30, h * 0.87)
//           ..lineTo(w * 0.70, h * 0.87)
//           ..lineTo(w * 0.70, h * 0.79)
//           ..cubicTo(w * 0.82, h * 0.75, w * 0.98, h * 0.65, w * 0.98, h * 0.50)
//           ..cubicTo(w * 0.98, h * 0.28, w * 0.80, h * 0.03, w * 0.50, h * 0.03)
//           ..close();

//     // ── 1. Inner radial glow — painted INSIDE the bulb glass ─────────────
//     //       Clipped so it never bleeds outside the shape.
//     if (intensity > 0.0) {
//       canvas.save();
//       canvas.clipPath(bulbPath);

//       final glowCenter = Offset(w * 0.50, h * 0.44);
//       final glowRadius = w * 0.52;

//       // Radial gradient: warm white core → amber mid → transparent edge
//       final glowPaint =
//           Paint()
//             ..shader = RadialGradient(
//               colors: [
//                 const Color(0xFFFFFDE7).withOpacity(0.90 * intensity),
//                 const Color(0xFFFFE082).withOpacity(0.55 * intensity),
//                 const Color(0xFFFFA726).withOpacity(0.0),
//               ],
//               stops: const [0.0, 0.55, 1.0],
//             ).createShader(
//               Rect.fromCircle(center: glowCenter, radius: glowRadius),
//             );

//       canvas.drawCircle(glowCenter, glowRadius, glowPaint);
//       canvas.restore();
//     }

//     // ── 2. Glass fill ─────────────────────────────────────────────────────
//     canvas.drawPath(
//       bulbPath,
//       Paint()
//         ..color = bulbFill
//         ..style = PaintingStyle.fill,
//     );

//     // ── 3. Glass stroke ───────────────────────────────────────────────────
//     canvas.drawPath(
//       bulbPath,
//       Paint()
//         ..color = bulbStroke
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.1,
//     );

//     // ── 4. Filament ───────────────────────────────────────────────────────
//     final filPath =
//         Path()
//           ..moveTo(w * 0.36, h * 0.81)
//           ..quadraticBezierTo(w * 0.40, h * 0.62, w * 0.38, h * 0.46)
//           ..quadraticBezierTo(w * 0.44, h * 0.33, w * 0.50, h * 0.24)
//           ..quadraticBezierTo(w * 0.56, h * 0.33, w * 0.62, h * 0.46)
//           ..quadraticBezierTo(w * 0.60, h * 0.62, w * 0.64, h * 0.81);

//     canvas.drawPath(
//       filPath,
//       Paint()
//         ..color = filCol
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.15
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round,
//     );

//     // Hot white core on filament when lit
//     if (intensity > 0.05) {
//       canvas.drawPath(
//         filPath,
//         Paint()
//           ..color = const Color(0xFFFFFDE7).withOpacity(0.7 * intensity)
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = 0.5
//           ..strokeCap = StrokeCap.round
//           ..strokeJoin = StrokeJoin.round,
//       );
//     }

//     // ── 5. Base segments ──────────────────────────────────────────────────
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromLTWH(w * 0.28, h * 0.87, w * 0.44, h * 0.065),
//         const Radius.circular(1),
//       ),
//       Paint()
//         ..color = baseCol
//         ..style = PaintingStyle.fill,
//     );
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromLTWH(w * 0.30, h * 0.935, w * 0.40, h * 0.060),
//         const Radius.circular(1),
//       ),
//       Paint()
//         ..color = base2Col
//         ..style = PaintingStyle.fill,
//     );

//     // ── 6. Shine highlight — top-left of glass ────────────────────────────
//     canvas.drawOval(
//       Rect.fromCenter(
//         center: Offset(w * 0.34, h * 0.27),
//         width: w * 0.10,
//         height: h * 0.16,
//       ),
//       Paint()
//         ..color = Colors.white.withOpacity(0.42)
//         ..style = PaintingStyle.fill,
//     );
//   }

//   @override
//   bool shouldRepaint(_BulbPainter old) => old.intensity != intensity;
// }
