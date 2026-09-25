import '../../features/vendor/data/models/vendor.dart';
import '../../features/vendor/models/vendor_service.dart';
import 'event/event_category.dart';
import 'services/service_enums.dart';

class EnhancedSampleData {
  static List<VendorService> getEnhancedVendorServices() {
    final services = <VendorService>[];
    int idCounter = 100; // Start from 100 to avoid conflicts

    // Additional Catering Services
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: '6',
      name: 'Birthday Party Catering',
      description: 'Fun and delicious catering for birthday parties with themed menus and decorations.',
      category: EventCategory.catering,
      type: ServiceType.package,
      basePrice: 1800.0,
      active: true,
      availability: {
        'monday': {'start': '08:00', 'end': '20:00', 'available': true},
        'tuesday': {'start': '08:00', 'end': '20:00', 'available': true},
        'wednesday': {'start': '08:00', 'end': '20:00', 'available': true},
        'thursday': {'start': '08:00', 'end': '20:00', 'available': true},
        'friday': {'start': '08:00', 'end': '20:00', 'available': true},
        'saturday': {'start': '08:00', 'end': '22:00', 'available': true},
        'sunday': {'start': '08:00', 'end': '22:00', 'available': true},
      },
      maxBookingsPerDay: 4,
      advanceBookingDays: 30,
      images: ['https://via.placeholder.com/300x200?text=Birthday+Catering'],
      options: {
        'theme': ['Princess', 'Superhero', 'Jungle', 'Space', 'Ocean'],
        'guestCount': [20, 30, 50, 80, 100],
        'menuType': ['Kids Menu', 'Adult Menu', 'Mixed Menu'],
      },
      requirements: {},
      logistics: {
        'hasDelivery': true,
        'deliveryFee': 100.0,
        'deliveryRadius': '25km',
        'hasSetup': true,
        'hasPickup': false,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ));

    // Additional Photography Services
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: '7',
      name: 'Portrait Photography',
      description: 'Professional portrait photography for individuals, families, and corporate headshots.',
      category: EventCategory.photography,
      type: ServiceType.service,
      basePrice: 800.0,
      active: true,
      availability: {
        'monday': {'start': '09:00', 'end': '17:00', 'available': true},
        'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
        'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
        'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
        'friday': {'start': '09:00', 'end': '17:00', 'available': true},
        'saturday': {'start': '09:00', 'end': '16:00', 'available': true},
        'sunday': {'start': '10:00', 'end': '15:00', 'available': false},
      },
      maxBookingsPerDay: 6,
      advanceBookingDays: 14,
      images: ['https://via.placeholder.com/300x200?text=Portrait+Photography'],
      options: {
        'sessionType': ['Individual', 'Family', 'Corporate', 'Graduation'],
        'location': ['Studio', 'Outdoor', 'Home', 'Office'],
        'addOns': ['Hair & Makeup', 'Wardrobe Styling', 'Digital Retouching'],
      },
      requirements: {},
      logistics: {
        'hasDelivery': false,
        'deliveryFee': 0.0,
        'deliveryRadius': '0km',
        'hasSetup': false,
        'hasPickup': false,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      updatedAt: DateTime.now(),
    ));

    // Additional Venue Services
    services.add(VendorService(
      id: (idCounter++).toString(),
      vendorId: '8',
      name: 'Garden Wedding Venue',
      description: 'Beautiful outdoor garden venue perfect for intimate weddings and romantic ceremonies.',
      category: EventCategory.venue,
      type: ServiceType.rental,
      basePrice: 3500.0,
      active: true,
      availability: {
        'monday': {'start': '00:00', 'end': '23:59', 'available': true},
        'tuesday': {'start': '00:00', 'end': '23:59', 'available': true},
        'wednesday': {'start': '00:00', 'end': '23:59', 'available': true},
        'thursday': {'start': '00:00', 'end': '23:59', 'available': true},
        'friday': {'start': '00:00', 'end': '23:59', 'available': true},
        'saturday': {'start': '00:00', 'end': '23:59', 'available': true},
        'sunday': {'start': '00:00', 'end': '23:59', 'available': true},
      },
      maxBookingsPerDay: 1,
      advanceBookingDays: 120,
      images: ['https://via.placeholder.com/300x200?text=Garden+Venue'],
      options: {
        'capacity': [50, 80, 120, 150],
        'season': ['Spring', 'Summer', 'Autumn', 'Winter'],
        'amenities': ['Garden', 'Pavilion', 'Restrooms', 'Parking'],
      },
      requirements: {},
      logistics: {
        'hasDelivery': false,
        'deliveryFee': 0.0,
        'deliveryRadius': '0km',
        'hasSetup': false,
        'hasPickup': false,
      },
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now(),
    ));

    return services;
  }

  static List<Vendor> getAdditionalVendors() {
    final vendors = <Vendor>[];
    int idCounter = 100;

    // Additional Catering Vendor
    vendors.add(Vendor(
      id: (idCounter++).toString(),
      name: 'Sweet Treats Catering',
      categories: ['Catering'],
      subcategories: ['Desserts', 'Pastries', 'Sweet Tables'],
      description: 'Specialized in desserts, pastries, and sweet tables for all occasions.',
      location: 'Petaling Jaya, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Sweet+Treats'],
      rating: 4.7,
      reviewCount: 89,
      status: VendorStatus.approved,
      documents: {'businessLicense': 'approved'},
      subscriptionTier: SubscriptionTier.basic,
      logistics: {'deliveryRadius': '30km', 'setupIncluded': true},
      contactInfo: {'phone': '+60 3-1234 5678', 'email': 'info@sweettreats.com'},
      sampleServiceIds: [],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
    ));

    // Additional Photography Vendor
    vendors.add(Vendor(
      id: (idCounter++).toString(),
      name: 'Creative Lens Photography',
      categories: ['Photography'],
      subcategories: ['Creative', 'Artistic', 'Fashion'],
      description: 'Creative and artistic photography with unique perspectives and modern techniques.',
      location: 'Cyberjaya, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Creative+Lens'],
      rating: 4.9,
      reviewCount: 156,
      status: VendorStatus.approved,
      documents: {'businessLicense': 'approved'},
      subscriptionTier: SubscriptionTier.premium,
      logistics: {'deliveryRadius': '80km', 'setupIncluded': false},
      contactInfo: {'phone': '+60 3-8765 4321', 'email': 'hello@creativelens.com'},
      sampleServiceIds: [],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ));

    // Additional Venue Vendor
    vendors.add(Vendor(
      id: (idCounter++).toString(),
      name: 'Skyline Rooftop Venue',
      categories: ['Venue'],
      subcategories: ['Rooftop', 'Modern', 'City View'],
      description: 'Modern rooftop venue with stunning city skyline views, perfect for intimate events.',
      location: 'Kuala Lumpur, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Skyline+Venue'],
      rating: 4.6,
      reviewCount: 78,
      status: VendorStatus.approved,
      documents: {'businessLicense': 'approved'},
      subscriptionTier: SubscriptionTier.standard,
      logistics: {'deliveryRadius': '0km', 'setupIncluded': false},
      contactInfo: {'phone': '+60 3-5555 6666', 'email': 'book@skylinevenue.com'},
      sampleServiceIds: [],
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now(),
    ));

    return vendors;
  }
}













