import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/provider/notifcation_list_screen_provider.dart';
import 'package:innovator/Innovator/screens/CreatePost/createpost.dart';
import 'package:innovator/Innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/Innovator/Notification/Notification_Listscreen.dart';
import 'package:innovator/ecommerce/screens/Shop/Shop_Page.dart';
import 'package:innovator/elearning/screens/course_list_screen.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/Innovator/screens/Search/Searchpage.dart';
import 'package:innovator/research/screens/research_list_screen.dart';

const double _kEdgeThreshold = 80.0;

enum _MenuMode { floating, bottomNav, topNav }

class FloatingMenuOverlay {
  static OverlayEntry? _entry;
  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final overlay = Overlay.of(context, rootOverlay: true);
        _entry = OverlayEntry(
          builder: (_) => const ProviderScope(child: FloatingMenuWidget()),
        );
        overlay.insert(_entry!);
      } catch (e) {
        _isShowing = false;
        developer.log('Error showing FloatingMenuOverlay: $e');
      }
    });
  }

  static void remove() {
    _entry?.remove();
    _entry = null;
    _isShowing = false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING MENU WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class FloatingMenuWidget extends ConsumerStatefulWidget {
  const FloatingMenuWidget({super.key});

  @override
  ConsumerState<FloatingMenuWidget> createState() => _FloatingMenuWidgetState();
}

class _FloatingMenuWidgetState extends ConsumerState<FloatingMenuWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _buttonX = 0;
  double _buttonY = 0;
  int _selectedNavIndex = 0;
  _MenuMode _menuMode = _MenuMode.floating;

  static const List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home, 'label': '', 'action': 'navigate_home'},
    {'icon': Icons.search, 'label': '', 'action': 'view_profile'},
    {'icon': Icons.add_a_photo, 'label': '', 'action': 'add_photo'},
    {'icon': Icons.notifications, 'label': '', 'action': 'notification'},
    {'icon': Icons.menu, 'label': '', 'action': 'drawer'},
  ];

  final List<Map<String, dynamic>> _topIcons = [
    {'icon': Icons.home, 'name': 'FEED', 'action': 'navigate_home'},
    {'icon': Icons.school, 'name': 'COURSE', 'action': 'open_course'},
    {'icon': Icons.add_a_photo, 'name': 'ADD POST', 'action': 'add_photo'},
    {
      'icon': Icons.menu_book_rounded,
      'name': 'Research Paper',
      'action': 'show_papers',
    },
  ];

  final List<Map<String, dynamic>> _bottomIcons = [
    {'icon': Icons.shop, 'name': 'SHOP', 'action': 'open_shop'},
    {'icon': Icons.search, 'name': 'SEARCH', 'action': 'view_profile'},
    {
      'icon': Icons.notifications,
      'name': 'Notification',
      'action': 'notification',
    },
    {'icon': Icons.menu, 'name': 'Drawer', 'action': 'drawer'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      setState(() {
        _buttonX = size.width - 60;
        _buttonY = size.height * 0.5;
      });
    });
    // NOTE: no more _fetchUnreadNotificationCount() or periodic timer here.
    // The badge is driven entirely by notificationProvider state.
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  NavigatorState get _nav => Navigator.of(context, rootNavigator: true);

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  void _onFloatingButtonDragEnd(DraggableDetails details, Size size) {
    final dy = details.offset.dy;
    final dx = details.offset.dx;
    _MenuMode newMode;

    if (dy >= size.height - _kEdgeThreshold) {
      newMode = _MenuMode.bottomNav;
    } else if (dy <= _kEdgeThreshold) {
      newMode = _MenuMode.topNav;
    } else {
      newMode = _MenuMode.floating;
    }

    setState(() {
      _menuMode = newMode;
      if (newMode == _MenuMode.floating) {
        _buttonX = dx.clamp(0.0, size.width - 50);
        _buttonY = (dy + 25).clamp(50.0, size.height - 50);
      }
      if (_isExpanded) {
        _isExpanded = false;
        _animationController.reverse();
      }
    });
  }

  void _onNavBarDragEnd(DraggableDetails details, Size size) {
    final dy = details.offset.dy;
    final dx = details.offset.dx;
    if (dy < size.height - _kEdgeThreshold && dy > _kEdgeThreshold) {
      setState(() {
        _menuMode = _MenuMode.floating;
        _buttonX = dx.clamp(0.0, size.width - 50);
        _buttonY = dy.clamp(50.0, size.height - 50);
      });
    }
  }

  Future<void> _handleAction(String action) async {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }

    switch (action) {
      case 'navigate_home':
        _nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Homepage()),
          (route) => false,
        );
        break;
      case 'open_course':
        _nav.push(MaterialPageRoute(builder: (_) => CourseListScreen()));
        break;
      case 'add_photo':
        _nav.push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        break;
      case 'show_papers':
        _nav.push(MaterialPageRoute(builder: (_) => ResearchListScreen()));
        break;
      case 'open_shop':
        _nav.push(MaterialPageRoute(builder: (_) => const ShopPage()));
        break;
      case 'view_profile':
        _nav.push(MaterialPageRoute(builder: (_) => const SearchPage()));
        break;
      case 'notification':
        _nav.push(
          MaterialPageRoute(builder: (_) => const NotificationListScreen()),
        );
        break;
      case 'drawer':
        SmoothDrawerService.showLeftDrawer(context, ref);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action not implemented: $action')),
        );
    }
  }

  BorderRadius _buttonBorderRadius(Size size) {
    if (_buttonX >= size.width - 70) {
      return const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      );
    } else if (_buttonX <= 70) {
      return const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      );
    }
    return BorderRadius.circular(30);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_menuMode == _MenuMode.bottomNav)
            _buildNavBar(size, isBottom: true, unreadCount: unreadCount)
          else if (_menuMode == _MenuMode.topNav)
            _buildNavBar(size, isBottom: false, unreadCount: unreadCount)
          else ...[
            if (_isExpanded)
              Positioned(
                left: _buttonX,
                top: _buttonY - 25 - (_topIcons.length * 52),
                child: _buildIconsContainer(
                  _topIcons,
                  size,
                  unreadCount: unreadCount,
                ),
              ),

            Positioned(
              left: _buttonX,
              top: _buttonY - 25,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Draggable(
                    feedback: Material(
                      color: Colors.orange.withOpacity(0.5),
                      borderRadius: _buttonBorderRadius(size),
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu,
                          color: AppColors.whitecolor,
                          size: 24,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Material(
                        color: Colors.orange,
                        borderRadius: _buttonBorderRadius(size),
                        child: Container(width: 50, height: 50),
                      ),
                    ),
                    onDragEnd: (d) => _onFloatingButtonDragEnd(d, size),
                    child: GestureDetector(
                      onTap: _toggleMenu,
                      child: Material(
                        elevation: 4,
                        color: Colors.orange,
                        borderRadius: _buttonBorderRadius(size),
                        child: Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          child: AnimatedIcon(
                            icon: AnimatedIcons.menu_close,
                            progress: _animation,
                            color: AppColors.whitecolor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (unreadCount > 0 && !_isExpanded)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _Badge(
                        count: unreadCount,
                        minSize: 18,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            if (_isExpanded)
              Positioned(
                left: _buttonX,
                top: _buttonY + 33,
                child: _buildIconsContainer(
                  _bottomIcons,
                  size,
                  unreadCount: unreadCount,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavBar(
    Size size, {
    required bool isBottom,
    required int unreadCount,
  }) {
    final topPadding = isBottom ? 0.0 : MediaQuery.of(context).padding.top;
    return Positioned(
      left: 0,
      right: 0,
      bottom: isBottom ? 0 : null,
      top: isBottom ? null : 0,
      child: _NavBar(
        items: _navItems,
        selectedIndex: _selectedNavIndex,
        unreadCount: unreadCount,
        isBottom: isBottom,
        topPadding: topPadding,
        onItemTap: (i) {
          setState(() => _selectedNavIndex = i);
          _handleAction(_navItems[i]['action']);
        },
        onDragEnd: (d) => _onNavBarDragEnd(d, size),
      ),
    );
  }

  Widget _buildIconsContainer(
    List<Map<String, dynamic>> items,
    Size size, {
    required int unreadCount,
  }) {
    BorderRadius br;
    if (_buttonX >= size.width - 70) {
      br = const BorderRadius.only(
        topLeft: Radius.circular(25),
        bottomLeft: Radius.circular(25),
      );
    } else if (_buttonX <= 70) {
      br = const BorderRadius.only(
        topRight: Radius.circular(25),
        bottomRight: Radius.circular(25),
      );
    } else {
      br = BorderRadius.circular(25);
    }

    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(-1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            items.map((item) {
              final isNotif = item['action'] == 'notification';
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => _handleAction(item['action']),
                  child: Tooltip(
                    message: item['name'],
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(item['icon'], color: Colors.orange, size: 22),
                          if (isNotif && unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _Badge(
                                count: unreadCount,
                                minSize: 14,
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final double minSize;
  final double fontSize;

  const _Badge({
    required this.count,
    required this.minSize,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.whitecolor, width: 1.5),
      ),
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: AppColors.whitecolor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _NavBar extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int selectedIndex;
  final int unreadCount;
  final bool isBottom;
  final double topPadding;
  final void Function(int) onItemTap;
  final void Function(DraggableDetails) onDragEnd;

  const _NavBar({
    required this.items,
    required this.selectedIndex,
    required this.unreadCount,
    required this.isBottom,
    required this.topPadding,
    required this.onItemTap,
    required this.onDragEnd,
  });

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = Tween<Offset>(
      begin: widget.isBottom ? const Offset(0, 1) : const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br =
        widget.isBottom
            ? const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            )
            : const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            );

    final barContent = Container(
      height: 65 + widget.topPadding,
      padding: EdgeInsets.only(top: widget.topPadding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: widget.isBottom ? const Offset(0, -3) : const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(widget.items.length, (i) {
          final item = widget.items[i];
          final selected = widget.selectedIndex == i;
          final isNotif = item['action'] == 'notification';
          final hasBadge = isNotif && widget.unreadCount > 0;

          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onItemTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        width: selected ? 40 : 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? Colors.orange.withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item['icon'],
                          size: 22,
                          color: selected ? Colors.orange : Colors.black,
                        ),
                      ),
                      if (hasBadge)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: _Badge(
                            count: widget.unreadCount,
                            minSize: 16,
                            fontSize: 8,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: selected ? 10 : 9,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? Colors.orange : Colors.grey,
                    ),
                    child: Text(item['label']),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );

    return SlideTransition(
      position: _anim,
      child: LongPressDraggable(
        delay: const Duration(milliseconds: 400),
        feedback: Opacity(
          opacity: 0.7,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: barContent,
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: barContent),
        onDragEnd: widget.onDragEnd,
        child: barContent,
      ),
    );
  }
}
