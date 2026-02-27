import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium dispute resolution dialog with reason categories,
/// cost breakdown, transport cost policy, and refund calculation.
class DisputeResolutionDialog extends StatefulWidget {
  final String orderId;
  final String cropName;
  final double quantity;
  final String unit;
  final double totalAmount;
  final Future<void> Function({
    required String reason,
    required String category,
    required String transportCostBearer,
    required double estimatedReturnCost,
    required double refundAmount,
  }) onDisputeSubmit;

  const DisputeResolutionDialog({
    super.key,
    required this.orderId,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.totalAmount,
    required this.onDisputeSubmit,
  });

  @override
  State<DisputeResolutionDialog> createState() => _DisputeResolutionDialogState();
}

class _DisputeResolutionDialogState extends State<DisputeResolutionDialog> {
  // 0 = select reason, 1 = review cost breakdown, 2 = processing, 3 = submitted
  int _currentStep = 0;
  String? _selectedCategory;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const List<_DisputeCategory> _categories = [
    _DisputeCategory(
      key: 'defective',
      icon: Icons.broken_image_rounded,
      title: 'Defective Goods',
      description: 'Goods are damaged, rotten, or unusable',
      color: Color(0xFFEF4444),
      transportBearer: 'farmer',
      policy: 'Farmer bears return transport cost',
    ),
    _DisputeCategory(
      key: 'quality_mismatch',
      icon: Icons.compare_rounded,
      title: 'Quality Mismatch',
      description: 'Grade or quality differs from listing',
      color: Color(0xFFF59E0B),
      transportBearer: 'farmer',
      policy: 'Farmer bears return transport cost',
    ),
    _DisputeCategory(
      key: 'wrong_item',
      icon: Icons.swap_horiz_rounded,
      title: 'Wrong Item',
      description: 'Received a different crop or variety',
      color: Color(0xFF8B5CF6),
      transportBearer: 'farmer',
      policy: 'Farmer bears return transport cost',
    ),
    _DisputeCategory(
      key: 'quantity_short',
      icon: Icons.production_quantity_limits_rounded,
      title: 'Quantity Shortage',
      description: 'Received less than the ordered quantity',
      color: Color(0xFF3B82F6),
      transportBearer: 'farmer',
      policy: 'Partial refund, no return needed',
    ),
    _DisputeCategory(
      key: 'transit_damage',
      icon: Icons.local_shipping_rounded,
      title: 'Damaged in Transit',
      description: 'Goods damaged during transportation',
      color: Color(0xFF06B6D4),
      transportBearer: 'carrier',
      policy: 'Carrier/insurance bears the cost',
    ),
    _DisputeCategory(
      key: 'other',
      icon: Icons.help_outline_rounded,
      title: 'Other Issue',
      description: 'Any other problem with the order',
      color: Color(0xFF64748B),
      transportBearer: 'pending_review',
      policy: 'Cost allocation after review',
    ),
  ];

  _DisputeCategory? get _selected =>
      _selectedCategory == null ? null : _categories.firstWhere((c) => c.key == _selectedCategory);

  // Estimated return transport cost (mock calculation based on order value)
  double get _estimatedReturnCost {
    if (_selected?.key == 'quantity_short') return 0; // No return needed
    return (widget.totalAmount * 0.05).clamp(50, 500); // 5% of order, min ₹50, max ₹500
  }

  double get _refundAmount {
    if (_selected?.key == 'quantity_short') {
      return widget.totalAmount * 0.3; // 30% partial refund for shortage
    }
    // Full refund minus transport cost deduction for farmer-at-fault cases
    if (_selected?.transportBearer == 'farmer') {
      return widget.totalAmount; // Full refund to retailer, farmer pays transport separately
    }
    return widget.totalAmount;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildCategorySelection()
                    : _currentStep == 1
                        ? _buildCostBreakdown()
                        : _buildSubmitted(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _currentStep == 3
              ? [AppTheme.primaryGreen, AppTheme.accentBlue]
              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentStep == 0) {
                Navigator.pop(context);
              } else if (_currentStep == 1) {
                setState(() => _currentStep = 0);
              }
            },
            child: Icon(
              _currentStep < 2 ? Icons.arrow_back_rounded : Icons.gavel_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep == 3 ? 'Dispute Filed' : 'Dispute Resolution',
                  style: AppTheme.headingSmall.copyWith(color: Colors.white, fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.cropName} • ₹${widget.totalAmount.toStringAsFixed(0)}',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentStep < 2 ? 'Step ${_currentStep + 1}/2' : '✓',
              style: AppTheme.bodySmall.copyWith(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 0: Category Selection
  // ─────────────────────────────────────────────
  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What went wrong?', style: AppTheme.headingSmall.copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Select the issue that best describes your problem',
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),

        ..._categories.map((cat) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _CategoryTile(
            category: cat,
            isSelected: _selectedCategory == cat.key,
            onTap: () => setState(() => _selectedCategory = cat.key),
          ),
        )),

        const SizedBox(height: 16),

