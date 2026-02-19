import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glassmorphism card wrapper for onboarding / auth screens.
class GlassCardWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCardWrapper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard,
      padding: padding,
      child: child,
    );
  }
}
