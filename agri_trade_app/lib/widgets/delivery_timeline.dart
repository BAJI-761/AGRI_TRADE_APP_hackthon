import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeliveryTimeline extends StatelessWidget {
  final String currentStatus;

  const DeliveryTimeline({super.key, required this.currentStatus});

  static const List<_StepData> _steps = [
    _StepData('processing', Icons.inventory_2_rounded, 'Order Processing'),
    _StepData('shipped', Icons.local_shipping_rounded, 'Shipped'),
    _StepData('inTransit', Icons.route_rounded, 'In Transit'),
    _StepData('outForDelivery', Icons.delivery_dining_rounded, 'Out for Delivery'),
    _StepData('delivered', Icons.check_circle_rounded, 'Delivered'),
  ];

  @override
  Widget build(BuildContext context) {
    final statusKeys = _steps.map((s) => s.key).toList();
    int currentIndex = statusKeys.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    // Progress fraction (0.0 to 1.0)
    final progress = _steps.length > 1 ? currentIndex / (_steps.length - 1) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery Status', style: AppTheme.headingSmall.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      _steps[currentIndex].label,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTheme.labelLarge.copyWith(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Gradient progress bar
          _GradientProgressBar(progress: progress),

          const SizedBox(height: 20),

          // Timeline steps
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == _steps.length - 1;

            return _TimelineStep(
              step: step,
              isActive: isActive,
              isCurrent: isCurrent,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Step data model
// ─────────────────────────────────────────────
class _StepData {
  final String key;
  final IconData icon;
  final String label;
  const _StepData(this.key, this.icon, this.label);
}

// ─────────────────────────────────────────────
// Gradient progress bar
// ─────────────────────────────────────────────
class _GradientProgressBar extends StatelessWidget {
  final double progress;
  const _GradientProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGreenDark,
                      AppTheme.primaryGreen,
                      AppTheme.accentBlue,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Shimmer dot at the end
              if (progress > 0 && progress < 1)
                Positioned(
                  left: constraints.maxWidth * progress - 6,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual timeline step
// ─────────────────────────────────────────────
class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isActive;
  final bool isCurrent;
  final bool isLast;

  const _TimelineStep({
    required this.step,
    required this.isActive,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical connector line + circle
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle node
                Container(
                  width: isCurrent ? 36 : 28,
                  height: isCurrent ? 36 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? (isCurrent
                            ? AppTheme.primaryGreen
                            : AppTheme.primaryGreen.withValues(alpha: 0.15))
                        : AppTheme.textTertiary.withValues(alpha: 0.1),
                    border: isCurrent
                        ? Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 3)
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isActive ? step.icon : Icons.circle_outlined,
                    size: isCurrent ? 18 : 14,
                    color: isActive
                        ? (isCurrent ? Colors.white : AppTheme.primaryGreen)
                        : AppTheme.textTertiary,
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primaryGreen.withValues(alpha: 0.25)
                            : AppTheme.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Step content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppTheme.primaryGreenSurface.withValues(alpha: 0.6)
                    : (isActive ? AppTheme.surfaceLight : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      step.label,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: isCurrent ? FontWeight.w700 : (isActive ? FontWeight.w600 : FontWeight.normal),
                        color: isActive ? AppTheme.textPrimary : AppTheme.textTertiary,
                        fontSize: isCurrent ? 14 : 13,
                      ),
                    ),
                  ),
                  if (isActive && !isCurrent)
                    const Icon(Icons.check_rounded, size: 16, color: AppTheme.primaryGreen),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CURRENT',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
