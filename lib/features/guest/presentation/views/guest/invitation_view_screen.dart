import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/core/utils/guest_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/features/guest/data/models/event_wish.dart';
import 'package:eventease/features/guest/data/providers/event_wish_provider.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/notification.dart';

class InvitationViewScreen extends StatefulWidget {
  final String invitationCode;

  const InvitationViewScreen({
    super.key,
    required this.invitationCode,
  });

  @override
  State<InvitationViewScreen> createState() => _InvitationViewScreenState();
}

class _InvitationViewScreenState extends State<InvitationViewScreen> {
  Invitation? _invitation;
  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isInit = true;
  final TextEditingController _directWishController = TextEditingController();
  bool _isSendingWish = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadInvitationData();
      _isInit = false;
    }
  }

  Future<void> _loadInvitationData() async {
    // Check if data was passed in arguments first
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['event'] != null) {
      setState(() {
        _invitation = args['invitation'] as Invitation?;
        _event = args['event'] as Event;
        _isLoading = false;
      });
      _checkIfHostAndRedirect();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      final code = widget.invitationCode.trim().toUpperCase();

      // 1. Try to find a specific invitation first (force refresh to ensure latest status)
      var invitation = await invitationProvider.getInvitationByCode(code, forceRefresh: true);

      if (invitation == null) {
        // 2. If not found, check if this is a "Master Code" (Short Event ID)
        final event = await eventProvider.getEventByShortId(code);
        
        if (event != null) {
          if (!mounted) return;
          setState(() {
            _event = event;
            _invitation = null; // Signal that this is a new guest join
            _isLoading = false;
          });
          _checkIfHostAndRedirect();
          return;
        }

        if (!mounted) return;
        setState(() {
          _errorMessage = 'Invitation or Event not found. Please check the link.';
          _isLoading = false;
        });
        return;
      }

      // 3. Specific invitation found
      final event = await eventProvider.fetchEventById(invitation.eventId);
      if (event == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Event information not available.';
          _isLoading = false;
        });
        return;
      }

      // Mark invitation as viewed
      await invitationProvider.markInvitationViewed(invitation.id);
      
      // Save code locally for session persistence
      await invitationProvider.addJoinedInvitationCode(code);

      // --- DEBUG ---
      debugPrint('DEBUG: Invitation loaded: ${invitation.id}, Status: ${invitation.status}, RespondedAt: ${invitation.respondedAt}');
      // --- END DEBUG ---

      // --- ADDED: Check if already RSVP'd ---
      if (invitation.status == InvitationStatus.accepted) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          GuestRoutes.guestDashboard,
          arguments: {'event': event, 'invitation': invitation},
        );
        return;
      }
      // --- END ADDED ---

      if (!mounted) return;
      setState(() {
        _invitation = invitation;
        _event = event;
        _isLoading = false;
      });
      _checkIfHostAndRedirect();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load invitation. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _checkIfHostAndRedirect() {
    if (_event == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.userId == _event!.hostId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Welcome back, Host! Redirecting to Planning Hub...'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/planning-hub',
          arguments: {'eventId': _event!.id},
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Invitation...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invitation Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadInvitationData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_event == null) {
      return const Scaffold(
        body: Center(
          child: Text('No event data available'),
        ),
      );
    }

    // Wrap the scaffold in a consumer and force-fetch/check status on build
    return Consumer<InvitationProvider>(
      builder: (context, invitationProvider, child) {
        // If we have an invitation, attempt to refresh it to get the latest RSVP status
        if (_invitation != null) {
          invitationProvider.getInvitationByCode(_invitation!.invitationCode, forceRefresh: true)
            .then((fresh) {
              if (fresh != null && fresh.status != _invitation!.status) {
                if (mounted) setState(() => _invitation = fresh);
              }
            });
        }
        
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero Header with Event Image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _event!.coverImage != null
                      ? Image.network(
                          _event!.coverImage!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.celebration,
                            size: 80,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
                title: Text(_event!.title),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareInvitation(context),
                  ),
                ],
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Invitation Message
                      if (_invitation != null && _invitation!.personalMessage != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.mail,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Personal Message',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_invitation!.personalMessage!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Event Details
                      _buildEventDetailsSection(),

                      const SizedBox(height: 16),

                      // Host Information
                      _buildHostInfoSection(),

                      const SizedBox(height: 16),

                      // RSVP Section
                      _buildRSVPSection(),

                      const SizedBox(height: 16),

                      // Wishes & Blessings
                      _buildDirectWishSection(),

                      const SizedBox(height: 16),

                      // Additional Actions
                      _buildAdditionalActions(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Event Title
            Text(
              _event!.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            // Event Description
            Text(
              _event!.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            // Event Date & Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_formatDate(_event!.date)} at ${_formatTime(_event!.startTime)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Venue
            InkWell(
              onTap: () => _openMapDirections(_event!.venue.location.isNotEmpty ? _event!.venue.location : _event!.venue.name),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _event!.venue.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          if (_event!.venue.location.isNotEmpty && _event!.venue.location != _event!.venue.name)
                            Text(
                              _event!.venue.location,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.navigation_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Event Type & Theme
            Row(
              children: [
                Icon(
                  _event!.type.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _event!.type.displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_event!.theme != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.palette,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _event!.theme!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),

            // Dress Code
            if (_event!.dressCode != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.checkroom,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dress Code: ${_event!.dressCode!}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitation Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.invitationCode,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shareInvitation(context),
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    tooltip: 'Copy Code',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with others to invite them to the event',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: _event!.hostProfileImage != null
                      ? ClipOval(
                          child: Image.network(
                            _event!.hostProfileImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _event!.hostName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_event!.hostEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _event!.hostEmail!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (_event!.hostPhone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _event!.hostPhone!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_event!.hostPhone != null || _event!.hostEmail != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_event!.hostPhone != null) ...[
                    ElevatedButton.icon(
                      onPressed: () => _callHost(_event!.hostPhone!),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _whatsappHost(_event!.hostPhone!),
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                  if (_event!.hostEmail != null)
                    ElevatedButton.icon(
                      onPressed: () => _emailHost(_event!.hostEmail!),
                      icon: const Icon(Icons.email, size: 16),
                      label: const Text('Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRSVPSection() {
    return Consumer<InvitationProvider>(
      builder: (context, invitationProvider, child) {
        // Fetch the freshest version of the invitation from the provider
        final invitation = _invitation != null 
            ? invitationProvider.getInvitationById(_invitation!.id) ?? _invitation 
            : null;
        
        final isExpired = _event!.date.isBefore(DateTime.now());
        final isResponded = invitation?.respondedAt != null;
        final isJoined = invitation != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RSVP',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (isExpired) ...[
                  // ... (keep expired logic)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_busy, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'This event has already passed',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isResponded) ...[
                  // ... (keep responded logic)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have ${invitation!.rsvpResponse == 'accepted' ? 'accepted' : 'declined'} this invitation',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _navigateToRSVP(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Update RSVP'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToDashboard(context),
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('Go to Guest Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else if (isJoined) ...[
                  // NEW: Logic for guests who joined but haven't RSVP'd
                  Text(
                    'You have successfully joined the event! Please complete your RSVP.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToRSVP(context),
                    icon: const Icon(Icons.rsvp),
                    label: const Text('Complete RSVP Now'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  // New guest
                  Text(
                    'Please let us know if you can attend this event.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showJoinDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Join This Event'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final TextEditingController nameController = TextEditingController(
      text: authProvider.isAuthenticated ? authProvider.userName : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome! Please enter your name to join the guest list.'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              
              final name = nameController.text.trim();
              Navigator.pop(context);
              
              setState(() => _isLoading = true);
              
              try {
                final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
                // Create a new invitation for this guest
                final newInv = await invitationProvider.createInvitation(
                  eventId: _event!.id,
                  guestName: name,
                  guestEmail: authProvider.isAuthenticated ? authProvider.userEmail : '', // Link to account if authenticated
                );
                
                if (mounted) {
                  setState(() {
                    _invitation = newInv;
                    _isLoading = false;
                  });
                  // Automatically take them to the RSVP screen
                  _navigateToRSVP(context);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error joining event: $e')),
                  );
                }
              }
            },
            child: const Text('Join & RSVP'),
          ),
        ],
      ),
    );
  }

  // Additional Actions
  Widget _buildAdditionalActions() {
    return Row(
      children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEventDetails(context),
                    icon: const Icon(Icons.info),
                    label: const Text('Event Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToGiftRegistry(context),
                    icon: const Icon(Icons.card_giftcard),
                    label: const Text('Gift Registry'),
                  ),
                ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0 && difference <= 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  void _shareInvitation(BuildContext context) {
    // Shared Master Code is eventId substring
    final masterCode = _event!.id.substring(0, 8).toUpperCase();
    
    Clipboard.setData(ClipboardData(text: 'Join our event! Event Code: $masterCode'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event code copied to clipboard!')),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    if (_event == null || _invitation == null) return;
    Navigator.of(context).pushNamed(
      GuestRoutes.guestDashboard,
      arguments: {'event': _event, 'invitation': _invitation},
    );
  }

  void _navigateToRSVP(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(
      GuestRoutes.rsvp,
      arguments: {'invitation': _invitation, 'event': _event},
    );
    
    // Refresh data after returning
    if (result == true && mounted) {
      _loadInvitationData();
    }
  }

  void _navigateToEventDetails(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.eventDetails,
      arguments: {'event': _event},
    );
  }

  void _navigateToGiftRegistry(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.giftRegistry,
      arguments: {'event': _event},
    );
  }

  // --- Map Directions (GMap / Waze) ---
  void _openMapDirections(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedQuery';
    final wazeUrl = 'https://waze.com/ul?q=$encodedQuery';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Get Directions via',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: const Text('Google Maps'),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(googleMapsUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    _showErrorSnackBar('Could not open Google Maps');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation, color: Colors.teal),
                title: const Text('Waze'),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(wazeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    _showErrorSnackBar('Could not open Waze');
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- Host Contacts ---
  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _callHost(String phone) async {
    final uri = Uri.parse('tel:${_cleanPhoneNumber(phone)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar('Could not make call');
    }
  }

  void _whatsappHost(String phone) async {
    final cleaned = _cleanPhoneNumber(phone).replaceAll('+', '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open WhatsApp');
    }
  }

  void _emailHost(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Question regarding ${_event!.title}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showErrorSnackBar('Could not open email client');
    }
  }

  // --- Direct Wishes & Blessings Panel ---
  Widget _buildDirectWishSection() {
    if (_invitation == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wishes & Blessings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message of congratulations or well wishes directly to the host.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _directWishController,
              decoration: const InputDecoration(
                hintText: 'Your warm wishes, blessings, or message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSendingWish ? null : _sendDirectWish,
                icon: _isSendingWish
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Send Wish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDirectWish() async {
    final message = _directWishController.text.trim();
    if (message.isEmpty) {
      _showErrorSnackBar('Please enter a message first');
      return;
    }

    setState(() => _isSendingWish = true);

    try {
      final wishProvider = Provider.of<EventWishProvider>(context, listen: false);
      final guestName = _invitation!.guestName ?? _invitation!.guestEmail;
      final newWish = EventWish(
        id: const Uuid().v4(),
        eventId: _event!.id,
        guestId: _invitation!.guestEmail,
        guestName: guestName,
        message: message,
        createdAt: DateTime.now(),
      );

      await wishProvider.addWish(newWish);

      // Send notification to host
      final notificationService = NotificationService();
      await notificationService.createNotification(
        userId: _event!.hostId,
        title: 'New Guest Wish',
        message: '$guestName left a new wish for "${_event!.title}": "$message"',
        type: NotificationType.eventUpdate,
        priority: NotificationPriority.normal,
        relatedId: _event!.id,
      );

      _directWishController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wish sent successfully! Thank you.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send wish. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSendingWish = false);
      }
    }
  }

  @override
  void dispose() {
    _directWishController.dispose();
    super.dispose();
  }
}
