import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/market_service.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../theme/app_theme.dart';
import 'create_order_screen.dart';
import 'retailer_profile_screen.dart';

class RetailerSearchScreen extends StatefulWidget {
  const RetailerSearchScreen({super.key});

  @override
  _RetailerSearchScreenState createState() => _RetailerSearchScreenState();
}

class _RetailerSearchScreenState extends State<RetailerSearchScreen> {
  final _searchController = TextEditingController();
  final marketService = MarketService();
  final List<Map<String, dynamic>> _retailers = [];
  List<Map<String, dynamic>> _filteredRetailers = [];
  String _selectedCrop = 'All';

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'retailer')
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs.map((d) {
            final data = d.data();
            return {
              'id': d.id,
              ...data,
            };
          }).toList();
      setState(() {
        _retailers
          ..clear()
          ..addAll(list);
        _filteredRetailers = _applyFilter(_searchController.text);
      });
    });
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
                  ls.getLocalizedString('find_retailers_title'),
                  style: AppTheme.headingMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
        bodyChildren: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: AppTheme.inputDecoration.copyWith(
                    hintText: ls.getLocalizedString('search_retailers_hint'),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (q) => setState(() => _filteredRetailers = _applyFilter(q)),
                ),
                const SizedBox(height: 16),
                
                // Crop Filter
                Row(
                  children: [
                    Text(
                      '${ls.getLocalizedString('filter_by_crop')} ',
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCrop,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
                            items: [
                              ls.getLocalizedString('all'),
                              'Wheat', 'Rice', 'Corn', 'Soybeans'
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: AppTheme.bodyLarge),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCrop = newValue!;
                                _filteredRetailers = _applyFilter(_searchController.text);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results Section
          _filteredRetailers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ls.getLocalizedString('no_retailers_found'),
                          style: AppTheme.bodyLarge.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filteredRetailers.length,
                  itemBuilder: (context, index) {
                    final r = _filteredRetailers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: AppTheme.cardDecoration,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                              Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${ls.getLocalizedString('retailer_label')}: ${r['name'] ?? r['username'] ?? r['phone'] ?? r['id']}',
                                        style: AppTheme.headingSmall.copyWith(color: AppTheme.primaryGreen, fontSize: 18),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      // Location
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              (r['address'] ?? (ls.isTelugu ? 'అందుబాటులో లేదు' : 'Not Available')) as String,
                                              style: AppTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Specialization
                                      Row(
                                        children: [
                                          const Icon(Icons.category, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              r['specialization'] ?? (ls.isTelugu ? 'బియ్యం, గోధుమలు' : 'Rice, Wheat'),
                                              style: AppTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Stats Row (Rating & Trades)
                                      Row(
                                        children: [
                                           // Rating
                                           if (r['averageRating'] != null) ...[
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  (num.tryParse(r['averageRating'].toString()) ?? 0.0).toStringAsFixed(1),
                                                  style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          
                                          // Trades (Mocked for now if missing)
                                          Row(
                                            children: [
                                              const Icon(Icons.handshake, color: AppTheme.primaryGreen, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${r['totalCompletedTrades'] ?? (ls.isTelugu ? '10+' : '10+')} ${ls.isTelugu ? 'వ్యాపారాలు' : 'Trades'}',
                                                style: AppTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                     if(r['isVerified'] == true)
                                      const Icon(Icons.verified, color: Colors.blue, size: 24)
                                     else
                                      const Icon(Icons.store_mall_directory, color: AppTheme.primaryGreen, size: 32),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RetailerProfileScreen(retailerData: r),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryGreen),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(ls.isTelugu ? 'ప్రొఫైల్ చూడండి' : 'View Profile'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                       Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateOrderScreen(retailerId: r['id'] ?? r['phone']),
                                        ),
                                      );
                                    },
                                    style: AppTheme.primaryButtonStyle.copyWith(
                                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                    child: Text(
                                      ls.isTelugu ? 'రిక్వెస్ట్ పంపండి' : 'Send Request',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _applyFilter(String query) {
    final lower = query.toLowerCase();
    return _retailers.where((r) {
      final name = (r['name'] ?? r['username'] ?? '').toString().toLowerCase();
      // Removed phone search to enhance privacy, or keep strictly internal? 
      // Keeping internal search might be okay, but display is banned.
      // Let's allow search by name primarily.
      final addr = (r['address'] ?? '').toString().toLowerCase();
      final matchesSearch = lower.isEmpty || name.contains(lower) || addr.contains(lower);
      return matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
