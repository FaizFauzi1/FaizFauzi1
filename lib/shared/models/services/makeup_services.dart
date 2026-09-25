import '../../../features/vendor/models/vendor_service.dart';
import '../../../shared/models/services/service_enums.dart';
import '../event/event_category.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';

class MakeupServices {
  static List<VendorService> getMakeupServices() {
    final services = <VendorService>[];
    int idCounter = 1;

    // Bridal Makeup Service
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: 'makeup_vendor_1',
      name: 'Bridal Makeup Package',
      description: 'Complete bridal makeup service including foundation, eyes, lips, and hair styling. Professional makeup artist with premium products for your special day.',
      category: EventCategory.beauty,
      subcategory: 'Bridal Makeup',
      type: ServiceType.service,
      basePrice: 1200.0,
      active: true,
      availability: {
        'monday': {'start': '08:00', 'end': '18:00', 'available': true},
        'tuesday': {'start': '08:00', 'end': '18:00', 'available': true},
        'wednesday': {'start': '08:00', 'end': '18:00', 'available': true},
        'thursday': {'start': '08:00', 'end': '18:00', 'available': true},
        'friday': {'start': '08:00', 'end': '18:00', 'available': true},
        'saturday': {'start': '06:00', 'end': '20:00', 'available': true},
        'sunday': {'start': '06:00', 'end': '20:00', 'available': true},
      },
      maxBookingsPerDay: 4,
      advanceBookingDays: 90,
      images: [
        ImageConstants.beautyPlaceholder,
      ],
      options: {
        'makeupType': ['Natural', 'Glamorous', 'Romantic', 'Classic', 'Modern', 'Vintage'],
        'hairStyle': ['Updo', 'Half-up', 'Down', 'Braided', 'Curled', 'Straight'],
        'addOns': ['False Lashes', 'Airbrush Makeup', 'Hair Extensions', 'Touch-up Kit', 'Bridesmaid Package'],
        'skinType': ['Normal', 'Oily', 'Dry', 'Combination', 'Sensitive'],
        'products': ['Premium Brands', 'Hypoallergenic', 'Long-lasting', 'Waterproof'],
      },
      requirements: {
        'documents': ['License', 'Portfolio', 'Insurance'],
        'permits': [],
        'technical': {
          'setupTime': '1-2 hours',
          'lighting': 'Natural light preferred',
          'spaceNeeded': 'Small area',
        },
      },
      logistics: {
        'hasDelivery': false,
        'deliveryFee': 0.0,
        'deliveryRadius': '0km',
        'hasSetup': false,
        'hasPickup': false,
        'travelIncluded': true,
        'travelRadius': '50km',
        'onSite': true,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      amenities: ['Hypoallergenic Products', 'Touch-up Kit', 'Hair Styling Tools'],
      reviews: [
        {'rating': 5, 'comment': 'Amazing bridal makeup, lasted all day!', 'user': 'Sarah L.', 'date': '2024-02-15'},
        {'rating': 5, 'comment': 'Professional and beautiful results.', 'user': 'Maya K.', 'date': '2024-01-20'},
      ],
    ));

