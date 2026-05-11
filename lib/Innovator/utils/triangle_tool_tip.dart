// import 'package:flutter/material.dart';

// class ArrowPopupMenu extends StatefulWidget {
//   final List<PopupMenuEntry<String>> items;
//   final Function(String) onSelected;

//   const ArrowPopupMenu({
//     super.key,
//     required this.items,
//     required this.onSelected,
//   });

//   @override
//   State<ArrowPopupMenu> createState() => _ArrowPopupMenuState();
// }

// class _ArrowPopupMenuState extends State<ArrowPopupMenu> {
//   OverlayEntry? _overlayEntry;
//   final GlobalKey _key = GlobalKey();

//   void _showMenu() {
//     final RenderBox renderBox =
//         _key.currentContext!.findRenderObject() as RenderBox;
//     final Offset offset = renderBox.localToGlobal(Offset.zero);
//     final Size size = renderBox.size;

//     _overlayEntry = OverlayEntry(
//       builder:
//           (context) => GestureDetector(
//             behavior: HitTestBehavior.translucent,
//             onTap: _hideMenu,
//             child: Stack(
//               children: [
//                 Positioned(
//                   left: offset.dx - 60, // adjust horizontal position
//                   top: offset.dy + size.height + 5,
//                   child: Material(
//                     color: Colors.transparent,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // ▲ Triangle arrow indicator
//                         Padding(
//                           padding: const EdgeInsets.only(left: 70),
//                           child: CustomPaint(
//                             size: const Size(16, 8),
//                             painter: _TrianglePainter(),
//                           ),
//                         ),
//                         // Popup box
//                         Container(
//                           width: 130,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(8),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withAlpha(15),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               _menuItem("Edit", Icons.edit_outlined),
//                               const Divider(height: 1),
//                               _menuItem("Delete", Icons.delete_outlined,
//                                   isDestructive: true),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );

//     Overlay.of(context).insert(_overlayEntry!);
//   }

//   Widget _menuItem(String label, IconData icon,
//       {bool isDestructive = false}) {
//     return InkWell(
//       onTap: () {
//         _hideMenu();
//         widget.onSelected(label.toLowerCase());
//       },
//       borderRadius: BorderRadius.circular(8),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         child: Row(
//           children: [
//             Icon(icon,
//                 size: 18,
//                 color: isDestructive ? Colors.red : Colors.grey[700]),
//             const SizedBox(width: 10),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: isDestructive ? Colors.red : Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _hideMenu() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }

//   @override
//   void dispose() {
//     _hideMenu();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       key: _key,
//       onTap: _showMenu,
//       child: const Icon(Icons.more_horiz, color: Colors.grey),
//     );
//   }
// }

// // Triangle painter for the arrow indicator
// class _TrianglePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white;
//     final path =
//         Path()
//           ..moveTo(0, size.height)
//           ..lineTo(size.width / 2, 0)
//           ..lineTo(size.width, size.height)
//           ..close();
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }




import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// Where the arrow tip appears on the popup container.
///
/// - topLeft / topCenter / topRight    → popup appears **below** the trigger
/// - bottomLeft / bottomCenter / bottomRight → popup appears **above** the trigger
/// - leftCenter  → popup appears to the **right** of the trigger
/// - rightCenter → popup appears to the **left** of the trigger
enum ArrowPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  leftCenter,
  rightCenter,
}

/// A single item displayed inside [ArrowPopupMenu].
class ArrowMenuItem {
  /// The label text shown for this item.
  final String label;

  /// Optional icon shown to the left of [label].
  final IconData? icon;

  /// Fully custom leading widget. Takes precedence over [icon] if both are set.
  final Widget? leading;

  /// Color of [label]. Defaults to `Colors.black87`.
  final Color? textColor;

  /// Color of [icon]. Defaults to `Colors.grey[700]`.
  final Color? iconColor;

  /// Override the entire [label] text style. Overrides [textColor] if set.
  final TextStyle? textStyle;

  /// Show a divider **after** this specific item.
  /// By default dividers appear between all items (never after the last).
  final bool showDividerAfter;

  /// Called when this item is tapped.
  final VoidCallback onTap;

