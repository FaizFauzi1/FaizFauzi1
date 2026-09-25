# EventEase Advertisement System

## Overview

The EventEase Advertisement System provides a comprehensive solution for managing banner, native, and interstitial ads throughout the application. This system includes placement management, analytics tracking, and admin controls.

## Features

### 1. Advertisement Types

#### Banner Ads
- Horizontal banner ads displayed at the top of screens
- Fixed height and responsive width
- Used for product/service promotion
- Current placement: Search screen header

#### Native Ads
- Context-aware ads that blend with feed content
- Include image, title, subtitle, and call-to-action
- Best for in-feed advertising
- Current placement: After 3 items in search results

#### Interstitial Ads
- Full-screen overlay ads
- Shown at key user interactions (navigation events)
- Includes countdown timer and close functionality
- Frequency capped to avoid user annoyance (3-minute minimum interval)
- Current placements: Before navigating to detail screens from search

### 2. Core Components

#### AdConfiguration Model
Represents an advertisement with the following properties:
- `id`: Unique identifier
- `name`: Display name for admin
- `description`: Admin description
- `type`: AdType (banner, native, interstitial)
- `status`: AdStatus (active, inactive, paused)
- `platform`: AdPlatform (android, ios, web)
- `adUnitId`: Google Ad Unit ID
- `imageUrl`: Image/creative URL
- `title`: Ad title
- `subtitle`: Optional subtitle
- `callToAction`: Button text
- `targetUrl`: URL to open on click
- `priority`: Display priority (1-10)
- `currentImpressions`: Tracked impression count
- `currentClicks`: Tracked click count
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

#### AdPlacement Model
Defines where ads are displayed:
- `id`: Unique placement identifier
- `name`: Display name
- `description`: Placement description
- `adType`: Type of ad for this placement
- `screen`: Screen name (e.g., 'search', 'home')
- `position`: Position on screen (e.g., 'top', 'feed', 'interstitial')
- `adIds`: List of ad IDs eligible for this placement
- `isEnabled`: Enable/disable placement without deleting

### 3. Ad Widgets

#### BannerAdWidget
```dart
BannerAdWidget(
  placementId: 'search_banner_top',
  height: 50.0, // Optional, defaults to 50
)
```
Displays banner ads at specified placements.

#### NativeAdWidget
```dart
NativeAdWidget(
  placementId: 'search_native_feed',
)
```
Displays native ads with full context.

#### InterstitialAdManager
```dart
if (InterstitialAdManager.shouldShowInterstitial(placementId, context)) {
  await InterstitialAdManager.showInterstitial(placementId, context);
}
```
Manages interstitial ad frequency and display.

### 4. Ad Provider (State Management)

The `AdProvider` manages all ads and placements:

#### Key Methods
- `getBestAdForPlacement(placementId)`: Get highest-priority active ad for placement
- `recordImpression(adId)`: Track ad view
- `recordClick(adId)`: Track ad click
- `addAd(ad)`: Create new ad
- `updateAd(ad)`: Update existing ad
- `deleteAd(adId)`: Remove ad
- `addPlacement(placement)`: Create new placement
- `updatePlacement(placement)`: Update placement
- `deletePlacement(placementId)`: Remove placement
- `getPlacementsForScreen(screen)`: Get all active placements for a screen

#### Analytics Properties
- `totalImpressions`: Total views across all ads
- `totalClicks`: Total clicks across all ads
- `overallCTR`: Overall click-through rate
- `activeAdsCount`: Number of active ads

### 5. Admin Interface

The `AdminAdsManagementScreen` provides a complete admin panel with three tabs:

#### Advertisements Tab
- List all ads with thumbnails
- View impressions and click counts
- Toggle active/inactive status
- Edit ad details
- Delete ads
- Create new ads

#### Placements Tab
- View all ad placements
- Enable/disable placements
- See assigned ads for each placement
- Screen and position information

#### Analytics Tab
- Total impressions counter
- Total clicks counter
- Click-through rate (CTR) calculation
- Per-ad performance breakdown

## Implementation Guide

