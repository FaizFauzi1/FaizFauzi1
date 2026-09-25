import 'package:flutter/material.dart';
import '../../models/vendor_service_workflow_models.dart';

class VendorWorkflowProvider with ChangeNotifier {
  // Current active vendor
  String _currentVendorId = 'v-101';
  String _currentVendorName = 'Grand Hall & Event Services';

  // Services catalog
  final List<CommonServiceInfo> _services = [];
  final Map<String, List<ServicePackageItem>> _servicePackages = {};
  final Map<String, List<ServiceAppointmentType>> _serviceAppointmentTypes = {};
  final Map<String, Map<String, dynamic>> _categorySpecificData = {};

  // Appointments
  final List<ServiceAppointmentBooking> _appointments = [];

  // Collaborative Packages
  final List<CollaborativePackage> _packages = [];
  final List<CollaboratorInvitation> _invitations = [];
  final List<ParentPackageBooking> _packageBookings = [];

  // Unified Calendar items
  final List<VendorCalendarItem> _calendarItems = [];

  // Getters
  String get currentVendorId => _currentVendorId;
  String get currentVendorName => _currentVendorName;
  List<CommonServiceInfo> get services => List.unmodifiable(_services);
  List<ServiceAppointmentBooking> get appointments => List.unmodifiable(_appointments);
  List<CollaborativePackage> get packages => List.unmodifiable(_packages);
  List<CollaboratorInvitation> get invitations => List.unmodifiable(_invitations);
  List<ParentPackageBooking> get packageBookings => List.unmodifiable(_packageBookings);
  List<VendorCalendarItem> get calendarItems => List.unmodifiable(_calendarItems);

  VendorWorkflowProvider() {
    _initSampleData();
  }

  void setCurrentVendor(String id, String name) {
    _currentVendorId = id;
    _currentVendorName = name;
    notifyListeners();
  }

  List<ServicePackageItem> getPackagesForService(String serviceId) {
    return _servicePackages[serviceId] ?? [];
  }

  List<ServiceAppointmentType> getAppointmentTypesForService(String serviceId) {
    return _serviceAppointmentTypes[serviceId] ?? [];
  }

  Map<String, dynamic> getCategorySpecificData(String serviceId) {
    return _categorySpecificData[serviceId] ?? {};
  }

  // ==========================================
  // SERVICE MANAGEMENT
  // ==========================================

  void saveService({
    required CommonServiceInfo service,
    required List<ServicePackageItem> packages,
    required List<ServiceAppointmentType> appointmentTypes,
    required Map<String, dynamic> categoryData,
  }) {
    final existingIndex = _services.indexWhere((s) => s.id == service.id);
    if (existingIndex >= 0) {
      _services[existingIndex] = service;
    } else {
      _services.insert(0, service);
    }

    _servicePackages[service.id] = packages;
    _serviceAppointmentTypes[service.id] = appointmentTypes;
    _categorySpecificData[service.id] = categoryData;

    _rebuildCalendarItems();
    notifyListeners();
  }

  void deleteService(String serviceId) {
    _services.removeWhere((s) => s.id == serviceId);
    _servicePackages.remove(serviceId);
    _serviceAppointmentTypes.remove(serviceId);
    _categorySpecificData.remove(serviceId);
    notifyListeners();
  }

  void updateServiceStatus(String serviceId, ServiceStatus newStatus) {
    final index = _services.indexWhere((s) => s.id == serviceId);
    if (index >= 0) {
      _services[index] = _services[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // ==========================================
  // APPOINTMENT MANAGEMENT
  // ==========================================

  void bookAppointment(ServiceAppointmentBooking booking) {
    _appointments.insert(0, booking);
    _rebuildCalendarItems();
    notifyListeners();
  }

  void updateAppointmentStatus(String appointmentId, ServiceAppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      _appointments[index] = _appointments[index].copyWith(status: status);
      _rebuildCalendarItems();
      notifyListeners();
    }
  }

  void recordAppointmentOutcome({
    required String appointmentId,
    required String outcomeStatus,
    required String outcomeNotes,
  }) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      _appointments[index] = _appointments[index].copyWith(
        status: ServiceAppointmentStatus.completed,
        outcomeStatus: outcomeStatus,
        outcomeNotes: outcomeNotes,
      );
      _rebuildCalendarItems();
      notifyListeners();
    }
  }

