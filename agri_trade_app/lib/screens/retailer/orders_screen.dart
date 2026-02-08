import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart' as model;
import '../../services/voice_service.dart';
import '../../services/language_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/navigation_helper.dart';

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
    // Link notification service
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    _service.setNotificationService(notificationService);
  }
  

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('orders'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [],
        ),
      body: StreamBuilder<List<model.Order>>(
        stream: _service.streamOrdersForRetailer(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Consumer<LanguageService>(
              builder: (context, ls, _) => Center(child: Text(ls.getLocalizedString('no_orders_yet'))),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: o.status == 'accepted'
                              ? Colors.green
                              : o.status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                          child: Icon(
                            o.status == 'accepted'
                                ? Icons.check
                                : o.status == 'rejected'
                                    ? Icons.close
                                    : Icons.pending,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${o.crop} • ${o.quantity} ${o.unit}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Consumer<LanguageService>(
                          builder: (context, ls, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${ls.getLocalizedString('price_per_unit')}: ₹${o.pricePerUnit} ${ls.getLocalizedString('per')} ${o.unit}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ls.getLocalizedString('available_date')}: ${_formatDate(o.availableDate)}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  '${ls.getLocalizedString('location')}: ${o.location}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ls.getLocalizedString('status')}: ${o.status}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        trailing: ConstrainedBox(
                          constraints: BoxConstraints(
                            // Keep actions compact on very small widths
                            maxWidth: MediaQuery.of(context).size.width * 0.35,
                          ),
                          child: FittedBox(
                            alignment: Alignment.centerRight,
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (o.status == 'pending') ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green, size: 18),
                                        onPressed: () => _acceptOrder(o.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                        onPressed: () => _rejectOrder(o.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        onTap: () {
                          _showOrderDetails(context, o);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showOrderDetails(BuildContext context, model.Order o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.crop,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, ls, _) => Text(
                        '${ls.getLocalizedString('quantity')}: ${o.quantity} ${o.unit}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Consumer<LanguageService>(
                      builder: (context, ls, _) => Text(
                        '${ls.getLocalizedString('price_per_unit')}: ₹${o.pricePerUnit}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Consumer<LanguageService>(
                      builder: (context, ls, _) => Text(
                        '${ls.getLocalizedString('available_date')}: ${_formatDate(o.availableDate)}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (o.location.isNotEmpty)
                      Consumer<LanguageService>(
                        builder: (context, ls, _) => Text(
                          '${ls.getLocalizedString('location')}: ${o.location}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    if (o.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Consumer<LanguageService>(
                        builder: (context, ls, _) => Text(
                          '${ls.getLocalizedString('notes')}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        o.notes,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                        label: Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(ls.getLocalizedString('accept')),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectOrder(o.id);
                        },
                        icon: const Icon(Icons.close),
                        label: Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(ls.getLocalizedString('reject')),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(ls.getLocalizedString('close')),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  

  

  Future<void> _acceptOrder(String orderId) async {
    try {
      await _service.acceptOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, ls, _) => Text(ls.currentLanguage == 'te' 
                ? 'ఆర్డర్ అంగీకరించబడింది!' 
                : 'Order accepted successfully!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    try {
      await _service.rejectOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Consumer<LanguageService>(
              builder: (context, ls, _) => Text(ls.currentLanguage == 'te' 
                ? 'ఆర్డర్ తిరస్కరించబడింది.' 
                : 'Order rejected.'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


