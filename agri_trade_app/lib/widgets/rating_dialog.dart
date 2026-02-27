import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Premium rating dialog shown after trade completion.
/// Allows rating the trade partner (1-5 stars) with optional review.
class RatingDialog extends StatefulWidget {
  final String orderId;
  final String partnerName;
  final String cropName;
  final String partnerRole; // 'farmer' or 'retailer'

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.partnerName,
    required this.cropName,
    required this.partnerRole,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  // Quick review tags
  final List<String> _positiveTags = ['Great Quality', 'On Time', 'Good Price', 'Well Packed', 'Honest Seller'];
  final List<String> _negativeTags = ['Late Delivery', 'Poor Quality', 'Overpriced', 'Bad Packaging', 'Unresponsive'];
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bounceAnim = CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: _submitted ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final tags = _rating >= 3 ? _positiveTags : (_rating > 0 ? _negativeTags : <String>[]);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFFB800), const Color(0xFFF59E0B)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rate Your Experience', style: AppTheme.headingSmall.copyWith(color: Colors.white, fontSize: 17)),
                      Text('${widget.cropName} trade with ${widget.partnerName}',
                        style: AppTheme.bodySmall.copyWith(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Star rating
                Text(
                  _ratingLabel(),
                  style: AppTheme.headingSmall.copyWith(
                    fontSize: 15,
                    color: _rating == 0 ? AppTheme.textSecondary : _ratingColor(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIdx = i + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _rating = starIdx);
                        _bounceController.forward(from: 0);
                      },
                      child: AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (_, child) {
                          final scale = _rating == starIdx ? 1.0 + (_bounceAnim.value * 0.15) : 1.0;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            starIdx <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: starIdx <= _rating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
                            size: 44,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Quick tags
                if (tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: tags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => setState(() {
                          selected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? (_rating >= 3 ? AppTheme.primaryGreen : AppTheme.errorRed).withValues(alpha: 0.1)
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? (_rating >= 3 ? AppTheme.primaryGreen : AppTheme.errorRed)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? (_rating >= 3 ? AppTheme.primaryGreen : AppTheme.errorRed)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Review text
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write a review (optional)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _rating == 0 || _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.thumb_up_rounded, color: Color(0xFFF59E0B), size: 40),
          ),
          const SizedBox(height: 20),
          Text('Thank You!', style: AppTheme.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Your rating helps build trust\nin the AgriTrade community.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(
              Icons.star_rounded,
              color: i < _rating ? const Color(0xFFF59E0B) : Colors.grey.shade300,
              size: 28,
            )),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      // Save rating to Firestore
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'rating': {
          'score': _rating,
          'tags': _selectedTags.toList(),
          'review': _reviewController.text.trim(),
          'ratedBy': widget.partnerRole == 'farmer' ? 'retailer' : 'farmer',
          'ratedAt': FieldValue.serverTimestamp(),
        },
      });
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _ratingLabel() {
    switch (_rating) {
      case 1: return '😞 Poor';
      case 2: return '😐 Below Average';
      case 3: return '🙂 Average';
      case 4: return '😊 Good';
      case 5: return '🤩 Excellent!';
      default: return 'Tap a star to rate';
    }
  }

  Color _ratingColor() {
    switch (_rating) {
      case 1: return AppTheme.errorRed;
      case 2: return Colors.orange;
      case 3: return const Color(0xFFF59E0B);
      case 4: return AppTheme.primaryGreen;
      case 5: return AppTheme.primaryGreen;
      default: return AppTheme.textSecondary;
    }
  }
}
