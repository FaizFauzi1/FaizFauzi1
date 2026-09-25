import 'package:flutter/material.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/models/booking_change.dart';
import 'package:eventease/features/booking/data/models/booking_price_adjustment.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:eventease/core/services/admin_notification_service.dart';
import 'package:eventease/core/services/analytics_service.dart';
import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/referral/data/referral_service.dart';
import 'package:intl/intl.dart';

class BookingProvider with ChangeNotifier {
  List<Booking> _bookings = [];
  List<Booking> _customerBookings = [];
  List<Booking> _vendorBookings = [];

  bool _isLoading = false;
  String? _error;

  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<Booking> get customerBookings => List.unmodifiable(_customerBookings);
  List<Booking> get vendorBookings => List.unmodifiable(_vendorBookings);
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load customer bookings
  Future<void> loadCustomerBookings(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.select(
        table: 'bookings',
        filters: {'customer_id': customerId},
        columns: '*, customer_user(*), vendor_profiles(business_name), vendor_services(name), installment_plans(*, installment_payments(*))',
      );

      _customerBookings = response.map((data) => Booking.fromSupabase(data)).toList();
      _customerBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      
      // Update main list
      _syncBookingsList();
      
    } catch (e) {
      print('Error loading customer bookings: $e');
      _error = 'Failed to load bookings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load vendor bookings
  Future<void> loadVendorBookings(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.select(
        table: 'bookings',
        filters: {'vendor_id': vendorId},
        columns: '*, customer_user(*), vendor_profiles(business_name), vendor_services(name), installment_plans(*, installment_payments(*))',
      );

      _vendorBookings = response.map((data) => Booking.fromSupabase(data)).toList();
      _vendorBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      // Check for past bookings and update status if necessary
      await _checkAndExpirePastBookings(_vendorBookings);

      // Update main list
      _syncBookingsList();

    } catch (e) {
      print('Error loading vendor bookings: $e');
      _error = 'Failed to load bookings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncBookingsList() {
    // Combine lists without duplicates
    final Set<String> ids = {};
    final List<Booking> combined = [];
    
    for (var b in _vendorBookings) {
      if (ids.add(b.id)) combined.add(b);
    }
    for (var b in _customerBookings) {
      if (ids.add(b.id)) combined.add(b);
    }
    _bookings = combined;
  }

  // Add a new booking
  Future<Booking?> addBooking(Booking booking) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.insert(
        table: 'bookings',
        data: booking.toSupabaseJson(),
      );

        if (response.isNotEmpty) {
          var newBooking = Booking.fromSupabase(response.first);
          
          // If the response from insert doesn't include joined data, 
          // we might need to preserve the vendor name from the input booking object
          if (newBooking.vendorName.isEmpty && booking.vendorName.isNotEmpty) {
            newBooking = newBooking.copyWith(vendorName: booking.vendorName);
          }

          _bookings.add(newBooking);
          
          // Add to sublists if applicable
          if (_customerBookings.isNotEmpty && newBooking.customerId == _customerBookings.first.customerId) {
            _customerBookings.add(newBooking);
            _customerBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
          }
          
          if (_vendorBookings.isNotEmpty && newBooking.vendorId == _vendorBookings.first.vendorId) {
            _vendorBookings.add(newBooking);
            _vendorBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
          }

          // Trigger Notification
          await NotificationService().sendBookingSubmittedNotification(
            customerId: newBooking.customerId,
            vendorId: newBooking.vendorId,
            bookingId: newBooking.id,
            serviceName: newBooking.serviceName.isNotEmpty ? newBooking.serviceName : (newBooking.packageName.isNotEmpty ? newBooking.packageName : "Service"),
            bookingDate: newBooking.bookingDate,
          );

          // Admin Notification: New Booking (Handles high-value alerts internally)
          await AdminNotificationService().notifyNewBooking(
            newBooking.id,
            newBooking.amount,
            newBooking.customerName.isNotEmpty ? newBooking.customerName : "Customer",
            newBooking.vendorName.isNotEmpty ? newBooking.vendorName : "Vendor"
          );

          // Track in PostHog Analytics
          AnalyticsService().trackBookingCreated(
            bookingId: newBooking.id,
            vendorId: newBooking.vendorId,
            amount: newBooking.amount,
            status: _statusToString(newBooking.status),
          );

          return newBooking;
        }
    } catch (e) {
      print('Error adding booking: $e');
      _error = 'Failed to create booking';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVendor: return 'pending_vendor';
      case BookingStatus.awaitingPayment: return 'awaiting_payment';
      case BookingStatus.confirmed: return 'confirmed';
      case BookingStatus.inProgress: return 'in_progress';
      case BookingStatus.completed: return 'completed';
      case BookingStatus.cancelledByUser: return 'cancelled_by_user';
      case BookingStatus.cancelledByVendor: return 'cancelled_by_vendor';
      case BookingStatus.rejected: return 'rejected';
      case BookingStatus.expired: return 'expired';
      case BookingStatus.pending: return 'pending';
      case BookingStatus.cancelled: return 'cancelled';
      case BookingStatus.changeRequested: return 'change_requested';
      case BookingStatus.changeApproved: return 'change_approved';
      case BookingStatus.changeRejected: return 'change_rejected';
      case BookingStatus.awaitingAdjustmentPayment: return 'awaiting_adjustment_payment';
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await SupabaseService.update(
        table: 'bookings',
        data: {
          'status': _statusToString(status),
          'updated_at': DateTime.now().toIso8601String(),
        },
        column: 'id',
        value: bookingId,
      );

      _updateLocalBookingStatus(bookingId, status);

      if (status == BookingStatus.confirmed ||
          status == BookingStatus.completed) {
        final row = await SupabaseService.client
            .from('bookings')
            .select('customer_id')
            .eq('id', bookingId)
            .maybeSingle();
        final customerId = row?['customer_id'] as String?;
        if (customerId != null) {
          await ReferralService.qualifyReferral(customerId, 'first_booking');
        }
      }
    } catch (e) {
      print('Error updating booking status: $e');
      _error = 'Failed to update status';
      notifyListeners();
    }
  }

  void _updateLocalBookingStatus(String bookingId, BookingStatus status) {
    final now = DateTime.now();
    
    int index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: status, updatedAt: now);
    }
    
    index = _customerBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _customerBookings[index] = _customerBookings[index].copyWith(status: status, updatedAt: now);
    }
    
    index = _vendorBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      _vendorBookings[index] = _vendorBookings[index].copyWith(status: status, updatedAt: now);
    }
    
    notifyListeners();
  }

  // --- Installment Methods ---

  // Create an installment plan for a booking
  Future<void> createInstallmentPlan(InstallmentPlan plan, List<Map<String, dynamic>> paymentSchedule) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Insert the plan
      final planResponse = await SupabaseService.insert(
        table: 'installment_plans',
        data: plan.toSupabaseJson(),
      );

      if (planResponse.isNotEmpty) {
        final planId = planResponse.first['id'];
        
        // 2. Insert the payment schedule
        for (final p in paymentSchedule) {
          await SupabaseService.insert(
            table: 'installment_payments',
            data: {
              'plan_id': planId,
              'amount': p['amount'],
              'due_date': (p['dueDate'] as DateTime).toIso8601String().split('T')[0],
              'status': p['status'],
            },
          );
        }

        // 3. Update payment status of the booking to partially_paid (assuming deposit is handled)
        // Note: The actual deposit payment would have happened just before this.
        
        // Refresh the booking data locally to show installments
        await _refreshBookingWithInstallments(plan.bookingId);
      }
    } catch (e) {
      print('Error creating installment plan: $e');
      _error = 'Failed to create installment plan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshBookingWithInstallments(String bookingId) async {
    try {
      final response = await SupabaseService.select(
        table: 'bookings',
        filters: {'id': bookingId},
        columns: '*, customer_user(*), vendor_services(name), installment_plans(*, installment_payments(*))',
      );

      if (response.isNotEmpty) {
        final updatedBooking = Booking.fromSupabase(response.first);
        
        // Update local lists
        _updateLocalBooking(updatedBooking);
      }
    } catch (e) {
      print('Error refreshing booking: $e');
    }
  }

  void _updateLocalBooking(Booking updatedBooking) {
    int index = _bookings.indexWhere((b) => b.id == updatedBooking.id);
    if (index != -1) _bookings[index] = updatedBooking;
    
    index = _customerBookings.indexWhere((b) => b.id == updatedBooking.id);
    if (index != -1) _customerBookings[index] = updatedBooking;
    
    index = _vendorBookings.indexWhere((b) => b.id == updatedBooking.id);
    if (index != -1) _vendorBookings[index] = updatedBooking;
    
    notifyListeners();
  }

  // --- Amendment Flow Methods ---

  // Request a booking change
  Future<void> requestBookingChange(BookingChange change) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.insert(
        table: 'booking_changes',
        data: change.toSupabaseJson(),
      );

      if (response.isNotEmpty) {
        // Update booking status to changeRequested
        await updateBookingStatus(change.bookingId, BookingStatus.changeRequested);
      }
    } catch (e) {
      print('Error requesting booking change: $e');
      _error = 'Failed to request change';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch changes for a specific booking
  Future<List<BookingChange>> getBookingChanges(String bookingId) async {
    try {
      final response = await SupabaseService.select(
        table: 'booking_changes',
        filters: {'booking_id': bookingId},
      );
      return response.map((data) => BookingChange.fromSupabase(data)).toList();
    } catch (e) {
      print('Error fetching booking changes: $e');
      return [];
    }
  }

  // Approve a booking change (Vendor)
  Future<void> approveBookingChange(String changeId, String bookingId, {double priceDiff = 0.0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Update change status to approved
      await SupabaseService.update(
        table: 'booking_changes',
        data: {
          'status': 'approved',
          'price_diff': priceDiff,
          'resolved_at': DateTime.now().toIso8601String(),
        },
        column: 'id',
        value: changeId,
      );

      // 2. Determine next booking status based on priceDiff
      BookingStatus nextStatus;
      if (priceDiff > 0) {
        nextStatus = BookingStatus.awaitingAdjustmentPayment;
        
        // Create a price adjustment record
        await SupabaseService.insert(
          table: 'booking_price_adjustments',
          data: {
            'booking_id': bookingId,
            'change_id': changeId,
            'amount': priceDiff,
            'adjustment_type': 'extra_charge',
            'payment_status': 'pending',
          },
        );
      } else {
        nextStatus = BookingStatus.confirmed;
        
        // If priceDiff < 0, create a refund adjustment
        if (priceDiff < 0) {
          await SupabaseService.insert(
            table: 'booking_price_adjustments',
            data: {
              'booking_id': bookingId,
              'change_id': changeId,
              'amount': priceDiff,
              'adjustment_type': 'refund',
              'payment_status': 'pending',
            },
          );
        }
        
        // APPLY THE CHANGES TO THE BOOKING TABLE
        final changes = await getBookingChanges(bookingId);
        final change = changes.firstWhere((c) => c.id == changeId);
        
        await _applyApprovedChanges(bookingId, change);
      }

      await updateBookingStatus(bookingId, nextStatus);

    } catch (e) {
      print('Error approving booking change: $e');
      _error = 'Failed to approve change';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apply approved changes to the bookings table (internal)
  Future<void> _applyApprovedChanges(String bookingId, BookingChange change) async {
    final Map<String, dynamic> updateData = {};
    
    if (change.type == BookingChangeType.date) {
      final newDateStr = change.newValue['date']?.toString();
      if (newDateStr != null) {
        final newDate = DateTime.parse(newDateStr);
        updateData['booking_date'] = newDate.toIso8601String().split('T')[0];
        updateData['event_date'] = updateData['booking_date'];
      }
    } else if (change.type == BookingChangeType.package) {
      updateData['package_name'] = change.newValue['packageName'];
      updateData['total_amount'] = (change.newValue['amount'] as num).toDouble();
    }
    
    updateData['updated_at'] = DateTime.now().toIso8601String();

    if (updateData.isNotEmpty) {
      await SupabaseService.update(
        table: 'bookings',
        data: updateData,
        column: 'id',
        value: bookingId,
      );
      
      _refreshLocalBookingData(bookingId, updateData);
    }
  }

  void _refreshLocalBookingData(String bookingId, Map<String, dynamic> updateData) {
     int index = _bookings.indexWhere((b) => b.id == bookingId);
     if (index != -1) {
       var b = _bookings[index];
       if (updateData.containsKey('booking_date')) b = b.copyWith(bookingDate: DateTime.parse(updateData['booking_date']));
       if (updateData.containsKey('package_name')) b = b.copyWith(packageName: updateData['package_name']);
       if (updateData.containsKey('total_amount')) b = b.copyWith(amount: updateData['total_amount']);
       _bookings[index] = b;
     }
     notifyListeners();
  }

  // Reject a booking change (Vendor)
  Future<void> rejectBookingChange(String changeId, String bookingId, String reason) async {
    try {
      await SupabaseService.update(
        table: 'booking_changes',
        data: {
          'status': 'rejected',
          'vendor_notes': reason,
          'resolved_at': DateTime.now().toIso8601String(),
        },
        column: 'id',
        value: changeId,
      );

      await updateBookingStatus(bookingId, BookingStatus.confirmed);
    } catch (e) {
      print('Error rejecting booking change: $e');
      _error = 'Failed to reject change';
      notifyListeners();
    }
  }

  // Fetch all pending changes for a vendor across all their bookings
  Future<List<BookingChange>> getPendingVendorChanges(String vendorId) async {
    try {
      // Filter to bookings with 'changeRequested' status (already loaded locally)
      final changeRequestedBookingIds = _vendorBookings
          .where((b) => b.status == BookingStatus.changeRequested)
          .map((b) => b.id)
          .toList();

      if (changeRequestedBookingIds.isEmpty) return [];

      // Single batch query using IN clause to avoid N+1 round-trips
      final response = await SupabaseService.client
          .from('booking_changes')
          .select()
          .inFilter('booking_id', changeRequestedBookingIds)
          .eq('status', 'pending');

      return (response as List<dynamic>)
          .map((data) => BookingChange.fromSupabase(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching vendor changes (batch): $e');
      // Fallback: individual queries if batch fails
      try {
        final changeRequestedBookingIds = _vendorBookings
            .where((b) => b.status == BookingStatus.changeRequested)
            .map((b) => b.id)
            .toList();
        final List<BookingChange> allPending = [];
        for (var id in changeRequestedBookingIds) {
          final changes = await getBookingChanges(id);
          allPending.addAll(changes.where((c) => c.status == BookingChangeStatus.pending));
        }
        return allPending;
      } catch (fallbackError) {
        print('Error in fallback vendor changes fetch: $fallbackError');
        return [];
      }
    }
  }

  // Get booking by ID
  Booking? getBookingById(String bookingId) {
    try {
      return _bookings.firstWhere((booking) => booking.id == bookingId);
    } catch (e) {
      return null;
    }
  }

  // Get bookings by status
  List<Booking> getBookingsByStatus(BookingStatus status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  // Get upcoming bookings for customer
  List<Booking> getUpcomingCustomerBookings(String customerId) {
    // Rely on loaded data
    final now = DateTime.now();
    return _customerBookings.where((booking) =>
      booking.bookingDate.isAfter(now) &&
      booking.status != BookingStatus.cancelled
    ).toList();
  }

  // Get upcoming bookings for vendor
  List<Booking> getUpcomingVendorBookings(String vendorId) {
    final now = DateTime.now();
    return _vendorBookings.where((booking) =>
      booking.bookingDate.isAfter(now) &&
      booking.status != BookingStatus.cancelled
    ).toList();
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelledByUser);
  }

  // Accept booking (Vendor confirms availability)
  Future<void> acceptBooking(String bookingId) async {
    final booking = getBookingById(bookingId);
    await updateBookingStatus(bookingId, BookingStatus.awaitingPayment);
    
    // Trigger Notification
    if (booking != null) {
      await NotificationService().sendVendorConfirmedNotification(
        customerId: booking.customerId,
        bookingId: bookingId,
        serviceName: booking.serviceName.isNotEmpty ? booking.serviceName : (booking.packageName.isNotEmpty ? booking.packageName : "Service"),
      );
    }
  }

  // Reject booking
  Future<void> rejectBooking(String bookingId) async {
    final booking = getBookingById(bookingId);
    await updateBookingStatus(bookingId, BookingStatus.rejected);
    
    // Trigger Notification
    if (booking != null) {
      await NotificationService().createNotification(
        userId: booking.customerId,
        title: 'Booking Rejected',
        message: 'Unfortunately, your booking for ${booking.serviceName} has been rejected by the vendor.',
        type: NotificationType.vendorRejected,
        priority: NotificationPriority.high,
        relatedId: bookingId,
      );
    }
  }

  // Get booking statistics
  Map<String, int> getBookingStats(String userId, bool isVendor) {
    final userBookings = isVendor
      ? _vendorBookings
      : _customerBookings; // Assuming filtered lists are already relevant to logged in user

    return {
      'total': userBookings.length,
      'pending': userBookings.where((b) => b.status == BookingStatus.pendingVendor).length,
      'awaitingPayment': userBookings.where((b) => b.status == BookingStatus.awaitingPayment).length,
      'confirmed': userBookings.where((b) => b.status == BookingStatus.confirmed).length,
      'inProgress': userBookings.where((b) => b.status == BookingStatus.inProgress).length,
      'completed': userBookings.where((b) => b.status == BookingStatus.completed).length,
      'cancelled': userBookings.where((b) => b.status == BookingStatus.cancelledByUser || b.status == BookingStatus.cancelledByVendor).length,
      'changeRequested': userBookings.where((b) => b.status == BookingStatus.changeRequested).length,
    };
  }

  // Check for past-date bookings that are still pending/awaiting payment and mark as expired
  Future<void> _checkAndExpirePastBookings(List<Booking> bookings) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final expiredBookings = bookings.where((b) => 
      (b.status == BookingStatus.pendingVendor || b.status == BookingStatus.awaitingPayment) &&
      b.bookingDate.isBefore(today)
    ).toList();

    if (expiredBookings.isEmpty) return;

    for (var b in expiredBookings) {
      try {
        await updateBookingStatus(b.id, BookingStatus.expired);
      } catch (e) {
        print('Error expiring booking ${b.id}: $e');
      }
    }
  }

  // Clear all data (for logout)
  void clearData() {
    _bookings.clear();
    _customerBookings.clear();
    _vendorBookings.clear();
    notifyListeners();
  }
}
