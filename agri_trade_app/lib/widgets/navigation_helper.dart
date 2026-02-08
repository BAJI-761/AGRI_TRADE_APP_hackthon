import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation helper widget for forward/backward navigation
class NavigationHelper extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final bool showForwardButton;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const NavigationHelper({
    super.key,
    required this.child,
    this.showBackButton = true,
    this.showForwardButton = false,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: showBackButton,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && onBack != null) {
          onBack!();
        }
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 0) {
              // Swipe right - go back
              if (Navigator.canPop(context)) {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              }
            } else if (details.primaryVelocity! < 0) {
              // Swipe left - go forward (if implemented)
              if (onForward != null) {
                HapticFeedback.lightImpact();
                onForward!();
              }
            }
          }
        },
        child: child,
      ),
    );
  }
}

/// AppBar with navigation buttons
class NavigationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showBackButton;
  final bool showForwardButton;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final Widget? leading;

  const NavigationAppBar({
    super.key,
    required this.title,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.showBackButton = true,
    this.showForwardButton = false,
    this.onBack,
    this.onForward,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);
    final canGoForward = showForwardButton && onForward != null;

    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor ?? Colors.green,
      foregroundColor: foregroundColor ?? Colors.white,
      leading: leading ??
          (showBackButton && canGoBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onBack != null) {
                      onBack!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  tooltip: 'Go back (or swipe right)',
                )
              : null),
      automaticallyImplyLeading: showBackButton && canGoBack,
      actions: [
        if (canGoForward)
          IconButton(
            icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                HapticFeedback.lightImpact();
                onForward!();
              },
              tooltip: 'Go forward (or swipe left)',
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Floating navigation buttons
class FloatingNavigationButtons extends StatelessWidget {
  final bool showBack;
  final bool showForward;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  const FloatingNavigationButtons({
    super.key,
    this.showBack = true,
    this.showForward = false,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);
    final canGoForward = showForward && onForward != null;

    if (!canGoBack && !canGoForward) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      left: 16,
      child: Row(
        children: [
          if (canGoBack)
            FloatingActionButton.small(
              heroTag: 'back_button',
              onPressed: () {
                HapticFeedback.lightImpact();
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          if (canGoBack && canGoForward) const SizedBox(width: 8),
          if (canGoForward)
            FloatingActionButton.small(
              heroTag: 'forward_button',
              onPressed: () {
                HapticFeedback.lightImpact();
                onForward!();
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