  const ArrowMenuItem({
    required this.label,
    this.icon,
    this.leading,
    this.textColor,
    this.iconColor,
    this.textStyle,
    this.showDividerAfter = false,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// A fully customizable popup menu with a directional arrow indicator.
///
/// ### Usage
/// ```dart
/// ArrowPopupMenu(
///   child: const Icon(Icons.more_horiz),
///   arrowPosition: ArrowPosition.topRight,
///   arrowColor: Colors.white,
///   backgroundColor: Colors.white,
///   items: [
///     ArrowMenuItem(
///       label: 'Edit',
///       icon: Icons.edit_outlined,
///       onTap: () => _edit(),
///     ),
///     ArrowMenuItem(
///       label: 'Delete',
///       icon: Icons.delete_outlined,
///       textColor: Colors.red,
///       iconColor: Colors.red,
///       onTap: () => _delete(),
///     ),
///   ],
/// )
/// ```
class ArrowPopupMenu extends StatefulWidget {
  // ── Required ───────────────────────────────────────────────────────────────

  /// Items shown inside the popup. Defined at the call site.
  final List<ArrowMenuItem> items;

  /// The widget that triggers the menu on tap.
  final Widget child;

  // ── Arrow ──────────────────────────────────────────────────────────────────

  /// Where the arrow tip appears on the popup. Defaults to [ArrowPosition.topCenter].
  final ArrowPosition arrowPosition;

  /// Fill color of the arrow triangle. Defaults to [Colors.white].
  final Color arrowColor;

  /// Width × height of the arrow triangle. Defaults to `Size(16, 8)`.
  /// For [ArrowPosition.leftCenter] / [rightCenter] the dimensions are
  /// automatically swapped so the triangle protrudes correctly.
  final Size arrowSize;

  // ── Container ──────────────────────────────────────────────────────────────

  /// Background color of the popup container. Defaults to [Colors.white].
  final Color backgroundColor;

  /// Corner radius of the popup container. Defaults to `8`.
  final double borderRadius;

  /// Fixed width of the popup. When `null` the container grows to fit its items.
  final double? menuWidth;

  /// Custom shadow for the popup container.
  final BoxShadow? shadow;

  // ── Items ──────────────────────────────────────────────────────────────────

  /// Padding applied to every menu item row.
  final EdgeInsets itemPadding;

  /// Horizontal gap between the icon / leading widget and the label text.
  final double iconLabelSpacing;

  /// Color of the dividers between items. Defaults to `Color(0xFFE0E0E0)`.
  final Color dividerColor;

  // ── Layout ─────────────────────────────────────────────────────────────────

  /// Gap in logical pixels between the trigger widget and the popup. Defaults to `4`.
  final double gap;

  const ArrowPopupMenu({
    super.key,
    required this.items,
    required this.child,
    this.arrowPosition = ArrowPosition.topCenter,
    this.arrowColor = Colors.white,
    this.arrowSize = const Size(16, 8),
    this.backgroundColor = Colors.white,
    this.borderRadius = 8,
    this.menuWidth,
    this.shadow,
    this.itemPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.iconLabelSpacing = 10,
    this.dividerColor = const Color(0xFFE0E0E0),
    this.gap = 4,
  });

  @override
  State<ArrowPopupMenu> createState() => _ArrowPopupMenuState();
}

class _ArrowPopupMenuState extends State<ArrowPopupMenu> {
  OverlayEntry? _overlay;
  final GlobalKey _triggerKey = GlobalKey();

  void _show() {
    final box =
        _triggerKey.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final triggerSize = box.size;
    final screenSize = MediaQuery.of(context).size;

    _overlay = OverlayEntry(
      builder: (_) => _ArrowMenuOverlay(
        items: widget.items,
        arrowPosition: widget.arrowPosition,
        arrowColor: widget.arrowColor,
        backgroundColor: widget.backgroundColor,
        borderRadius: widget.borderRadius,
        arrowSize: widget.arrowSize,
        menuWidth: widget.menuWidth,
        itemPadding: widget.itemPadding,
        iconLabelSpacing: widget.iconLabelSpacing,
        dividerColor: widget.dividerColor,
        shadow: widget.shadow,
        gap: widget.gap,
        triggerOffset: offset,
        triggerSize: triggerSize,
        screenSize: screenSize,
        onDismiss: _hide,
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _hide() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _triggerKey,
      onTap: _show,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY (internal)
// ─────────────────────────────────────────────────────────────────────────────

class _ArrowMenuOverlay extends StatelessWidget {
  final List<ArrowMenuItem> items;
  final ArrowPosition arrowPosition;
  final Color arrowColor;
  final Color backgroundColor;
  final double borderRadius;
  final Size arrowSize;
  final double? menuWidth;
  final EdgeInsets itemPadding;
  final double iconLabelSpacing;
  final Color dividerColor;
  final BoxShadow? shadow;
  final double gap;
  final Offset triggerOffset;
  final Size triggerSize;
  final Size screenSize;
  final VoidCallback onDismiss;

  const _ArrowMenuOverlay({
    required this.items,
    required this.arrowPosition,
    required this.arrowColor,
    required this.backgroundColor,
    required this.borderRadius,
    required this.arrowSize,
    required this.menuWidth,
    required this.itemPadding,
    required this.iconLabelSpacing,
    required this.dividerColor,
    required this.shadow,
    required this.gap,
    required this.triggerOffset,
    required this.triggerSize,
    required this.screenSize,
    required this.onDismiss,
  });

  // ── position helpers ───────────────────────────────────────────────────────

  bool get _isTop =>
      arrowPosition == ArrowPosition.topLeft ||
      arrowPosition == ArrowPosition.topCenter ||
      arrowPosition == ArrowPosition.topRight;

  bool get _isBottom =>
      arrowPosition == ArrowPosition.bottomLeft ||
      arrowPosition == ArrowPosition.bottomCenter ||
      arrowPosition == ArrowPosition.bottomRight;

  bool get _isLeft => arrowPosition == ArrowPosition.leftCenter;
  bool get _isRight => arrowPosition == ArrowPosition.rightCenter;

  /// Width used for layout calculations (falls back to 160 when intrinsic).
  double get _calcWidth => menuWidth ?? 160.0;

  /// Left edge of the popup box for top / bottom positions.
  double get _boxLeft {
    switch (arrowPosition) {
      case ArrowPosition.topLeft:
      case ArrowPosition.bottomLeft:
        return triggerOffset.dx;
      case ArrowPosition.topCenter:
      case ArrowPosition.bottomCenter:
        return triggerOffset.dx + triggerSize.width / 2 - _calcWidth / 2;
      case ArrowPosition.topRight:
      case ArrowPosition.bottomRight:
        return triggerOffset.dx + triggerSize.width - _calcWidth;
      default:
        return triggerOffset.dx;
    }
  }

  /// Horizontal padding-left for the arrow so it sits at the right corner/center.
  double get _arrowLeftOffset {
    switch (arrowPosition) {
      case ArrowPosition.topLeft:
      case ArrowPosition.bottomLeft:
        return borderRadius + 4;
      case ArrowPosition.topCenter:
      case ArrowPosition.bottomCenter:
        return _calcWidth / 2 - arrowSize.width / 2;
      case ArrowPosition.topRight:
      case ArrowPosition.bottomRight:
        return _calcWidth - borderRadius - arrowSize.width - 4;
      default:
        return 0;
    }
  }

  BoxShadow get _defaultShadow => BoxShadow(
        color: Colors.black.withAlpha(25),
        blurRadius: 14,
        offset: const Offset(0, 5),
      );

  // ── builders ───────────────────────────────────────────────────────────────

  Widget _box() {
    return Container(
      width: menuWidth,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [shadow ?? _defaultShadow],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isLast = i == items.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _itemRow(item),
                if (!isLast || item.showDividerAfter)
                  Divider(height: 1, thickness: 1, color: dividerColor),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _itemRow(ArrowMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onDismiss();
          item.onTap();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: itemPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.leading != null) ...[
                item.leading!,
                SizedBox(width: iconLabelSpacing),
              ] else if (item.icon != null) ...[
                Icon(item.icon, size: 18,
                    color: item.iconColor ?? Colors.grey[700]),
                SizedBox(width: iconLabelSpacing),
              ],
              Text(
                item.label,
                style: item.textStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: item.textColor ?? Colors.black87,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Paints the triangle. For side arrows width ↔ height are swapped.
  Widget _arrow({bool flipped = false, bool horizontal = false}) {
    final size =
        horizontal ? Size(arrowSize.height, arrowSize.width) : arrowSize;
    return CustomPaint(
      size: size,
      painter: _TrianglePainter(
        color: arrowColor,
        flipped: flipped,
        horizontal: horizontal,
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onDismiss,
      child: Stack(
        children: [
          // ── Arrow at top (popup below trigger) ──────────────────────────
          if (_isTop)
            Positioned(
              left: _boxLeft,
              top: triggerOffset.dy + triggerSize.height + gap,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: _arrowLeftOffset),
                      child: _arrow(), // ▲
                    ),
                    _box(),
                  ],
                ),
              ),
            ),

          // ── Arrow at bottom (popup above trigger) ────────────────────────
          if (_isBottom)
            Positioned(
              left: _boxLeft,
              bottom: screenSize.height - triggerOffset.dy + gap,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _box(),
                    Padding(
                      padding: EdgeInsets.only(left: _arrowLeftOffset),
                      child: _arrow(flipped: true), // ▼
                    ),
                  ],
                ),
              ),
            ),

          // ── Arrow at left (popup to the right of trigger) ────────────────
          if (_isLeft)
            Positioned(
              left: triggerOffset.dx + triggerSize.width + gap,
              top: triggerOffset.dy + triggerSize.height / 2,
              child: FractionalTranslation(
                // shift up by half its own height → centers on trigger
                translation: const Offset(0, -0.5),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _arrow(horizontal: true), // ◄
                      _box(),
                    ],
                  ),
                ),
              ),
            ),

          // ── Arrow at right (popup to the left of trigger) ────────────────
          if (_isRight)
            Positioned(
              right: screenSize.width - triggerOffset.dx + gap,
              top: triggerOffset.dy + triggerSize.height / 2,
              child: FractionalTranslation(
                translation: const Offset(0, -0.5),
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _box(),
                      _arrow(horizontal: true, flipped: true), // ►
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIANGLE PAINTER (internal)
// ─────────────────────────────────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  final Color color;

  /// Reverses the pointing direction.
  final bool flipped;

  /// Switches between vertical (▲▼) and horizontal (◄►) triangles.
  final bool horizontal;

  const _TrianglePainter({
    required this.color,
    this.flipped = false,
    this.horizontal = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (horizontal) {
      if (flipped) {
        // Points right ►
        path
          ..moveTo(0, 0)
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height / 2)
          ..close();
      } else {
        // Points left ◄
        path
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
      }
    } else {
      if (flipped) {
        // Points down ▼
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();
      } else {
        // Points up ▲
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..close();
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color ||
      old.flipped != flipped ||
      old.horizontal != horizontal;
}