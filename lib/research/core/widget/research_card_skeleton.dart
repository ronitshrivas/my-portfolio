import 'package:flutter/material.dart';

class ResearchCardSkeleton extends StatefulWidget {
  const ResearchCardSkeleton({super.key});

  @override
  State<ResearchCardSkeleton> createState() => _ResearchCardSkeletonState();
}

class _ResearchCardSkeletonState extends State<ResearchCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final base = const Color(0xFFE8EAED);
        final highlight = const Color(0xFFF5F6F8);
        final color = Color.lerp(base, highlight, _anim.value)!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E4E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Box(color: color, width: double.infinity, height: 14),
                        const SizedBox(height: 6),
                        _Box(color: color, width: 180, height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Box(color: color, width: 48, height: 24, radius: 20),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Box(color: color, width: 14, height: 14, radius: 4),
                  const SizedBox(width: 6),
                  _Box(color: color, width: 160, height: 12),
                ],
              ),
              const SizedBox(height: 8),
              _Box(color: color, width: double.infinity, height: 12),
              const SizedBox(height: 4),
              _Box(color: color, width: 220, height: 12),
              const SizedBox(height: 14),
              Divider(height: 1, color: const Color(0xFFE2E4E8)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Box(color: color, width: 72, height: 24, radius: 6),
                  _Box(color: color, width: 80, height: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double radius;

  const _Box({
    required this.color,
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}