  void linkQuoteToAppointment(String appointmentId, String quoteId) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      _appointments[index] = _appointments[index].copyWith(generatedQuoteId: quoteId);
      notifyListeners();
    }
  }

  void linkBookingToAppointment(String appointmentId, String childBookingId) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index >= 0) {
      _appointments[index] = _appointments[index].copyWith(linkedChildBookingId: childBookingId);
      notifyListeners();
    }
  }

  // Filter appointments
  List<ServiceAppointmentBooking> getUpcomingAppointments() {
    return _appointments
        .where((a) =>
            a.status != ServiceAppointmentStatus.cancelled &&
            a.status != ServiceAppointmentStatus.declined &&
            a.status != ServiceAppointmentStatus.completed)
        .toList();
  }

  List<ServiceAppointmentBooking> getAppointmentsForEvent(String eventId) {
    return _appointments.where((a) => a.eventId == eventId).toList();
  }

  // ==========================================
  // COLLABORATIVE PACKAGE MANAGEMENT
  // ==========================================

  void savePackage(CollaborativePackage pkg) {
    final index = _packages.indexWhere((p) => p.id == pkg.id);
    if (index >= 0) {
      _packages[index] = pkg;
    } else {
      _packages.insert(0, pkg);
    }
    notifyListeners();
  }

  void deletePackage(String packageId) {
    _packages.removeWhere((p) => p.id == packageId);
    notifyListeners();
  }

  void updatePackageComponentCollaborator({
    required String packageId,
    required String componentId,
    required String selectedCollaboratorId,
  }) {
    final pkgIndex = _packages.indexWhere((p) => p.id == packageId);
    if (pkgIndex >= 0) {
      final pkg = _packages[pkgIndex];
      final updatedComponents = pkg.components.map((c) {
        if (c.id == componentId) {
          return c.copyWith(selectedCollaboratorId: selectedCollaboratorId);
        }
        return c;
      }).toList();
      _packages[pkgIndex] = pkg.copyWith(components: updatedComponents);
      notifyListeners();
    }
  }

  void sendCollaboratorInvitation(CollaboratorInvitation invitation) {
    _invitations.insert(0, invitation);
    notifyListeners();
  }

  void respondToInvitation({
    required String invitationId,
    required bool accept,
    String? offeredServiceId,
    String? offeredServiceName,
    double? partnerPrice,
    double? partnerDiscount,
    List<ServiceAppointmentType>? offeredAppointments,
  }) {
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index >= 0) {
      final inv = _invitations[index];
      if (accept) {
        final updated = inv.copyWith(
          status: CollaborationStatus.offerSubmitted,
          offeredServiceId: offeredServiceId,
          offeredServiceName: offeredServiceName,
          partnerPriceOffered: partnerPrice,
          partnerDiscount: partnerDiscount,
          offeredAppointments: offeredAppointments ?? [],
        );
        _invitations[index] = updated;

        // If package exists locally, add vendor as approved collaborator option
        final pkgIndex = _packages.indexWhere((p) => p.id == inv.packageId);
        if (pkgIndex >= 0) {
          final pkg = _packages[pkgIndex];
          final compIndex = pkg.components.indexWhere((c) => c.componentName == inv.roleComponentName);
          if (compIndex >= 0) {
            final comp = pkg.components[compIndex];
            final priceDelta = (partnerPrice ?? comp.packageAllowance) - comp.packageAllowance;
            final newOption = CollaboratorOption(
              vendorId: inv.targetVendorId,
              vendorName: inv.targetVendorName,
              serviceId: offeredServiceId ?? 'srv-new',
              serviceName: offeredServiceName ?? inv.roleComponentName,
              partnerPrice: partnerPrice ?? comp.packageAllowance,
              priceDelta: priceDelta,
              appointmentOptions: offeredAppointments ?? [],
              isApproved: true,
              isAvailable: true,
            );
            final updatedCollaborators = List<CollaboratorOption>.from(comp.approvedCollaborators)..add(newOption);
            final updatedComp = comp.copyWith(approvedCollaborators: updatedCollaborators);
            final updatedComponents = List<PackageComponent>.from(pkg.components)..[compIndex] = updatedComp;
            _packages[pkgIndex] = pkg.copyWith(components: updatedComponents);
          }
        }
      } else {
        _invitations[index] = inv.copyWith(status: CollaborationStatus.declined);
      }
      notifyListeners();
    }
  }

  // Create Parent Package Booking + Child Bookings
  ParentPackageBooking bookCollaborativePackage({
    required CollaborativePackage package,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String? eventId,
    required String? eventName,
    required DateTime eventDate,
    required List<String> linkedAppointmentIds,
  }) {
    final bookingCode = 'PKG-${1000 + _packageBookings.length + 1}';

    // Calculate total price with customer chosen collaborators
    double total = package.basePrice;
    final List<ChildPackageBooking> childBookings = [];

    for (final comp in package.components) {
      final selected = comp.selectedCollaborator;
      if (selected != null) {
        total += selected.priceDelta;
        childBookings.add(
          ChildPackageBooking(
            childBookingId: 'CB-${childBookings.length + 101}',
            parentBookingCode: bookingCode,
            componentName: comp.componentName,
            category: comp.category,
            vendorId: selected.vendorId,
            vendorName: selected.vendorName,
            serviceId: selected.serviceId,
            serviceName: selected.serviceName,
            agreedPrice: selected.partnerPrice,
            priceDelta: selected.priceDelta,
            linkedAppointmentIds: linkedAppointmentIds,
          ),
        );
      }
    }

    final parentBooking = ParentPackageBooking(
      bookingCode: bookingCode,
      packageId: package.id,
      packageName: package.title,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
      basePackagePrice: package.basePrice,
      totalCalculatedPrice: total,
      childBookings: childBookings,
      linkedAppointmentIds: linkedAppointmentIds,
    );

    _packageBookings.insert(0, parentBooking);
    _rebuildCalendarItems();
    notifyListeners();
    return parentBooking;
  }

  // ==========================================
  // UNIFIED CALENDAR
  // ==========================================

  void addBlockedTime({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String reason,
  }) {
    _calendarItems.add(
      VendorCalendarItem(
        id: 'cal-block-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Blocked: $reason',
        type: VendorCalendarItemType.blockedTime,
        date: date,
        startTime: startTime,
        endTime: endTime,
        notes: reason,
      ),
    );
    notifyListeners();
  }

  void _rebuildCalendarItems() {
    _calendarItems.clear();

    // 1. Appointments
    for (final appt in _appointments) {
      if (appt.status != ServiceAppointmentStatus.cancelled &&
          appt.status != ServiceAppointmentStatus.declined) {
        _calendarItems.add(
          VendorCalendarItem(
            id: 'cal-appt-${appt.id}',
            title: '${appt.appointmentTypeName} (${appt.purpose.displayName})',
            type: VendorCalendarItemType.appointment,
            date: appt.scheduledDate,
            startTime: appt.scheduledTime,
            endTime: _calculateEndTime(appt.scheduledTime, appt.durationMinutes),
            location: appt.location,
            clientName: appt.customerName,
            serviceOrEventName: appt.eventName ?? appt.serviceName,
            relatedId: appt.id,
            notes: appt.customerNotes,
          ),
        );
      }
    }

    // 2. Sample Bookings & Logistics
    final now = DateTime.now();
    _calendarItems.addAll([
      VendorCalendarItem(
        id: 'cal-book-1',
        title: 'Wedding Reception - Grand Ballroom',
        type: VendorCalendarItemType.booking,
        date: now.add(const Duration(days: 3)),
        startTime: '16:00',
        endTime: '23:00',
        location: 'Grand Hall, Floor 2',
        clientName: 'Sarah & Adam',
        serviceOrEventName: 'Grand Hall Wedding Package',
        notes: '350 guests confirmed',
      ),
      VendorCalendarItem(
        id: 'cal-setup-1',
        title: 'Hall Setup & Audio Check',
        type: VendorCalendarItemType.setupTime,
        date: now.add(const Duration(days: 3)),
        startTime: '13:00',
        endTime: '16:00',
        location: 'Grand Hall, Floor 2',
        notes: 'Stage backdrop and sound system check',
      ),
      VendorCalendarItem(
        id: 'cal-travel-1',
        title: 'Travel Time to Site Inspection',
        type: VendorCalendarItemType.travelTime,
        date: now.add(const Duration(days: 1)),
        startTime: '10:00',
        endTime: '11:00',
        location: 'Kuala Lumpur City Center',
        notes: 'Site visit travel buffer',
      ),
      VendorCalendarItem(
        id: 'cal-block-1',
        title: 'Maintenance & Facility Cleaning',
        type: VendorCalendarItemType.blockedTime,
        date: now.add(const Duration(days: 7)),
        startTime: '09:00',
        endTime: '18:00',
        location: 'Ballroom A & B',
        notes: 'Deep carpet shampooing and lighting maintenance',
      ),
    ]);
  }

  String _calculateEndTime(String startTime, int durationMinutes) {
    try {
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final totalMinutes = (hours * 60) + minutes + durationMinutes;
        final endH = (totalMinutes ~/ 60) % 24;
        final endM = totalMinutes % 60;
        return '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return startTime;
  }

  // ==========================================
  // SAMPLE DATA INITIALIZATION
  // ==========================================

  void _initSampleData() {
    final now = DateTime.now();

    // 1. Catering Service
    final cateringService = CommonServiceInfo(
      id: 'srv-catering-1',
      vendorId: _currentVendorId,
      vendorName: 'ABC Catering & Culinary Co.',
      serviceName: 'Grand Royal Banquet Catering',
      category: ServiceCategoryType.catering,
      subcategory: 'Malay & International Buffet',
      description:
          'Five-star dining experience for weddings and major corporate galas. Comprehensive buffet setup, live cooking stalls, and professional table service.',
      serviceLocation: 'Kuala Lumpur & Selangor',
      serviceArea: 'Within 60km of Klang Valley',
      startingPrice: 65.0,
      pricingModel: ServicePricingModel.perPersonPrice,
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      workingHoursStart: '08:00',
      workingHoursEnd: '23:00',
      cancellationPolicy: 'Full refund 30 days prior. 50% deposit retained if cancelled within 14 days.',
      depositRequirementPercent: 30.0,
      paymentSchedule: '30% upon confirmation, 70% 5 days prior to event.',
      status: ServiceStatus.published,
    );
    _services.add(cateringService);

    _servicePackages[cateringService.id] = [
      ServicePackageItem(
        id: 'pkg-cat-1',
        serviceId: cateringService.id,
        packageName: 'Classic Heritage Buffet',
        description: '10-course authentic traditional Malay banquet with 2 signature drinks.',
        price: 65.0,
        duration: '4 hours serving',
        includedServices: ['10-course buffet', 'Chafing dishes & setup', '6 service staff', 'Free iced cordials'],
        addOns: ['Live Satay Stall (RM15/pax)', 'Whole Roast Lamb (RM1,800)'],
      ),
      ServicePackageItem(
        id: 'pkg-cat-2',
        serviceId: cateringService.id,
        packageName: 'Royal Platinum Banquet',
        description: 'Premium international fusion banquet with 3 live cooking stations and dome VIP table service.',
        price: 95.0,
        duration: '5 hours serving',
        includedServices: ['14-course premium menu', 'Dome VIP table service', '12 professional waiters', 'Dessert bar'],
        addOns: ['Artisan Dessert Table (RM1,200)', 'Barista Coffee Cart (RM1,500)'],
      ),
    ];

    _serviceAppointmentTypes[cateringService.id] = [
      ServiceAppointmentType(
        id: 'appt-type-tasting',
        serviceId: cateringService.id,
        name: 'Food Tasting Session',
        description: 'Sample up to 6 signature dishes in our executive tasting lounge before confirming your menu.',
        purpose: AppointmentPurpose.tasting,
        durationMinutes: 60,
        location: 'Culinary Studio Lounge, Damansara',
        maxParticipants: 4,
        fee: 100.0,
        isPaid: true,
        isDeposit: true,
        isRefundable: false,
        creditTowardBooking: true, // Credited to booking!
      ),
      ServiceAppointmentType(
        id: 'appt-type-menu-consult',
        serviceId: cateringService.id,
        name: 'Menu & Dietary Consultation',
        description: 'Discuss custom allergen requests, vegetarian alternatives, and seating logistics with our Head Chef.',
        purpose: AppointmentPurpose.consultation,
        durationMinutes: 45,
        location: 'Online Video Call or Studio',
        maxParticipants: 3,
        fee: 0.0,
        isPaid: false,
        creditTowardBooking: false,
      ),
    ];

    _categorySpecificData[cateringService.id] = {
      'cuisineType': 'Traditional Malay & International Fusion',
      'serviceStyle': 'Buffet & Dome Service',
      'minGuests': 100,
      'maxGuests': 2000,
      'buffetPlatedPacked': 'Buffet',
      'isHalal': true,
      'isVegetarian': true,
      'servingDurationHours': 4,
      'numberOfStaff': 10,
      'equipmentIncluded': true,
      'setupIncluded': true,
      'cleanupIncluded': true,
      'deliveryIncluded': true,
    };

    // 2. Venue Service
    final venueService = CommonServiceInfo(
      id: 'srv-venue-1',
      vendorId: _currentVendorId,
      vendorName: 'Grand Hall & Event Services',
      serviceName: 'The Grand Imperial Ballroom',
      category: ServiceCategoryType.venue,
      subcategory: 'Pillarless Ballroom',
      description:
          'Stunning pillarless ballroom equipped with 4K LED screen wall, motorized staging, crystal chandeliers, and VIP holding rooms.',
      serviceLocation: 'Kuala Lumpur',
      serviceArea: 'Central KL',
      startingPrice: 6000.0,
      pricingModel: ServicePricingModel.dailyPrice,
      status: ServiceStatus.published,
    );
    _services.add(venueService);

    _servicePackages[venueService.id] = [
      ServicePackageItem(
        id: 'pkg-venue-half',
        serviceId: venueService.id,
        packageName: 'Half Day Rental (Morning / Evening)',
        description: '6 hours access including 2 hours preparation setup and full audio/visual system.',
        price: 6000.0,
        duration: '6 hours',
        includedServices: ['40 tables & 400 banquet chairs', '4K LED video screen', 'Basic stage lighting', 'Sound system'],
        extraHourPrice: 800.0,
      ),
      ServicePackageItem(
        id: 'pkg-venue-full',
        serviceId: venueService.id,
        packageName: 'Full Day Grand Ballroom',
        description: '12 hours comprehensive access, bridal suite, rehearsal slot, and dedicated AV technician.',
        price: 11000.0,
        duration: '12 hours',
        includedServices: ['Full ballroom access', 'Bridal dressing suite', 'VIP room', 'Dedicated AV technician'],
        extraHourPrice: 800.0,
      ),
    ];

    _serviceAppointmentTypes[venueService.id] = [
      ServiceAppointmentType(
        id: 'appt-type-site-visit',
        serviceId: venueService.id,
        name: 'Venue Site Visit & Floorplan Tour',
        description: 'Guided tour of ballroom, backstage suites, parking access, and stage configurations.',
        purpose: AppointmentPurpose.visit,
        durationMinutes: 60,
        location: 'Grand Hall On-site, Level 2',
        maxParticipants: 6,
        fee: 0.0, // Free
        isPaid: false,
        creditTowardBooking: false,
      ),
      ServiceAppointmentType(
        id: 'appt-type-tech-check',
        serviceId: venueService.id,
        name: 'Technical & AV Walkthrough',
        description: 'Test presentation videos, sound checks, lighting cues, and floor plan placements.',
        purpose: AppointmentPurpose.inspection,
        durationMinutes: 45,
        location: 'Grand Ballroom AV Console',
        fee: 0.0,
        isPaid: false,
      ),
    ];

    _categorySpecificData[venueService.id] = {
      'venueType': 'Ballroom / Event Hall',
      'capacityGuests': 800,
      'indoorOutdoor': 'Indoor',
      'tablesIncluded': true,
      'chairsIncluded': true,
      'parkingSpaces': 300,
      'airConditioning': true,
      'soundSystemIncluded': true,
      'lightingIncluded': true,
      'outsideCateringAllowed': true,
      'outsideVendorsAllowed': true,
      'securityDeposit': 2000.0,
    };

    // 3. Photography Service
    final photoService = CommonServiceInfo(
      id: 'srv-photo-1',
      vendorId: 'v-201',
      vendorName: 'Pixel & Lens Weddings',
      serviceName: 'Cinematic Wedding Photography',
      category: ServiceCategoryType.photography,
      subcategory: 'Candid & Cinematic',
      description: 'Documentary and editorial wedding coverage capturing timeless emotive moments.',
      serviceLocation: 'Selangor & Putrajaya',
      serviceArea: 'Nationwide',
      startingPrice: 2500.0,
      pricingModel: ServicePricingModel.packagePrice,
      status: ServiceStatus.published,
    );
    _services.add(photoService);

    _servicePackages[photoService.id] = [
      ServicePackageItem(
        id: 'pkg-photo-essential',
        serviceId: photoService.id,
        packageName: 'Essential Collection',
        description: '8 hours single photographer coverage with 500 color-graded photos.',
        price: 2500.0,
        duration: '8 hours',
        includedServices: ['1 Principal Photographer', '500 High-Res Edited Photos', 'Online Gallery (12 months)', 'Pendrive'],
        extraHourPrice: 250.0,
      ),
      ServicePackageItem(
        id: 'pkg-photo-premium',
        serviceId: photoService.id,
        packageName: 'Premium Storyteller',
        description: '10 hours dual photographer coverage, 800 edited photos, and flush-mount wedding album.',
        price: 4000.0,
        duration: '10 hours',
        includedServices: ['2 Photographers', '800 Edited Photos', '12x12 Flush Mount Leather Album', 'Pre-wedding mini shoot'],
        extraHourPrice: 350.0,
      ),
      ServicePackageItem(
        id: 'pkg-photo-luxury',
        serviceId: photoService.id,
        packageName: 'Luxury Heirloom',
        description: '12 hours comprehensive coverage, drone aerials, parent albums, and 1,000 photos.',
        price: 6000.0,
        duration: '12 hours',
        includedServices: ['2 Photographers + 1 Assistant', '1,000 Edited Photos', 'Drone Aerial Photos', '2 Parent Albums', 'Full Pre-wedding Session'],
        extraHourPrice: 400.0,
      ),
    ];

    _serviceAppointmentTypes[photoService.id] = [
      ServiceAppointmentType(
        id: 'appt-type-photo-consult',
        serviceId: photoService.id,
        name: 'Concept & Moodboard Consultation',
        description: 'Discuss wedding timeline, shot lists, lighting preferences, and couple aesthetic.',
        purpose: AppointmentPurpose.consultation,
        durationMinutes: 45,
        location: 'Bangsar Studio or Zoom',
        fee: 0.0,
        isPaid: false,
      ),
    ];

    // 4. Boutique / Fashion Service
    final boutiqueService = CommonServiceInfo(
      id: 'srv-boutique-1',
      vendorId: 'v-301',
      vendorName: 'Bella Bridal & Couture',
      serviceName: 'Bridal Gowns & Tuxedos Rental',
      category: ServiceCategoryType.boutiqueFashion,
      subcategory: 'Bridal & Formalwear',
      description: 'Exclusive imported wedding gowns, contemporary tuxedos, custom fittings and alterations.',
      serviceLocation: 'Kuala Lumpur',
      serviceArea: 'West Malaysia',
      startingPrice: 800.0,
      pricingModel: ServicePricingModel.packagePrice,
      status: ServiceStatus.published,
    );
    _services.add(boutiqueService);

    _servicePackages[boutiqueService.id] = [
      ServicePackageItem(
        id: 'pkg-boutique-single',
        serviceId: boutiqueService.id,
        packageName: 'Gown Rental Package',
        description: '1 Premium wedding gown rental with complimentary veil, tiara, and alterations.',
        price: 800.0,
        duration: '4 days rental',
        includedServices: ['Dry cleaning included', 'Basic alteration', 'Accessories bundle'],
      ),
      ServicePackageItem(
        id: 'pkg-boutique-couple',
        serviceId: boutiqueService.id,
        packageName: 'Couple Romance Suite',
        description: '1 Luxury gown + 1 Groom tuxedo complete with shoes and cufflinks.',
        price: 1500.0,
        duration: '5 days rental',
        includedServices: ['1 Luxury Gown', '1 3-Piece Tuxedo', 'Accessories for Bride & Groom', 'Free alteration'],
      ),
    ];

    _serviceAppointmentTypes[boutiqueService.id] = [
      ServiceAppointmentType(
        id: 'appt-type-fitting',
        serviceId: boutiqueService.id,
        name: 'Bridal Test Fitting',
        description: 'Try up to 5 designer gowns in our private bridal fitting suite with a personal stylist.',
        purpose: AppointmentPurpose.fitting,
        durationMinutes: 60,
        location: 'Bella Bridal Suite, Bukit Bintang',
        maxParticipants: 3,
        fee: 50.0,
        isPaid: true,
        creditTowardBooking: true, // Credited when gown booked!
      ),
      ServiceAppointmentType(
        id: 'appt-type-measurement',
        serviceId: boutiqueService.id,
        name: 'Custom Measurement & Alteration',
        description: 'Full 16-point body measurement taken by our master tailor for exact fitting.',
        purpose: AppointmentPurpose.measurement,
        durationMinutes: 30,
        location: 'Bella Bridal Atelier',
        fee: 0.0,
        isPaid: false,
      ),
      ServiceAppointmentType(
        id: 'appt-type-pickup',
        serviceId: boutiqueService.id,
        name: 'Gown Collection & Final Check',
        description: 'Final try-on and dress handover in protective garment travel bags.',
        purpose: AppointmentPurpose.collection,
        durationMinutes: 30,
        location: 'Bella Bridal Atelier',
        fee: 0.0,
      ),
    ];

    // 5. Makeup & Beauty Service
    final makeupService = CommonServiceInfo(
      id: 'srv-makeup-1',
      vendorId: 'v-401',
      vendorName: 'Glam Studio & Hair Artistry',
      serviceName: 'Bridal Makeup & Styling',
      category: ServiceCategoryType.makeupAndBeauty,
      subcategory: 'Bridal Beauty',
      description: 'Luxury bridal makeup using premium cruelty-free cosmetics, airbrush foundation, and custom hair design.',
      serviceLocation: 'Klang Valley',
      serviceArea: 'Travel to venue available',
      startingPrice: 800.0,
      pricingModel: ServicePricingModel.packagePrice,
      status: ServiceStatus.published,
    );
    _services.add(makeupService);

    _serviceAppointmentTypes[makeupService.id] = [
      ServiceAppointmentType(
        id: 'appt-type-makeup-trial',
        serviceId: makeupService.id,
        name: 'Bridal Makeup & Hair Trial',
        description: 'Complete trial run of your wedding look including false lashes, skin prep, and hair veil setting.',
        purpose: AppointmentPurpose.trial,
        durationMinutes: 90,
        location: 'Glam Studio, Mont Kiara',
        maxParticipants: 2,
        fee: 150.0,
        isPaid: true,
        creditTowardBooking: true,
      ),
      ServiceAppointmentType(
        id: 'appt-type-makeup-consult',
        serviceId: makeupService.id,
        name: 'Skin Prep & Style Consultation',
        description: 'Evaluate skin type, color tones, dress neckline matching, and schedule timeline.',
        purpose: AppointmentPurpose.consultation,
        durationMinutes: 30,
        location: 'Online Video Call',
        fee: 0.0,
      ),
    ];

    // ==========================================
    // INITIAL SAMPLE APPOINTMENTS
    // ==========================================
    _appointments.addAll([
      ServiceAppointmentBooking(
        id: 'apt-101',
        appointmentTypeId: 'appt-type-tasting',
        appointmentTypeName: 'Food Tasting Session',
        purpose: AppointmentPurpose.tasting,
        serviceId: cateringService.id,
        serviceName: cateringService.serviceName,
        vendorId: _currentVendorId,
        vendorName: _currentVendorName,
        customerId: 'cust-1',
        customerName: 'Sarah & Adam',
        customerPhone: '+60 12-345 6789',
        eventId: 'evt-101',
        eventName: 'Sarah & Adam Wedding',
        scheduledDate: now.add(const Duration(days: 2)),
        scheduledTime: '14:00',
        durationMinutes: 60,
        participantsCount: 4,
        location: 'Culinary Studio Lounge, Damansara',
        fee: 100.0,
        isPaid: true,
        creditTowardBooking: true,
        status: ServiceAppointmentStatus.confirmed,
        categorySpecificDetails: {
          'preferredMenu': ['Malay Heritage', 'Western Grilled'],
          'dietary': '2 vegetarian, No peanuts',
          'guestCount': 350,
        },
        customerNotes: 'Bride has mild seafood allergy. Groom prefers beef rendang tok.',
      ),
      ServiceAppointmentBooking(
        id: 'apt-102',
        appointmentTypeId: 'appt-type-site-visit',
        appointmentTypeName: 'Venue Site Visit & Floorplan Tour',
        purpose: AppointmentPurpose.visit,
        serviceId: venueService.id,
        serviceName: venueService.serviceName,
        vendorId: _currentVendorId,
        vendorName: _currentVendorName,
        customerId: 'cust-2',
        customerName: 'Michael Chen & Amanda',
        customerPhone: '+60 17-987 6543',
        eventId: 'evt-102',
        eventName: 'Chen Wedding Dinner',
        scheduledDate: now.add(const Duration(days: 5)),
        scheduledTime: '11:00',
        durationMinutes: 60,
        participantsCount: 3,
        location: 'Grand Hall Level 2',
        fee: 0.0,
        isPaid: false,
        status: ServiceAppointmentStatus.confirmed,
        categorySpecificDetails: {
          'expectedGuests': 500,
          'areasToInspect': 'Stage, Ballroom, VIP Suites, Kitchen load-in',
          'setup': 'Round tables + Stage catwalk',
        },
      ),
      ServiceAppointmentBooking(
        id: 'apt-103',
        appointmentTypeId: 'appt-type-fitting',
        appointmentTypeName: 'Bridal Test Fitting',
        purpose: AppointmentPurpose.fitting,
        serviceId: boutiqueService.id,
        serviceName: boutiqueService.serviceName,
        vendorId: 'v-301',
        vendorName: 'Bella Bridal & Couture',
        customerId: 'cust-1',
        customerName: 'Sarah & Adam',
        customerPhone: '+60 12-345 6789',
        eventId: 'evt-101',
        eventName: 'Sarah & Adam Wedding',
        scheduledDate: now.add(const Duration(days: 8)),
        scheduledTime: '15:30',
        durationMinutes: 60,
        participantsCount: 2,
        location: 'Bella Bridal Suite',
        fee: 50.0,
        isPaid: true,
        creditTowardBooking: true,
        status: ServiceAppointmentStatus.confirmed,
        categorySpecificDetails: {
          'dressSelection': 'Royal Princess Lace Gown',
          'size': 'M',
          'height': '165 cm',
          'alteration': 'Hemming and waist taper',
        },
      ),
      ServiceAppointmentBooking(
        id: 'apt-104',
        appointmentTypeId: 'appt-type-makeup-trial',
        appointmentTypeName: 'Bridal Makeup & Hair Trial',
        purpose: AppointmentPurpose.trial,
        serviceId: makeupService.id,
        serviceName: makeupService.serviceName,
        vendorId: 'v-401',
        vendorName: 'Glam Studio & Hair Artistry',
        customerId: 'cust-1',
        customerName: 'Sarah & Adam',
        customerPhone: '+60 12-345 6789',
        eventId: 'evt-101',
        eventName: 'Sarah & Adam Wedding',
        scheduledDate: now.add(const Duration(days: 12)),
        scheduledTime: '10:00',
        durationMinutes: 90,
        participantsCount: 1,
        location: 'Glam Studio, Mont Kiara',
        fee: 150.0,
        isPaid: true,
        creditTowardBooking: true,
        status: ServiceAppointmentStatus.confirmed,
        categorySpecificDetails: {
          'makeupStyle': 'Soft Glam Natural Dewy',
          'hairStyle': 'Low Textured Bun with Hairpin',
        },
      ),
    ]);

    // ==========================================
    // INITIAL COLLABORATIVE PACKAGE
    // ==========================================
    final weddingPackage = CollaborativePackage(
      id: 'pkg-collab-101',
      ownerVendorId: _currentVendorId,
      ownerVendorName: _currentVendorName,
      title: 'Premium Royal Wedding Package',
      description:
          'All-in-one luxury wedding package designed by Grand Hall & ABC Catering. Includes venue, banquet catering, stage decor, and hand-picked collaborators for photography, bridal makeup, and wedding cake.',
      eventTypes: ['Wedding'],
      basePrice: 25000.0,
      components: [
        // 1. Fixed Venue Component
        PackageComponent(
          id: 'comp-venue',
          componentName: 'Venue (Ballroom)',
          category: ServiceCategoryType.venue,
          description: 'The Grand Imperial Ballroom for up to 500 guests with 4K LED Screen.',
          isFixedVendor: true,
          selectionRule: ComponentSelectionRule.exactlyOne,
          appointmentRule: ComponentAppointmentRule.requiredBeforeBooking,
          packageAllowance: 6000.0,
          approvedCollaborators: [
            CollaboratorOption(
              vendorId: _currentVendorId,
              vendorName: _currentVendorName,
              serviceId: venueService.id,
              serviceName: venueService.serviceName,
              partnerPrice: 6000.0,
              priceDelta: 0.0,
              appointmentOptions: _serviceAppointmentTypes[venueService.id] ?? [],
            ),
          ],
          selectedCollaboratorId: _currentVendorId,
        ),

        // 2. Fixed Catering Component
        PackageComponent(
          id: 'comp-catering',
          componentName: 'Catering Banquet',
          category: ServiceCategoryType.catering,
          description: '10-course authentic banquet for 300 guests with buffet setup and staff.',
          isFixedVendor: true,
          selectionRule: ComponentSelectionRule.exactlyOne,
          appointmentRule: ComponentAppointmentRule.recommendedAppointment,
          packageAllowance: 10000.0,
          approvedCollaborators: [
            CollaboratorOption(
              vendorId: _currentVendorId,
              vendorName: 'ABC Catering & Culinary Co.',
              serviceId: cateringService.id,
              serviceName: cateringService.serviceName,
              partnerPrice: 10000.0,
              priceDelta: 0.0,
              appointmentOptions: _serviceAppointmentTypes[cateringService.id] ?? [],
            ),
          ],
          selectedCollaboratorId: _currentVendorId,
        ),

        // 3. Customer Choice Photography Component
        PackageComponent(
          id: 'comp-photo',
          componentName: 'Wedding Photography',
          category: ServiceCategoryType.photography,
          description: 'Full day professional wedding photography coverage with edited high-res digital albums.',
          isFixedVendor: false,
          selectionRule: ComponentSelectionRule.exactlyOne,
          appointmentRule: ComponentAppointmentRule.optionalAppointment,
          packageAllowance: 3000.0,
          approvedCollaborators: [
            CollaboratorOption(
              vendorId: 'v-201',
              vendorName: 'Pixel & Lens Weddings',
              rating: 4.9,
              reviewsCount: 88,
              serviceId: photoService.id,
              serviceName: 'Essential Storyteller (8 hrs)',
              partnerPrice: 3000.0,
              priceDelta: 0.0, // Included
              appointmentOptions: _serviceAppointmentTypes[photoService.id] ?? [],
            ),
            CollaboratorOption(
              vendorId: 'v-202',
              vendorName: 'Artisan Moments Co.',
              rating: 5.0,
              reviewsCount: 114,
              serviceId: 'srv-photo-artisan',
              serviceName: 'Dual Cinema Master (10 hrs)',
              partnerPrice: 3300.0,
              priceDelta: 300.0, // +RM300
              appointmentOptions: [
                ServiceAppointmentType(
                  id: 'appt-artisan-consult',
                  serviceId: 'srv-photo-artisan',
                  name: 'Storytelling Creative Brief',
                  description: '1-on-1 visual moodboard and drone shot plan.',
                  purpose: AppointmentPurpose.consultation,
                  durationMinutes: 45,
                  location: 'Artisan Studio or Zoom',
                ),
              ],
            ),
            CollaboratorOption(
              vendorId: 'v-203',
              vendorName: 'Lina Visuals',
              rating: 4.8,
              reviewsCount: 45,
              serviceId: 'srv-photo-lina',
              serviceName: 'Standard Wedding Coverage',
              partnerPrice: 2800.0,
              priceDelta: -200.0, // -RM200
            ),
          ],
          selectedCollaboratorId: 'v-201',
        ),

        // 4. Customer Choice Bridal Makeup Component
        PackageComponent(
          id: 'comp-makeup',
          componentName: 'Bridal Makeup & Styling',
          category: ServiceCategoryType.makeupAndBeauty,
          description: 'Professional bridal makeup and hairstyling on the wedding day.',
          isFixedVendor: false,
          selectionRule: ComponentSelectionRule.exactlyOne,
          appointmentRule: ComponentAppointmentRule.recommendedAppointment,
          packageAllowance: 800.0,
          approvedCollaborators: [
            CollaboratorOption(
              vendorId: 'v-401',
              vendorName: 'Glam Studio & Hair Artistry',
              rating: 4.9,
              reviewsCount: 62,
              serviceId: makeupService.id,
              serviceName: 'Bridal Makeup & Styling',
              partnerPrice: 800.0,
              priceDelta: 0.0, // Included
              appointmentOptions: _serviceAppointmentTypes[makeupService.id] ?? [],
            ),
            CollaboratorOption(
              vendorId: 'v-402',
              vendorName: 'Beauty by Sarah',
              rating: 4.9,
              reviewsCount: 94,
              serviceId: 'srv-sarah-makeup',
              serviceName: 'Signature Airbrush Glam',
              partnerPrice: 850.0,
              priceDelta: 50.0, // +RM50
              appointmentOptions: [
                ServiceAppointmentType(
                  id: 'appt-sarah-trial',
                  serviceId: 'srv-sarah-makeup',
                  name: 'Airbrush Makeup Trial',
                  description: 'Full airbrush trial session with lash styling.',
                  purpose: AppointmentPurpose.trial,
                  durationMinutes: 90,
                  location: 'Sarah Beauty Studio',
                  fee: 150.0,
                  isPaid: true,
                  creditTowardBooking: true,
                ),
                ServiceAppointmentType(
                  id: 'appt-sarah-hair',
                  serviceId: 'srv-sarah-makeup',
                  name: 'Hair Trial',
                  description: 'Try up to 2 bridal updos and veil settings.',
                  purpose: AppointmentPurpose.trial,
                  durationMinutes: 60,
                  location: 'Sarah Beauty Studio',
                  fee: 80.0,
                  isPaid: true,
                  creditTowardBooking: true,
                ),
              ],
            ),
            CollaboratorOption(
              vendorId: 'v-403',
              vendorName: 'Makeup Pro Studio',
              rating: 5.0,
              reviewsCount: 140,
              serviceId: 'srv-pro-makeup',
              serviceName: 'Celebrity Bridal Glam',
              partnerPrice: 1000.0,
              priceDelta: 200.0, // +RM200
              appointmentOptions: [
                ServiceAppointmentType(
                  id: 'appt-pro-trial',
                  serviceId: 'srv-pro-makeup',
                  name: 'VIP Makeup Trial',
                  description: 'Full celebrity trial with skin prep ampoule.',
                  purpose: AppointmentPurpose.trial,
                  durationMinutes: 90,
                  location: 'Pavilion Suite',
                  fee: 200.0,
                  isPaid: true,
                  creditTowardBooking: true,
                ),
              ],
            ),
            CollaboratorOption(
              vendorId: 'v-404',
              vendorName: 'Lina Beauty Studio',
              rating: 4.7,
              reviewsCount: 38,
              serviceId: 'srv-lina-makeup',
              serviceName: 'Natural Glow Bridal Look',
              partnerPrice: 750.0,
              priceDelta: -50.0, // -RM50
            ),
          ],
          selectedCollaboratorId: 'v-401',
        ),

        // 5. Customer Choice Cake Component
        PackageComponent(
          id: 'comp-cake',
          componentName: 'Tiered Wedding Cake',
          category: ServiceCategoryType.cake,
          description: '3-tier custom tiered cake with edible gold leaf, sugar flowers, and flavor tasting.',
          isFixedVendor: false,
          selectionRule: ComponentSelectionRule.exactlyOne,
          appointmentRule: ComponentAppointmentRule.optionalAppointment,
          packageAllowance: 1200.0,
          approvedCollaborators: [
            CollaboratorOption(
              vendorId: 'v-501',
              vendorName: 'Sweet Artisan Cake Studio',
              rating: 4.9,
              reviewsCount: 77,
              serviceId: 'srv-sweet-cake',
              serviceName: '3-Tier Royal Blossom Cake',
              partnerPrice: 1200.0,
              priceDelta: 0.0,
              appointmentOptions: [
                ServiceAppointmentType(
                  id: 'appt-cake-tasting',
                  serviceId: 'srv-sweet-cake',
                  name: 'Cake Tasting & Flavor Selection',
                  description: 'Sample 5 cake sponges and gourmet fillings (e.g. Belgian Chocolate, Earl Grey Salted Caramel).',
                  purpose: AppointmentPurpose.tasting,
                  durationMinutes: 45,
                  location: 'Sweet Studio Bangsar',
                  maxParticipants: 4,
                  fee: 60.0,
                  isPaid: true,
                  creditTowardBooking: true,
                ),
              ],
            ),
            CollaboratorOption(
              vendorId: 'v-502',
              vendorName: 'Luxe Patisserie',
              rating: 4.8,
              reviewsCount: 51,
              serviceId: 'srv-luxe-cake',
              serviceName: '4-Tier Grand Cascade Cake',
              partnerPrice: 1500.0,
              priceDelta: 300.0, // +RM300
            ),
          ],
          selectedCollaboratorId: 'v-501',
        ),

        // 6. Fixed Decoration Component
        PackageComponent(
          id: 'comp-decor',
          componentName: 'Floral & Stage Decoration',
          category: ServiceCategoryType.decoration,
          description: 'Full stage floral arch, entrance walkway aisle stands, and VIP main table centerpiece.',
          isFixedVendor: true,
          selectionRule: ComponentSelectionRule.exactlyOne,
          appointmentRule: ComponentAppointmentRule.recommendedAppointment,
          packageAllowance: 4000.0,
          approvedCollaborators: [
            CollaboratorOption(
              vendorId: 'v-601',
              vendorName: 'Bloom & Petal Decor',
              rating: 4.9,
              reviewsCount: 93,
              serviceId: 'srv-decor-bloom',
              serviceName: 'Royal Elegance Fresh Flower Stage',
              partnerPrice: 4000.0,
              priceDelta: 0.0,
              appointmentOptions: [
                ServiceAppointmentType(
                  id: 'appt-decor-consult',
                  serviceId: 'srv-decor-bloom',
                  name: 'Floral Theme & 3D Stage Design Review',
                  description: 'Review 3D render designs, color swatches, and fresh flower sample arrangements.',
                  purpose: AppointmentPurpose.designReview,
                  durationMinutes: 60,
                  location: 'Bloom Studio Damansara',
                ),
              ],
            ),
          ],
          selectedCollaboratorId: 'v-601',
        ),
      ],
    );
    _packages.add(weddingPackage);

    // ==========================================
    // SAMPLE INVITATIONS
    // ==========================================
    _invitations.addAll([
      CollaboratorInvitation(
        id: 'inv-101',
        packageId: 'pkg-ext-201',
        packageName: 'Luxury Corporate Gala 2026',
        ownerVendorId: 'v-888',
        ownerVendorName: 'Apex Event Planners',
        targetVendorId: _currentVendorId,
        targetVendorName: _currentVendorName,
        roleCategory: ServiceCategoryType.catering,
        roleComponentName: 'Executive Gala Dinner',
        eventDate: '15 Nov 2026',
        location: 'Kuala Lumpur Convention Centre',
        packageAllowance: 12000.0,
        requestedAppointmentTypes: ['Food Tasting Session', 'Menu Consultation'],
        status: CollaborationStatus.pending,
      ),
      CollaboratorInvitation(
        id: 'inv-102',
        packageId: weddingPackage.id,
        packageName: weddingPackage.title,
        ownerVendorId: _currentVendorId,
        ownerVendorName: _currentVendorName,
        targetVendorId: 'v-402',
        targetVendorName: 'Beauty by Sarah',
        roleCategory: ServiceCategoryType.makeupAndBeauty,
        roleComponentName: 'Bridal Makeup & Styling',
        eventDate: '20 Dec 2026',
        location: 'Grand Ballroom, Level 2',
        packageAllowance: 800.0,
        requestedAppointmentTypes: ['Airbrush Makeup Trial'],
        status: CollaborationStatus.offerSubmitted,
        partnerPriceOffered: 850.0,
        partnerDiscount: 150.0,
        offeredServiceId: 'srv-sarah-makeup',
        offeredServiceName: 'Signature Airbrush Glam',
      ),
    ]);

    _rebuildCalendarItems();
  }
}
