import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/market_service.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_helper.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../theme/app_theme.dart';

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
                                      Text(
                                        (r['address'] ?? '-') as String,
                                        style: AppTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      if (r['averageRating'] != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ...List.generate(5, (index) {
                                              final rating = (num.tryParse(r['averageRating'].toString()) ?? 0.0).toDouble();
                                              return Icon(
                                                index < rating.floor()
                                                    ? Icons.star
                                                    : (index < rating
                                                        ? Icons.star_half
                                                        : Icons.star_border),
                                                color: Colors.amber,
                                                size: 14,
                                              );
                                            }),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                (num.tryParse(r['averageRating'].toString()) ?? 0.0).toStringAsFixed(1),
                                                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (r['totalReviews'] != null && (r['totalReviews'] as num) > 0) ...[
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  '(${r['totalReviews']})',
                                                  style: AppTheme.bodySmall.copyWith(color: Colors.grey),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Icon(Icons.store_mall_directory, color: AppTheme.primaryGreen, size: 32),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showRetailerContactDialog(context, r);
                                    },
                                    icon: const Icon(Icons.phone, size: 18),
                                    label: Text(ls.getLocalizedString('contact')),
                                    style: AppTheme.primaryButtonStyle.copyWith(
                                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showRatingDialog(context, r);
                                    },
                                    icon: const Icon(Icons.rate_review, size: 18),
                                    label: Text(ls.getLocalizedString('rate')),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryGreen,
                                      side: const BorderSide(color: AppTheme.primaryGreen),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      final phone = (r['phone'] ?? '').toString().toLowerCase();
      final addr = (r['address'] ?? '').toString().toLowerCase();
      final matchesSearch = lower.isEmpty || name.contains(lower) || phone.contains(lower) || addr.contains(lower);
      return matchesSearch;
    }).toList();
  }

  void _showRetailerContactDialog(BuildContext context, Map<String, dynamic> r) {
    final ls = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ls.getLocalizedString('contact_retailer'), style: AppTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ls.getLocalizedString('retailer_label')}: ${r['name'] ?? r['username'] ?? r['phone'] ?? r['id']}', style: AppTheme.bodyLarge),
            const SizedBox(height: 8),
            if ((r['address'] ?? '').toString().isNotEmpty) Text(r['address'], style: AppTheme.bodySmall),
            const SizedBox(height: 16),
            Text(ls.getLocalizedString('contact_information'), style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${ls.getLocalizedString('phone')}: ${r['phone'] ?? '-'}', style: AppTheme.bodyLarge),
            if ((r['email'] ?? '').toString().isNotEmpty)
              Text('${ls.getLocalizedString('email')}: ${r['email']}', style: AppTheme.bodyLarge),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ls.getLocalizedString('close'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ls.getLocalizedString('contact_request_sent')),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            style: AppTheme.primaryButtonStyle,
            child: Text(ls.getLocalizedString('send_request')),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> retailer) {
    double selectedRating = 0.0;
    final reviewController = TextEditingController();
    final ls = Provider.of<LanguageService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(ls.getLocalizedString('rate_retailer'), style: AppTheme.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ls.getLocalizedString('retailer_label')}: ${retailer['name'] ?? retailer['username'] ?? retailer['phone'] ?? retailer['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  ls.getLocalizedString('select_rating'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = (index + 1).toDouble();
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedRating = rating;
                        });
                      },
                      child: Icon(
                        selectedRating >= rating ? Icons.star : Icons.star_border,
                        color: selectedRating >= rating ? Colors.amber : Colors.grey,
                        size: 40,
                      ),
                    );
                  }),
                ),
                if (selectedRating > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    ls.getLocalizedString('write_review_optional'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reviewController,
                    decoration: AppTheme.inputDecoration.copyWith(
                      hintText: ls.getLocalizedString('review_hint'),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ls.getLocalizedString('cancel_btn'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: selectedRating > 0
                  ? () async {
                      try {
                        final authService = Provider.of<AuthService>(context, listen: false);
                        final farmerId = authService.user?.uid ?? authService.phone ?? 'anonymous';
                        final retailerId = retailer['id'] ?? retailer['phone'] ?? '';
                        
                        await FirebaseFirestore.instance
                            .collection('retailer_reviews')
                            .add({
                          'retailerId': retailerId,
                          'farmerId': farmerId,
                          'rating': selectedRating,
                          'review': reviewController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'retailerName': retailer['name'] ?? retailer['username'] ?? '',
                        });
                        
                        // Update retailer's average rating
                        await _updateRetailerRating(retailerId);
                        
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ls.getLocalizedString('review_submitted')),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error submitting review: $e'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                      }
                    }
                  : null,
              style: AppTheme.primaryButtonStyle,
              child: Text(ls.getLocalizedString('submit')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRetailerRating(String retailerId) async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('retailer_reviews')
          .where('retailerId', isEqualTo: retailerId)
          .get();
      
      if (reviewsSnapshot.docs.isEmpty) return;
      
      double totalRating = 0.0;
      int count = 0;
      
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'];
        if (rating != null) {
          totalRating += (rating is int ? rating.toDouble() : rating as double);
          count++;
        }
      }
      
      if (count > 0) {
        final averageRating = totalRating / count;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(retailerId)
            .update({
          'averageRating': averageRating,
          'totalReviews': count,
        });
      }
    } catch (e) {
      debugPrint('Error updating retailer rating: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
