import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/order.dart' as model;
import '../../widgets/navigation_helper.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  final OrderService _service = OrderService();

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final farmerId = authService.user?.uid ?? authService.phone ?? '';

    if (farmerId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Consumer<LanguageService>(
            builder: (context, ls, _) => Text(ls.getLocalizedString('my_orders')),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Consumer<LanguageService>(
            builder: (context, ls, _) => Text(ls.getLocalizedString('please_login_again')),
          ),
        ),
      );
    }

    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('my_orders'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      body: StreamBuilder<List<model.Order>>(
        stream: _service.streamOrdersForFarmer(farmerId),
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
              builder: (context, ls, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      ls.getLocalizedString('no_orders_yet'),
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ls.getLocalizedString('create_order_to_start'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child: _buildStatItem(
                            context,
                            Provider.of<LanguageService>(context, listen: false).getLocalizedString('total'),
                            '${orders.length}',
                          ),
                        ),
                        Flexible(
                          child: _buildStatItem(
                            context,
                            Provider.of<LanguageService>(context, listen: false).getLocalizedString('accepted'),
                            '${orders.where((o) => o.status == 'accepted').length}',
                          ),
                        ),
                        Flexible(
                          child: _buildStatItem(
                            context,
                            Provider.of<LanguageService>(context, listen: false).getLocalizedString('pending'),
                            '${orders.where((o) => o.status == 'pending').length}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Orders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${ls.getLocalizedString('location')}: ${o.location}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: o.status == 'accepted'
                                      ? Colors.green.withOpacity(0.1)
                                      : o.status == 'rejected'
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${ls.getLocalizedString('status')}: ${o.status.toUpperCase()}',
                                  style: TextStyle(
                                    color: o.status == 'accepted'
                                        ? Colors.green
                                        : o.status == 'rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDate(o.createdAt),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
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

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(BuildContext context, model.Order o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    o.crop,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: o.status == 'accepted'
                          ? Colors.green.withOpacity(0.1)
                          : o.status == 'rejected'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      o.status.toUpperCase(),
                      style: TextStyle(
                        color: o.status == 'accepted'
                            ? Colors.green
                            : o.status == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<LanguageService>(
                builder: (context, ls, _) => SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _detailRow(
                        ls.getLocalizedString('quantity'),
                        '${o.quantity} ${o.unit}',
                      ),
                      _detailRow(
                        ls.getLocalizedString('price_per_unit'),
                        '₹${o.pricePerUnit} per ${o.unit}',
                      ),
                      _detailRow(
                        ls.getLocalizedString('total'),
                        '₹${(o.quantity * o.pricePerUnit).toStringAsFixed(2)}',
                      ),
                      _detailRow(
                        ls.getLocalizedString('available_date'),
                        _formatDate(o.availableDate),
                      ),
                      if (o.location.isNotEmpty)
                        _detailRow(
                          ls.getLocalizedString('location'),
                          o.location,
                        ),
                      if (o.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ls.getLocalizedString('notes'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          o.notes,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _detailRow(
                        ls.getLocalizedString('created_at'),
                        _formatDate(o.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Consumer<LanguageService>(
                    builder: (context, ls, _) => Text(ls.getLocalizedString('close')),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

