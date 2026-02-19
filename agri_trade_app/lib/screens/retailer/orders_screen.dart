import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as model;
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _service = OrderService();
  
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
                  Color statusColor = o.status == 'accepted'
                      ? AppTheme.primaryGreen
                      : o.status == 'rejected'
                          ? AppTheme.errorRed
                          : AppTheme.secondaryAmber;

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
                                       color: statusColor.withOpacity(0.1),
                                       shape: BoxShape.circle,
                                     ),
                                     child: Icon(
                                       o.status == 'accepted'
                                            ? Icons.check
                                            : o.status == 'rejected'
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
                                   if (o.status == 'pending')
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
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          o.status.toUpperCase(),
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
              const SizedBox(height: 32),
              if (o.status == 'pending')
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: AppTheme.primaryButtonStyle,
                    child: Text(ls.getLocalizedString('close')), // Fixed: removed builder
                  ),
                ),
            ],
          ),
        );
      },
    );
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
}


