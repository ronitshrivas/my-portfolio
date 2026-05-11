import 'package:flutter/material.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';

class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String gifPath;

  const CustomRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.gifPath = 'animation/IdeaBulb.gif',
  }) : super(key: key);

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator>
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Add scroll tracking
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _animationController.forward();

    try {
      await widget.onRefresh();
    } finally {
      await _animationController.reverse();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            // Prevent refresh on fast downward scrolls
            if (notification is OverscrollNotification) {
              // Only allow refresh on overscroll at the top (negative overscroll)
              if (notification.overscroll < 0 &&
                  notification.metrics.pixels <= 0) {
                // This is a valid pull-to-refresh at the top
                return false; // Allow the refresh
              } else if (notification.overscroll > 0) {
                // This is overscroll at the bottom or fast scrolling down
                return true; // Block the refresh
              }
            }
            return false;
          },
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _handleRefresh,
            displacement: 40,
            edgeOffset: 0,
            triggerMode: RefreshIndicatorTriggerMode.onEdge,
            strokeWidth: 2.5,
            color: Colors.blue,
            backgroundColor: AppColors.whitecolor,
            child: widget.child,
          ),
        ),
        // Custom GIF overlay
        if (_isRefreshing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.whitecolor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(widget.gifPath, fit: BoxFit.contain),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Refreshing...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
