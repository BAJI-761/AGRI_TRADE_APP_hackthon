import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable scaffold with premium gradient header and rounded content area.
///
/// Eliminates the copy-pasted Stack > gradient Container + SafeArea > Column
/// pattern used in farmer & retailer home screens.
class AppGradientScaffold extends StatelessWidget {
  /// Widgets rendered inside the gradient header area (above the rounded card).
  final List<Widget> headerChildren;

  /// Widgets rendered inside the scrollable white content area.
  final List<Widget> bodyChildren;

  /// Optional FAB
  final Widget? floatingActionButton;

  /// Header height as fraction of screen height (default 0.32).
  final double headerHeightFraction;

  const AppGradientScaffold({
    super.key,
    required this.headerChildren,
    required this.bodyChildren,
    this.floatingActionButton,
    this.headerHeightFraction = 0.32,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = (screenHeight * headerHeightFraction).clamp(200.0, 380.0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Gradient header
          Container(
            height: headerHeight,
            decoration: AppTheme.gradientHeaderDecoration,
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header content
                ...headerChildren,

                // Content area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: bodyChildren,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
