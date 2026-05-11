// Optional: Add this widget for visual swipe indicators
// You can add this to both Homepage and VideoFeedPage for better UX

import 'package:flutter/material.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/Innovator/screens/Feed/Video_Feed.dart';

class _SwipeIndicator extends StatefulWidget {
  final bool isLeftSwipe;

  const _SwipeIndicator({Key? key, required this.isLeftSwipe})
    : super(key: key);

  @override
  __SwipeIndicatorState createState() => __SwipeIndicatorState();
}

class __SwipeIndicatorState extends State<_SwipeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);

    // Hide indicator after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_animation.value * 0.5),
          child: Transform.translate(
            offset: Offset(
              widget.isLeftSwipe
                  ? _animation.value * 20
                  : -_animation.value * 20,
              0,
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.whitecolor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isLeftSwipe ? Icons.chevron_right : Icons.chevron_left,
                color: AppColors.whitecolor,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternative: PageView based navigation for smoother transitions
// You can use this instead of GestureDetector approach

class FeedNavigator extends StatefulWidget {
  const FeedNavigator({Key? key}) : super(key: key);

  @override
  _FeedNavigatorState createState() => _FeedNavigatorState();
}

class _FeedNavigatorState extends State<FeedNavigator> {
  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          Homepage(), // This would be the modified Homepage without toggle button
          ReelsScreen(), // This would be the modified VideoFeedPage without toggle button
        ],
      ),
    );
  }
}
