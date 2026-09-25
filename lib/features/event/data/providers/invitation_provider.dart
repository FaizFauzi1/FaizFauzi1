import 'package:flutter/material.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class InvitationProvider with ChangeNotifier {
  final List<Invitation> _invitations = [];
  final List<Event> _events = [];
  bool _isLoading = false;
  
  List<String> _joinedInvitationCodes = [];

  // Getters
  List<Invitation> get invitations => List.unmodifiable(_invitations);
  List<Event> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;
  List<String> get joinedInvitationCodes => _joinedInvitationCodes;

  InvitationProvider() {
    _loadJoinedCodes();
  }

  Future<void> _loadJoinedCodes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _joinedInvitationCodes = prefs.getStringList('joined_invitation_codes') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('InvitationProvider: Error loading joined codes: $e');
    }
  }

  Future<void> addJoinedInvitationCode(String code) async {
    if (_joinedInvitationCodes.contains(code)) return;
    
    _joinedInvitationCodes.insert(0, code);
    if (_joinedInvitationCodes.length > 10) {
      _joinedInvitationCodes = _joinedInvitationCodes.sublist(0, 10);
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('joined_invitation_codes', _joinedInvitationCodes);
      notifyListeners();
    } catch (e) {
      debugPrint('InvitationProvider: Error saving joined code: $e');
    }
  }

  Future<void> removeJoinedCode(String code) async {
    if (!_joinedInvitationCodes.contains(code)) return;
    
    _joinedInvitationCodes.remove(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('joined_invitation_codes', _joinedInvitationCodes);
      notifyListeners();
    } catch (e) {
      debugPrint('InvitationProvider: Error removing joined code: $e');
    }
  }

  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'EVT-${List.generate(6, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  // Invitation CRUD Operations
  Future<Invitation> createInvitation({
    required String eventId,
    required String guestName,
    required String guestEmail,
    String? personalMessage,
  }) async {
    final invitation = Invitation(
      id: const Uuid().v4(),
      eventId: eventId,
      guestEmail: guestEmail,
      guestName: guestName,
      status: InvitationStatus.sent,
      invitationCode: generateInvitationCode(),
      personalMessage: personalMessage,
      allowPlusOne: true,
      maxPlusOnes: 1,
      sentAt: DateTime.now(),
      plusOneNames: [],
      additionalData: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await addInvitation(invitation);
    return invitation;
  }

  Invitation? getInvitationById(String invitationId) {
    try {
      return _invitations.firstWhere((invitation) => invitation.id == invitationId);
    } catch (e) {
      return null;
    }
  }

  Future<Invitation?> getInvitationByCode(String code, {bool forceRefresh = false}) async {
    // Check locally first unless forceRefresh is true
    if (!forceRefresh) {
      try {
        final local = _invitations.firstWhere((inv) => inv.invitationCode == code);
        return local;
      } catch (_) {
        // Fall through to Supabase
      }
    }
    
    // Fetch from Supabase
    try {
      final response = await SupabaseService.client
          .from('event_invitations')
          .select()
          .eq('invitation_code', code)
          .maybeSingle();
      
      if (response != null) {
        final invitation = Invitation.fromSupabase(response);
        addInvitation(invitation); // Add to local list/update existing
        return invitation;
      }
    } catch (e) {
      debugPrint('InvitationProvider: Error fetching invitation by code: $e');
    }
    return null;
  }

  Future<void> loadInvitationsForEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('event_invitations')
          .select()
          .eq('event_id', eventId);
      
      final loadedInvitations = (response as List).map((json) => Invitation.fromSupabase(json)).toList();
      
      // Update local list
      for (var inv in loadedInvitations) {
        final index = _invitations.indexWhere((i) => i.id == inv.id);
        if (index != -1) {
          _invitations[index] = inv;
        } else {
          _invitations.add(inv);
        }
      }
    } catch (e) {
      debugPrint('InvitationProvider: Error loading invitations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Invitation> getInvitationsForEvent(String eventId) {
    return _invitations.where((invitation) => invitation.eventId == eventId).toList();
  }

  List<Invitation> getInvitationsForGuest(String guestEmail) {
    return _invitations.where((invitation) => invitation.guestEmail == guestEmail).toList();
  }

  List<Invitation> getPendingInvitations(String guestEmail) {
    return _invitations.where((invitation) =>
      invitation.guestEmail == guestEmail &&
      (invitation.status == InvitationStatus.sent || invitation.status == InvitationStatus.pending)
    ).toList();
  }

  List<Invitation> getAcceptedInvitations(String guestEmail) {
    return _invitations.where((invitation) =>
      invitation.guestEmail == guestEmail &&
      invitation.status == InvitationStatus.accepted
    ).toList();
  }

  Future<void> addInvitation(Invitation invitation) async {
    // Save to Supabase
    try {
      await SupabaseService.client
          .from('event_invitations')
          .upsert(invitation.toSupabaseJson());
    } catch (e) {
      debugPrint('InvitationProvider: Error adding invitation to Supabase: $e');
    }

    // Update locally
    final index = _invitations.indexWhere((i) => i.id == invitation.id);
    if (index != -1) {
      _invitations[index] = invitation;
    } else {
      _invitations.add(invitation);
    }
    notifyListeners();
  }

  Future<void> updateInvitation(Invitation updatedInvitation) async {
    // Update in Supabase
    try {
      await SupabaseService.client
          .from('event_invitations')
          .update(updatedInvitation.toSupabaseJson())
          .eq('id', updatedInvitation.id);
    } catch (e) {
      debugPrint('InvitationProvider: Error updating invitation in Supabase: $e');
    }

    final index = _invitations.indexWhere((invitation) => invitation.id == updatedInvitation.id);
    if (index != -1) {
      _invitations[index] = updatedInvitation;
      notifyListeners();
    }
  }

  void removeInvitation(String invitationId) {
    _invitations.removeWhere((invitation) => invitation.id == invitationId);
    notifyListeners();
  }

  // Bulk Invitation Operations
  void sendBulkInvitations(String eventId, List<String> guestEmails, {
    String? personalMessage,
    bool allowPlusOne = false,
    int maxPlusOnes = 0,
  }) {
    final event = getEventById(eventId);
    if (event == null) return;

    for (final email in guestEmails) {
      final invitation = Invitation(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}_${email.hashCode}',
        eventId: eventId,
        guestEmail: email,
        status: InvitationStatus.sent,
        invitationCode: _generateInvitationCode(),
        personalMessage: personalMessage,
        allowPlusOne: allowPlusOne,
        maxPlusOnes: maxPlusOnes,
        sentAt: DateTime.now(),
        plusOneNames: [],
        additionalData: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      addInvitation(invitation);
    }
  }

  // RSVP Operations
  Future<void> respondToInvitation(String invitationId, String response, {
    int numberOfGuests = 1,
    List<String> plusOneNames = const [],
    String? dietaryPreferences,
    String? seatingPreference,
    String? mealChoice,
    String? notes,
    Map<String, dynamic> additionalData = const {},
  }) async {
    final invitation = getInvitationById(invitationId);
    if (invitation == null) return;

    final status = response == 'accepted' ? InvitationStatus.accepted : InvitationStatus.declined;

    final updatedInvitation = invitation.copyWith(
      status: status,
      rsvpResponse: response,
      respondedAt: DateTime.now(),
      plusOneNames: plusOneNames,
      updatedAt: DateTime.now(),
      additionalData: {
        ...invitation.additionalData,
        ...additionalData,
        'numberOfGuests': numberOfGuests,
        'dietary_preferences': dietaryPreferences,
        'seating_preference': seatingPreference,
        'meal_choice': mealChoice,
        'notes': notes,
      },
    );

    // Update in Supabase
    try {
      await SupabaseService.client
          .from('event_invitations')
          .update(updatedInvitation.toSupabaseJson())
          .eq('id', updatedInvitation.id);

      // Force-fetch the latest record to guarantee sync
      final freshResponse = await SupabaseService.client
          .from('event_invitations')
          .select()
          .eq('id', updatedInvitation.id)
          .single();
      
      final freshInvitation = Invitation.fromSupabase(freshResponse);
      
      // Update local state
      final index = _invitations.indexWhere((i) => i.id == freshInvitation.id);
      if (index != -1) {
        _invitations[index] = freshInvitation;
      }
      
    } catch (e) {
      debugPrint('InvitationProvider: Error updating guest record: $e');
    }

    // Ensure guest record exists/is updated in Supabase (keep existing logic)
    try {
      // Check if guest record already exists
      final existingResponse = await SupabaseService.client
          .from('event_guests')
          .select('id')
          .eq('invitation_id', invitationId)
          .maybeSingle();
      
      final Map<String, dynamic> guestData = {
        'invitation_id': invitationId,
        'event_id': invitation.eventId,
        'name': invitation.guestName ?? 'Guest',
        'email': invitation.guestEmail,
        'phone': invitation.guestPhone,
        'is_attending': response == 'accepted',
        'number_of_guests': numberOfGuests,
        'dietary_preferences': dietaryPreferences,
        'seating_preference': seatingPreference,
        'meal_choice': mealChoice,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingResponse != null) {
        // Update
        await SupabaseService.client
            .from('event_guests')
            .update(guestData)
            .eq('id', existingResponse['id']);
      } else {
        // Insert
        guestData['id'] = const Uuid().v4();
        guestData['created_at'] = DateTime.now().toIso8601String();
        await SupabaseService.client
            .from('event_guests')
            .insert(guestData);
      }
    } catch (e) {
      debugPrint('InvitationProvider: Error updating guest record: $e');
    }
    notifyListeners();
  }

  // Invitation Tracking
  Future<void> markInvitationViewed(String invitationId) async {
    final invitation = getInvitationById(invitationId);
    if (invitation != null && invitation.viewedAt == null) {
      final updatedInvitation = invitation.copyWith(
        status: InvitationStatus.viewed,
        viewedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateInvitation(updatedInvitation);
    }
  }

  // Event CRUD Operations
  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  void addEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  void updateEvent(Event updatedEvent) {
    final index = _events.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  void removeEvent(String eventId) {
    _events.removeWhere((event) => event.id == eventId);
    // Also remove all invitations for this event
    _invitations.removeWhere((invitation) => invitation.eventId == eventId);
    notifyListeners();
  }

  // Analytics and Reporting
  Map<String, dynamic> getInvitationAnalytics(String eventId) {
    final eventInvitations = getInvitationsForEvent(eventId);

    final totalSent = eventInvitations.length;
    final viewed = eventInvitations.where((inv) => inv.viewedAt != null).length;
    final accepted = eventInvitations.where((inv) => inv.status == InvitationStatus.accepted).length;
    final declined = eventInvitations.where((inv) => inv.status == InvitationStatus.declined).length;
    final pending = eventInvitations.where((inv) =>
      inv.status == InvitationStatus.sent ||
      inv.status == InvitationStatus.pending ||
      inv.status == InvitationStatus.viewed
    ).length;

    final viewRate = totalSent > 0 ? (viewed / totalSent) * 100 : 0.0;
    final acceptanceRate = totalSent > 0 ? (accepted / totalSent) * 100 : 0.0;

    return {
      'totalSent': totalSent,
      'viewed': viewed,
      'accepted': accepted,
      'declined': declined,
      'pending': pending,
      'viewRate': viewRate,
      'acceptanceRate': acceptanceRate,
    };
  }

  Map<String, dynamic> getGuestAnalytics(String guestEmail) {
    final guestInvitations = getInvitationsForGuest(guestEmail);

    final totalInvitations = guestInvitations.length;
    final acceptedCount = guestInvitations.where((inv) => inv.status == InvitationStatus.accepted).length;
    final declinedCount = guestInvitations.where((inv) => inv.status == InvitationStatus.declined).length;

    return {
      'totalInvitations': totalInvitations,
      'acceptedCount': acceptedCount,
      'declinedCount': declinedCount,
      'responseRate': totalInvitations > 0 ? ((acceptedCount + declinedCount) / totalInvitations) * 100 : 0.0,
    };
  }

  // Utility Methods
  String generateInvitationCode([String prefix = 'EVT']) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = StringBuffer(prefix);
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = now.substring(now.length - 4); // Use last 4 digits of timestamp
    random.write(suffix);
    
    // Add 2 random chars
    final r = (DateTime.now().microsecondsSinceEpoch % chars.length);
    random.write(chars[r]);
    random.write(chars[(r + 7) % chars.length]);
    
    return random.toString();
  }

  Future<Invitation> getOrCreateGeneralInvitation(String eventId, String hostEmail) async {
    // Check if a general invitation already exists
    try {
      final response = await SupabaseService.client
          .from('event_invitations')
          .select()
          .eq('event_id', eventId)
          .eq('guest_email', 'general@invite.eventease')
          .maybeSingle();
      
      if (response != null) {
        return Invitation.fromSupabase(response);
      }
    } catch (e) {
      debugPrint('InvitationProvider: Error checking general invitation: $e');
    }

    // Create a new general invitation
    final invitation = Invitation(
      id: const Uuid().v4(),
      eventId: eventId,
      guestEmail: 'general@invite.eventease',
      guestName: 'Guest',
      status: InvitationStatus.sent,
      invitationCode: generateInvitationCode(),
      allowPlusOne: true,
      maxPlusOnes: 1,
      sentAt: DateTime.now(),
      plusOneNames: [],
      additionalData: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await addInvitation(invitation);
    return invitation;
  }

  // Reminder System
  List<Invitation> getUpcomingEvents(String guestEmail, {int daysAhead = 7}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    return getAcceptedInvitations(guestEmail)
        .where((invitation) {
          final event = getEventById(invitation.eventId);
          return event != null &&
                 event.date.isAfter(now) &&
                 event.date.isBefore(futureDate);
        })
        .toList()
      ..sort((a, b) {
        final eventA = getEventById(a.eventId)!;
        final eventB = getEventById(b.eventId)!;
        return eventA.date.compareTo(eventB.date);
      });
  }

  // Export/Import functionality (for backup/sharing)
  List<Map<String, dynamic>> exportInvitations(String eventId) {
    return getInvitationsForEvent(eventId)
        .map((invitation) => invitation.toJson())
        .toList();
  }

  void importInvitations(List<Map<String, dynamic>> invitationData) {
    for (final data in invitationData) {
      final invitation = Invitation.fromJson(data);
      // Check if invitation already exists
      if (getInvitationById(invitation.id) == null) {
        addInvitation(invitation);
      } else {
        updateInvitation(invitation);
      }
    }
  }

  // Initialize with sample data
  void initializeSampleData() {
    // Add sample event
    final sampleEvent = Event.sample();
    addEvent(sampleEvent);

    // Add sample invitations
    final sampleInvitation1 = Invitation.sample();
    final sampleInvitation2 = Invitation(
      id: 'inv_2',
      eventId: 'event_1',
      guestEmail: 'jane.smith@email.com',
      guestName: 'Jane Smith',
      guestPhone: '+60 13-456 7890',
      status: InvitationStatus.sent,
      invitationCode: 'XYZ789ABC',
      personalMessage: 'We can\'t wait to celebrate with you!',
      allowPlusOne: true,
      maxPlusOnes: 1,
      sentAt: DateTime.now().subtract(const Duration(days: 5)),
      plusOneNames: [],
      additionalData: {},
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    );

    addInvitation(sampleInvitation1);
    addInvitation(sampleInvitation2);
  }

  // Clear all data
  void clearAllData() {
    _invitations.clear();
    _events.clear();
    notifyListeners();
  }

}
