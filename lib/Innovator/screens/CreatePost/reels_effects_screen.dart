import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReelsEffectsScreen extends ConsumerStatefulWidget {
  const ReelsEffectsScreen({super.key});

  @override
  ConsumerState<ReelsEffectsScreen> createState() => _ReelsEffectsScreenState();
}

class _ReelsEffectsScreenState extends ConsumerState<ReelsEffectsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIdx = -1;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

  static const List<_Effect> _effects = [
    _Effect(
      'Beauty',
      Icons.face_retouching_natural,
      Color(0xFF6C63FF),
      'Smooth skin tone',
    ),
    _Effect(
      'Glitch',
      Icons.broken_image_rounded,
      Color(0xFFFF4444),
      'Retro glitch vibe',
    ),
    _Effect(
      'Neon',
      Icons.electric_bolt_rounded,
      Color(0xFF00E5FF),
      'Neon glow overlay',
    ),
    _Effect('Vintage', Icons.photo_filter, Color(0xFFD4A017), 'Film grain'),
    _Effect('Mirror', Icons.flip_rounded, Color(0xFF00C853), 'Mirror effect'),
    _Effect(
      'Blur BG',
      Icons.blur_on_rounded,
      Color(0xFF2196F3),
      'Background blur',
    ),
    _Effect(
      'Sparkle',
      Icons.auto_awesome_rounded,
      Color(0xFFFFC107),
      'Sparkle overlay',
    ),
    _Effect(
      'Rainbow',
      Icons.gradient_rounded,
      Color(0xFFE91E63),
      'Rainbow tones',
    ),
    _Effect(
      'Slow Mo',
      Icons.slow_motion_video_rounded,
      Color(0xFF9C27B0),
      '0.5× playback',
    ),
    _Effect(
      'Zoom Blur',
      Icons.zoom_in_rounded,
      Color(0xFF00BCD4),
      'Radial blur',
    ),
    _Effect(
      '3D Tilt',
      Icons.view_in_ar_rounded,
      Color(0xFF4CAF50),
      '3D perspective',
    ),
    _Effect(
      'Duotone',
      Icons.tonality_rounded,
      Color(0xFFFF5722),
      'Two-tone look',
    ),
    _Effect(
      'Ghost',
      Icons.blur_circular_rounded,
      Color(0xFF607D8B),
      'Ghost echo',
    ),
    _Effect(
      'Oversaturation',
      Icons.palette_rounded,
      Color(0xFFFF4081),
      'Pop colors',
    ),
    _Effect('Sketch', Icons.draw_rounded, Color(0xFF795548), 'Pencil sketch'),
    _Effect(
      'Negative',
      Icons.invert_colors_rounded,
      Color(0xFF424242),
      'Color invert',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnim = Tween<double>(
      begin: -2,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Effects',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Done',
              style: TextStyle(
                color: _orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedIdx >= 0) _buildSelectedBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Choose Effect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_effects.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (_selectedIdx >= 0)
                  GestureDetector(
                    onTap: () => setState(() => _selectedIdx = -1),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: _effects.length,
              itemBuilder: (_, i) => _buildEffectTile(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBanner() {
    final e = _effects[_selectedIdx];
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder:
          (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  e.color.withOpacity(0.3),
                  e.color.withOpacity(0.1),
                  e.color.withOpacity(0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: GradientRotation(_shimmerAnim.value),
              ),
              border: Border.all(color: e.color.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(e.icon, color: e.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: TextStyle(
                          color: e.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        e.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: e.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Applied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEffectTile(int i) {
    final e = _effects[i];
    final selected = _selectedIdx == i;

    return GestureDetector(
      onTap: () => setState(() => _selectedIdx = selected ? -1 : i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color:
              selected
                  ? e.color.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: selected ? e.color : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 46 : 40,
              height: selected ? 46 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? e.color.withOpacity(0.3) : Colors.white10,
              ),
              child: Icon(
                e.icon,
                color: selected ? e.color : Colors.white60,
                size: selected ? 24 : 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              e.name,
              style: TextStyle(
                color: selected ? e.color : Colors.white70,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (selected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: e.color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Effect {
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const _Effect(this.name, this.icon, this.color, this.description);
}
