import '../../../features/vendor/data/models/vendor_service_item.dart';

final List<VendorServiceItem> beautyServices = [
  VendorServiceItem(
    id: 'beauty_facial',
    name: 'Facial Treatments',
    description: 'Rejuvenating facial treatments for glowing skin.',
    category: 'Beauty',
    subcategory: 'Facial',
    price: 150.0, // Base price for basic facial
    imageUrl: 'https://example.com/facial.jpg',
    features: [
      'Deep cleansing',
      'Hydration therapy',
      'Anti-aging masks',
      'Customized skincare'
    ],
    isPopular: true,
    rating: 4.6,
    reviewCount: 200,
    pricingTiers: {
      'Basic Facial - 30 min': 80.0,
      'Hydrating Facial - 45 min': 120.0,
      'Anti-Aging Facial - 60 min': 150.0,
      'Luxury Spa Facial - 90 min': 200.0,
    },
  ),
  VendorServiceItem(
    id: 'beauty_massage',
    name: 'Massage Therapy',
    description: 'Relaxing massage services for stress relief.',
    category: 'Beauty',
    subcategory: 'Massage',
    price: 120.0, // Base price for 60 min massage
    imageUrl: 'https://example.com/massage.jpg',
    features: [
      'Swedish massage',
      'Deep tissue options',
      'Aromatherapy oils',
      'Hot stone therapy'
    ],
    isPopular: true,
    rating: 4.7,
    reviewCount: 180,
    pricingTiers: {
      '30 min Relaxation': 60.0,
      '60 min Swedish': 100.0,
      '90 min Deep Tissue': 140.0,
      '120 min Full Body': 180.0,
    },
  ),
  VendorServiceItem(
    id: 'beauty_body_treatment',
    name: 'Body Treatments',
    description: 'Full body treatments for wellness and beauty.',
    category: 'Beauty',
    subcategory: 'Body Treatment',
    price: 200.0, // Base price for body scrub
    imageUrl: 'https://example.com/body_treatment.jpg',
    features: [
      'Body scrubs',
      'Wraps and masks',
      'Cellulite reduction',
      'Detox therapies'
    ],
    isPopular: false,
    rating: 4.5,
    reviewCount: 120,
    pricingTiers: {
      'Body Scrub - 45 min': 100.0,
      'Body Wrap - 60 min': 150.0,
      'Full Body Treatment - 90 min': 200.0,
      'Luxury Detox Package - 120 min': 250.0,
    },
  ),
  VendorServiceItem(
    id: 'beauty_hair_treatment',
    name: 'Hair Treatments',
    description: 'Professional hair care and styling services.',
    category: 'Beauty',
    subcategory: 'Hair Treatment',
    price: 100.0, // Base price for hair treatment
    imageUrl: 'https://example.com/hair_treatment.jpg',
    features: [
      'Deep conditioning',
      'Hair masks',
      'Scalp treatments',
      'Color protection'
    ],
    isPopular: false,
    rating: 4.4,
    reviewCount: 150,
    pricingTiers: {
      'Basic Conditioning - 30 min': 50.0,
      'Deep Treatment - 45 min': 80.0,
      'Scalp Therapy - 60 min': 100.0,
      'Luxury Hair Package - 90 min': 150.0,
    },
  ),
  VendorServiceItem(
    id: 'beauty_nail_care',
    name: 'Nail Care Services',
    description: 'Manicure and pedicure services for beautiful nails.',
    category: 'Beauty',
    subcategory: 'Nail Care',
    price: 50.0, // Base price for manicure
    imageUrl: 'https://example.com/nail_care.jpg',
    features: [
      'Classic manicure',
      'Gel polish options',
      'Nail art',
      'Foot spa'
    ],
    isPopular: true,
    rating: 4.6,
    reviewCount: 160,
    pricingTiers: {
      'Basic Manicure - 30 min': 25.0,
      'Deluxe Manicure - 45 min': 40.0,
      'Spa Pedicure - 60 min': 50.0,
      'Full Nail Package - 90 min': 70.0,
    },
  ),
];
