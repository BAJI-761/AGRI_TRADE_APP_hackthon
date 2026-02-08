import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/market_service.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_helper.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  _InventoryManagementScreenState createState() =>
      _InventoryManagementScreenState();
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
    'Wheat',
    'Rice',
    'Corn',
    'Soybeans',
    'Cotton',
    'Sugarcane',
    'Potatoes',
    'Tomatoes',
    'Onions',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _retailerId = authService.user?.uid ?? authService.phone ?? '';
      
      // Load initial inventory from Firestore
      if (_retailerId != null && _retailerId!.isNotEmpty) {
        _loadInventoryFromFirestore();
        
        // Listen to real-time updates from Firestore
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
      } else {
        // Fallback to default items if not logged in
        setState(() {
          _inventory.addAll([
            {'crop': 'Wheat', 'quantity': 1000, 'price': 50.0, 'unit': 'kg'},
            {'crop': 'Rice', 'quantity': 800, 'price': 30.0, 'unit': 'kg'},
            {'crop': 'Corn', 'quantity': 1200, 'price': 25.0, 'unit': 'kg'},
          ]);
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
        
        // If no items, add default items
        if (_inventory.isEmpty) {
          _inventory.addAll([
            {'crop': 'Wheat', 'quantity': 1000, 'price': 50.0, 'unit': 'kg'},
            {'crop': 'Rice', 'quantity': 800, 'price': 30.0, 'unit': 'kg'},
            {'crop': 'Corn', 'quantity': 1200, 'price': 25.0, 'unit': 'kg'},
          ]);
        }
      });
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('inventory'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _isAddingItem = true;
                });
              },
            ),
          ],
        ),
      body: Column(
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
                      child: _buildSummaryItem(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('total_items'),
                        '${_inventory.length}',
                      ),
                    ),
                    Flexible(
                      child: _buildSummaryItem(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('total_value'),
                        '\$${_calculateTotalValue().toStringAsFixed(2)}',
                      ),
                    ),
                    Flexible(
                      child: _buildSummaryItem(
                        context,
                        Provider.of<LanguageService>(context, listen: false).getLocalizedString('avg_price'),
                        '\$${_calculateAveragePrice().toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Add Item Form
          if (_isAddingItem) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Consumer<LanguageService>(
                              builder: (context, ls, _) => Text(
                                ls.getLocalizedString('add_new_item'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isAddingItem = false;
                                  _editingIndex = null;
                                  _cropController.clear();
                                  _quantityController.clear();
                                  _priceController.clear();
                                  _formKey.currentState?.reset();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Crop Type Dropdown
                        DropdownButtonFormField<String>(
                          value: _cropController.text.isEmpty ? null : _cropController.text,
                          decoration: InputDecoration(
                            labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('crop_type'),
                            prefixIcon: const Icon(Icons.agriculture),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _cropTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _cropController.text = newValue ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('please_select_crop_type');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Quantity Input
                        TextFormField(
              controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('quantity_kg'),
                            prefixIcon: const Icon(Icons.scale),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('please_enter_quantity');
                            }
                            if (double.tryParse(value) == null) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('enter_valid_number');
                            }
                            if (double.parse(value) <= 0) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('quantity_greater_than_zero');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Price Input
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('price_per_kg'),
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
              keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('please_enter_price');
                            }
                            if (double.tryParse(value) == null) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('enter_valid_number');
                            }
                            if (double.parse(value) < 0) {
                              return Provider.of<LanguageService>(context, listen: false).getLocalizedString('price_cannot_be_negative');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Add Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _addInventoryItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Consumer<LanguageService>(
                              builder: (context, ls, _) => Text(
                                ls.getLocalizedString('add_to_inventory'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ] else ...[
            // Inventory List
            Expanded(
              child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.agriculture,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      item['crop']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            '${ls.getLocalizedString('quantity')}: ${item['quantity']} ${item['unit']}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            '${ls.getLocalizedString('price_label')}: ₹${item['price'].toStringAsFixed(2)} per ${item['unit']}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            '${ls.getLocalizedString('total')}: ₹${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Consumer<LanguageService>(
                            builder: (context, ls, _) => Row(
                              children: [
                                const Icon(Icons.edit, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(ls.getLocalizedString('edit')),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Consumer<LanguageService>(
                            builder: (context, ls, _) => Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(ls.getLocalizedString('delete')),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editInventoryItem(index);
                        } else if (value == 'delete') {
                          _deleteInventoryItem(index);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Future<void> _addInventoryItem() async {
    if (!_formKey.currentState!.validate()) return;

    final newItem = {
      'crop': _cropController.text.trim(),
      'quantity': double.parse(_quantityController.text),
      'price': double.parse(_priceController.text),
      'unit': 'kg',
    };

    try {
      if (_editingIndex != null && _inventory[_editingIndex!]['id'] != null) {
        // Update existing item in Firestore
        final itemId = _inventory[_editingIndex!]['id'];
        await FirebaseFirestore.instance
            .collection('retailer_inventory')
            .doc(itemId)
            .update({
          'crop': newItem['crop'],
          'quantity': newItem['quantity'],
          'price': newItem['price'],
          'unit': newItem['unit'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _editingIndex = null;
        final ls = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ls.getLocalizedString('item_updated')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Add new item to Firestore
        if (_retailerId != null && _retailerId!.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('retailer_inventory')
              .add({
            'retailerId': _retailerId,
            'crop': newItem['crop'],
            'quantity': newItem['quantity'],
            'price': newItem['price'],
            'unit': newItem['unit'],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Fallback: add to local list if not logged in
          setState(() {
            _inventory.add(newItem);
          });
        }
        final ls = Provider.of<LanguageService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ls.getLocalizedString('item_added_to_inventory')),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      setState(() {
        _isAddingItem = false;
        _cropController.clear();
        _quantityController.clear();
        _priceController.clear();
        _formKey.currentState?.reset();
      });
    } catch (e) {
      debugPrint('Error saving inventory item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editInventoryItem(int index) {
    final item = _inventory[index];
    setState(() {
      _cropController.text = item['crop']?.toString() ?? '';
      _quantityController.text = item['quantity']?.toString() ?? '';
      _priceController.text = item['price']?.toString() ?? '';
      _isAddingItem = true;
      _editingIndex = index;
    });
    
    // Scroll to form when editing
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Scrollable.ensureVisible(
          _formKey.currentContext ?? context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _deleteInventoryItem(int index) async {
    final item = _inventory[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LanguageService>(
          builder: (context, ls, _) => Text(ls.getLocalizedString('delete_item')),
        ),
        content: Consumer<LanguageService>(
          builder: (context, ls, _) => Text('${ls.getLocalizedString('delete_item_confirm')}: ${item['crop']}?'),
        ),
        actions: [
          Consumer<LanguageService>(
            builder: (context, ls, _) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ls.getLocalizedString('cancel_btn')),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (item['id'] != null && _retailerId != null && _retailerId!.isNotEmpty) {
                  // Delete from Firestore
                  await FirebaseFirestore.instance
                      .collection('retailer_inventory')
                      .doc(item['id'])
                      .delete();
                } else {
                  // Fallback: remove from local list
                  setState(() {
                    _inventory.removeAt(index);
                  });
                }
                final ls = Provider.of<LanguageService>(context, listen: false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ls.getLocalizedString('item_deleted')),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                debugPrint('Error deleting item: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting item: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Consumer<LanguageService>(
              builder: (context, ls, _) => Text(ls.getLocalizedString('delete')),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalValue() {
    return _inventory.fold(0.0, (sum, item) => sum + (item['quantity'] * item['price']));
  }

  double _calculateAveragePrice() {
    if (_inventory.isEmpty) return 0.0;
    final totalValue = _calculateTotalValue();
    final totalQuantity = _inventory.fold(0.0, (sum, item) => sum + item['quantity']);
    return totalValue / totalQuantity;
  }

  @override
  void dispose() {
    _cropController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
