import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/features/guest/data/providers/guest_provider.dart';
import 'package:eventease/features/guest/data/models/event_wish.dart';
import 'package:eventease/features/guest/data/providers/event_wish_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:eventease/core/utils/guest_routes.dart';
import 'package:eventease/core/utils/app_theme.dart';

class RSVPScreen extends StatefulWidget {
  const RSVPScreen({super.key});

  @override
  State<RSVPScreen> createState() => _RSVPScreenState();
}

class _RSVPScreenState extends State<RSVPScreen> {
  Invitation? _invitation;
  Event? _event;
  Guest? _guest;
  bool _isLoading = false;
  String? _errorMessage;

  // RSVP Form Data
  String _rsvpResponse = 'accepted';
  int _plusOneCount = 0;
  String _dietaryRestrictions = '';
  String _specialRequests = '';
  String _mealPreference = '';
  bool _isAttendingCeremony = true;
  bool _isAttendingReception = true;
  final TextEditingController _wishController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _invitation = args['invitation'] as Invitation?;
      _event = args['event'] as Event?;
      _guest = args['guest'] as Guest?;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingRSVP();
    });
  }

  void _loadExistingRSVP() {
    if (_invitation != null && _invitation!.respondedAt != null) {
      setState(() {
        _rsvpResponse = _invitation!.rsvpResponse ?? 'accepted';
        _plusOneCount = _invitation!.plusOneNames.length;
        _dietaryRestrictions = _invitation!.additionalData['dietaryRestrictions'] ?? '';
        _specialRequests = _invitation!.additionalData['specialRequests'] ?? '';
        _mealPreference = _invitation!.additionalData['mealPreference'] ?? '';
        _isAttendingCeremony = _invitation!.additionalData['isAttendingCeremony'] ?? true;
        _isAttendingReception = _invitation!.additionalData['isAttendingReception'] ?? true;
      });
    }
  }

  Future<void> _submitRSVP() async {
    if (_invitation == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      
      final guestName = _invitation!.guestName ?? _invitation!.guestEmail;
      final notificationService = NotificationService();

      // Save wish if message is not empty
      if (_wishController.text.isNotEmpty) {
        final wishProvider = Provider.of<EventWishProvider>(context, listen: false);
        final newWish = EventWish(
          id: const Uuid().v4(),
          eventId: _event!.id,
          guestId: _invitation!.guestEmail, // Using email as guestId if not logged in
          guestName: guestName,
          message: _wishController.text,
          createdAt: DateTime.now(),
        );
        await wishProvider.addWish(newWish);

        // Send wish notification to host
        await notificationService.createNotification(
          userId: _event!.hostId,
          title: 'New Guest Wish',
          message: '$guestName left a new wish for "${_event!.title}": "${_wishController.text}"',
          type: NotificationType.eventUpdate,
          priority: NotificationPriority.normal,
          relatedId: _event!.id,
        );
      }

      // Use the improved respondToInvitation method which handles Supabase sync for both invitation and guest record
      await invitationProvider.respondToInvitation(
        _invitation!.id,
        _rsvpResponse,
        numberOfGuests: _plusOneCount + 1,
        plusOneNames: List.generate(_plusOneCount, (index) => 'Guest ${index + 1}'),
        dietaryPreferences: _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null,
        mealChoice: _mealPreference.isNotEmpty ? _mealPreference : null,
        notes: _specialRequests.isNotEmpty ? _specialRequests : null,
        additionalData: {
          'isAttendingCeremony': _isAttendingCeremony,
          'isAttendingReception': _isAttendingReception,
        },
      );

      // Send RSVP response notification to host
      await notificationService.createNotification(
        userId: _event!.hostId,
        title: 'Guest RSVP Response',
        message: '$guestName has ${_rsvpResponse == "accepted" ? "accepted" : "declined"} your invitation to "${_event!.title}".',
        type: NotificationType.eventUpdate,
        priority: NotificationPriority.high,
        relatedId: _event!.id,
      );

      setState(() {
        _isLoading = false;
      });

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _rsvpResponse == 'accepted'
                  ? 'RSVP submitted successfully! We look forward to seeing you.'
                  : 'RSVP submitted. We\'re sorry you can\'t make it.',
            ),
            backgroundColor: _rsvpResponse == 'accepted'
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('RSVPScreen: Error submitting RSVP: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to submit RSVP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_invitation == null || _event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('RSVP Error'),
        ),
        body: const Center(
          child: Text('No invitation data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP'),
        actions: [
          if (_invitation!.respondedAt != null)
            TextButton(
              onPressed: _isLoading ? null : _submitRSVP,
              child: Text(
                'Update',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event!.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(_event!.date)} at ${_formatTime(_event!.startTime)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _event!.venue.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // RSVP Response
            Text(
              'Will you be attending?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Yes, I\'ll attend'),
                    value: 'accepted',
                    groupValue: _rsvpResponse,
                    onChanged: (value) {
                      setState(() {
                        _rsvpResponse = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('No, I can\'t attend'),
                    value: 'declined',
                    groupValue: _rsvpResponse,
                    onChanged: (value) {
                      setState(() {
                        _rsvpResponse = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Additional Guests (only show if accepted)
            if (_rsvpResponse == 'accepted') ...[
              Text(
                'Additional Guests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How many additional guests will you bring?'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _plusOneCount > 0
                                ? () => setState(() => _plusOneCount--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Expanded(
                            child: Text(
                              _plusOneCount.toString(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _plusOneCount++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total guests: ${_plusOneCount + 1}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Event Attendance Options
              Text(
                'Event Attendance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Attending Ceremony'),
                        value: _isAttendingCeremony,
                        onChanged: (value) {
                          setState(() {
                            _isAttendingCeremony = value ?? true;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Attending Reception'),
                        value: _isAttendingReception,
                        onChanged: (value) {
                          setState(() {
                            _isAttendingReception = value ?? true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Meal Preferences
              Text(
                'Meal Preferences',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _mealPreference.isNotEmpty ? _mealPreference : null,
                        decoration: const InputDecoration(
                          labelText: 'Meal Preference',
                          hintText: 'Select your meal preference',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'chicken', child: Text('Chicken')),
                          DropdownMenuItem(value: 'beef', child: Text('Beef')),
                          DropdownMenuItem(value: 'fish', child: Text('Fish')),
                          DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                          DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _mealPreference = value ?? '';
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: _dietaryRestrictions,
                        decoration: const InputDecoration(
                          labelText: 'Dietary Restrictions',
                          hintText: 'Any allergies or dietary restrictions?',
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          _dietaryRestrictions = value;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: _specialRequests,
                        decoration: const InputDecoration(
                          labelText: 'Special Requests',
                          hintText: 'Any special requests or notes?',
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          _specialRequests = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Gift Registry Link
              Text(
                'Gift Registry',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard, color: AppTheme.secondaryColor),
                  title: const Text('View Gift Registry'),
                  subtitle: const Text('See what the hosts have requested'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/gift-registry',
                      arguments: {'event': _event},
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Wishes & Blessings
              Text(
                'Wishes & Blessings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Leave a message for the hosts:'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _wishController,
                        decoration: const InputDecoration(
                          hintText: 'Your warm wishes, blessings, or message...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRSVP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _invitation!.respondedAt != null ? 'Update RSVP' : 'Submit RSVP',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }
}
