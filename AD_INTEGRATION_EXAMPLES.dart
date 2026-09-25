// Ad Integration Examples for Other Screens

// ============================================================================
// EXAMPLE 1: HOME SCREEN WITH BANNER AND NATIVE ADS
// ============================================================================

import 'package:flutter/material.dart';
import 'package:eventease/shared/widgets/ad_widgets.dart';

class HomeScreenExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Column(
        children: [
          // Banner ad at top
          BannerAdWidget(
            placementId: 'home_banner_top',
            height: 50,
          ),

          Expanded(
            child: ListView.builder(
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                // Insert native ad after 3 items
                if (index == 3) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: NativeAdWidget(
                      placementId: 'home_native_feed',
                    ),
                  );
                }

                final itemIndex = index > 3 ? index - 1 : index;
                if (itemIndex >= items.length) {
                  return SizedBox.shrink();
                }

                return _buildItemCard(items[itemIndex]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(item) {
    // Your card widget
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(item.name),
    );
  }
}

// ============================================================================
// EXAMPLE 2: BOOKING SCREEN WITH INTERSTITIAL BEFORE CONFIRMATION
// ============================================================================

import 'package:eventease/shared/widgets/ad_widgets.dart';

class BookingScreenExample extends StatefulWidget {
  @override
  _BookingScreenExampleState createState() => _BookingScreenExampleState();
}

class _BookingScreenExampleState extends State<BookingScreenExample> {
  Future<void> _confirmBooking() async {
    // Show interstitial ad before processing booking
    if (InterstitialAdManager.shouldShowInterstitial(
      'booking_confirmation_interstitial',
      context,
    )) {
      await InterstitialAdManager.showInterstitial(
        'booking_confirmation_interstitial',
        context,
      );
    }

    // Process booking
    _processBooking();
  }

  void _processBooking() {
    // Your booking logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Booking confirmed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking')),
      body: Column(
        children: [
          // Banner ad at top
          BannerAdWidget(
            placementId: 'booking_banner_top',
            height: 50,
          ),
          // Booking form...
          ElevatedButton(
            onPressed: _confirmBooking,
            child: Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: VENDOR PROFILE WITH MULTIPLE AD PLACEMENTS
// ============================================================================

class VendorProfileExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Banner ad in sliver
          SliverToBoxAdapter(
            child: BannerAdWidget(
              placementId: 'vendor_profile_banner_top',
              height: 50,
            ),
          ),

          // Vendor info
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vendor image
                  // Vendor name
                  // Rating
                ],
              ),
            ),
          ),

          // Native ad in sliver
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: NativeAdWidget(
                placementId: 'vendor_profile_native_mid',
              ),
            ),
          ),

          // Services list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildServiceTile(services[index]);
              },
              childCount: services.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(service) {
    return ListTile(
      title: Text(service.name),
      subtitle: Text(service.description),
    );
  }
}

// ============================================================================
// EXAMPLE 4: CREATING NEW PLACEMENTS IN AD PROVIDER
// ============================================================================

import 'package:eventease/core/providers/ad_provider.dart';
import 'package:eventease/shared/models/ad_models.dart';
import 'package:provider/provider.dart';

