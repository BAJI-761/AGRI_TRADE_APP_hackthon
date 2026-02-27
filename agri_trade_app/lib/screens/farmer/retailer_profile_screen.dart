import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/language_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_gradient_scaffold.dart';
import '../../widgets/primary_button.dart';
import 'create_order_screen.dart';

class RetailerProfileScreen extends StatelessWidget {
  final Map<String, dynamic> retailerData;

  const RetailerProfileScreen({super.key, required this.retailerData});

  @override
  Widget build(BuildContext context) {
    final ls = Provider.of<LanguageService>(context);
    final String retailerName = retailerData['name'] ?? retailerData['username'] ?? retailerData['phone'] ?? retailerData['id'];
    final String retailerId = retailerData['id'] ?? retailerData['phone'] ?? ''; // Ensure we have an ID

    // Extract additional info or use placeholders
    final String gstNumber = retailerData['gst'] ?? retailerData['gstNumber'] ?? '29ABCDE1234F1Z5'; // Mock if missing
    final String yearsInBusiness = retailerData['yearsInBusiness']?.toString() ?? '5+'; 
    final String totalTrades = retailerData['totalCompletedTrades']?.toString() ?? '120+';
    final String specialization = retailerData['specialization'] ?? 'Rice, Wheat, Pulses';
    final double rating = (num.tryParse(retailerData['averageRating']?.toString() ?? '0') ?? 0).toDouble();

    // Mask GST
    final String maskedGst = gstNumber.length > 4 
        ? 'XXXX-XXXX-${gstNumber.substring(gstNumber.length - 4)}' 
        : gstNumber;

    return AppGradientScaffold(
      headerHeightFraction: 0.25,
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
                Expanded(
                  child: Text(
                    ls.getLocalizedString('retailer_profile_title') == 'retailer_profile_title' 
                        ? (ls.isTelugu ? 'వ్యాపారి వివరాలు' : 'Retailer Profile')
                        : ls.getLocalizedString('retailer_profile_title'),
                    style: AppTheme.headingMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    retailerName.isNotEmpty ? retailerName[0].toUpperCase() : 'R',
                    style: AppTheme.headingMedium.copyWith(color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        retailerName,
                        style: AppTheme.headingSmall.copyWith(color: Colors.white),
                      ),
                      if (retailerData['isVerified'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                ls.isTelugu ? 'ధృవీకరించబడింది' : 'Verified Business',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      bodyChildren: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Row
               Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      label: ls.isTelugu ? 'రేటింగ్' : 'Rating',
                      value: rating.toStringAsFixed(1),
                      icon: Icons.star,
                      iconColor: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      label: ls.isTelugu ? 'వ్యాపారాలు' : 'Trades',
                      value: totalTrades,
                      icon: Icons.handshake,
                      iconColor: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      label: ls.isTelugu ? 'అనుభవం' : 'Years',
                      value: yearsInBusiness,
                      icon: Icons.history,
                      iconColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Business Details
              _buildSectionTitle(context, ls.isTelugu ? 'వ్యాపార వివరాలు' : 'Business Details'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  children: [
                    _buildDetailRow(
                      context, 
                      icon: Icons.location_on, 
                      label: ls.getLocalizedString('location'), 
                      value: retailerData['address'] ?? (ls.isTelugu ? 'అందుబాటులో లేదు' : 'Not Available'),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context, 
                      icon: Icons.badge, 
                      label: 'GST Number', 
                      value: maskedGst,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context, 
                      icon: Icons.category, 
                      label: ls.isTelugu ? 'ప్రత్యేకత' : 'Specialization', 
                      value: specialization,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              PrimaryButton(
                label: ls.isTelugu ? 'వ్యాపార అభ్యర్థన పంపండి' : 'Send Trade Request',
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateOrderScreen(retailerId: retailerId),
                    ),
                  );
                },
              ),
              // const SizedBox(height: 16),
              // OutlinedButton.icon(
              //   onPressed: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(content: Text(ls.isTelugu ? 'చాట్ త్వరలో రానుంది' : 'Chat feature coming soon')),
              //     );
              //   },
              //   icon: const Icon(Icons.chat_bubble_outline),
              //   label: Text(ls.isTelugu ? 'చాట్ చేయండి' : 'Chat with Retailer'),
              //   style: OutlinedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //     side: const BorderSide(color: AppTheme.primaryGreen),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {required String label, required String value, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(fontSize: 18),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTheme.headingSmall,
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
