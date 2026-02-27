import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as model;
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../services/payment_service.dart';
import '../../services/trade_lifecycle_service.dart';
import 'dart:convert';

 // Phase 2
import '../../widgets/delivery_timeline.dart';
import '../../widgets/mock_payment_dialog.dart';
import '../../widgets/dispute_resolution_dialog.dart';
import '../../widgets/rating_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _service = OrderService();
  final PaymentService _paymentService = PaymentService();
  final TradeLifecycleService _lifecycleService = TradeLifecycleService();
  
  @override
  void initState() {
    super.initState();
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    _service.setNotificationService(notificationService);
  }
  
  @override
  Widget build(BuildContext context) {
    final ls = Provider.of<LanguageService>(context);

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
                  ls.getLocalizedString('orders'),
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          StreamBuilder<List<model.Order>>(
            stream: _service.streamOrdersForRetailer(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorRed)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: AppTheme.primaryButtonStyle,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      ls.getLocalizedString('no_orders_yet'),
                      style: AppTheme.bodyLarge.copyWith(color: Colors.grey),
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final o = orders[index];
                  
                  // Phase 2: Use displayStatus from Order model
                  final displayStatus = o.displayStatus;
                  
                  // Color based on tradeState ONLY
                  Color statusColor;
                  final state = o.tradeState;
                  
                  if (state == 'completed') {
                    statusColor = AppTheme.primaryGreen;
                  } else if (state == 'disputed') {
                    statusColor = AppTheme.errorRed;
                  } else if (state == 'paymentHeld') {
                    statusColor = Colors.purple;
                  } else if (state == 'accepted') {
                    statusColor = AppTheme.primaryGreen;
                  } else if (state == 'rejected') {
                    statusColor = AppTheme.errorRed;
                  } else {
                    statusColor = AppTheme.secondaryAmber; // pending
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
                                 children: [
                                   Container(
                                     padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                                       color: statusColor.withValues(alpha: 0.1),
                                       shape: BoxShape.circle,
                                     ),
                                     child: Icon(
                                       state == 'accepted' || state == 'paymentHeld' || state == 'completed'
                                            ? Icons.check
                                            : state == 'rejected' || state == 'disputed'
                                                ? Icons.close
                                                : Icons.pending,
                                       color: statusColor,
                                       size: 24,
                                     ),
                                   ),
                                   const SizedBox(width: 16),
                                   Expanded(
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           '${o.crop} • ${o.quantity} ${o.unit}',
                                           style: AppTheme.headingSmall.copyWith(fontSize: 18),
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                         const SizedBox(height: 4),
                                         Text(
                                            '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)}',
                                            style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen),
                                         ),
                                       ],
                                     ),
                                   ),
                                   if (state == 'pending')
                                     Column(
                                       children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 32),
                                            onPressed: () => _acceptOrder(o.id),
                                            tooltip: ls.getLocalizedString('accept'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: AppTheme.errorRed, size: 32),
                                            onPressed: () => _rejectOrder(o.id),
                                            tooltip: ls.getLocalizedString('reject'),
                                          ),
                                       ],
                                     )
                                   else
                                     Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          o.tradeState.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                     ),
                                 ],
                               ),
                               const SizedBox(height: 12),
                               const Divider(),
                               const SizedBox(height: 8),
                               _buildDetailRow(ls.getLocalizedString('price_per_unit'), '₹${o.pricePerUnit} / ${o.unit}'),
                               _buildDetailRow(ls.getLocalizedString('location'), o.location),
                               _buildDetailRow(ls.getLocalizedString('available_date'), _formatDate(o.availableDate)),
                             ],
                           ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: AppTheme.bodySmall.copyWith(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showOrderDetails(BuildContext context, model.Order o) {
    final ls = Provider.of<LanguageService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(o.crop, style: AppTheme.headingMedium),
              const SizedBox(height: 8),
              Text('${o.quantity} ${o.unit}', style: AppTheme.headingSmall.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 24),
              _buildFullDetailRow(ls.getLocalizedString('price_per_unit'), '₹${o.pricePerUnit}'),
              _buildFullDetailRow(ls.getLocalizedString('available_date'), _formatDate(o.availableDate)),
              if (o.location.isNotEmpty)
                _buildFullDetailRow(ls.getLocalizedString('location'), o.location),
              if (o.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('${ls.getLocalizedString('notes')}:', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(o.notes, style: AppTheme.bodyLarge),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              

              
              Text(
                ls.currentLanguage == 'te' ? 'నాణ్యత నివేదిక' : 'Quality Report',
                style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 12),
              
              // Images
              if (o.cropImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: o.cropImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildSafeImage(o.cropImages[index]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Table Data
              Table(
                columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(2)},
                children: [
                  _buildTableRow(ls.currentLanguage == 'te' ? 'రైతు GST' : 'Farmer GST', o.gstNumber),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'సాగు తేదీ' : 'Cultivated Date', _formatDate(o.cultivatedDate ?? DateTime.now())), 
                  _buildTableRow(ls.currentLanguage == 'te' ? 'కోత తేదీ' : 'Harvested Date', _formatDate(o.harvestedDate ?? DateTime.now())),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'నిల్వ' : 'Storage', '${o.storageType} (${o.storageDuration} days)'),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'తేమ' : 'Moisture', '${o.moistureContent}%'),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'గ్రేడ్' : 'Grade', o.grade),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'ఆర్గానిక్' : 'Organic', o.isOrganic ? 'Yes' : 'No'),
                  if (!o.isOrganic)
                     _buildTableRow(ls.currentLanguage == 'te' ? 'పురుగుమందులు' : 'Pesticides', o.pesticidesUsed),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'ప్యాకేజింగ్' : 'Packaging', o.packaging),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'భూమి' : 'Land Area', '${o.landArea} Acres'),
                  _buildTableRow(ls.currentLanguage == 'te' ? 'రకం' : 'Variety', o.cropVariety),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Phase 5: Reputation Impact (Visible to Retailer too)
              if (o.reputationImpact != 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildFullDetailRow('Reputation Impact', 
                  o.reputationImpact > 0 ? '+${o.reputationImpact} (To Farmer)' : '${o.reputationImpact} (To Farmer)'),
              ],

              const SizedBox(height: 32),
              if (o.tradeState == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _acceptOrder(o.id);
                        },
                        icon: const Icon(Icons.check),
                        label: Text(ls.getLocalizedString('accept')),
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(AppTheme.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectOrder(o.id);
                        },
                        icon: const Icon(Icons.close),
                        label: Text(ls.getLocalizedString('reject')),
                         style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(AppTheme.errorRed),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Phase 6: Retailer Lifecycle Actions - REFACTORED
                
                Builder(
                  builder: (context) {
                    final state = o.tradeState;
                    // Debug print
                    debugPrint('Building Retailer Actions for Order ${o.id}: State=$state');

                    // 1. Accepted -> Show Proceed to Payment
                    if (state == 'accepted') {
                       return Column(
                         children: [
                           SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final nav = Navigator.of(context);
                                  
                                  // Close the bottom sheet first
                                  nav.pop();
                                  
                                  // Show mock payment dialog
                                  final result = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => MockPaymentDialog(
                                      orderId: o.id,
                                      cropName: o.crop,
                                      quantity: o.quantity,
                                      unit: o.unit,
                                      pricePerUnit: o.pricePerUnit,
                                      onPaymentComplete: () => _paymentService.holdPayment(o.id),
                                    ),
                                  );
                                  
                                  if (result == true) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Payment held in escrow'),
                                        backgroundColor: Colors.purple,
                                      ),
                                    );
                                  }
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(Colors.purple),
                                ),
                                child: const Text("Proceed to Payment"), 
                              ),
                            ),
                            const SizedBox(height: 12),
                         ],
                       );
                    }

                    if (state == 'paymentHeld') {
                      return Column(
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Tracking', style: AppTheme.headingSmall.copyWith(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                                onPressed: () => _showTrackingUpdateDialog(context, o),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DeliveryTimeline(currentStatus: o.deliveryTracking?.status ?? 'processing'),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(context);
                                
                                try {
                                  await _lifecycleService.confirmDelivery(o.id);
                                  nav.pop();
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Delivery Confirmed!'), backgroundColor: AppTheme.primaryGreen),
                                  );
                                } catch (e) {
                                  nav.pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
                                  );
                                }
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(AppTheme.primaryGreen),
                              ),
                              child: const Text("Confirm Delivery"), 
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                 final messenger = ScaffoldMessenger.of(context);
                                 Navigator.pop(context);
                                 _showDisputeResolution(context, o, messenger);
                              },
                              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                              child: const Text("Raise Dispute"),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }

                    // 3. Completed -> Badge
                    if (state == 'completed') {
                      return Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                                SizedBox(width: 8),
                                Text('COMPLETED', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => RatingDialog(
                                    orderId: o.id,
                                    partnerName: 'Farmer',
                                    cropName: o.crop,
                                    partnerRole: 'farmer',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.star_rounded, size: 18),
                              label: const Text('Rate This Trade'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // 4. Disputed -> Badge
                    if (state == 'disputed') {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text('DISPUTED', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }

                    // 5. Rejected -> Badge
                    if (state == 'rejected') {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text('REJECTED', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }

                    // Default close button
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: AppTheme.primaryButtonStyle,
                        child: Text(ls.getLocalizedString('close')), 
                      ),
                    );
                  }
                ),
            ],
          ),
        ),
        );
      },
    );
  }

  Future<void> _showDisputeResolution(BuildContext context, model.Order o, ScaffoldMessengerState messenger) async {
    final totalAmount = o.quantity * o.pricePerUnit;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DisputeResolutionDialog(
        orderId: o.id,
        cropName: o.crop,
        quantity: o.quantity,
        unit: o.unit,
        totalAmount: totalAmount,
        onDisputeSubmit: ({
          required String reason,
          required String category,
          required String transportCostBearer,
          required double estimatedReturnCost,
          required double refundAmount,
        }) => _lifecycleService.raiseDispute(
          o.id,
          reason,
          category: category,
          transportCostBearer: transportCostBearer,
          estimatedReturnCost: estimatedReturnCost,
          refundAmount: refundAmount,
          totalOrderAmount: totalAmount,
        ),
      ),
    );
    
    if (result == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Dispute filed successfully'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildFullDetailRow(String label, String value) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text('$label:', style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600])),
           Text(value, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
         ],
       ),
     );
  }

  Future<void> _acceptOrder(String orderId) async {
    final ls = Provider.of<LanguageService>(context, listen: false);
    try {
      await _service.acceptOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ls.currentLanguage == 'te' 
                ? 'ఆర్డర్ అంగీకరించబడింది!' 
                : 'Order accepted successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting order: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final ls = Provider.of<LanguageService>(context, listen: false);
    try {
      await _service.rejectOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ls.currentLanguage == 'te' 
                ? 'ఆర్డర్ తిరస్కరించబడింది.' 
                : 'Order rejected.'),
             backgroundColor: AppTheme.secondaryAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting order: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
  Future<void> _showTrackingUpdateDialog(BuildContext parentContext, model.Order order) async {
    final trackingIdController = TextEditingController(text: order.deliveryTracking?.trackingId ?? '');
    final carrierController = TextEditingController(text: order.deliveryTracking?.carrierName ?? '');
    String selectedStatus = order.deliveryTracking?.status ?? 'processing';
    
    final steps = ['processing', 'shipped', 'inTransit', 'outForDelivery', 'delivered'];
    final labels = {
      'processing': 'Processing',
      'shipped': 'Shipped',
      'inTransit': 'In Transit',
      'outForDelivery': 'Out for Delivery',
      'delivered': 'Delivered'
    };

    await showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Update Tracking'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: steps.contains(selectedStatus) ? selectedStatus : steps.first,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: steps.map((s) => DropdownMenuItem(value: s, child: Text(labels[s]!))).toList(),
                    onChanged: (v) => setState(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: trackingIdController,
                    decoration: const InputDecoration(labelText: 'Tracking ID (Optional)'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: carrierController,
                    decoration: const InputDecoration(labelText: 'Carrier Name (Optional)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  final dialogNav = Navigator.of(dialogContext);
                  
                  try {
                    final tracking = model.DeliveryTracking(
                      status: selectedStatus,
                      trackingId: trackingIdController.text,
                      carrierName: carrierController.text,
                      lastUpdated: DateTime.now(),
                    );
                    await _service.updateDeliveryTracking(order.id, tracking);
                    
                    // Close the dialog
                    dialogNav.pop();
                    // Close the parent bottom sheet so the list refreshes with new data
                    if (parentContext.mounted) {
                      Navigator.of(parentContext).pop();
                    }
                    
                    messenger.showSnackBar(const SnackBar(content: Text('Tracking updated!')));
                  } catch (e) {
                    dialogNav.pop();
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSafeImage(String imageSource) {
    if (imageSource.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    
    // 1. Handle network URLs
    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    // 2. Handle base64 (with or without data URI prefix)
    try {
      String base64String = imageSource;
      
      // Strip data URI prefix if present (e.g., "data:image/png;base64,...")
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      
      // Clean whitespace/newlines that can break decoding
      base64String = base64String.trim().replaceAll(RegExp(r'\s'), '');
      
      final bytes = base64Decode(base64String);
      if (bytes.isEmpty) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error decoding image: $e');
      return Container(
        color: Colors.grey[200],
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey, size: 28),
            SizedBox(height: 4),
            Text('Error', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }
  }
}


