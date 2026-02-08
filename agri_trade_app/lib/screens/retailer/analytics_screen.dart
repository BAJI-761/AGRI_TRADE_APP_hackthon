import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as model;
import '../../services/language_service.dart';
import '../../widgets/navigation_helper.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('analytics'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      body: StreamBuilder<List<model.Order>>(
        stream: orderService.streamOrdersForRetailer(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final total = orders.length;
          final accepted = orders.where((o) => o.status == 'accepted').length;
          final rejected = orders.where((o) => o.status == 'rejected').length;
          final pending = total - accepted - rejected;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statCard(context, 'Total Orders', total.toString(), Icons.receipt_long, Colors.green),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard(context, 'Accepted', accepted.toString(), Icons.check_circle, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(context, 'Pending', pending.toString(), Icons.hourglass_bottom, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                _statCard(context, 'Rejected', rejected.toString(), Icons.cancel, Colors.red),
                const SizedBox(height: 16),
                const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 8),
                ...orders.take(10).map((o) => ListTile(
                      leading: const Icon(Icons.shopping_bag, color: Colors.green),
                      title: Text(
                        '${o.crop} • ${o.quantity} ${o.unit}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)} • ${o.status ?? 'pending'}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}


