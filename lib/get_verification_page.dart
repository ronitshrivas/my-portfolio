import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/providers/innovator_providers.dart';
import 'models/api_response.dart';
import 'theme/brand_colors.dart';
import 'widgets/cached_feed_image.dart';
import 'widgets/liquid_pressable.dart';

const _ink = BrandColors.ink;

/// Multi-phase "Get Verification Badge" flow: personal details → professional
/// details → profile picture → submit for review. Styled with the app's liquid
/// water-glass surfaces and brand palette.
class GetVerificationPage extends ConsumerStatefulWidget {
  const GetVerificationPage({super.key});

  @override
  ConsumerState<GetVerificationPage> createState() =>
      _GetVerificationPageState();
}

class _GetVerificationPageState extends ConsumerState<GetVerificationPage> {
  int _phase = 0;
  bool _submitting = false;

  // Phase 1 — personal.
  final _fullName = TextEditingController();
  final _dob = TextEditingController();
  final _gender = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  // Phase 2 — professional.
  final _occupation = TextEditingController();
  final _education = TextEditingController();
  final _bio = TextEditingController();

  // Phase 3 — photo.
  Uint8List? _photoBytes;
  String? _existingAvatarUrl;

  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    // Ensure the profile is loaded so the form can auto-fill from Edit Profile
    // data — even if the shared provider hasn't hydrated yet this session.
    Future.microtask(() async {
      if (ref.read(currentUserProvider) != null) return;
      try {
        final me = await ref.read(profileApiProvider).getMe();
        if (!mounted) return;
        ref.read(currentUserProvider.notifier).set(me);
      } catch (_) {
        // Best-effort prefill; the form still works empty.
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _dob, _gender, _phone, _address,
      _occupation, _education, _bio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(UserProfile me) {
    if (_prefilled) return;
    _prefilled = true;
    _fullName.text = (me.fullName ?? '').trim();
    _dob.text = (me.dateOfBirth ?? '').trim();
    _gender.text = (me.gender ?? '').trim();
    _phone.text = (me.phone ?? '').trim();
    _address.text = (me.address ?? '').trim();
    // Prefer the richer multi-value lists (from Edit Profile), fall back to the
    // single fields.
    _occupation.text = me.allOccupations.isNotEmpty
        ? me.allOccupations.join(', ')
        : (me.occupation ?? '').trim();
    _education.text = me.allEducations.isNotEmpty
        ? me.allEducations.join(', ')
        : (me.education ?? '').trim();
    _bio.text = (me.bio ?? '').trim();
    final avatar = me.avatar?.trim();
    if (avatar != null && avatar.isNotEmpty) _existingAvatarUrl = avatar;
  }

  bool get _phase1Valid =>
      _fullName.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty;
  bool get _phase2Valid =>
      _occupation.text.trim().isNotEmpty || _education.text.trim().isNotEmpty;
  // Valid if a new photo was chosen, or the user already has a profile picture.
  bool get _phase3Valid =>
      (_photoBytes != null && _photoBytes!.isNotEmpty) ||
      (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty);

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _photoBytes = bytes);
    } catch (_) {
      _toast('Could not pick the photo.');
    }
  }

  void _next() {
    if (_phase == 0 && !_phase1Valid) {
      _toast('Enter your full name and phone number.');
      return;
    }
    if (_phase == 1 && !_phase2Valid) {
      _toast('Add your occupation or education.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _phase++);
  }

  void _back() {
    if (_phase == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _phase--);
  }

  Future<void> _submit() async {
    if (!_phase3Valid) {
      _toast('Upload a profile picture to finish.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(profileApiProvider).submitVerification(
            fullName: _fullName.text.trim(),
            dateOfBirth: _dob.text.trim(),
            gender: _gender.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            occupation: _occupation.text.trim(),
            education: _education.text.trim(),
            bio: _bio.text.trim(),
            photoBytes: _photoBytes,
          );
      if (!mounted) return;
      ref.invalidate(verificationStatusProvider);
      // Also refresh the current-user profile (avatar may have changed).
      ref.read(currentUserProvider.notifier).refresh();
      HapticFeedback.mediumImpact();
      setState(() => _submitting = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast('Could not submit application.');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: SafeArea(
        child: statusAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          error: (_, __) => _wizardScaffold(context),
          data: (status) {
            // Prefill from current profile once it's available. Watching means
            // this retries automatically when the provider hydrates.
            final me = ref.watch(currentUserProvider);
            if (me != null) _prefill(me);

            if (status.isApproved) {
              return _StatusView(
                icon: Icons.verified_rounded,
                iconColor: BrandColors.accent,
                title: 'You’re verified',
                message:
                    'Your verification badge is active across Innovator.',
                onBack: () => Navigator.of(context).maybePop(),
              );
            }
            if (status.isPending) {
              return _StatusView(
                icon: Icons.hourglass_top_rounded,
                iconColor: _ink,
                title: 'Under review',
                message:
                    'Your application is being reviewed. You’ll get the badge '
                    'once it’s approved.',
                onBack: () => Navigator.of(context).maybePop(),
              );
            }
            return _wizardScaffold(context);
          },
        ),
      ),
    );
  }

  Widget _wizardScaffold(BuildContext context) {
    return Column(
      children: [
        _Header(phase: _phase, onBack: _back),
        _StepDots(phase: _phase, total: 3),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: _phaseBody(),
          ),
        ),
        _Footer(
          phase: _phase,
          submitting: _submitting,
          onPrimary: _phase == 2 ? _submit : _next,
        ),
      ],
    );
  }

