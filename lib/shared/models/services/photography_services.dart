import '../../../features/vendor/data/models/vendor_service_item.dart';

final List<VendorServiceItem> photographyServices = [
  VendorServiceItem(
    id: 'photography_wedding',
    name: 'Wedding Photography Service',
    description: 'Professional wedding photography capturing your special moments.',
    category: 'Photography',
    subcategory: 'Wedding',
    price: 5000.0, // Base price for full day
    imageUrl: 'https://example.com/wedding_photography.jpg',
    features: [
      'Full day coverage',
      'High-resolution images',
      'Online gallery',
      'Printed album'
    ],
    isPopular: true,
    rating: 4.8,
    reviewCount: 200,
    pricingTiers: {
      'Basic Package - 4 Hours': 3000.0,
      'Standard Package - 8 Hours': 5000.0,
      'Premium Package - 12 Hours': 7000.0,
      'Deluxe Package - Full Day': 9000.0,
    },
  ),
  VendorServiceItem(
    id: 'photography_corporate',
    name: 'Corporate Photography',
    description: 'Professional photography for business events and headshots.',
    category: 'Photography',
    subcategory: 'Corporate',
    price: 2000.0, // Base price for event
    imageUrl: 'https://example.com/corporate_photography.jpg',
    features: [
      'Event coverage',
      'Headshots',
      'Team photos',
      'Digital delivery'
    ],
    isPopular: false,
    rating: 4.5,
    reviewCount: 150,
    pricingTiers: {
      'Headshots Only - 1 Hour': 500.0,
      'Event Coverage - 4 Hours': 2000.0,
      'Full Package - 8 Hours': 3500.0,
    },
  ),
  VendorServiceItem(
    id: 'photography_portrait',
    name: 'Portrait Photography',
    description: 'Personalized portrait sessions for individuals and families.',
    category: 'Photography',
    subcategory: 'Portrait',
    price: 800.0, // Base price for session
    imageUrl: 'https://example.com/portrait_photography.jpg',
    features: [
      'Studio session',
      'Outdoor options',
      'Edited photos',
      'Prints included'
    ],
    isPopular: true,
    rating: 4.7,
    reviewCount: 180,
    pricingTiers: {
      'Basic Session - 1 Hour': 500.0,
      'Premium Session - 2 Hours': 800.0,
      'Family Package - 3 Hours': 1200.0,
    },
  ),
  VendorServiceItem(
    id: 'photography_event',
    name: 'Event Photography',
    description: 'Capture the essence of your events with professional photography.',
    category: 'Photography',
    subcategory: 'Event',
    price: 2500.0, // Base price for event
    imageUrl: 'https://example.com/event_photography.jpg',
    features: [
      'Full event coverage',
      'Candid shots',
      'Group photos',
      'Quick turnaround'
    ],
    isPopular: false,
    rating: 4.6,
    reviewCount: 120,
    pricingTiers: {
      'Basic Coverage - 2 Hours': 1000.0,
      'Standard Coverage - 4 Hours': 1800.0,
      'Full Coverage - 8 Hours': 2500.0,
    },
  ),
  VendorServiceItem(
    id: 'photography_product',
    name: 'Product Photography',
    description: 'High-quality product photography for e-commerce and marketing.',
    category: 'Photography',
    subcategory: 'Product',
    price: 1500.0, // Base price for 10 products
    imageUrl: 'https://example.com/product_photography.jpg',
    features: [
      'Studio setup',
      'Multiple angles',
      'Retouching',
      'Commercial use'
    ],
    isPopular: false,
    rating: 4.4,
    reviewCount: 90,
    pricingTiers: {
      'Basic - 5 Products': 800.0,
      'Standard - 10 Products': 1500.0,
      'Premium - 20 Products': 2500.0,
    },
  ),
];