    // Event Makeup Artist
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: 'makeup_vendor_2',
      name: 'Event Makeup Artist',
      description: 'Professional makeup services for parties, corporate events, and celebrations. Quick application with long-lasting results.',
      category: EventCategory.beauty,
      subcategory: 'Event Makeup',
      type: ServiceType.service,
      basePrice: 800.0,
      hourlyRate: 150.0,
      active: true,
      availability: {
        'monday': {'start': '09:00', 'end': '17:00', 'available': true},
        'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
        'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
        'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
        'friday': {'start': '09:00', 'end': '17:00', 'available': true},
        'saturday': {'start': '08:00', 'end': '18:00', 'available': true},
        'sunday': {'start': '08:00', 'end': '18:00', 'available': true},
      },
      maxBookingsPerDay: 6,
      advanceBookingDays: 30,
      images: [
        ImageConstants.beautyPlaceholder,
      ],
      options: {
        'makeupType': ['Natural', 'Bold', 'Smoky Eyes', 'Red Lips'],
        'duration': [1, 2, 3],
        'addOns': ['Hair Styling', 'Nail Art', 'Group Discounts'],
      },
      requirements: {
        'documents': ['License', 'Portfolio'],
        'permits': [],
        'technical': {
          'setupTime': '30 minutes',
          'spaceNeeded': 'Minimal',
        },
      },
      logistics: {
        'hasDelivery': false,
        'deliveryFee': 0.0,
        'deliveryRadius': '0km',
        'hasSetup': false,
        'hasPickup': false,
        'travelIncluded': true,
        'travelRadius': '30km',
        'onSite': true,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
      amenities: ['Quick Application', 'Long-lasting Products'],
      reviews: [
        {'rating': 4, 'comment': 'Great for events, very efficient.', 'user': 'John D.', 'date': '2024-03-10'},
      ],
    ));

    // Makeup Kit Rental
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: 'makeup_vendor_3',
      name: 'Professional Makeup Kit Rental',
      description: 'Rent professional makeup kits for DIY beauty needs. Includes brushes, products, and accessories for various occasions.',
      category: EventCategory.beauty,
      subcategory: 'Makeup Kit Rental',
      type: ServiceType.rental,
      basePrice: 500.0,
      active: true,
      availability: {
        'monday': {'start': '09:00', 'end': '17:00', 'available': true},
        'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
        'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
        'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
        'friday': {'start': '09:00', 'end': '17:00', 'available': true},
        'saturday': {'start': '09:00', 'end': '17:00', 'available': true},
        'sunday': {'start': '09:00', 'end': '17:00', 'available': true},
      },
      maxBookingsPerDay: 5,
      advanceBookingDays: 14,
      images: [
        ImageConstants.beautyPlaceholder,
      ],
      options: {
        'kitType': ['Basic', 'Professional', 'Bridal', 'Event'],
        'duration': [1, 2, 3, 7],
        'addOns': ['Extra Brushes', 'Hair Tools', 'Cleaning Kit'],
      },
      requirements: {
        'documents': ['ID Proof'],
        'permits': [],
        'technical': {
          'depositRequired': true,
          'cleanReturn': true,
        },
      },
      logistics: {
        'hasDelivery': true,
        'deliveryFee': 50.0,
        'deliveryRadius': '20km',
        'hasSetup': false,
        'hasPickup': true,
        'depositRequired': true,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now(),
      amenities: ['Professional Brushes', 'Premium Products'],
      reviews: [
        {'rating': 4, 'comment': 'Good quality kit, easy rental process.', 'user': 'Emma R.', 'date': '2024-02-28'},
      ],
    ));

    // Airbrush Makeup Service
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: 'makeup_vendor_4',
      name: 'Airbrush Makeup Service',
      description: 'Advanced airbrush makeup for flawless, long-lasting results. Perfect for photoshoots, weddings, and special events.',
      category: EventCategory.beauty,
      subcategory: 'Airbrush Makeup',
      type: ServiceType.service,
      basePrice: 1500.0,
      active: true,
      availability: {
        'monday': {'start': '08:00', 'end': '18:00', 'available': true},
        'tuesday': {'start': '08:00', 'end': '18:00', 'available': true},
        'wednesday': {'start': '08:00', 'end': '18:00', 'available': true},
        'thursday': {'start': '08:00', 'end': '18:00', 'available': true},
        'friday': {'start': '08:00', 'end': '18:00', 'available': true},
        'saturday': {'start': '06:00', 'end': '20:00', 'available': true},
        'sunday': {'start': '06:00', 'end': '20:00', 'available': true},
      },
      maxBookingsPerDay: 3,
      advanceBookingDays: 60,
      images: [
        ImageConstants.beautyPlaceholder,
      ],
      options: {
        'makeupType': ['Flawless', 'Natural Airbrush', 'Dramatic'],
        'addOns': ['Hair Styling', 'Touch-up', 'Photoshoot Ready'],
      },
      requirements: {
        'documents': ['License', 'Portfolio', 'Equipment Certification'],
        'permits': [],
        'technical': {
          'setupTime': '1.5 hours',
          'powerSupply': 'Standard outlet',
        },
      },
      logistics: {
        'hasDelivery': false,
        'deliveryFee': 0.0,
        'deliveryRadius': '0km',
        'hasSetup': false,
        'hasPickup': false,
        'travelIncluded': true,
        'travelRadius': '40km',
        'onSite': true,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now(),
      amenities: ['Airbrush Equipment', 'Long-lasting Formula'],
      reviews: [
        {'rating': 5, 'comment': 'Incredible results, perfect for photos!', 'user': 'Lisa M.', 'date': '2024-01-30'},
      ],
    ));

    // Group Makeup Service
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: 'makeup_vendor_5',
      name: 'Group Makeup Service',
      description: 'Makeup services for groups including bridesmaids, groomsmen, and event attendees. Discounts available for bulk bookings.',
      category: EventCategory.beauty,
      subcategory: 'Group Makeup',
      type: ServiceType.service,
      basePrice: 600.0,
      active: true,
      availability: {
        'monday': {'start': '08:00', 'end': '18:00', 'available': true},
        'tuesday': {'start': '08:00', 'end': '18:00', 'available': true},
        'wednesday': {'start': '08:00', 'end': '18:00', 'available': true},
        'thursday': {'start': '08:00', 'end': '18:00', 'available': true},
        'friday': {'start': '08:00', 'end': '18:00', 'available': true},
        'saturday': {'start': '06:00', 'end': '20:00', 'available': true},
        'sunday': {'start': '06:00', 'end': '20:00', 'available': true},
      },
      maxBookingsPerDay: 10,
      advanceBookingDays: 45,
      images: [
        ImageConstants.beautyPlaceholder,
      ],
      options: {
        'groupSize': [5, 10, 15, 20],
        'makeupType': ['Uniform', 'Individual Styles'],
        'addOns': ['Hair Styling', 'Bulk Discount'],
      },
      requirements: {
        'documents': ['License', 'Portfolio'],
        'permits': [],
        'technical': {
          'setupTime': '2-4 hours',
          'spaceNeeded': 'Medium area',
        },
      },
      logistics: {
        'hasDelivery': false,
        'deliveryFee': 0.0,
        'deliveryRadius': '0km',
        'hasSetup': false,
        'hasPickup': false,
        'travelIncluded': true,
        'travelRadius': '50km',
        'onSite': true,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      updatedAt: DateTime.now(),
      amenities: ['Bulk Discounts', 'Team of Artists'],
      reviews: [
        {'rating': 4, 'comment': 'Great for groups, efficient service.', 'user': 'Anna P.', 'date': '2024-03-05'},
      ],
    ));

    return services;
  }
}