class AdPlacementSetupExample {
  static void setupCustomPlacements(BuildContext context) {
    final adProvider = context.read<AdProvider>();

    // Add new placement for booking confirmation screen
    adProvider.addPlacement(
      AdPlacement(
        id: 'booking_confirmation_interstitial',
        name: 'Booking Confirmation Interstitial',
        description: 'Full-screen ad shown before booking confirmation',
        adType: AdType.interstitial,
        screen: 'booking',
        position: 'interstitial',
        adIds: ['interstitial_1'], // Add more ad IDs for variety
        isEnabled: true,
      ),
    );

    // Add banner placement for vendor profile
    adProvider.addPlacement(
      AdPlacement(
        id: 'vendor_profile_banner_top',
        name: 'Vendor Profile Banner Top',
        description: 'Banner at top of vendor profile screen',
        adType: AdType.banner,
        screen: 'vendor_profile',
        position: 'top',
        adIds: ['banner_1'],
        isEnabled: true,
      ),
    );

    // Add native placement for vendor profile
    adProvider.addPlacement(
      AdPlacement(
        id: 'vendor_profile_native_mid',
        name: 'Vendor Profile Native Mid',
        description: 'Native ad in middle of vendor profile',
        adType: AdType.native,
        screen: 'vendor_profile',
        position: 'mid',
        adIds: ['native_1'],
        isEnabled: true,
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: CREATING NEW ADS PROGRAMMATICALLY
// ============================================================================

import 'package:uuid/uuid.dart';

class AdCreationExample {
  static void createNewAd(BuildContext context, {
    required String name,
    required AdType type,
    required String title,
    String? imageUrl,
    String? targetUrl,
  }) {
    final adProvider = context.read<AdProvider>();

    final newAd = AdConfiguration(
      id: const Uuid().v4(),
      name: name,
      description: 'Custom ad for EventEase',
      type: type,
      status: AdStatus.active,
      platform: AdPlatform.android,
      adUnitId: 'ca-app-pub-xxxxxxx/xxxxxxx',
      imageUrl: imageUrl,
      title: title,
      subtitle: 'Premium Event Services',
      callToAction: 'Learn More',
      targetUrl: targetUrl ?? 'https://eventease.com',
      priority: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    adProvider.addAd(newAd);
  }

  // Usage example:
  static void example(BuildContext context) {
    createNewAd(
      context,
      name: 'My Catering Service Ad',
      type: AdType.native,
      title: 'Premium Catering Services',
      imageUrl: 'https://via.placeholder.com/300x200?text=Catering',
      targetUrl: 'https://eventease.com/catering',
    );
  }
}

// ============================================================================
// EXAMPLE 6: BEST PRACTICES CHECKLIST
// ============================================================================

/*
BEST PRACTICES FOR AD INTEGRATION:

1. PLACEMENT STRATEGY
   ✓ Put banner ads at screen tops for visibility
   ✓ Insert native ads after 3-5 content items (not too frequent)
   ✓ Show interstitials before navigation, not on every action
   ✓ Never block primary user actions with ads

2. USER EXPERIENCE
   ✓ Frequency cap interstitials (3+ minute intervals)
   ✓ Always provide close button for interstitials
   ✓ Make ads visually consistent with app design
   ✓ Test ad performance with real users

3. ANALYTICS
   ✓ Monitor CTR (target: 2-5% for banner, 5-10% for native)
   ✓ Track conversion from ads to actual bookings
   ✓ Analyze which ad types perform best
   ✓ Adjust placement based on metrics

4. CONTENT
   ✓ Match ads to screen context (wedding ads on wedding screen)
   ✓ Use high-quality images for native ads
   ✓ Keep CTAs clear and actionable
   ✓ Rotate ad creatives to prevent banner blindness

5. PERFORMANCE
   ✓ Use lazy loading for image ads
   ✓ Don't load too many ads in memory
   ✓ Cache ad images when possible
   ✓ Monitor memory usage in Analytics

6. COMPLIANCE
   ✓ Clearly label ads (show "Sponsored" label)
   ✓ Provide privacy policy link
   ✓ Don't mislead users with ad content
   ✓ Follow platform guidelines (Google AdMob, etc.)
*/

// ============================================================================
// EXAMPLE 7: CONDITIONAL AD DISPLAY
// ============================================================================

class ConditionalAdExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        // Only show ads if user is not premium
        final shouldShowAds = !isUserPremium();

        return Scaffold(
          body: Column(
            children: [
              if (shouldShowAds)
                BannerAdWidget(
                  placementId: 'search_banner_top',
                  height: 50,
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    // Show native ad every 5 items for free users
                    if (shouldShowAds && index % 5 == 4) {
                      return NativeAdWidget(
                        placementId: 'content_feed_native',
                      );
                    }
                    return _buildItemCard(items[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool isUserPremium() {
    // Check user subscription status
    return false; // Example
  }

  Widget _buildItemCard(item) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Text(item.toString()),
    );
  }
}

// ============================================================================
// EXAMPLE 8: AD ANALYTICS INTEGRATION
// ============================================================================

import 'package:provider/provider.dart';

class AdAnalyticsExample {
  static void displayAnalytics(BuildContext context) {
    final adProvider = context.read<AdProvider>();

    final analytics = {
      'total_impressions': adProvider.totalImpressions,
      'total_clicks': adProvider.totalClicks,
      'overall_ctr': adProvider.overallCTR,
      'active_ads': adProvider.activeAdsCount,
    };

    print('Ad Analytics: $analytics');

    // You can send this to analytics service
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'ad_metrics',
    //   parameters: Map<String, Object>.from(analytics),
    // );
  }

  static void trackSpecificAd(BuildContext context, String adId) {
    final adProvider = context.read<AdProvider>();
    final analytics = adProvider.getAdAnalytics(adId);
    
    print('Ad $adId Analytics: $analytics');
    // impressions: count
    // clicks: count
    // ctr: percentage
  }
}