### Adding Banner Ads to a Screen

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Your content
        BannerAdWidget(placementId: 'your_placement_id'),
        // More content
      ],
    ),
  );
}
```

### Adding Native Ads to Feed

In a ListView or Column with dynamic content:

```dart
ListView.builder(
  itemCount: items.length + 1, // +1 for ad
  itemBuilder: (context, index) {
    if (index == 3) { // Insert ad after 3 items
      return NativeAdWidget(placementId: 'your_feed_placement');
    }
    final itemIndex = index > 3 ? index - 1 : index;
    if (itemIndex >= items.length) return SizedBox.shrink();
    
    return _buildItemCard(items[itemIndex]);
  },
)
```

### Adding Interstitial Ads Before Navigation

```dart
void _navigateToDetail(item) {
  if (InterstitialAdManager.shouldShowInterstitial(placementId, context)) {
    InterstitialAdManager.showInterstitial(placementId, context).then((_) {
      _performNavigation(item);
    });
  } else {
    _performNavigation(item);
  }
}
```

### Accessing Admin Interface

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AdminAdsManagementScreen(),
  ),
);
```

## Current Search Screen Integration

The search screen now includes:

1. **Banner Ad (Top)**
   - Placement ID: `search_banner_top`
   - Position: Below search bar
   - Shows the first active banner ad

2. **Native Ads (Feed)**
   - Placement ID: `search_native_feed`
   - Position: After 3 search results
   - Shows context-aware product ads

3. **Interstitial Ads (Navigation)**
   - Placement ID: `search_interstitial`
   - Trigger: When navigating to venue/service details
   - Frequency: Maximum once every 3 minutes

## Analytics Tracking

All ad interactions are automatically tracked:

- **Impressions**: Counted when ad widget is built
- **Clicks**: Counted when user taps the ad
- **CTR**: Calculated as (clicks / impressions) * 100

Access analytics in the Admin Analytics tab.

## Sample Data

The system comes with sample ads and placements:

### Sample Ads
1. **Wedding Venue Banner** (banner_1)
2. **Catering Services Native Ad** (native_1)
3. **Photography Interstitial** (interstitial_1)

### Sample Placements
- Home Screen Banner Top
- Home Screen Native Feed
- Search Screen Banner Top
- Search Screen Interstitial

## Best Practices

1. **Ad Frequency**: Space out interstitial ads (3+ minute intervals)
2. **Ad Placement**: Use native ads in feeds, banners at top
3. **Priority**: Higher priority ads display more often (1-10 scale)
4. **Testing**: Test ads with sample data before production
5. **Analytics**: Monitor CTR and adjust ad content accordingly
6. **Targeting**: Use relevant ads for each screen type

## File Structure

```
lib/
├── core/
│   └── providers/
│       └── ad_provider.dart                 # Ad state management
├── shared/
│   ├── models/
│   │   └── ad_models.dart                   # Ad data models
│   └── widgets/
│       └── ad_widgets.dart                  # Ad display widgets
├── features/
│   ├── customer/
│   │   └── presentation/views/
│   │       └── customer/
│   │           └── search_screen.dart       # Search with ads integrated
│   └── admin/
│       └── presentation/views/
│           └── admin_ads_management_screen.dart  # Admin panel
```

## Future Enhancements

1. Integration with Google AdMob for real ads
2. Programmatic ad serving with remote configuration
3. Advanced analytics dashboard
4. A/B testing for ad creatives
5. Demographic-based ad targeting
6. Real-time ad performance reporting
7. Revenue tracking and split management

## Troubleshooting

### Ads not showing
- Check if placement is enabled in admin panel
- Verify ads are assigned to the placement
- Ensure ad status is "active"
- Check if screen name matches placement configuration

### High memory usage
- Limit number of native ads in single feed
- Use image optimization for ad creatives
- Consider lazy-loading ads in long lists

### Poor CTR
- Review ad relevance to screen context
- Test different ad creatives
- Optimize call-to-action text
- Check ad placement positions

## Contact & Support

For issues or feature requests related to the ad system, contact the development team.
