import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/market_service.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  _InventoryManagementScreenState createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final marketService = MarketService();
  
  final List<Map<String, dynamic>> _inventory = [];
  
  bool _isAddingItem = false;
  int? _editingIndex;
  String? _retailerId;

  final List<String> _cropTypes = [
    'Wheat', 'Rice', 'Corn', 'Soybeans', 'Cotton', 'Sugarcane', 'Potatoes', 'Tomatoes', 'Onions', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _retailerId = authService.user?.uid ?? authService.phone ?? '';
      
      if (_retailerId != null && _retailerId!.isNotEmpty) {
        _loadInventoryFromFirestore();
        FirebaseFirestore.instance
            .collection('retailer_inventory')
            .where('retailerId', isEqualTo: _retailerId)
            .snapshots()
            .listen((snapshot) {
          if (mounted) {
            setState(() {
              _inventory.clear();
              for (var doc in snapshot.docs) {
                final data = doc.data();
                _inventory.add({
                  'id': doc.id,
                  'crop': data['crop'],
                  'quantity': data['quantity'],
                  'price': data['price'],
                  'unit': data['unit'] ?? 'kg',
                });
              }
            });
          }
        });
      }
    });
  }

  Future<void> _loadInventoryFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('retailer_inventory')
          .where('retailerId', isEqualTo: _retailerId)
          .get();
      
      setState(() {
        _inventory.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _inventory.add({
            'id': doc.id,
            'crop': data['crop'],
            'quantity': data['quantity'],
            'price': data['price'],
            'unit': data['unit'] ?? 'kg',
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                        ls.getLocalizedString('inventory'),
                        style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                if (!_isAddingItem)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(ls.getLocalizedString('add'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => _isAddingItem = true),
                  ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          if (!_isAddingItem) ...[
            // Summary
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration.copyWith(
                color: Colors.white,
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(context, ls.getLocalizedString('total_items'), '${_inventory.length}'),
                  Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                  _buildSummaryItem(context, ls.getLocalizedString('total_value'), '₹${_calculateTotalValue().toStringAsFixed(0)}'),
                ],
              ),
            ),
            // List
            _inventory.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            ls.getLocalizedString('no_items_in_inventory'),
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _inventory.length,
                    itemBuilder: (context, index) => _buildInventoryCard(context, index, ls),
                  ),
          ] else ...[
             Padding(
               padding: const EdgeInsets.all(24),
               child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: AppTheme.cardDecoration,
                 child: Form(
                   key: _formKey,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(child: Text(ls.getLocalizedString('add_new_item'), style: AppTheme.headingSmall)),
                           IconButton(
                             icon: const Icon(Icons.close, color: Colors.grey),
                             onPressed: () {
                               setState(() {
                                 _isAddingItem = false;
                                 _editingIndex = null;
                                 _cropController.clear();
                                 _quantityController.clear();
                                 _priceController.clear();
                               });
                             },
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),
                       DropdownButtonFormField<String>(
                         initialValue: _cropController.text.isEmpty ? null : _cropController.text,
                         decoration: AppTheme.inputDecoration.copyWith(
                           labelText: ls.getLocalizedString('crop_type'),
                           prefixIcon: const Icon(Icons.grass, color: AppTheme.primaryGreen),
                         ),
                         items: _cropTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                         onChanged: (v) => setState(() => _cropController.text = v ?? ''),
                         validator: (v) => v == null ? ls.getLocalizedString('please_select_crop_type') : null,
                       ),
                       const SizedBox(height: 16),
                       TextFormField(
                         controller: _quantityController,
                         keyboardType: TextInputType.number,
                         decoration: AppTheme.inputDecoration.copyWith(
                           labelText: ls.getLocalizedString('quantity_kg'),
                           prefixIcon: const Icon(Icons.scale, color: AppTheme.primaryGreen),
                         ),
                         validator: (v) {
                           if (v?.isEmpty ?? true) return ls.getLocalizedString('please_enter_quantity');
                           if (double.tryParse(v!) == null) return ls.getLocalizedString('enter_valid_number');
                           return null;
                         },
                       ),
                       const SizedBox(height: 16),
                       TextFormField(
                         controller: _priceController,
                         keyboardType: TextInputType.number,
                         decoration: AppTheme.inputDecoration.copyWith(
                           labelText: ls.getLocalizedString('price_per_kg'),
                           prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryGreen),
                         ),
                         validator: (v) {
                           if (v?.isEmpty ?? true) return ls.getLocalizedString('please_enter_price');
                           if (double.tryParse(v!) == null) return ls.getLocalizedString('enter_valid_number');
                           return null;
                         },
                       ),
                       const SizedBox(height: 32),
                       SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                           onPressed: _addInventoryItem,
                           style: AppTheme.primaryButtonStyle,
                           child: Text(ls.getLocalizedString('add_to_inventory')),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTheme.headingMedium.copyWith(color: AppTheme.primaryGreen)),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }

  Widget _buildInventoryCard(BuildContext context, int index, LanguageService ls) {
    final item = _inventory[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inventory_2, color: AppTheme.primaryGreen),
        ),
        title: Text(item['crop'] ?? '', style: AppTheme.headingSmall.copyWith(fontSize: 18)),
        subtitle: Text(
          '${item['quantity']} ${item['unit']} • ₹${item['price']}/${item['unit']}',
          style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹${((item['quantity'] ?? 0) * (item['price'] ?? 0)).toStringAsFixed(0)}',
                  style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen, fontSize: 16),
                ),
                Text(ls.getLocalizedString('total'), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') _editInventoryItem(index);
                if (value == 'delete') _deleteInventoryItem(index);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(ls.getLocalizedString('edit')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Text(ls.getLocalizedString('delete')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalValue() {
    double total = 0;
    for (var item in _inventory) {
      double q = (item['quantity'] ?? 0).toDouble();
      double p = (item['price'] ?? 0).toDouble();
      total += q * p;
    }
    return total;
  }

  void _addInventoryItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final data = {
        'retailerId': _retailerId,
        'crop': _cropController.text,
        'quantity': double.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'unit': 'kg', // Default unit
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingIndex != null) {
        // Update existing
        final id = _inventory[_editingIndex!]['id'];
        await FirebaseFirestore.instance
            .collection('retailer_inventory')
            .doc(id)
            .update(data);
      } else {
        // Add new
        await FirebaseFirestore.instance
            .collection('retailer_inventory')
            .add(data);
      }
      
      if (mounted) {
        setState(() {
          _isAddingItem = false;
          _editingIndex = null;
          _cropController.clear();
          _quantityController.clear();
          _priceController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(_editingIndex != null ? 'Item updated' : 'Item added'), backgroundColor: AppTheme.primaryGreen)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _editInventoryItem(int index) {
    setState(() {
      _editingIndex = index;
      _isAddingItem = true;
      final item = _inventory[index];
      _cropController.text = item['crop'] ?? '';
      _quantityController.text = (item['quantity'] ?? '').toString();
      _priceController.text = (item['price'] ?? '').toString();
    });
  }

  Future<void> _deleteInventoryItem(int index) async {
    try {
      final id = _inventory[index]['id'];
      await FirebaseFirestore.instance
          .collection('retailer_inventory')
          .doc(id)
          .delete();
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted'), backgroundColor: AppTheme.secondaryAmber),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }
}
