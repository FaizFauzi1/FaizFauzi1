import 'dart:io';
import 'package:flutter/material.dart';
import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/shared/models/gift_registry.dart';
import 'package:eventease/shared/models/photo_album.dart';
import 'package:eventease/features/event/data/models/guest_chat_message.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class GuestProvider with ChangeNotifier {
  final List<Guest> _guests = [];
  final List<Invitation> _invitations = [];
  final List<Event> _events = [];
  final List<PhotoAlbum> _photoAlbums = [];
  final List<GuestChatMessage> _chatMessages = [];
  bool _isLoading = false;

  // Getters
  List<Guest> get guests => List.unmodifiable(_guests);
  List<Invitation> get invitations => List.unmodifiable(_invitations);
  List<Event> get events => List.unmodifiable(_events);
  List<PhotoAlbum> get photoAlbums => List.unmodifiable(_photoAlbums);
  List<GuestChatMessage> get chatMessages => List.unmodifiable(_chatMessages);
  bool get isLoading => _isLoading;

  // Load Guests from Supabase
  Future<void> loadGuestsForEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('event_guests')
          .select()
          .eq('event_id', eventId);
      
      final loadedGuests = (response as List).map((json) => Guest.fromSupabase(json)).toList();
      
      _guests.removeWhere((g) => g.eventId == eventId);
      _guests.addAll(loadedGuests);
    } catch (e) {
      debugPrint('GuestProvider: Error loading guests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Photo Albums and Photos from Supabase
  Future<void> loadPhotoAlbumsForEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('event_photo_albums')
          .select('*, event_photos(*)')
          .eq('event_id', eventId);
      
      final loadedAlbums = (response as List).map((json) => PhotoAlbum.fromSupabase(json)).toList();
      
      _photoAlbums.removeWhere((a) => a.eventId == eventId);
      _photoAlbums.addAll(loadedAlbums);
    } catch (e) {
      debugPrint('GuestProvider: Error loading photo albums: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Photo Album in Supabase
  Future<void> createPhotoAlbum(PhotoAlbum album) async {
    try {
      await SupabaseService.client
          .from('event_photo_albums')
          .insert(album.toSupabaseJson());
      
      _photoAlbums.add(album);
      notifyListeners();
    } catch (e) {
      debugPrint('GuestProvider: Error creating photo album: $e');
      rethrow;
    }
  }

  // Upload Photo to Supabase Storage and Database
  Future<void> uploadPhoto({
    required String albumId,
    required File file,
    required String guestName,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.jpg';
      final path = '$albumId/$fileName';

      // 1. Upload to Storage
      final bytes = await file.readAsBytes();
      await SupabaseService.uploadFile(
        bucket: 'event-photos',
        path: path,
        fileBytes: bytes,
        contentType: 'image/jpeg',
      );

      // 2. Get Public URL
      final publicUrl = SupabaseService.getPublicUrl(
        bucket: 'event-photos',
        path: path,
      );

      // 3. Save to Database
      final photoData = {
        'id': const Uuid().v4(),
        'album_id': albumId,
        'url': publicUrl,
        'uploaded_by': guestName,
        'uploaded_at': DateTime.now().toIso8601String(),
        'is_approved': true, // Default to true for now, can be updated by host
      };

      await SupabaseService.client
          .from('event_photos')
          .insert(photoData);

      // 4. Update local state
      final index = _photoAlbums.indexWhere((a) => a.id == albumId);
      if (index != -1) {
        final newPhoto = Photo.fromSupabase(photoData);
        final album = _photoAlbums[index];
        final updatedPhotos = List<Photo>.from(album.photos)..add(newPhoto);
        _photoAlbums[index] = album.copyWith(photos: updatedPhotos);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('GuestProvider: Error uploading photo: $e');
      rethrow;
    }
  }

  // Guest Management
  Guest? getGuestById(String guestId) {
    try {
      return _guests.firstWhere((guest) => guest.id == guestId);
    } catch (e) {
      return null;
    }
  }

  List<Guest> getGuestsForEvent(String eventId) {
    return _guests.where((guest) => guest.eventId == eventId).toList();
  }

  List<Guest> getGuestsForInvitation(String invitationId) {
    return _guests.where((guest) => guest.invitationId == invitationId).toList();
  }

  Future<void> addGuest(Guest guest) async {
    try {
      await SupabaseService.client
          .from('event_guests')
          .insert(guest.toSupabaseJson());
      
      _guests.add(guest);
      notifyListeners();
    } catch (e) {
      debugPrint('GuestProvider: Error adding guest: $e');
    }
  }

  Future<void> updateGuest(Guest updatedGuest) async {
    try {
      await SupabaseService.client
          .from('event_guests')
          .update(updatedGuest.toSupabaseJson())
          .eq('id', updatedGuest.id);

      final index = _guests.indexWhere((guest) => guest.id == updatedGuest.id);
      if (index != -1) {
        _guests[index] = updatedGuest;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('GuestProvider: Error updating guest: $e');
    }
  }

  Future<void> removeGuest(String guestId) async {
    try {
      await SupabaseService.client
          .from('event_guests')
          .delete()
          .eq('id', guestId);

      _guests.removeWhere((guest) => guest.id == guestId);
      notifyListeners();
    } catch (e) {
      debugPrint('GuestProvider: Error removing guest: $e');
    }
  }

  // Invitation Management
  Invitation? getInvitationById(String invitationId) {
    try {
      return _invitations.firstWhere((invitation) => invitation.id == invitationId);
    } catch (e) {
      return null;
    }
  }

  Invitation? getInvitationByCode(String invitationCode) {
    try {
      return _invitations.firstWhere((invitation) => invitation.invitationCode == invitationCode);
    } catch (e) {
      return null;
    }
  }

  void addInvitation(Invitation invitation) {
    _invitations.add(invitation);
    notifyListeners();
  }

  // Event Management
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

  // Photo Album Management
  PhotoAlbum? getPhotoAlbumForEvent(String eventId) {
    try {
      return _photoAlbums.firstWhere((album) => album.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  void addPhotoAlbum(PhotoAlbum album) {
    _photoAlbums.add(album);
    notifyListeners();
  }

  void updatePhotoAlbum(PhotoAlbum updatedAlbum) {
    final index = _photoAlbums.indexWhere((album) => album.id == updatedAlbum.id);
    if (index != -1) {
      _photoAlbums[index] = updatedAlbum;
      notifyListeners();
    }
  }

  void addPhotoToAlbum(String albumId, Photo photo) {
    final index = _photoAlbums.indexWhere((a) => a.id == albumId);
    if (index != -1) {
      final album = _photoAlbums[index];
      final updatedPhotos = List<Photo>.from(album.photos)..add(photo);
      final updatedAlbum = album.copyWith(
        photos: updatedPhotos,
        updatedAt: DateTime.now(),
      );
      _photoAlbums[index] = updatedAlbum;
      notifyListeners();
    }
  }

  void approvePhoto(String albumId, String photoId) {
    final albumIndex = _photoAlbums.indexWhere((a) => a.id == albumId);
    if (albumIndex != -1) {
      final album = _photoAlbums[albumIndex];
      final photoIndex = album.photos.indexWhere((photo) => photo.id == photoId);
      if (photoIndex != -1) {
        final photo = album.photos[photoIndex];
        final updatedPhoto = photo.copyWith(isApproved: true);
        final updatedPhotos = List<Photo>.from(album.photos);
        updatedPhotos[photoIndex] = updatedPhoto;

        final updatedAlbum = album.copyWith(photos: updatedPhotos);
        _photoAlbums[albumIndex] = updatedAlbum;
        notifyListeners();
      }
    }
  }

  // Chat Management
  List<GuestChatMessage> getChatMessagesForEvent(String eventId) {
    return _chatMessages
        .where((message) => message.eventId == eventId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void addChatMessage(GuestChatMessage message) {
    _chatMessages.add(message);
    notifyListeners();
  }

  // Clear all data
  void clearAllData() {
    _guests.clear();
    _invitations.clear();
    _events.clear();
    _photoAlbums.clear();
    _chatMessages.clear();
    notifyListeners();
  }
}
