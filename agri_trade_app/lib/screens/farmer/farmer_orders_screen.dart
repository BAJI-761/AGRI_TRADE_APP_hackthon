import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/order.dart' as model;
import '../../models/trade_enums.dart'; // Phase 1
import '../../config/feature_flags.dart'; // Phase 2
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  final OrderService _service = OrderService();
  final PaymentService _paymentService = PaymentService(); // Phase 2
  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final farmerId = authService.user?.uid ?? authService.phone ?? '';
    final ls = Provider.of<LanguageService>(context);

    if (farmerId.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceWhite,
        appBar: AppBar(
          title: Text(ls.getLocalizedString('my_orders')),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(ls.getLocalizedString('please_login_again'))),
      );
    }

    return NavigationHelper(
      child: AppGradientScaffold(
        headerHeightFraction: 0.2,
        headerChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  ls.getLocalizedString('my_orders'),
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          StreamBuilder<List<model.Order>>(
            stream: _service.streamOrdersForFarmer(farmerId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
                );
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          ls.getLocalizedString('no_orders_yet'),
                          style: AppTheme.bodyLarge.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Summary Stats
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration.copyWith(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(context, ls.getLocalizedString('total'),
                              '${orders.length}'),
                          _buildStatItem(
                              context,
                              ls.getLocalizedString('accepted'),
                              '${orders.where((o) => o.status == 'accepted').length}'),
                          _buildStatItem(
                              context,
                              ls.getLocalizedString('pending'),
                              '${orders.where((o) => o.status == 'pending').length}'),
                        ],
                      ),
                    ),
                  ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(context, orders[index], ls),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.primaryGreen)),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }

  Widget _buildOrderCard(
      BuildContext context, model.Order o, LanguageService ls) {
    // Phase 2: Use displayStatus from Order model
    final displayStatus = o.displayStatus;
    
    // Determine color based on status/tradeState
    Color statusColor;
    if (o.tradeState == TradeState.paymentHeld) {
      statusColor = Colors.purple;
    } else if (o.status == 'accepted') {
      statusColor = AppTheme.primaryGreen;
    } else if (o.status == 'rejected') {
      statusColor = AppTheme.errorRed;
    } else {
      statusColor = AppTheme.secondaryAmber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(context, o),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(o.crop, style: AppTheme.headingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayStatus.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${o.quantity} ${o.unit}',
                              style: AppTheme.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text('₹${o.pricePerUnit}/${o.unit}',
                              style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)}',
                            style: AppTheme.headingSmall
                                .copyWith(color: AppTheme.primaryGreen)),
                        Text(_formatDate(o.createdAt),
                            style: AppTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, model.Order o) {
    final ls = Provider.of<LanguageService>(context, listen: false);
    
    // Determine color based on status/tradeState
    final displayStatus = o.displayStatus;
    Color statusColor;
    if (o.tradeState == TradeState.paymentHeld) {
      statusColor = Colors.purple;
    } else if (o.status == 'accepted') {
      statusColor = AppTheme.primaryGreen;
    } else if (o.status == 'rejected') {
      statusColor = AppTheme.errorRed;
    } else {
      statusColor = AppTheme.secondaryAmber;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(o.crop, style: AppTheme.headingMedium),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayStatus.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _detailRow(ls.getLocalizedString('quantity'),
                    '${o.quantity} ${o.unit}'),
                _detailRow(ls.getLocalizedString('price_per_unit'),
                    '₹${o.pricePerUnit} / ${o.unit}'),
                _detailRow(ls.getLocalizedString('total'),
                    '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(2)}'),
                _detailRow(ls.getLocalizedString('available_date'),
                    _formatDate(o.availableDate)),
                if (o.location.isNotEmpty)
                  _detailRow(ls.getLocalizedString('location'), o.location),
                if (o.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(ls.getLocalizedString('notes'),
                      style: AppTheme.bodySmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  Text(o.notes, style: AppTheme.bodyLarge),
                ],
                const SizedBox(height: 24),
                
                // Phase 2: Proceed to Payment Button
                if (FeatureFlags.escrowEnabled && 
                    o.tradeState == TradeState.accepted) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (isLoading) return;
                        setState(() => isLoading = true);
                        try {
                          await _paymentService.holdPayment(o.id);
                          if (context.mounted) {
                             Navigator.pop(context);
                             ScaffoldMessenger.of(context).showSnackBar( 
                               const SnackBar(content: Text('Processing payment hold...')),
                             );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                            setState(() => isLoading = false);
                          }
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (isLoading) return Colors.grey;
                          return Colors.purple;
                        }),
                      ),
                      child: _buildButtonChild(isLoading), 
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: AppTheme.primaryButtonStyle,
                    child: Text(ls.getLocalizedString('close')),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildButtonChild(bool isLoading) {
    if (isLoading) {
      return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: Colors.white));
    }
    return const Text("Proceed to Payment");
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600])),
          Text(value,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

