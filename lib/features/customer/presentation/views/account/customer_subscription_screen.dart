import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/providers/customer_subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';

class CustomerSubscriptionScreen extends StatefulWidget {
  const CustomerSubscriptionScreen({super.key});

  @override
  State<CustomerSubscriptionScreen> createState() => _CustomerSubscriptionScreenState();
}

class _CustomerSubscriptionScreenState extends State<CustomerSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Membership Plans', style: TextStyle(color: AppTheme.textPrimaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: Consumer<CustomerSubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentTier = provider.currentTier;
          final plans = provider.plans;

          return ResponsiveWrapper(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentPlanCard(currentTier, provider.expiryDate),
                  const SizedBox(height: 24),
                  const Text(
                    'Available Plans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (currentTier == 'free') ...[
                    _buildTrialCard(provider),
                    const SizedBox(height: 16),
                  ],
                  _buildPlanCard('Free', plans['free'], currentTier == 'free', provider),
                  const SizedBox(height: 16),
                  _buildPlanCard('Wedding Planner Pass', plans['wedding_pass'], provider.hasWeddingPass, provider),
                  const SizedBox(height: 32),
                  if (kIsWeb) const AppFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlanCard(String currentTier, DateTime? expiryDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Membership',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            currentTier.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (expiryDate != null && currentTier != 'wedding_pass') ...[
            const SizedBox(height: 8),
            Text(
              'Expires: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ] else if (currentTier == 'wedding_pass') ...[
            const SizedBox(height: 8),
            const Text(
              'Lifetime Access',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrialCard(CustomerSubscriptionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade700, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade700.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star, color: Colors.amber.shade700),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free 7-Day Trial',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Try all premium features for 7 days!',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleStartTrial(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Start Your Free Trial',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String tierKey, Map<String, dynamic> plan, bool isCurrent, CustomerSubscriptionProvider provider) {
    // Determine card color/style based on tier
    Color headerColor;
    if (tierKey == 'Free') headerColor = Colors.grey;
    else if (tierKey == 'Wedding Planner Pass') headerColor = Colors.amber.shade700;
    else headerColor = AppTheme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: AppTheme.primaryColor, width: 2) : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !isCurrent, // Expand upgrade options by default
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['name'],
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
              if (plan['price'] == 0)
                const Text('FREE', style: TextStyle(fontWeight: FontWeight.bold))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${plan['currency']} ${plan['price']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'per ${plan['duration'].toString().toLowerCase()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Divider(),
            ...List.generate(
              (plan['benefits'] as List).length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan['benefits'][index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isCurrent)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Current Plan', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleUpgrade(provider, tierKey == 'Wedding Planner Pass' ? 'wedding_pass' : tierKey.toLowerCase()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Upgrade to ${plan['name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade(CustomerSubscriptionProvider provider, String tier) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upgrade'),
        content: Text('Are you sure you want to upgrade to the $tier plan? You will be redirected to the payment portal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (success == true) {
      final paymentUrl = await provider.upgradeSubscription(tier);
      if (mounted) {
        if (paymentUrl != null) {
          if (paymentUrl == "success") {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membership upgraded successfully!')),
              );
          } else {
              // Launch Billplz URL
              final Uri url = Uri.parse(paymentUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment page opened. Your membership will be updated upon successful payment.')),
                );
                
                // Start polling to detect when the user completes payment in the browser
                if (url.pathSegments.isNotEmpty) {
                  final billId = url.pathSegments.last;
                  provider.startPollingBill(billId, tier);
                }
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not launch payment URL. Please try again later.')),
                );
              }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to generate payment link. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _handleStartTrial(CustomerSubscriptionProvider provider) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Free Trial'),
        content: const Text('Would you like to start your 7-day free trial of the Wedding Planner Pass? No payment required!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
            child: const Text('Start Trial', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (success == true) {
      final result = await provider.startFreeTrial();
      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Free trial started! Enjoy your premium features.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start trial. Please try again later.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
