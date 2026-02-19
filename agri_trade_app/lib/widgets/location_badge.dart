import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Translucent location badge shown below the header bar on dashboards.
class LocationBadge extends StatelessWidget {
  final String location;

  const LocationBadge({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppTheme.secondaryAmber, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                location,
                style: AppTheme.bodySmall.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
