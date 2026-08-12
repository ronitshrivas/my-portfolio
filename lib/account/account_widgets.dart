import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_colors.dart';
import '../widgets/fast_glass.dart';

const _ink = BrandColors.ink;

/// Floating glass toast used across the account screens.
void accountToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      backgroundColor: _ink.withValues(alpha: .92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
      ),
    ),
  );
}

/// Back button + title header, matching the privacy/settings pages.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
      child: Row(
        children: [
          FastTap(
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(color: Colors.white.withValues(alpha: .95)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: _ink.withValues(alpha: .85),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted text field used on the account forms.
class AccountField extends StatelessWidget {
  const AccountField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _ink.withValues(alpha: .6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: .6),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
            cursorColor: _ink,
            decoration: InputDecoration(
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: _ink.withValues(alpha: .4)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary filled button with an in-flight spinner; disabled while [busy].
class AccountPrimaryButton extends StatelessWidget {
  const AccountPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.busy = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool busy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFC0392B) : BrandColors.secondarySurface;
    return FastTap(
      onTap: busy ? () {} : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: busy ? .6 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color,
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
