import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as model;
import '../../theme/app_theme.dart';
import '../../services/language_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
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
                  ls.getLocalizedString('analytics'),
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          StreamBuilder<List<model.Order>>(
            stream: orderService.streamOrdersForRetailer(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ));
              }
              
              final orders = snapshot.data ?? [];
              final total = orders.length;
              final accepted = orders.where((o) => o.status == 'accepted').length;
              final rejected = orders.where((o) => o.status == 'rejected').length;
              final pending = total - accepted - rejected;
              
              double totalValue = 0;
              for (var o in orders) {
                if (o.status != 'rejected') {
                  totalValue += (o.quantity * o.pricePerUnit);
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Value Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.cardDecoration.copyWith(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.currency_rupee, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ls.getLocalizedString('total_order_value'),
                                style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                              ),
                              Text(
                                '₹${totalValue.toStringAsFixed(0)}',
                                style: AppTheme.headingMedium.copyWith(color: Colors.white, fontSize: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(ls.getLocalizedString('orders_overview'), style: AppTheme.headingSmall),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            context,
                            ls.getLocalizedString('total'),
                            total.toString(),
                            Icons.receipt_long,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            context,
                            ls.getLocalizedString('order_status_pending'),
                            pending.toString(),
                            Icons.hourglass_bottom,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            context,
                            ls.getLocalizedString('order_status_accepted'),
                            accepted.toString(),
                            Icons.check_circle,
                            AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            context,
                            ls.getLocalizedString('order_status_rejected'),
                            rejected.toString(),
                            Icons.cancel,
                            AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    Text(ls.getLocalizedString('recent_orders'), style: AppTheme.headingSmall),
                    const SizedBox(height: 16),
                    
                    if (orders.isEmpty)
                      Center(
                        child: Text(
                          ls.getLocalizedString('no_orders_yet'),
                          style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                        ),
                      )
                    else
                      ...orders.take(5).map((o) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppTheme.cardDecoration,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                            child: const Icon(Icons.shopping_bag, color: AppTheme.primaryGreen),
                          ),
                          title: Text(o.crop, style: AppTheme.headingSmall.copyWith(fontSize: 16)),
                          subtitle: Text(
                            '${o.quantity} ${o.unit} • ₹${o.pricePerUnit}/${o.unit}',
                            style: AppTheme.bodySmall,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)}',
                                style: AppTheme.headingSmall.copyWith(fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (o.status == 'accepted' ? AppTheme.primaryGreen : 
                                         o.status == 'rejected' ? AppTheme.errorRed : Colors.orange).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  o.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: o.status == 'accepted' ? AppTheme.primaryGreen : 
                                           o.status == 'rejected' ? AppTheme.errorRed : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                      const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Expanded(
                child: Text(
                  value,
                  style: AppTheme.headingMedium.copyWith(fontSize: 24, color: color),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}