  Widget _phaseBody() {
    return switch (_phase) {
      0 => _GlassSection(
          title: 'Personal details',
          subtitle: 'Tell us who you are.',
          children: [
            _Field(label: 'Full name', controller: _fullName),
            _Field(label: 'Date of birth', controller: _dob, hint: 'DD/MM/YYYY'),
            _Field(label: 'Gender', controller: _gender),
            _Field(
              label: 'Phone',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
            _Field(label: 'Address', controller: _address),
          ],
        ),
      1 => _GlassSection(
          title: 'Professional details',
          subtitle: 'What do you do?',
          children: [
            _Field(label: 'Occupation', controller: _occupation),
            _Field(label: 'Education', controller: _education),
            _Field(label: 'Bio', controller: _bio, maxLines: 4),
          ],
        ),
      _ => _GlassSection(
          title: 'Profile picture',
          subtitle: 'Add a clear photo of yourself.',
          children: [
            _PhotoPicker(
              bytes: _photoBytes,
              existingUrl: _existingAvatarUrl,
              onPick: _pickPhoto,
            ),
          ],
        ),
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.phase, required this.onBack});

  final int phase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const titles = ['Get verified', 'Get verified', 'Get verified'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 4),
      child: Row(
        children: [
          LiquidPressable(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            rippleColor: _ink,
            intensity: .6,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .6),
                border: Border.all(color: Colors.white.withValues(alpha: .6)),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: 20, color: _ink.withValues(alpha: .8)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              titles[phase],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.2,
              ),
            ),
          ),
          Icon(Icons.verified_rounded,
              color: BrandColors.accent.withValues(alpha: .85)),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.phase, required this.total});

  final int phase;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == phase ? 26 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i <= phase
                    ? BrandColors.secondarySurface
                    : _ink.withValues(alpha: .18),
              ),
            ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: _ink.withValues(alpha: .55),
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _ink.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 15, color: _ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _ink.withValues(alpha: .35)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              filled: true,
              fillColor: _ink.withValues(alpha: .04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.bytes,
    required this.onPick,
    this.existingUrl,
  });

  final Uint8List? bytes;
  final String? existingUrl;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (bytes != null) {
      avatar = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (existingUrl != null && existingUrl!.isNotEmpty) {
      avatar = CachedFeedImage(
        url: existingUrl!,
        fit: BoxFit.cover,
        width: 140,
        height: 140,
        errorWidget: Icon(
          Icons.add_a_photo_rounded,
          size: 40,
          color: _ink.withValues(alpha: .4),
        ),
      );
    } else {
      avatar = Icon(
        Icons.add_a_photo_rounded,
        size: 40,
        color: _ink.withValues(alpha: .4),
      );
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onPick,
            child: Container(
              width: 140,
              height: 140,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ink.withValues(alpha: .05),
                border: Border.all(
                  color: _ink.withValues(alpha: .15),
                  width: 1.5,
                ),
              ),
              child: avatar,
            ),
          ),
          const SizedBox(height: 14),
          LiquidPressable(
            onTap: onPick,
            borderRadius: BorderRadius.circular(14),
            rippleColor: _ink,
            intensity: .6,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _ink.withValues(alpha: .15)),
              ),
              child: Text(
                (bytes == null && (existingUrl == null || existingUrl!.isEmpty))
                    ? 'Choose photo'
                    : 'Change photo',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _ink.withValues(alpha: .8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.phase,
    required this.submitting,
    required this.onPrimary,
  });

  final int phase;
  final bool submitting;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final isLast = phase == 2;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewPaddingOf(context).bottom + 14,
      ),
      child: LiquidPressable(
        onTap: submitting ? () {} : onPrimary,
        borderRadius: BorderRadius.circular(16),
        rippleColor: Colors.white,
        intensity: .6,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BrandColors.secondarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  isLast ? 'Submit for review' : 'Continue',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.onBack,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: LiquidPressable(
              onTap: onBack,
              borderRadius: BorderRadius.circular(999),
              rippleColor: _ink,
              intensity: .6,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .6),
                  border: Border.all(color: Colors.white.withValues(alpha: .6)),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    size: 20, color: _ink.withValues(alpha: .8)),
              ),
            ),
          ),
          const Spacer(),
          Icon(icon, size: 72, color: iconColor),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: _ink.withValues(alpha: .6),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
