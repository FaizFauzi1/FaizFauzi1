import 'package:flutter/material.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/features/event/data/models/event_collaborator.dart';
import 'package:eventease/shared/models/gift_registry.dart';
import 'package:eventease/shared/models/photo_album.dart';
import 'package:eventease/features/event/data/models/guest_chat_message.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/shared/models/planner_models.dart';
import 'package:eventease/features/event/data/models/event_template.dart';
import 'package:uuid/uuid.dart';

class EventProvider with ChangeNotifier {
  final List<Event> _events = [];
  final List<Invitation> _invitations = [];
  final List<Guest> _guests = [];
  final List<GiftRegistry> _giftRegistries = [];
  final List<PhotoAlbum> _photoAlbums = [];
  final List<GuestChatMessage> _chatMessages = [];
  final List<ChecklistItem> _checklists = [];
  final List<TimelineEvent> _timelineEvents = [];
  final List<EventCollaborator> _collaborators = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Event> get events => List.unmodifiable(_events);
  List<Invitation> get invitations => List.unmodifiable(_invitations);
  List<Guest> get guests => List.unmodifiable(_guests);
  List<GiftRegistry> get giftRegistries => List.unmodifiable(_giftRegistries);
  List<PhotoAlbum> get photoAlbums => List.unmodifiable(_photoAlbums);
  List<GuestChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  List<ChecklistItem> get checklists => List.unmodifiable(_checklists);
  List<TimelineEvent> get timelineEvents => List.unmodifiable(_timelineEvents);
  List<EventCollaborator> get collaborators => List.unmodifiable(_collaborators);
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Private Helper Methods
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = StringBuffer();
    for (var i = 0; i < 8; i++) {
      random.write(chars[DateTime.now().millisecondsSinceEpoch % chars.length]);
    }
    return random.toString();
  }

  double _calculateEngagementScore(String eventId) {
    final invitations = getInvitationsForEvent(eventId);
    final guests = getGuestsForEvent(eventId);
    final chatMessages = getChatMessagesForEvent(eventId);

    if (invitations.isEmpty) return 0.0;

    final responseRate = invitations.where((inv) => inv.respondedAt != null).length / invitations.length;
    final attendanceRate = guests.where((guest) => guest.isAttending).length / invitations.length;
    final chatActivity = chatMessages.length > 0 ? (chatMessages.length / invitations.length) * 10 : 0;

    return ((responseRate * 0.3) + (attendanceRate * 0.5) + (chatActivity * 0.2)).clamp(0.0, 1.0) * 100;
  }

  // Event CRUD Operations
  Future<void> loadEvents(String hostId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.select(
        table: 'events',
        filters: {'host_id': hostId},
      );
      
      _events.clear();
      _events.addAll(data.map((json) => Event.fromSupabase(json)).toList());
      
      // Sort by date descending
      _events.sort((a, b) => b.date.compareTo(a.date));
      
    } catch (e) {
      print('Error loading events: $e');
      _error = 'Failed to load events';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Event?> getEventByShortId(String shortId) async {
    try {
      // 1. Try RPC function for short-ID prefix matching (cast uuid to text in PostgreSQL)
      try {
        final data = await SupabaseService.client
            .rpc('get_event_by_short_id', params: {'prefix': shortId})
            .select()
            .limit(1)
            .maybeSingle();
        if (data != null) {
          return Event.fromSupabase(data);
        }
      } catch (rpcError) {
        debugPrint('RPC get_event_by_short_id failed (likely not created yet), falling back to exact UUID match: $rpcError');
        
        // 2. Fallback: If it's a full UUID (36 chars), do a direct eq match on ID
        if (shortId.length == 36) {
          final data = await SupabaseService.client
              .from('events')
              .select()
              .eq('id', shortId)
              .maybeSingle();
          if (data != null) {
            return Event.fromSupabase(data);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting event by short ID: $e');
      return null;
    }
  }

  // Load all details for a specific event
  Future<void> loadEventDetails(String eventId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 1. Load Invitations
      final invitationsData = await SupabaseService.select(
        table: 'event_invitations',
        filters: {'event_id': eventId},
      );
      _invitations.removeWhere((i) => i.eventId == eventId);
      _invitations.addAll(invitationsData.map((json) => Invitation.fromSupabase(json)).toList());
      
      // 2. Load Guests (if invitations exist)
      if (invitationsData.isNotEmpty) {
        final invitationIds = invitationsData.map((i) => i['id']).toList();
        // Batch loading guests for all invitations to avoid loop of await calls
        final guestsData = await SupabaseService.client
            .from('event_guests')
            .select()
            .inFilter('invitation_id', invitationIds);
        
        for (var invId in invitationIds) {
          _guests.removeWhere((g) => g.invitationId == invId);
        }
        _guests.addAll(guestsData.map((json) => Guest.fromSupabase(json)).toList());
      }

      // 3. Load Checklists
      final checklistData = await SupabaseService.select(
        table: 'event_checklists',
        filters: {'event_id': eventId},
      );
      _checklists.removeWhere((c) => c.eventId == eventId);
      _checklists.addAll(checklistData.map((json) => ChecklistItem.fromSupabase(json)).toList());

      // 4. Load Timeline
      final timelineData = await SupabaseService.select(
        table: 'event_timeline',
        filters: {'event_id': eventId},
      );
      _timelineEvents.removeWhere((t) => t.eventId == eventId);
      _timelineEvents.addAll(timelineData.map((json) => TimelineEvent.fromSupabase(json)).toList());
      _timelineEvents.sort((a, b) => a.date.compareTo(b.date));

      // 5. Load Registries
      final registriesData = await SupabaseService.select(
        table: 'gift_registries',
        columns: '*, gift_registry_items(*)',
        filters: {'event_id': eventId},
      );
      _giftRegistries.removeWhere((r) => r.eventId == eventId);
      _giftRegistries.addAll(registriesData.map((json) => GiftRegistry.fromSupabase(json)).toList());

      // 6. Load Albums
      final albumsData = await SupabaseService.select(
        table: 'event_photo_albums',
        columns: '*, event_photos(*)',
        filters: {'event_id': eventId},
      );
      _photoAlbums.removeWhere((a) => a.eventId == eventId);
      _photoAlbums.addAll(albumsData.map((json) => PhotoAlbum.fromSupabase(json)).toList());

      // 7. Load Chat Messages
      final messagesData = await SupabaseService.select(
        table: 'event_guest_chat_messages',
        filters: {'event_id': eventId},
      );
      _chatMessages.removeWhere((m) => m.eventId == eventId);
      _chatMessages.addAll(messagesData.map((json) => GuestChatMessage.fromSupabase(json)).toList());
      _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    } catch (e) {
      debugPrint('EventProvider: Error loading event details: $e');
      _error = 'Failed to load event details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  List<Event> getEventsByHost(String hostId) {
    return _events.where((event) => event.hostId == hostId).toList();
  }

  List<Event> getUpcomingEvents({int daysAhead = 30}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    return _events
        .where((event) =>
          event.date.isAfter(now) &&
          event.date.isBefore(futureDate) &&
          event.status != EventStatus.cancelled
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Event> getPastEvents() {
    final now = DateTime.now();
    return _events
        .where((event) =>
          event.date.isBefore(now) &&
          event.status != EventStatus.cancelled
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addEvent(Event event, {EventTemplate? template}) async {
    try {
      final json = event.toSupabaseJson();
      print('DEBUG: Adding event to Supabase: $json');
      
      final response = await SupabaseService.insert(
        table: 'events',
        data: json,
      );
      
      print('DEBUG: Supabase response: $response');
      
      if (response.isNotEmpty) {
        final newEvent = Event.fromSupabase(response.first);
        _events.add(newEvent);
        
        // Initialize template tools if provided
        if (template != null && template.type != EventTemplateType.blank) {
          await _initializeTemplateTools(newEvent, template);
        }

        notifyListeners();
      } else {
        throw Exception('Failed to insert event into database - empty response');
      }
    } catch (e) {
      print('Error adding event: $e');
      if (e is Map && e.containsKey('message')) {
        _error = 'Failed to add event: ${e['message']}';
      } else {
        _error = 'Failed to add event: ${e.toString()}';
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> applyTemplate(Event event, EventTemplate template, {bool clearExisting = true}) async {
    print('DEBUG: Applying template: ${template.title}, clearExisting: $clearExisting');
    try {
      if (clearExisting) {
        // Clear existing checklists
        await SupabaseService.client.from('event_checklists').delete().eq('event_id', event.id);
        _checklists.removeWhere((c) => c.eventId == event.id);
        
        // Clear existing budgets and categories
        final budget = await SupabaseService.client.from('budgets').select('id').eq('event_id', event.id).maybeSingle();
        if (budget != null) {
          final budgetId = budget['id'];
          await SupabaseService.client.from('budget_categories').delete().eq('budget_id', budgetId);
          await SupabaseService.client.from('budgets').delete().eq('id', budgetId);
        }

        // Clear existing timeline events
        await SupabaseService.client.from('event_timeline').delete().eq('event_id', event.id);
        _timelineEvents.removeWhere((t) => t.eventId == event.id);
      }
      
      await _initializeTemplateTools(event, template);
      notifyListeners();
    } catch (e) {
      print('DEBUG: Failed to apply template: $e');
    }
  }

  Future<void> _initializeTemplateTools(Event event, EventTemplate template) async {
    print('DEBUG: Initializing event tools for template: ${template.title}');
    try {
      // 1. Initialize Checklists
      for (final itemTitle in template.defaultChecklistItems) {
        final item = ChecklistItem(
          id: const Uuid().v4(),
          eventId: event.id,
          userId: event.hostId,
          title: itemTitle,
          category: 'Planning', // Default category for templates
          createdAt: DateTime.now(),
        );
        await SupabaseService.insert(
          table: 'event_checklists',
          data: item.toSupabaseJson(),
        );
        _checklists.add(item);
      }
      
      // 2. Initialize Budgets
      if (template.defaultBudgetCategories.isNotEmpty) {
        final budgetId = const Uuid().v4();
        final budgetData = {
          'id': budgetId,
          'event_id': event.id,
          'customer_id': event.hostId,
          'total_budget': 10000.0, // Default budget
          'allocated_budget': 0.0,
          'spent_budget': 0.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await SupabaseService.insert(
          table: 'budgets',
          data: budgetData,
        );
        
        for (final cat in template.defaultBudgetCategories) {
          // Generate a fresh UUID for every category instance from the template
          final uniqueCategory = cat.copyWith(id: const Uuid().v4());
          await SupabaseService.insert(
            table: 'budget_categories',
            data: uniqueCategory.toSupabaseJson(budgetId),
          );
        }
      }

      // 3. Initialize Timeline Events
      if (template.defaultTimelineEvents.isNotEmpty) {
        final eventDate = event.date;
        for (final tEvent in template.defaultTimelineEvents) {
          final targetDate = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            10, 0,
          ).add(Duration(days: tEvent.offsetDays));

          final timelineItem = TimelineEvent(
            id: const Uuid().v4(),
            eventId: event.id,
            userId: event.hostId,
            title: tEvent.title,
            category: tEvent.category,
            date: targetDate,
            notes: tEvent.notes,
            createdAt: DateTime.now(),
          );
          await SupabaseService.insert(
            table: 'event_timeline',
            data: timelineItem.toSupabaseJson(),
          );
          _timelineEvents.add(timelineItem);
        }
        _timelineEvents.sort((a, b) => a.date.compareTo(b.date));
      }

      // 3. Initialize Default Photo Album if Photo Sharing is enabled
      final guestFeatures = event.additionalInfo?['guestFeatures'] as Map<String, dynamic>?;
      if (guestFeatures != null && guestFeatures['photoSharing'] == true) {
        final defaultAlbum = PhotoAlbum(
          id: const Uuid().v4(),
          eventId: event.id,
          title: 'Event Gallery',
          description: 'Share your favorite moments from ${event.title}!',
          photos: [],
          allowGuestUploads: true,
          requireApproval: false,
          maxPhotosPerGuest: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await createPhotoAlbumForEvent(event.id, defaultAlbum);
      }
    } catch (e) {
      print('DEBUG: Failed to initialize template tools: $e');
    }
  }

  Future<void> updateEvent(Event updatedEvent) async {
    try {
      await SupabaseService.update(
        table: 'events',
        data: updatedEvent.toSupabaseJson(),
        column: 'id',
        value: updatedEvent.id,
      );
      
      final index = _events.indexWhere((event) => event.id == updatedEvent.id);
      if (index != -1) {
        _events[index] = updatedEvent;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating event: $e');
      // Optimistic update rollback or error message
    }
  }

  Future<void> removeEvent(String eventId) async {
    try {
      await SupabaseService.delete(
        table: 'events',
        column: 'id',
        value: eventId,
      );
      
      _events.removeWhere((event) => event.id == eventId);
      // Clean up related local lists
      final invitationIds = _invitations.where((inv) => inv.eventId == eventId).map((inv) => inv.id).toSet();
      _invitations.removeWhere((invitation) => invitation.eventId == eventId);
      _guests.removeWhere((guest) => invitationIds.contains(guest.invitationId));
      _giftRegistries.removeWhere((registry) => registry.eventId == eventId);
      _photoAlbums.removeWhere((album) => album.eventId == eventId);
      _chatMessages.removeWhere((message) => message.eventId == eventId);
      
      notifyListeners();
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  // Invitation Management
  List<Invitation> getInvitationsForEvent(String eventId) {
    return _invitations.where((invitation) => invitation.eventId == eventId).toList();
  }

  Future<void> addInvitationToEvent(Invitation invitation) async {
    try {
      await SupabaseService.insert(
        table: 'event_invitations',
        data: invitation.toSupabaseJson(),
      );
      _invitations.add(invitation);
      notifyListeners();
    } catch (e) {
      debugPrint('EventProvider: Error adding invitation: $e');
    }
  }

  Future<Event?> fetchEventById(String id) async {
    // Check local first
    final local = getEventById(id);
    if (local != null) return local;

    try {
      final response = await SupabaseService.client
          .from('events')
          .select()
          .eq('id', id)
          .single();
      
      if (response != null) {
        final event = Event.fromSupabase(response);
        _events.add(event);
        notifyListeners();
        return event;
      }
    } catch (e) {
      debugPrint('EventProvider: Error fetching event by ID $id: $e');
    }
    return null;
  }

  Future<void> sendInvitationsForEvent(String eventId, List<String> guestEmails, {
    String? personalMessage,
    bool allowPlusOne = false,
    int maxPlusOnes = 0,
  }) async {
    final event = getEventById(eventId);
    if (event == null) return;

    for (final email in guestEmails) {
      final invitation = Invitation(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}_${email.hashCode}', // Will be ignored/overwritten by DB usually, or used if we pass it
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
      
      // In a real app, we would send email here (via Edge Function or backend)
      await addInvitationToEvent(invitation);
    }
  }

  // Guest Management
  List<Guest> getGuestsForEvent(String eventId) {
    final invitationIds = getInvitationsForEvent(eventId).map((inv) => inv.id).toSet();
    return _guests.where((guest) => invitationIds.contains(guest.invitationId)).toList();
  }

  Future<void> addGuestToEvent(Guest guest) async {
    try {
      await SupabaseService.insert(
        table: 'event_guests',
        data: guest.toSupabaseJson(),
      );
      _guests.add(guest);
      notifyListeners();
    } catch (e) {
       print('Error adding guest: $e');
    }
  }

  // Gift Registry Management
  GiftRegistry? getGiftRegistryForEvent(String eventId) {
    try {
      return _giftRegistries.firstWhere((registry) => registry.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  Future<void> createGiftRegistryForEvent(String eventId, GiftRegistry registry) async {
    try {
      // Insert registry
      final response = await SupabaseService.insert(
        table: 'gift_registries',
        data: registry.toSupabaseJson(),
      );
      
      // Items need to be inserted specifically
      for(var item in registry.items) {
        await SupabaseService.insert(
          table: 'gift_registry_items',
          data: item.toSupabaseJson(registry.id),
        );
      }
      
      _giftRegistries.add(registry);
      notifyListeners();
    } catch (e) {
        print('Error creating registry: $e');
    }
  }

  Future<void> updateGiftRegistryForEvent(GiftRegistry updatedRegistry) async {
     try {
       await SupabaseService.update(
        table: 'gift_registries',
        data: updatedRegistry.toSupabaseJson(),
        column: 'id',
        value: updatedRegistry.id,
      );
       // Updating items is complex (add/remove/update). 
       // For MVP, simplistic update:
       final index = _giftRegistries.indexWhere((registry) => registry.id == updatedRegistry.id);
      if (index != -1) {
        _giftRegistries[index] = updatedRegistry;
        notifyListeners();
      }
     } catch (e) {
        print('Error updating registry: $e');
     }
  }

  // Photo Album Management
  PhotoAlbum? getPhotoAlbumForEvent(String eventId) {
    try {
      return _photoAlbums.firstWhere((album) => album.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  Future<void> createPhotoAlbumForEvent(String eventId, PhotoAlbum album) async {
    try {
      await SupabaseService.insert(
        table: 'event_photo_albums',
        data: album.toSupabaseJson(),
      );
      // Photos would be empty initially typically
      _photoAlbums.add(album);
      notifyListeners();
    } catch (e) {
      print('Error creating album: $e');
    }
  }
  
  // Method to add photo to album
  Future<void> addPhotoToAlbum(String albumId, Photo photo) async {
    try {
      await SupabaseService.insert(
        table: 'event_photos',
        data: photo.toSupabaseJson(),
      );
      
      // Update local state
      final index = _photoAlbums.indexWhere((a) => a.id == albumId);
      if (index != -1) {
        final album = _photoAlbums[index];
        final updatedPhotos = List<Photo>.from(album.photos)..add(photo);
        _photoAlbums[index] = album.copyWith(photos: updatedPhotos);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding photo: $e');
    }
  }

  void updatePhotoAlbumForEvent(PhotoAlbum updatedAlbum) {
    // Assuming metadata update
     final index = _photoAlbums.indexWhere((album) => album.id == updatedAlbum.id);
    if (index != -1) {
      _photoAlbums[index] = updatedAlbum;
      notifyListeners();
    }
    // Sync to DB
    SupabaseService.update(
        table: 'event_photo_albums',
        data: updatedAlbum.toSupabaseJson(),
        column: 'id',
        value: updatedAlbum.id,
      );
  }

  // Chat Management
  List<GuestChatMessage> getChatMessagesForEvent(String eventId) {
    return _chatMessages
        .where((message) => message.eventId == eventId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> addChatMessageToEvent(GuestChatMessage message) async {
    try {
      await SupabaseService.insert(
        table: 'event_guest_chat_messages',
        data: message.toSupabaseJson(),
      );
      _chatMessages.add(message);
      notifyListeners();
    } catch (e) {
      print('Error adding message: $e');
    }
  }

  // Analytics and Reporting
  Map<String, dynamic> getEventAnalytics(String eventId) {
    final event = getEventById(eventId);
    if (event == null) return {};

    final eventInvitations = getInvitationsForEvent(eventId);
    final eventGuests = getGuestsForEvent(eventId);
    final eventChatMessages = getChatMessagesForEvent(eventId);

    final totalInvitations = eventInvitations.length;
    final acceptedInvitations = eventInvitations.where((inv) => inv.status == InvitationStatus.accepted).length;
    final declinedInvitations = eventInvitations.where((inv) => inv.status == InvitationStatus.declined).length;
    final pendingInvitations = eventInvitations.where((inv) =>
      inv.status == InvitationStatus.sent ||
      inv.status == InvitationStatus.pending ||
      inv.status == InvitationStatus.viewed
    ).length;

    final attendingGuests = eventGuests.where((guest) => guest.isAttending).length;
    final totalExpectedGuests = eventGuests.fold<int>(0, (sum, guest) => sum + guest.numberOfGuests);

    final giftRegistry = getGiftRegistryForEvent(eventId);
    final totalRegistryItems = giftRegistry?.items.length ?? 0;
    final purchasedItems = giftRegistry?.items.where((item) => item.isPurchased).length ?? 0;
    
    final photoAlbum = getPhotoAlbumForEvent(eventId);
    final totalPhotos = photoAlbum?.photos.length ?? 0;
    final approvedPhotos = photoAlbum?.photos.where((photo) => photo.isApproved).length ?? 0;

    return {
      'eventId': eventId,
      'eventTitle': event.title,
      'eventDate': event.date,
      'eventStatus': event.status,
      'totalInvitations': totalInvitations,
      'acceptedInvitations': acceptedInvitations,
      'declinedInvitations': declinedInvitations,
      'pendingInvitations': pendingInvitations,
      'attendingGuests': attendingGuests,
      'totalExpectedGuests': totalExpectedGuests,
      'acceptanceRate': totalInvitations > 0 ? (acceptedInvitations / totalInvitations) * 100 : 0.0,
      'totalRegistryItems': totalRegistryItems,
      'purchasedRegistryItems': purchasedItems,
      'registryPurchaseRate': totalRegistryItems > 0 ? (purchasedItems / totalRegistryItems) * 100 : 0.0,
      'totalPhotos': totalPhotos,
      'approvedPhotos': approvedPhotos,
      'totalChatMessages': eventChatMessages.length,
      'guestEngagementScore': _calculateEngagementScore(eventId),
    };
  }

  // Event Status Management
  void updateEventStatus(String eventId, EventStatus newStatus) {
    final event = getEventById(eventId);
    if (event != null) {
      final updatedEvent = event.copyWith(status: newStatus, updatedAt: DateTime.now());
      updateEvent(updatedEvent);
    }
  }

  // Bulk Operations
  void duplicateEvent(String originalEventId, DateTime newDate) {
    final originalEvent = getEventById(originalEventId);
    if (originalEvent == null) return;
    
    // We generate a new ID here, but Supabase will generate one if we don't pass it.
    // However, the duplicate logic implies creating a NEW event on backend.
    
    final duplicatedEvent = Event(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      title: '${originalEvent.title} (Copy)',
      description: originalEvent.description,
      type: originalEvent.type,
      date: newDate,
      startTime: originalEvent.startTime,
      endTime: originalEvent.endTime,
      venue: originalEvent.venue,
      hostId: originalEvent.hostId,
      hostName: originalEvent.hostName,
      hostEmail: originalEvent.hostEmail,
      hostPhone: originalEvent.hostPhone,
      hostProfileImage: originalEvent.hostProfileImage,
      status: EventStatus.draft,
      theme: originalEvent.theme,
      dressCode: originalEvent.dressCode,
      maxGuests: originalEvent.maxGuests,
      isPublic: originalEvent.isPublic,
      invitationMessage: originalEvent.invitationMessage,
      coverImage: originalEvent.coverImage,
      tags: originalEvent.tags,
      additionalInfo: originalEvent.additionalInfo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    addEvent(duplicatedEvent);
  }

  // Utility Methods
  // Search and Filter (Operates on loaded events)
  List<Event> searchEvents(String query, {String? hostId}) {
    final baseEvents = hostId != null ? getEventsByHost(hostId) : _events;

    return baseEvents.where((event) =>
      event.title.toLowerCase().contains(query.toLowerCase()) ||
      event.description.toLowerCase().contains(query.toLowerCase()) ||
      event.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }

  List<Event> filterEventsByType(EventType type, {String? hostId}) {
    final baseEvents = hostId != null ? getEventsByHost(hostId) : _events;
    return baseEvents.where((event) => event.type == type).toList();
  }

  List<Event> filterEventsByStatus(EventStatus status, {String? hostId}) {
    final baseEvents = hostId != null ? getEventsByHost(hostId) : _events;
    return baseEvents.where((event) => event.status == status).toList();
  }

  // Initialize with sample data (Legacy/Fallback)
  void initializeSampleData() {
    // Kept for compatibility but should be replaced by loadEvents() in init
    if (_events.isEmpty) {
        // Maybe fetch from Supabase?
        // For now, do nothing or user might be confused seeing sample data when logged in
    }
  }

  // Checklist Persistence
  List<ChecklistItem> getChecklistForEvent(String eventId) {
    return _checklists.where((c) => c.eventId == eventId).toList();
  }

  Future<void> addChecklistItem(ChecklistItem item) async {
    try {
      await SupabaseService.insert(
        table: 'event_checklists',
        data: item.toSupabaseJson(),
      );
      _checklists.add(item);
      notifyListeners();
    } catch (e) {
      print('Error adding checklist item: $e');
    }
  }

  Future<void> updateChecklistItem(ChecklistItem item) async {
    try {
      await SupabaseService.update(
        table: 'event_checklists',
        data: item.toSupabaseJson(),
        column: 'id',
        value: item.id,
      );
      final index = _checklists.indexWhere((c) => c.id == item.id);
      if (index != -1) {
        _checklists[index] = item;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating checklist item: $e');
    }
  }

  Future<void> deleteChecklistItem(String id) async {
    try {
      await SupabaseService.delete(
        table: 'event_checklists',
        column: 'id',
        value: id,
      );
      _checklists.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting checklist item: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // Collaboration Management
  // ─────────────────────────────────────────────────────────
  List<EventCollaborator> getCollaboratorsForEvent(String eventId) {
    return _collaborators.where((c) => c.eventId == eventId).toList();
  }

  Future<void> loadCollaborators(String eventId) async {
    try {
      final data = await SupabaseService.select(
        table: 'event_collaborators',
        filters: {'event_id': eventId},
      );
      
      _collaborators.removeWhere((c) => c.eventId == eventId);
      _collaborators.addAll(data.map((json) {
        return EventCollaborator.fromJson({
          'id': json['id'],
          'eventId': json['event_id'],
          'userId': json['user_id'],
          'email': json['email'],
          'role': json['role'],
          'status': json['status'],
          'inviteCode': json['invite_code'],
          'createdAt': json['created_at'],
          'updatedAt': json['updated_at'],
        });
      }).toList());
      
      notifyListeners();
    } catch (e) {
      print('Error loading collaborators: $e');
    }
  }

  Future<void> addCollaborator(EventCollaborator collabo) async {
    try {
      final json = {
        'id': collabo.id,
        'event_id': collabo.eventId,
        'user_id': collabo.userId,
        'email': collabo.email,
        'role': collabo.role.name,
        'status': collabo.status.name,
        'invite_code': collabo.inviteCode,
        'created_at': collabo.createdAt.toIso8601String(),
        'updated_at': collabo.updatedAt.toIso8601String(),
      };
      
      await SupabaseService.insert(
        table: 'event_collaborators',
        data: json,
      );
      
      _collaborators.add(collabo);
      notifyListeners();
    } catch (e) {
      print('Error adding collaborator: $e');
      rethrow;
    }
  }

  Future<void> updateCollaborator(EventCollaborator collabo) async {
    try {
      final json = {
        'role': collabo.role.name,
        'status': collabo.status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await SupabaseService.update(
        table: 'event_collaborators',
        data: json,
        column: 'id',
        value: collabo.id,
      );
      
      final index = _collaborators.indexWhere((c) => c.id == collabo.id);
      if (index != -1) {
        _collaborators[index] = collabo;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating collaborator: $e');
      rethrow;
    }
  }

  Future<void> removeCollaborator(String id) async {
    try {
      await SupabaseService.delete(
        table: 'event_collaborators',
        column: 'id',
        value: id,
      );
      _collaborators.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      print('Error removing collaborator: $e');
      rethrow;
    }
  }

  // Timeline Persistence
  List<TimelineEvent> getTimelineForEvent(String eventId) {
    return _timelineEvents.where((t) => t.eventId == eventId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> addTimelineEvent(TimelineEvent item) async {
    try {
      await SupabaseService.insert(
        table: 'event_timeline',
        data: item.toSupabaseJson(),
      );
      _timelineEvents.add(item);
      _timelineEvents.sort((a, b) => a.date.compareTo(b.date));
      notifyListeners();
    } catch (e) {
      print('Error adding timeline event: $e');
    }
  }

  Future<void> updateTimelineEvent(TimelineEvent item) async {
    try {
      await SupabaseService.update(
        table: 'event_timeline',
        data: item.toSupabaseJson(),
        column: 'id',
        value: item.id,
      );
      final index = _timelineEvents.indexWhere((t) => t.id == item.id);
      if (index != -1) {
        _timelineEvents[index] = item;
        _timelineEvents.sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }
    } catch (e) {
      print('Error updating timeline event: $e');
    }
  }

  Future<void> deleteTimelineEvent(String id) async {
    try {
      await SupabaseService.delete(
        table: 'event_timeline',
        column: 'id',
        value: id,
      );
      _timelineEvents.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting timeline event: $e');
    }
  }

  // Clear all data
  void clearAllData() {
    _events.clear();
    _invitations.clear();
    _guests.clear();
    _giftRegistries.clear();
    _photoAlbums.clear();
    _chatMessages.clear();
    _checklists.clear();
    _timelineEvents.clear();
    notifyListeners();
  }
}
