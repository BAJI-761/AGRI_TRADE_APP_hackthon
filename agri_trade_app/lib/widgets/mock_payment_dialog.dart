import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A mock payment landing page dialog that simulates a real payment experience.
/// After successful "payment", calls [onPaymentComplete] to continue the flow.
class MockPaymentDialog extends StatefulWidget {
  final String orderId;
  final String cropName;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final Future<void> Function() onPaymentComplete;

  const MockPaymentDialog({
    super.key,
    required this.orderId,
    required this.cropName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.onPaymentComplete,
  });

  @override
  State<MockPaymentDialog> createState() => _MockPaymentDialogState();
}

class _MockPaymentDialogState extends State<MockPaymentDialog>
    with TickerProviderStateMixin {
  // 0 = method selection, 1 = input details, 2 = processing, 3 = success
  int _currentStep = 0;
  String _selectedMethod = '';
  
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _upiIdController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScale;

  double get _totalAmount => widget.quantity * widget.pricePerUnit;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
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
            // Header
            _buildHeader(),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(),
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
              : [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (_currentStep < 2)
            GestureDetector(
              onTap: () {
                if (_currentStep == 0) {
                  Navigator.pop(context);
                } else {
                  setState(() => _currentStep = 0);
                }
              },
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            )
          else
            const Icon(Icons.lock_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep == 3 ? 'Payment Successful' : 'Secure Payment',
                  style: AppTheme.headingSmall.copyWith(color: Colors.white, fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentStep == 3
                      ? 'Funds held in escrow'
                      : '₹${_totalAmount.toStringAsFixed(0)} • ${widget.cropName}',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // SSL badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('SSL', style: AppTheme.bodySmall.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMethodSelection();
      case 1:
        return _buildPaymentForm();
      case 2:
        return _buildProcessing();
      case 3:
        return _buildSuccess();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────
  // STEP 0: Payment Method Selection
  // ─────────────────────────────────────────────
  Widget _buildMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _summaryRow('Crop', widget.cropName),
              _summaryRow('Quantity', '${widget.quantity} ${widget.unit}'),
              _summaryRow('Price/Unit', '₹${widget.pricePerUnit.toStringAsFixed(0)}'),
              const Divider(height: 16),
              _summaryRow('Total Amount', '₹${_totalAmount.toStringAsFixed(0)}', isBold: true),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('Select Payment Method', style: AppTheme.labelLarge),
        const SizedBox(height: 12),

        _PaymentMethodTile(
          icon: Icons.account_balance_rounded,
          title: 'UPI',
          subtitle: 'Google Pay, PhonePe, BHIM',
          color: const Color(0xFF4CAF50),
          isSelected: _selectedMethod == 'upi',
          onTap: () => setState(() => _selectedMethod = 'upi'),
        ),
        const SizedBox(height: 10),
        _PaymentMethodTile(
          icon: Icons.credit_card_rounded,
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, RuPay',
          color: const Color(0xFF2196F3),
          isSelected: _selectedMethod == 'card',
          onTap: () => setState(() => _selectedMethod = 'card'),
        ),
        const SizedBox(height: 10),
        _PaymentMethodTile(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Net Banking',
          subtitle: 'All major banks supported',
          color: const Color(0xFFFF9800),
          isSelected: _selectedMethod == 'netbanking',
          onTap: () => setState(() => _selectedMethod = 'netbanking'),
        ),

        const SizedBox(height: 24),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedMethod.isEmpty
                ? null
                : () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: Payment Input Form
  // ─────────────────────────────────────────────
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4A00E0).withValues(alpha: 0.08),
                const Color(0xFF8E2DE2).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('Amount to Pay', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(
                '₹${_totalAmount.toStringAsFixed(0)}',
                style: AppTheme.displayMedium.copyWith(
                  color: const Color(0xFF4A00E0),
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (_selectedMethod == 'upi') ..._buildUpiForm(),
        if (_selectedMethod == 'card') ..._buildCardForm(),
        if (_selectedMethod == 'netbanking') ..._buildNetBankingForm(),

        const SizedBox(height: 24),

        // Pay button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Pay ₹${_totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
        ),

        const SizedBox(height: 12),
        // Security note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              'Secured by 256-bit encryption',
              style: AppTheme.bodySmall.copyWith(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildUpiForm() {
    return [
      Text('Enter UPI ID', style: AppTheme.labelLarge),
      const SizedBox(height: 10),
      TextField(
        controller: _upiIdController,
        decoration: InputDecoration(
          hintText: 'yourname@upi',
          prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF4CAF50)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: AppTheme.surfaceLight,
        ),
      ),
      const SizedBox(height: 16),
      // UPI apps row
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _upiAppChip('Google Pay', const Color(0xFF4285F4)),
          _upiAppChip('PhonePe', const Color(0xFF5F259F)),
          _upiAppChip('BHIM', const Color(0xFF00BCD4)),
        ],
      ),
    ];
  }

  Widget _upiAppChip(String name, Color color) {
    return GestureDetector(
      onTap: () => _upiIdController.text = '${name.toLowerCase().replaceAll(' ', '')}@upi',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(name, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  List<Widget> _buildCardForm() {
    return [
      Text('Card Details', style: AppTheme.labelLarge),
      const SizedBox(height: 10),
      // Card number
      TextField(
        controller: _cardNumberController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(16),
          _CardNumberFormatter(),
        ],
        decoration: InputDecoration(
          hintText: '4242 4242 4242 4242',
          labelText: 'Card Number',
          prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF2196F3)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: AppTheme.surfaceLight,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          // Expiry
          Expanded(
            child: TextField(
              controller: _expiryController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
                _ExpiryFormatter(),
              ],
              decoration: InputDecoration(
                hintText: 'MM/YY',
                labelText: 'Expiry',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: AppTheme.surfaceLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // CVV
          Expanded(
            child: TextField(
              controller: _cvvController,
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                hintText: '•••',
                labelText: 'CVV',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: AppTheme.surfaceLight,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Accepted cards
      Row(
        children: [
          _cardBrandChip('VISA', const Color(0xFF1A1F71)),
          const SizedBox(width: 8),
          _cardBrandChip('Mastercard', const Color(0xFFEB001B)),
          const SizedBox(width: 8),
          _cardBrandChip('RuPay', const Color(0xFF007B3A)),
        ],
      ),
    ];
  }

  Widget _cardBrandChip(String brand, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(brand, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  List<Widget> _buildNetBankingForm() {
    final banks = [
      ('SBI', const Color(0xFF1F3B79)),
      ('HDFC', const Color(0xFF004B87)),
      ('ICICI', const Color(0xFFFF6600)),
      ('Axis', const Color(0xFF800020)),
      ('PNB', const Color(0xFF1B3A5C)),
      ('BOB', const Color(0xFFFF6600)),
    ];

    return [
      Text('Select Your Bank', style: AppTheme.labelLarge),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: banks.map((bank) => GestureDetector(
          onTap: () {},
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: bank.$2.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bank.$2.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.account_balance_rounded, color: bank.$2, size: 24),
                const SizedBox(height: 6),
                Text(bank.$1, style: TextStyle(color: bank.$2, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        )).toList(),
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // STEP 2: Processing Animation
  // ─────────────────────────────────────────────
  Widget _buildProcessing() {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A00E0).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 36),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text('Processing Payment...', style: AppTheme.headingSmall.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Please do not close this window',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A00E0)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 3: Success Screen
  // ─────────────────────────────────────────────
  Widget _buildSuccess() {
    return SizedBox(
      height: 340,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _successScale,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.accentBlue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment Successful!', style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            Text(
              '₹${_totalAmount.toStringAsFixed(0)} held in escrow',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              'Transaction ID: TXN${widget.orderId.substring(0, 8).toUpperCase()}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary, fontSize: 11),
            ),
            const SizedBox(height: 32),
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

  // ─────────────────────────────────────────────
  // Process mock payment
  // ─────────────────────────────────────────────
  Future<void> _processPayment() async {
    setState(() => _currentStep = 2);

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Perform the actual Firestore update
    try {
      await widget.onPaymentComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _currentStep = 1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
      return;
    }

    // Show success
    if (mounted) {
      setState(() => _currentStep = 3);
      _successController.forward();
    }
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          Text(
            value,
            style: isBold
                ? AppTheme.labelLarge.copyWith(color: const Color(0xFF4A00E0), fontSize: 16)
                : AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Payment method tile
// ─────────────────────────────────────────────
class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelLarge.copyWith(fontSize: 14)),
                  Text(subtitle, style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Input Formatters
// ─────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
