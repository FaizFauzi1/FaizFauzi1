import '../../../features/vendor/data/models/vendor_service_item.dart';

final List<VendorServiceItem> venueServices = [
  VendorServiceItem(
    id: 'venue_ballroom',
    name: 'Grand Ballroom Venue',
    description: 'Elegant ballroom perfect for weddings and large events.',
    category: 'Venue',
    subcategory: 'Ballroom',
    price: 15000.0, // Base price for full day
    imageUrl: 'https://example.com/ballroom_venue.jpg',
    features: [
      'Capacity: 500 guests',
      'Full catering setup',
      'Sound system included',
      'Parking available'
    ],
    isPopular: true,
    rating: 4.7,
    reviewCount: 180,
    pricingTiers: {
      'Half Day - 200 Guests': 8000.0,
      'Full Day - 300 Guests': 12000.0,
      'Full Day - 500 Guests': 15000.0,
      'Weekend Package - 500 Guests': 20000.0,
    },
  ),
  VendorServiceItem(
    id: 'venue_garden',
    name: 'Outdoor Garden Venue',
    description: 'Beautiful garden setting for intimate ceremonies.',
    category: 'Venue',
    subcategory: 'Garden',
    price: 8000.0, // Base price for full day
    imageUrl: 'https://example.com/garden_venue.jpg',
    features: [
      'Capacity: 200 guests',
      'Natural backdrop',
      'Tent setup available',
      'Scenic views'
    ],
    isPopular: true,
    rating: 4.8,
    reviewCount: 150,
    pricingTiers: {
      'Half Day - 100 Guests': 4000.0,
      'Full Day - 150 Guests': 6000.0,
      'Full Day - 200 Guests': 8000.0,
      'Extended Weekend - 200 Guests': 12000.0,
    },
  ),
  VendorServiceItem(
    id: 'venue_hotel',
    name: 'Hotel Conference Venue',
    description: 'Modern hotel conference rooms for business events.',
    category: 'Venue',
    subcategory: 'Hotel',
    price: 5000.0, // Base price for full day
    imageUrl: 'https://example.com/hotel_venue.jpg',
    features: [
      'Capacity: 150 guests',
      'AV equipment',
      'Catering options',
      'Accommodation nearby'
    ],
    isPopular: false,
    rating: 4.5,
    reviewCount: 120,
    pricingTiers: {
      'Half Day - 50 Guests': 2500.0,
      'Full Day - 100 Guests': 4000.0,
      'Full Day - 150 Guests': 5000.0,
      'Multi-Day Package - 150 Guests': 8000.0,
    },
  ),
  VendorServiceItem(
    id: 'venue_restaurant',
    name: 'Restaurant Venue',
    description: 'Charming restaurant spaces for small gatherings.',
    category: 'Venue',
    subcategory: 'Restaurant',
    price: 3000.0, // Base price for evening
    imageUrl: 'https://example.com/restaurant_venue.jpg',
    features: [
      'Capacity: 80 guests',
      'In-house catering',
      'Private dining',
      'Ambiance lighting'
    ],
    isPopular: false,
    rating: 4.6,
    reviewCount: 100,
    pricingTiers: {
      'Lunch - 40 Guests': 1500.0,
      'Dinner - 60 Guests': 2500.0,
      'Full Day - 80 Guests': 3000.0,
      'Weekend Special - 80 Guests': 4500.0,
    },
  ),
  VendorServiceItem(
    id: 'venue_barn',
    name: 'Rustic Barn Venue',
    description: 'Cozy barn venue for country-style events.',
    category: 'Venue',
    subcategory: 'Barn',
    price: 6000.0, // Base price for full day
    imageUrl: 'https://example.com/barn_venue.jpg',
    features: [
      'Capacity: 150 guests',
      'Rustic decor',
      'Outdoor space',
      'Fireplace available'
    ],
    isPopular: true,
    rating: 4.7,
    reviewCount: 90,
    pricingTiers: {
      'Half Day - 80 Guests': 3000.0,
      'Full Day - 120 Guests': 4500.0,
      'Full Day - 150 Guests': 6000.0,
      'Seasonal Package - 150 Guests': 7500.0,
    },
  ),
];
