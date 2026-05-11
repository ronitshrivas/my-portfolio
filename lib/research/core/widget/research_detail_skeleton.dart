import 'package:flutter/material.dart';

class ResearchDetailSkeleton extends StatefulWidget {
  const ResearchDetailSkeleton({super.key});

  @override
  State<ResearchDetailSkeleton> createState() => _ResearchDetailSkeletonState();
}

class _ResearchDetailSkeletonState extends State<ResearchDetailSkeleton>
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
        final color = Color.lerp(
          const Color(0xFFE8EAED),
          const Color(0xFFF5F6F8),
          _anim.value,
        )!;

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            _HeaderCardSkeleton(color: color),
            const SizedBox(height: 12),
            _DescriptionCardSkeleton(color: color),
            const SizedBox(height: 12),
            _DetailsCardSkeleton(color: color),
            const SizedBox(height: 12),
            _ResearcherCardSkeleton(color: color),
            const SizedBox(height: 12),
            _ActionButtonSkeleton(color: color),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

class _HeaderCardSkeleton extends StatelessWidget {
  final Color color;
  const _HeaderCardSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Box(color: color, width: 48, height: 48, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(color: color, width: double.infinity, height: 15),
                    const SizedBox(height: 6),
                    _Box(color: color, width: double.infinity, height: 15),
                    const SizedBox(height: 8),
                    _Box(color: color, width: 160, height: 13),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Box(color: color, width: 72, height: 28, radius: 20),
              const SizedBox(width: 8),
              _Box(color: color, width: 80, height: 28, radius: 20),
              const Spacer(),
              _Box(color: color, width: 64, height: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _DescriptionCardSkeleton extends StatelessWidget {
  final Color color;
  const _DescriptionCardSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Box(color: color, width: 100, height: 14),
          const SizedBox(height: 12),
          _Box(color: color, width: double.infinity, height: 13),
          const SizedBox(height: 6),
          _Box(color: color, width: double.infinity, height: 13),
          const SizedBox(height: 6),
          _Box(color: color, width: 200, height: 13),
        ],
      ),
    );
  }
}

class _DetailsCardSkeleton extends StatelessWidget {
  final Color color;
  const _DetailsCardSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Box(color: color, width: 60, height: 14),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                _Box(color: color, width: 18, height: 18, radius: 4),
                const SizedBox(width: 10),
                _Box(color: color, width: 80, height: 13),
              ]),
              _Box(color: color, width: 90, height: 13),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: const Color(0xFFE2E4E8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                _Box(color: color, width: 18, height: 18, radius: 4),
                const SizedBox(width: 10),
                _Box(color: color, width: 90, height: 13),
              ]),
              _Box(color: color, width: 90, height: 13),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResearcherCardSkeleton extends StatelessWidget {
  final Color color;
  const _ResearcherCardSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Box(color: color, width: 90, height: 14),
              const SizedBox(width: 8),
              _Box(color: color, width: 28, height: 22, radius: 20),
            ],
          ),
          const SizedBox(height: 16),
          _ResearcherRowSkeleton(color: color),
          const SizedBox(height: 12),
          Divider(height: 1, color: const Color(0xFFE2E4E8)),
          const SizedBox(height: 12),
          _ResearcherRowSkeleton(color: color),
        ],
      ),
    );
  }
}

class _ResearcherRowSkeleton extends StatelessWidget {
  final Color color;
  const _ResearcherRowSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Box(color: color, width: 36, height: 36, radius: 18),
        const SizedBox(width: 12),
        Expanded(child: _Box(color: color, width: double.infinity, height: 14)),
        const SizedBox(width: 12),
        _Box(color: color, width: 64, height: 28, radius: 8),
      ],
    );
  }
}

class _ActionButtonSkeleton extends StatelessWidget {
  final Color color;
  const _ActionButtonSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return _Box(color: color, width: double.infinity, height: 52, radius: 14);
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E4E8)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
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