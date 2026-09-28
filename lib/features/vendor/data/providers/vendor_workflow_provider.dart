import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/vendor_service_workflow_models.dart';

class VendorWorkflowProvider with ChangeNotifier {
  // Current active vendor
  String _currentVendorId = '';
  String _currentVendorName = '';
  StreamSubscription<AuthState>? _authSubscription;

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
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _loadCurrentVendor();
    });
    _loadCurrentVendor();
  }

  Future<void> _loadCurrentVendor() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setCurrentVendor('', '');
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('vendor_profiles')
          .select('id, business_name')
          .eq('user_id', userId)
          .maybeSingle();

      if (profile == null) {
        setCurrentVendor('', '');
        return;
      }

      setCurrentVendor(
        profile['id']?.toString() ?? '',
        profile['business_name']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('Failed to load workflow vendor profile: $e');
    }
  }

  void setCurrentVendor(String id, String name) {
    final vendorChanged = _currentVendorId != id;
    _currentVendorId = id;
    _currentVendorName = name;
    if (vendorChanged) {
      _services.clear();
      _servicePackages.clear();
      _serviceAppointmentTypes.clear();
      _categorySpecificData.clear();
      _appointments.clear();
      _packages.clear();
      _invitations.clear();
      _packageBookings.clear();
      _calendarItems.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
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
}
