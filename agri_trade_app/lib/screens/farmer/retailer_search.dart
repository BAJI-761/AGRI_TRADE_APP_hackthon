import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/market_service.dart';
import '../../services/language_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/navigation_helper.dart';

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
      final list = snapshot.docs.map((d) => {
            'id': d.id,
            ...d.data(),
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
    return NavigationHelper(
      child: Scaffold(
        appBar: NavigationAppBar(
          title: Provider.of<LanguageService>(context, listen: false).getLocalizedString('find_retailers_title'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('search_retailers_hint'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (q) => setState(() => _filteredRetailers = _applyFilter(q)),
                ),
                const SizedBox(height: 16),
                
                // Crop Filter (placeholder; future filter)
                Row(
                  children: [
                    Consumer<LanguageService>(
                      builder: (context, ls, _) => Text(
                        ls.getLocalizedString('filter_by_crop') + ' ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCrop,
                        isExpanded: true,
                        items: [
                          Provider.of<LanguageService>(context, listen: false).getLocalizedString('all'),
                          'Wheat', 'Rice', 'Corn', 'Soybeans'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                  ],
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _filteredRetailers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Consumer<LanguageService>(
                          builder: (context, ls, _) => Text(
                            ls.getLocalizedString('no_retailers_found'),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredRetailers.length,
                    itemBuilder: (context, index) {
                      final r = _filteredRetailers[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
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
                                        Consumer<LanguageService>(
                                          builder: (context, ls, _) => Text(
                                            '${ls.getLocalizedString('retailer_label')}: ${r['name'] ?? r['username'] ?? r['phone'] ?? r['id']}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (r['address'] ?? '-') as String,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                        if (r['averageRating'] != null) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ...List.generate(5, (index) {
                                                final rating = (r['averageRating'] as num).toDouble();
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
                                                  '${r['averageRating'].toStringAsFixed(1)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[700],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                              if (r['totalReviews'] != null && r['totalReviews'] > 0) ...[
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    '(${r['totalReviews']})',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: const [
                                      Icon(Icons.store_mall_directory, color: Colors.green, size: 24),
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
                                      icon: const Icon(Icons.phone),
                                      label: Consumer<LanguageService>(
                                        builder: (context, ls, _) => Text(ls.getLocalizedString('contact')),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _showRatingDialog(context, r);
                                      },
                                      icon: const Icon(Icons.rate_review),
                                      label: Consumer<LanguageService>(
                                        builder: (context, ls, _) => Text(ls.getLocalizedString('rate')),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        side: const BorderSide(color: Colors.green),
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
          ),
        ],
      ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Consumer<LanguageService>(
          builder: (context, ls, _) => Text(ls.getLocalizedString('contact_retailer')),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text('${ls.getLocalizedString('retailer_label')}: ${r['name'] ?? r['username'] ?? r['phone'] ?? r['id']}'),
            ),
            const SizedBox(height: 8),
            if ((r['address'] ?? '').toString().isNotEmpty) Text(r['address']),
            const SizedBox(height: 16),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text(ls.getLocalizedString('contact_information')),
            ),
            const SizedBox(height: 8),
            Consumer<LanguageService>(
              builder: (context, ls, _) => Text('${ls.getLocalizedString('phone')}: ${r['phone'] ?? '-'}'),
            ),
            if ((r['email'] ?? '').toString().isNotEmpty)
              Consumer<LanguageService>(
                builder: (context, ls, _) => Text('${ls.getLocalizedString('email')}: ${r['email']}'),
              ),
          ],
        ),
        actions: [
          Consumer<LanguageService>(
            builder: (context, ls, _) => TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(ls.getLocalizedString('close')),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Consumer<LanguageService>(
                    builder: (context, ls, _) => Text(ls.getLocalizedString('contact_request_sent')),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Consumer<LanguageService>(
              builder: (context, ls, _) => Text(ls.getLocalizedString('send_request')),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, Map<String, dynamic> retailer) {
    double selectedRating = 0.0;
    final reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Consumer<LanguageService>(
            builder: (context, ls, _) => Text(ls.getLocalizedString('rate_retailer')),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Text(
                    '${ls.getLocalizedString('retailer_label')}: ${retailer['name'] ?? retailer['username'] ?? retailer['phone'] ?? retailer['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<LanguageService>(
                  builder: (context, ls, _) => Text(
                    ls.getLocalizedString('select_rating'),
                    style: const TextStyle(fontSize: 16),
                  ),
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
                  Consumer<LanguageService>(
                    builder: (context, ls, _) => Text(
                      ls.getLocalizedString('write_review_optional'),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      hintText: Provider.of<LanguageService>(context, listen: false).getLocalizedString('review_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Consumer<LanguageService>(
              builder: (context, ls, _) => TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(ls.getLocalizedString('cancel_btn')),
              ),
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
                            content: Consumer<LanguageService>(
                              builder: (context, ls, _) => Text(ls.getLocalizedString('review_submitted')),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error submitting review: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Consumer<LanguageService>(
                builder: (context, ls, _) => Text(ls.getLocalizedString('submit')),
              ),
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
