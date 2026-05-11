import 'package:flutter/material.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.child,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Widget? child;


  CustomButton copyWith({
    String? label,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Widget? child,
  }) {
    return CustomButton(
      label: label ?? this.label,
      onPressed: onPressed ?? this.onPressed,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      child: child ?? this.child,
    );
  }
  // --------------------------

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppStyle.buttonColor,
      ),
      onPressed: onPressed,
      child: child ?? Text(label),
    );
  }
}