        // Additional details
        Text('Additional Details', style: AppTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: AppTheme.surfaceLight,
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedCategory == null || _detailsController.text.trim().isEmpty
                ? null
                : () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Review Cost Breakdown →', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: Cost Breakdown & Policy
  // ─────────────────────────────────────────────
  Widget _buildCostBreakdown() {
    final cat = _selected!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Issue summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cat.color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(cat.icon, color: cat.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.title, style: AppTheme.labelLarge.copyWith(color: cat.color)),
                    Text(
                      _detailsController.text.trim(),
                      style: AppTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Transport Policy Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('Return Transport Policy', style: AppTheme.labelLarge.copyWith(fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              _policyRow(
                'Transport Cost Bearer',
                _bearerLabel(cat.transportBearer),
                _bearerIcon(cat.transportBearer),
                _bearerColor(cat.transportBearer),
              ),
              const SizedBox(height: 8),
              _policyRow(
                'Estimated Return Cost',
                _estimatedReturnCost > 0 ? '₹${_estimatedReturnCost.toStringAsFixed(0)}' : 'N/A',
                Icons.monetization_on_rounded,
                AppTheme.secondaryAmber,
              ),
              if (cat.key != 'quantity_short') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.infoBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.transportBearer == 'farmer'
                              ? 'The farmer will arrange and pay for return shipping. This cost is deducted from the farmer\'s future settlements.'
                              : cat.transportBearer == 'carrier'
                                  ? 'The logistics carrier or their insurance will cover the return cost as per the shipping agreement.'
                                  : 'Transport cost will be allocated after dispute review by our team.',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.infoBlue, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Refund Breakdown
        Text('Refund Breakdown', style: AppTheme.headingSmall.copyWith(fontSize: 15)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.05),
                AppTheme.accentBlue.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              _breakdownRow('Escrow Amount', '₹${widget.totalAmount.toStringAsFixed(0)}'),
              if (cat.key == 'quantity_short')
                _breakdownRow('Partial Refund (30%)', '₹${_refundAmount.toStringAsFixed(0)}', isHighlight: true)
              else ...[
                _breakdownRow('Refund to Retailer', '₹${_refundAmount.toStringAsFixed(0)}', isHighlight: true),
                if (cat.transportBearer == 'farmer')
                  _breakdownRow(
                    'Return Transport (Farmer pays)',
                    '₹${_estimatedReturnCost.toStringAsFixed(0)}',
                    isDeduction: true,
                  ),
              ],
              const Divider(height: 16),
              _breakdownRow(
                'You Receive',
                '₹${_refundAmount.toStringAsFixed(0)}',
                isBold: true,
                isGreen: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDispute,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit Dispute', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 3: Submitted Confirmation
  // ─────────────────────────────────────────────
  Widget _buildSubmitted() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorRed.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.gavel_rounded, color: AppTheme.errorRed, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Dispute Filed', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Your dispute has been recorded.\nThe farmer will be notified.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Refund of ₹${_refundAmount.toStringAsFixed(0)} will be processed\nwithin 3-5 business days.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDispute() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onDisputeSubmit(
        reason: _detailsController.text.trim(),
        category: _selectedCategory!,
        transportCostBearer: _selected!.transportBearer,
        estimatedReturnCost: _estimatedReturnCost,
        refundAmount: _refundAmount,
      );
      if (mounted) setState(() => _currentStep = 3);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Helper Widgets ──────────────────────
  Widget _policyRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(value, style: AppTheme.labelLarge.copyWith(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _breakdownRow(String label, String value, {bool isBold = false, bool isHighlight = false, bool isDeduction = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall.copyWith(
            color: isDeduction ? AppTheme.errorRed : AppTheme.textSecondary,
            fontSize: 13,
          )),
          Text(
            isDeduction ? '-$value' : value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold || isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isGreen ? AppTheme.primaryGreen : (isDeduction ? AppTheme.errorRed : AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _bearerLabel(String bearer) {
    switch (bearer) {
      case 'farmer': return '🌾 Farmer';
      case 'carrier': return '🚚 Carrier';
      case 'retailer': return '🛒 Retailer';
      default: return '⏳ Pending Review';
    }
  }

  IconData _bearerIcon(String bearer) {
    switch (bearer) {
      case 'farmer': return Icons.agriculture_rounded;
      case 'carrier': return Icons.local_shipping_rounded;
      case 'retailer': return Icons.store_rounded;
      default: return Icons.hourglass_empty_rounded;
    }
  }

  Color _bearerColor(String bearer) {
    switch (bearer) {
      case 'farmer': return AppTheme.secondaryAmber;
      case 'carrier': return AppTheme.accentBlue;
      case 'retailer': return AppTheme.errorRed;
      default: return AppTheme.textSecondary;
    }
  }
}

// ─────────────────────────────────────────────
// Category Tile Widget
// ─────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final _DisputeCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? category.color.withValues(alpha: 0.08) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? category.color : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title, style: AppTheme.labelLarge.copyWith(fontSize: 13)),
                  Text(category.description, style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ),
            // Policy badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _bearerColor(category.transportBearer).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _bearerTag(category.transportBearer),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _bearerColor(category.transportBearer),
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? category.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? category.color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _bearerTag(String bearer) {
    switch (bearer) {
      case 'farmer': return 'FARMER PAYS';
      case 'carrier': return 'CARRIER PAYS';
      default: return 'REVIEW';
    }
  }

  Color _bearerColor(String bearer) {
    switch (bearer) {
      case 'farmer': return AppTheme.secondaryAmber;
      case 'carrier': return AppTheme.accentBlue;
      default: return AppTheme.textSecondary;
    }
  }
}

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────
class _DisputeCategory {
  final String key;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String transportBearer; // farmer, carrier, retailer, pending_review
  final String policy;

  const _DisputeCategory({
    required this.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.transportBearer,
    required this.policy,
  });
}
