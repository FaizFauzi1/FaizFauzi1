// Version: 1.0.1 - Fixing Null-Safety
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eventease/features/booking/data/models/appointment.dart';
import 'package:eventease/core/services/supabase_service.dart';

class AppointmentProvider with ChangeNotifier {
  final _supabase = SupabaseService.client;
  
  List<Appointment> _appointments = [];
  List<Appointment> _customerAppointments = [];
  List<Appointment> _vendorAppointments = [];
  bool _isLoading = false;
  String? _error;
  
  StreamSubscription? _appointmentSubscription;

  List<Appointment> get appointments => _appointments;
  List<Appointment> get customerAppointments => _customerAppointments;
  List<Appointment> get vendorAppointments => _vendorAppointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppointmentProvider() {
    _subscribeToAppointments();
  }

  @override
  void dispose() {
    _appointmentSubscription?.cancel();
    super.dispose();
  }

  // Subscribe to real-time appointment updates
  void _subscribeToAppointments() {
    _appointmentSubscription = _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _loadAppointmentsFromData(data);
        });
  }

  // Load appointments from stream data
  Future<void> _loadAppointmentsFromData(List<Map<String, dynamic>> data) async {
    try {
      _appointments = data.map((json) => Appointment.fromJson(json)).toList();
      
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Keep customer and vendor lists in sync with the real-time stream
        _customerAppointments = _appointments.where((a) => a.customerId == user.id).toList();
        _vendorAppointments = _appointments.where((a) => a.vendorId == user.id).toList();
        
        // Sort them by scheduled date descending
        _customerAppointments.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
        _vendorAppointments.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading appointments from stream: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load customer appointments
  Future<void> loadCustomerAppointments(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('customer_id', customerId)
          .order('scheduled_date', ascending: false);

      _customerAppointments = (response as List<dynamic>)
          .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _error = null;
    } catch (e) {
      debugPrint('Error loading customer appointments: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load vendor appointments
  Future<void> loadVendorAppointments(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('vendor_id', vendorId)
          .order('scheduled_date', ascending: false);

      _vendorAppointments = (response as List<dynamic>)
          .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _error = null;
    } catch (e) {
      debugPrint('Error loading vendor appointments: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new appointment
  Future<Appointment?> addAppointment(Appointment appointment) async {
    try {
      final response = await _supabase
          .from('appointments')
          .insert(appointment.toJson())
          .select()
          .single();

      final newAppointment = Appointment.fromJson(response);
      
      // Update local lists
      _appointments.add(newAppointment);
      if (_customerAppointments.isNotEmpty && 
          appointment.customerId == _customerAppointments.first.customerId) {
        _customerAppointments.add(newAppointment);
      }
      if (_vendorAppointments.isNotEmpty && 
          appointment.vendorId == _vendorAppointments.first.vendorId) {
        _vendorAppointments.add(newAppointment);
      }
      
      notifyListeners();
      return newAppointment;
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    try {
      await _supabase
          .from('appointments')
          .update({
            'status': status.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      // Update local lists
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      final customerIndex = _customerAppointments.indexWhere((a) => a.id == appointmentId);
      if (customerIndex != -1) {
        _customerAppointments[customerIndex] = _customerAppointments[customerIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      final vendorIndex = _vendorAppointments.indexWhere((a) => a.id == appointmentId);
      if (vendorIndex != -1) {
        _vendorAppointments[vendorIndex] = _vendorAppointments[vendorIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get appointment by ID
  Appointment? getAppointmentById(String appointmentId) {
    try {
      return _appointments.firstWhere((appointment) => appointment.id == appointmentId);
    } catch (e) {
      return null;
    }
  }

  // Get appointments by status
  List<Appointment> getAppointmentsByStatus(AppointmentStatus status) {
    return _appointments.where((appointment) => appointment.status == status).toList();
  }

  // Get upcoming appointments for customer
  List<Appointment> getUpcomingCustomerAppointments(String customerId) {
    final now = DateTime.now();
    return _customerAppointments.where((appointment) =>
      appointment.customerId == customerId &&
      appointment.scheduledDate.isAfter(now) &&
      appointment.status != AppointmentStatus.cancelled
    ).toList();
  }

  // Get upcoming appointments for vendor
  List<Appointment> getUpcomingVendorAppointments(String vendorId) {
    final now = DateTime.now();
    return _vendorAppointments.where((appointment) =>
      appointment.vendorId == vendorId &&
      appointment.scheduledDate.isAfter(now) &&
      appointment.status != AppointmentStatus.cancelled
    ).toList();
  }

  // Cancel appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    return await updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  // Confirm appointment
  Future<bool> confirmAppointment(String appointmentId) async {
    return await updateAppointmentStatus(appointmentId, AppointmentStatus.confirmed);
  }

  // Complete appointment
  Future<bool> completeAppointment(String appointmentId) async {
    return await updateAppointmentStatus(appointmentId, AppointmentStatus.completed);
  }

  // Get appointment statistics
  Map<String, int> getAppointmentStats(String userId, bool isVendor) {
    final userAppointments = isVendor
      ? _vendorAppointments.where((a) => a.vendorId == userId).toList()
      : _customerAppointments.where((a) => a.customerId == userId).toList();

    return {
      'total': userAppointments.length,
      'pending': userAppointments.where((a) => a.status == AppointmentStatus.pending).length,
      'confirmed': userAppointments.where((a) => a.status == AppointmentStatus.confirmed).length,
      'completed': userAppointments.where((a) => a.status == AppointmentStatus.completed).length,
      'cancelled': userAppointments.where((a) => a.status == AppointmentStatus.cancelled).length,
    };
  }

  // Create appointment from chat request
  Future<Appointment?> createAppointmentFromChatRequest({
    required String vendorId,
    required String customerId,
    required String serviceId,
    required DateTime scheduledDate,
    required AppointmentType type,
    Duration? duration,
    required String location,
    String? notes,
    double? cost,
    String? customerName,
    String? customerEmail,
    String? vendorName,
    String? serviceName,
    String? chatMessageId,
  }) async {
    final appointment = Appointment(
      id: '', // Will be generated by Supabase
      vendorId: vendorId,
      customerId: customerId,
      serviceId: serviceId,
      type: type,
      scheduledDate: scheduledDate,
      duration: duration,
      location: location,
      notes: notes ?? '',
      status: AppointmentStatus.pending,
      cost: cost,
      isPaid: false,
      reminder: true,
      createdAt: DateTime.now(),
      customerName: customerName,
      customerEmail: customerEmail,
      vendorName: vendorName,
      serviceName: serviceName,
      chatMessageId: chatMessageId,
      source: 'chat',
    );

    return await addAppointment(appointment);
  }

  // Clear all data (for logout)
  void clearData() {
    _appointments.clear();
    _customerAppointments.clear();
    _vendorAppointments.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
