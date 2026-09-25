import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/features/guest/data/providers/guest_provider.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart' as ep;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/constants/app_config.dart';
import 'package:eventease/features/budget/data/providers/budget_provider.dart';
import 'package:eventease/core/services/onboarding_service.dart';
import 'package:eventease/shared/widgets/tutorial_overlay.dart';
import 'package:eventease/features/event/presentation/widgets/digital_invite_card_dialog.dart';

class GuestListScreen extends StatefulWidget {
  final String? eventId;
  const GuestListScreen({super.key, this.eventId});

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredItems = [];
  String _selectedStatus = 'All';
  String _selectedTable = 'All';

  final List<String> _statuses = ['All', 'confirmed', 'pending', 'declined'];
  final List<String> _tables = ['All', '1', '2', '3', '4', '5'];
  String? _activeEventId;

  // Tutorial Keys
  final GlobalKey _addGuestKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _activeEventId = widget.eventId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    if (_activeEventId == null) {
      final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
      if (eventProvider.events.isNotEmpty) {
        setState(() {
          _activeEventId = eventProvider.events.first.id;
        });
      }
    }

    if (_activeEventId != null) {
      // Refresh latest data from Supabase
      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      final guestProvider = Provider.of<GuestProvider>(context, listen: false);
      
      await Future.wait([
        invitationProvider.loadInvitationsForEvent(_activeEventId!),
        guestProvider.loadGuestsForEvent(_activeEventId!),
      ]);
      
      _filterGuests();
    }

    // Check for tutorial
    final hasCompletedTutorial = await OnboardingService.isTutorialCompleted('guest_list');
    if (!hasCompletedTutorial && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _filterGuests() {
    final eventId = _activeEventId;
    if (eventId == null) return;
    
    final guestProvider = Provider.of<GuestProvider>(context, listen: false);
    final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
    
    final invitations = invitationProvider.getInvitationsForEvent(eventId);
    final guests = guestProvider.getGuestsForEvent(eventId);
    
    // Deduplicate: Keep only the first invitation found for each unique email
    final Map<String, Invitation> uniqueInvitations = {};
    for (final inv in invitations) {
      if (!uniqueInvitations.containsKey(inv.guestEmail)) {
        uniqueInvitations[inv.guestEmail] = inv;
      }
    }
    
    setState(() {
      _filteredItems = uniqueInvitations.values.where((inv) {
        final guest = guests.where((g) => g.invitationId == inv.id).firstOrNull;
        
        bool matchesSearch = (inv.guestName ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
                           inv.guestEmail.toLowerCase().contains(_searchController.text.toLowerCase());
        
        // Map invitation status to screen status
        String status = inv.status == InvitationStatus.accepted ? 'confirmed' : 
                       (inv.status == InvitationStatus.declined ? 'declined' : 'pending');
        
        bool matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;
        
        // Table number usually stored in guest notes or additional data
        String tableNum = guest?.seatingPreference ?? inv.additionalData['tableNumber'] ?? '';
        bool matchesTable = _selectedTable == 'All' || tableNum == _selectedTable;
        
        return matchesSearch && matchesStatus && matchesTable;
      }).toList();
    });
  }

  Future<void> _shareEventRSVP({String? guestName}) async {
    if (_activeEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event first')),
      );
      return;
    }

    final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
    final activeEvent = eventProvider.events.where((e) => e.id == _activeEventId).firstOrNull;

    if (activeEvent != null) {
      await DigitalInviteCardDialog.show(context, event: activeEvent, guestName: guestName);
      return;
    }

    final masterCode = _activeEventId!.substring(0, 8).toUpperCase();
    final rsvpUrl = '${AppConfig.inviteLinkBase}$masterCode';
    final appSchemeLink = '${AppConfig.appInviteLinkBase}$masterCode';
    
    final message = '🌟 You are invited to our event!\n\n'
        '📲 Open in App:\n$appSchemeLink\n\n'
        '🌐 Open in Browser:\n$rsvpUrl\n\n'
        '🔑 Event Join Code: $masterCode';
        
    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp. Copying link instead.')),
      );
      Clipboard.setData(ClipboardData(text: message));
    }
  }

  Widget _buildMasterCodeSection() {
    if (_activeEventId == null) return const SizedBox.shrink();
    final masterCode = _activeEventId!.substring(0, 8).toUpperCase();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event Join Code',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  masterCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _shareEventRSVP,
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GuestProvider, InvitationProvider>(
      builder: (context, guestProvider, invitationProvider, child) {
        final eventId = _activeEventId ?? '';
        final invitations = invitationProvider.getInvitationsForEvent(eventId);
        final guests = guestProvider.getGuestsForEvent(eventId);
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Guest List',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file, color: AppTheme.primaryColor),
                onPressed: _showImportOptions,
                tooltip: 'Import Guests',
              ),
              IconButton(
                icon: const Icon(Icons.download, color: AppTheme.primaryColor),
                onPressed: _exportGuestList,
                tooltip: 'Export Guests as CSV',
              ),
              IconButton(
                key: _addGuestKey,
                icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                onPressed: _showAddGuestDialog,
              ),
              IconButton(
                key: _shareKey,
                icon: const Icon(Icons.share, color: AppTheme.primaryColor),
                onPressed: _shareEventRSVP,
                tooltip: 'Share RSVP Link',
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildFilterChips(),
                  _buildMasterCodeSection(),
                  _buildGuestStats(invitations, guests),
                  Expanded(
                    child: _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : _buildGuestsList(guests),
                  ),
                ],
              ),
              if (_showTutorial)
                TutorialOverlay(
                  steps: [
                    TutorialStep(
                      title: 'Guest List Management',
                      message: 'Keep track of all your attendees, their RSVP status, and seating preferences.',
                      alignment: Alignment.center,
                    ),
                    TutorialStep(
                      title: 'Add Guests',
                      message: 'Start by adding your guests manually or importing them.',
                      targetKey: _addGuestKey,
                      alignment: Alignment.bottomCenter,
                    ),
                    TutorialStep(
                      title: 'Share RSVP Link',
                      message: 'Send this magic link to your guests so they can RSVP online instantly!',
                      targetKey: _shareKey,
                      alignment: Alignment.bottomCenter,
                    ),
                    TutorialStep(
                      title: 'Track Stats',
                      message: 'Real-time overview of your confirmed, pending, and declined invitations.',
                      targetKey: _statsKey,
                      alignment: Alignment.topCenter,
                    ),
                  ],
                  onCompleted: () {
                    OnboardingService.markTutorialAsCompleted('guest_list');
                    setState(() => _showTutorial = false);
                  },
                  onSkip: () {
                    OnboardingService.markTutorialAsCompleted('guest_list');
                    setState(() => _showTutorial = false);
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddGuestDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Guest'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _filterGuests(),
        decoration: InputDecoration(
          hintText: 'Search guests by name or email...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Status', _selectedStatus, (value) {
            setState(() {
              _selectedStatus = value;
              _filterGuests();
            });
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Table', _selectedTable, (value) {
            setState(() {
              _selectedTable = value;
              _filterGuests();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Function(String) onChanged) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) {
        List<String> options;
        switch (label) {
          case 'Status':
            options = _statuses;
            break;
          case 'Table':
            options = _tables;
            break;
          default:
            options = [];
        }
        
        return options.map((option) => PopupMenuItem(
          value: option,
          child: Text(option == 'All' ? 'All' : option.toUpperCase()),
        )).toList();
      },
      onSelected: onChanged,
    );
  }

  Widget _buildGuestStats(List<Invitation> invitations, List<Guest> guests) {
    final confirmed = invitations.where((i) => i.status == InvitationStatus.accepted).length;
    final pending = invitations.where((i) => i.status == InvitationStatus.sent || i.status == InvitationStatus.pending).length;
    final declined = invitations.where((i) => i.status == InvitationStatus.declined).length;
    final totalGuests = invitations.fold(0, (sum, inv) => sum + 1 + inv.plusOneNames.length);

    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        final eventId = _activeEventId;
        final budget = eventId != null ? budgetProvider.getBudgetForEvent(eventId) : null;
        final budgetAlerts = budget?.getBudgetAlerts() ?? [];
        final totalGuestCost = guests.fold<double>(0, (sum, guest) => sum + (guest.costPerGuest ?? 0.0));

        // Calculate budget allocation based on guest count
        final guestBudgetAllocation = totalGuests * 150.0; // Average cost per guest
        final budgetExceeded = budget != null && guestBudgetAllocation > budget.remainingBudget;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            key: _statsKey,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      totalGuests.toString(),
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Confirmed',
                      confirmed.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pending',
                      pending.toString(),
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Declined',
                      declined.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              if (budget != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildBudgetItem(
                        'Total Budget',
                        'RM ${budget.totalBudget.toStringAsFixed(0)}',
                        budget.totalBudget > 0 ? Colors.blue : Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: _buildBudgetItem(
                        'Spent',
                        'RM ${budget.spentBudget.toStringAsFixed(0)}',
                        budget.spentBudget > budget.totalBudget ? Colors.red : Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildBudgetItem(
                        'Remaining',
                        'RM ${budget.remainingBudget.toStringAsFixed(0)}',
                        budget.remainingBudget < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Guest budget allocation tracking
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: budgetExceeded ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: budgetExceeded ? Colors.red : Colors.green),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            budgetExceeded ? Icons.warning : Icons.check_circle,
                            color: budgetExceeded ? Colors.red : Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Guest Budget Allocation',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: budgetExceeded ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated cost for $totalGuests guests: RM ${guestBudgetAllocation.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: budgetExceeded ? Colors.red : Colors.green,
                        ),
                      ),
                      if (budgetExceeded) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Warning: Guest costs may exceed remaining budget!',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (budgetAlerts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            budgetAlerts.first,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestsList(List<Guest> guests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final invitation = _filteredItems[index] as Invitation;
        
        // Find all guest records for this invitation and take the latest one
        final guestRecords = guests.where((g) => g.email == invitation.guestEmail).toList();
        guestRecords.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final guest = guestRecords.isNotEmpty ? guestRecords.first : null;
        
        return _buildGuestCard(invitation, guest);
      },
    );
  }

  Widget _buildGuestCard(Invitation invitation, Guest? guest) {
    String statusStr;
    switch (invitation.status) {
      case InvitationStatus.accepted:
        statusStr = 'confirmed';
        break;
      case InvitationStatus.declined:
        statusStr = 'declined';
        break;
      default:
        statusStr = 'pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(statusStr).withOpacity(0.1),
          child: Text(
            (invitation.guestName ?? invitation.guestEmail)[0].toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(statusStr),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                invitation.guestName ?? invitation.guestEmail,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            _buildStatusChip(statusStr),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.vpn_key_rounded, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Join Code: ${_activeEventId!.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invitation.guestEmail,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (invitation.guestPhone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invitation.guestPhone!,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (guest?.dietaryPreferences != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.restaurant, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dietary: ${guest!.dietaryPreferences}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (invitation.plusOneNames.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_add, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plus Ones: ${invitation.plusOneNames.join(", ")}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if ((guest?.seatingPreference ?? invitation.additionalData['tableNumber'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.table_restaurant, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Table ${guest?.seatingPreference ?? invitation.additionalData['tableNumber']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (invitation.personalMessage != null || guest?.notes != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guest?.notes ?? invitation.personalMessage ?? '',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: () => _shareGuestRSVP(invitation),
              tooltip: 'Share RSVP via WhatsApp',
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditGuestDialog(invitation, guest);
                } else if (value == 'delete') {
                  _showDeleteGuestDialog(invitation);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareGuestRSVP(Invitation invitation) async {
    final eventProvider = Provider.of<ep.EventProvider>(context, listen: false);
    final event = eventProvider.getEventById(invitation.eventId);
    final guestName = invitation.guestName ?? 'Guest';

    if (event != null) {
      await DigitalInviteCardDialog.show(context, event: event, guestName: guestName);
      return;
    }

    final eventName = 'our special event';
    final guestCode = invitation.invitationCode.toUpperCase();
    final rsvpLink = '${AppConfig.inviteLinkBase}$guestCode';
    
    final message = '🌟 Hi $guestName!\n\n'
        'You are invited to $eventName. Please RSVP by clicking the link:\n$rsvpLink\n\n'
        '🔑 Event Join Code: $guestCode';
    final encodedMessage = Uri.encodeComponent(message);
    
    final whatsappUrl = Uri.parse('https://wa.me/${invitation.guestPhone ?? ""}?text=$encodedMessage');
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

                  Widget _buildStatusChip(String status) {
                    Color color;
                    String text;
                    
                    switch (status) {
                      case 'confirmed':
                        color = Colors.green;
                        text = 'CONFIRMED';
                        break;
                      case 'pending':
                        color = Colors.orange;
                        text = 'PENDING';
                        break;
                      case 'declined':
                        color = Colors.red;
                        text = 'DECLINED';
                        break;
                      default:
                        color = Colors.grey;
                        text = 'UNKNOWN';
                    }
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  Color _getStatusColor(String status) {
                    switch (status) {
                      case 'confirmed':
                        return Colors.green;
                      case 'pending':
                        return Colors.orange;
                      case 'declined':
                        return Colors.red;
                      default:
                        return Colors.grey;
                    }
                  }

                  Widget _buildEmptyState() {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No guests found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters or add some guests',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  void _showFilterSheet() {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildFilterSheet(),
                    );
                  }

                  Widget _buildFilterSheet() {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Filter Guests',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStatus = 'All';
                                      _selectedTable = 'All';
                                    });
                                    _filterGuests();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear all'),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFilterSection('Status', _statuses, _selectedStatus, (value) {
                                    setState(() {
                                      _selectedStatus = value;
                                    });
                                  }),
                                  const SizedBox(height: 24),
                                  _buildFilterSection('Table', _tables, _selectedTable, (value) {
                                    setState(() {
                                      _selectedTable = value;
                                    });
                                  }),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _filterGuests();
                                  Navigator.pop(context);
                                },
                                child: const Text('Apply Filters'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  Widget _buildFilterSection(String title, List<String> options, String selected, Function(String) onChanged) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((option) {
                            final isSelected = selected == option;
                            return FilterChip(
                              label: Text(option == 'All' ? 'All' : option.toUpperCase()),
                              selected: isSelected,
                              onSelected: (selected) => onChanged(option),
                              backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                              selectedColor: AppTheme.primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }

                  void _showAddGuestDialog() {
    _showGuestDialog(null, null);
  }

  void _showEditGuestDialog(Invitation invitation, Guest? guest) {
    _showGuestDialog(invitation, guest);
  }

  void _showGuestDialog(Invitation? invitation, Guest? guest) {
    final isEditing = invitation != null;
    final nameController = TextEditingController(text: invitation?.guestName ?? '');
    final emailController = TextEditingController(text: invitation?.guestEmail ?? '');
    final phoneController = TextEditingController(text: invitation?.guestPhone ?? '');
    final dietaryController = TextEditingController(text: guest?.dietaryPreferences ?? '');
    final plusOneNameController = TextEditingController(text: invitation?.plusOneNames?.isNotEmpty == true ? invitation!.plusOneNames![0] : '');
    final tableController = TextEditingController(text: guest?.seatingPreference ?? invitation?.additionalData['tableNumber'] ?? '');
    final notesController = TextEditingController(text: guest?.notes ?? invitation?.personalMessage ?? '');
    final costController = TextEditingController(text: guest?.costPerGuest?.toString() ?? '');

    String selectedStatus = invitation?.status == InvitationStatus.accepted ? 'confirmed' : 
                          (invitation?.status == InvitationStatus.declined ? 'declined' : 'pending');
                    bool hasPlusOne = invitation?.allowPlusOne ?? false;

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(isEditing ? 'Edit Guest' : 'Add Guest'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'RSVP Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['pending', 'confirmed', 'declined'].map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  selectedStatus = value!;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: dietaryController,
                                decoration: const InputDecoration(
                                  labelText: 'Dietary Restrictions',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., Vegetarian, Halal, None',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: hasPlusOne,
                                    onChanged: (value) {
                                      setState(() { // Wrap in setState to update UI
                                        hasPlusOne = value!;
                                      });
                                    },
                                  ),
                                  const Text('Plus One'),
                                ],
                              ),
                              if (hasPlusOne) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: plusOneNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Plus One Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextField(
                                controller: tableController,
                                decoration: const InputDecoration(
                                  labelText: 'Table Number',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., 1, 2, 3',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: notesController,
                                decoration: const InputDecoration(
                                  labelText: 'Notes',
                                  border: OutlineInputBorder(),
                                  hintText: 'Any additional notes',
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: costController,
                                decoration: const InputDecoration(
                                  labelText: 'Cost per Guest (RM)',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., 150.00',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                                final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
                                final guestProvider = Provider.of<GuestProvider>(context, listen: false);

                                if (isEditing) {
                                  final updatedInvitation = invitation!.copyWith(
                                    guestName: nameController.text,
                                    guestEmail: emailController.text,
                                    guestPhone: phoneController.text,
                                    status: selectedStatus == 'confirmed' ? InvitationStatus.accepted : 
                                            (selectedStatus == 'declined' ? InvitationStatus.declined : InvitationStatus.pending),
                                    personalMessage: notesController.text,
                                    allowPlusOne: hasPlusOne,
                                    plusOneNames: hasPlusOne && plusOneNameController.text.isNotEmpty ? [plusOneNameController.text] : [],
                                    additionalData: {
                                      ...(invitation.additionalData ?? {}),
                                      'tableNumber': tableController.text,
                                    },
                                    updatedAt: DateTime.now(),
                                  );
                                  invitationProvider.updateInvitation(updatedInvitation);
                                  
                                  if (guest != null) {
                                    final updatedGuest = guest.copyWith(
                                      name: nameController.text,
                                      email: emailController.text,
                                      phone: phoneController.text,
                                      dietaryPreferences: dietaryController.text,
                                      seatingPreference: tableController.text,
                                      notes: notesController.text,
                                      costPerGuest: double.tryParse(costController.text),
                                      hasPlusOne: hasPlusOne,
                                      plusOneName: hasPlusOne ? plusOneNameController.text : null,
                                      updatedAt: DateTime.now(),
                                    );
                                    guestProvider.updateGuest(updatedGuest);
                                  }
                                } else {
                                  final newInvitation = Invitation(
                                    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                                    eventId: widget.eventId ?? '',
                                    guestEmail: emailController.text,
                                    guestName: nameController.text,
                                    guestPhone: phoneController.text,
                                    status: selectedStatus == 'confirmed' ? InvitationStatus.accepted : 
                                            (selectedStatus == 'declined' ? InvitationStatus.declined : InvitationStatus.pending),
                                    invitationCode: 'code_${DateTime.now().millisecondsSinceEpoch}',
                                    allowPlusOne: hasPlusOne,
                                    maxPlusOnes: hasPlusOne ? 1 : 0,
                                    sentAt: DateTime.now(),
                                    plusOneNames: hasPlusOne && plusOneNameController.text.isNotEmpty ? [plusOneNameController.text] : [],
                                    personalMessage: notesController.text,
                                    additionalData: {
                                      'tableNumber': tableController.text,
                                    },
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  invitationProvider.addInvitation(newInvitation);

                                  final newGuest = Guest(
                                    id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
                                    eventId: widget.eventId ?? '',
                                    invitationId: newInvitation.id,
                                    name: nameController.text,
                                    email: emailController.text,
                                    phone: phoneController.text,
                                    isAttending: selectedStatus == 'confirmed',
                                    numberOfGuests: 1, // Default for new guest
                                    dietaryPreferences: dietaryController.text,
                                    seatingPreference: tableController.text,
                                    notes: notesController.text,
                                    costPerGuest: double.tryParse(costController.text),
                                    hasPlusOne: hasPlusOne,
                                    plusOneName: hasPlusOne ? plusOneNameController.text : null,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  guestProvider.addGuest(newGuest);
                                }
                                
                                _filterGuests();
                                Navigator.pop(context);
                              }
                            },
                            child: Text(isEditing ? 'Update' : 'Add'),
                          ),
                        ],
                      ),
                    );
  }

  void _showDeleteGuestDialog(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guest'),
        content: Text('Are you sure you want to remove ${invitation.guestName ?? invitation.guestEmail} from the guest list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<InvitationProvider>(context, listen: false).removeInvitation(invitation.id);
              _filterGuests();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guest removed successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Export Guest List ---
  Future<void> _exportGuestList() async {
    if (_activeEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event first')),
      );
      return;
    }

    final guestProvider = Provider.of<GuestProvider>(context, listen: false);
    final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
    
    final invitations = invitationProvider.getInvitationsForEvent(_activeEventId!);
    final guests = guestProvider.getGuestsForEvent(_activeEventId!);

    if (invitations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No guests to export')),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Name,Email,Phone,RSVP Status,Table Number,Dietary Preferences,Plus Ones,Notes,Cost per Guest (RM)');

    for (final inv in invitations) {
      final guest = guests.where((g) => g.invitationId == inv.id).firstOrNull;
      
      String status = inv.status == InvitationStatus.accepted ? 'Confirmed' : 
                     (inv.status == InvitationStatus.declined ? 'Declined' : 'Pending');

      final name = _escapeCsv(inv.guestName ?? '');
      final email = _escapeCsv(inv.guestEmail);
      final phone = _escapeCsv(inv.guestPhone ?? '');
      final tableNum = _escapeCsv(guest?.seatingPreference ?? inv.additionalData['tableNumber'] ?? '');
      final dietary = _escapeCsv(guest?.dietaryPreferences ?? '');
      final plusOnes = _escapeCsv(inv.plusOneNames.join('; '));
      final notes = _escapeCsv(guest?.notes ?? inv.personalMessage ?? '');
      final cost = guest?.costPerGuest?.toString() ?? '0.00';

      csvBuffer.writeln('$name,$email,$phone,$status,$tableNum,$dietary,$plusOnes,$notes,$cost');
    }

    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/guest_list_${_activeEventId!.substring(0, 8)}.csv';
      final file = File(filePath);
      await file.writeAsString(csvBuffer.toString());

      final xFile = XFile(filePath);
      await Share.shareXFiles([xFile], text: 'Exported Guest List');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guest list exported and shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting guest list: $e')),
        );
      }
    }
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // --- Import Guest Options ---
  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Import Guests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone, color: AppTheme.primaryColor),
              title: const Text('Import from Phone Contacts'),
              subtitle: const Text('Select contacts directly from your device'),
              onTap: () {
                Navigator.pop(context);
                _importFromPhoneContacts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_present, color: AppTheme.primaryColor),
              title: const Text('Import from CSV File'),
              subtitle: const Text('Upload a .csv file containing contact info'),
              onTap: () {
                Navigator.pop(context);
                _importFromCSV();
              },
            ),
            ListTile(
              leading: const Icon(Icons.paste, color: AppTheme.primaryColor),
              title: const Text('Paste Comma-Separated List'),
              subtitle: const Text('Paste names, emails, and phones directly'),
              onTap: () {
                Navigator.pop(context);
                _showPasteImportDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- Phone Contacts Import ---
  Future<void> _importFromPhoneContacts() async {
    try {
      final permission = await FlutterContacts.requestPermission();
      if (!permission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required to import from phone.')),
          );
        }
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
      }

      if (contacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts found on device.')),
          );
        }
        return;
      }

      if (!mounted) return;
      final selectedContacts = await showDialog<List<Contact>>(
        context: context,
        builder: (context) => PhoneContactsSelectorDialog(contacts: contacts),
      );

      if (selectedContacts == null || selectedContacts.isEmpty) return;

      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      final guestProvider = Provider.of<GuestProvider>(context, listen: false);

      int importedCount = 0;
      for (final contact in selectedContacts) {
        final name = contact.displayName;
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
        final email = contact.emails.isNotEmpty ? contact.emails.first.address : '';

        // Add guest details
        final newInvitation = Invitation(
          id: 'inv_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
          eventId: _activeEventId ?? '',
          guestEmail: email.isNotEmpty ? email : 'guest_${DateTime.now().millisecondsSinceEpoch}_$importedCount@imported.com',
          guestName: name,
          guestPhone: phone.isNotEmpty ? phone : null,
          status: InvitationStatus.pending,
          invitationCode: 'code_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
          allowPlusOne: false,
          maxPlusOnes: 0,
          sentAt: DateTime.now(),
          plusOneNames: [],
          personalMessage: null,
          additionalData: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        invitationProvider.addInvitation(newInvitation);

        final newGuest = Guest(
          id: 'guest_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
          eventId: _activeEventId ?? '',
          invitationId: newInvitation.id,
          name: name,
          email: email.isNotEmpty ? email : 'guest_${DateTime.now().millisecondsSinceEpoch}_$importedCount@imported.com',
          phone: phone.isNotEmpty ? phone : null,
          isAttending: false,
          numberOfGuests: 1,
          dietaryPreferences: null,
          seatingPreference: '',
          notes: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        guestProvider.addGuest(newGuest);

        importedCount++;
      }

      _filterGuests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $importedCount guests from phone!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing contacts: $e')),
        );
      }
    }
  }

  // --- CSV File Import ---
  Future<void> _importFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      String csvContent;
      final bytes = result.files.single.bytes;
      
      if (bytes != null) {
        csvContent = utf8.decode(bytes);
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        csvContent = await file.readAsString();
      } else {
        return;
      }

      await _parseAndAddCSVGuests(csvContent);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading file: $e')),
        );
      }
    }
  }

  Future<void> _parseAndAddCSVGuests(String csvContent) async {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return;

    int nameIndex = 0;
    int emailIndex = 1;
    int phoneIndex = 2;
    int tableIndex = -1;
    int dietaryIndex = -1;
    int notesIndex = -1;

    final headers = lines.first.split(',');
    bool hasHeader = false;
    if (headers.isNotEmpty && (headers[0].toLowerCase().contains('name') || headers[0].toLowerCase().contains('email'))) {
      hasHeader = true;
      for (int i = 0; i < headers.length; i++) {
        final h = headers[i].trim().toLowerCase();
        if (h.contains('name')) nameIndex = i;
        else if (h.contains('email')) emailIndex = i;
        else if (h.contains('phone')) phoneIndex = i;
        else if (h.contains('table')) tableIndex = i;
        else if (h.contains('dietary')) dietaryIndex = i;
        else if (h.contains('notes') || h.contains('message')) notesIndex = i;
      }
    }

    final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
    final guestProvider = Provider.of<GuestProvider>(context, listen: false);
    
    int importedCount = 0;
    final startIdx = hasHeader ? 1 : 0;

    for (int i = startIdx; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final fields = _splitCsvLine(line);
      if (fields.length <= nameIndex && fields.length <= emailIndex) continue;

      final guestName = fields.length > nameIndex ? fields[nameIndex].trim() : 'Imported Guest';
      final guestEmail = fields.length > emailIndex ? fields[emailIndex].trim() : '';
      final guestPhone = fields.length > phoneIndex ? fields[phoneIndex].trim() : '';
      final tableNum = (tableIndex != -1 && fields.length > tableIndex) ? fields[tableIndex].trim() : '';
      final dietary = (dietaryIndex != -1 && fields.length > dietaryIndex) ? fields[dietaryIndex].trim() : '';
      final notes = (notesIndex != -1 && fields.length > notesIndex) ? fields[notesIndex].trim() : '';

      if (guestName.isEmpty && guestEmail.isEmpty) continue;

      final newInvitation = Invitation(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
        eventId: _activeEventId ?? '',
        guestEmail: guestEmail.isNotEmpty ? guestEmail : 'guest_${DateTime.now().millisecondsSinceEpoch}_$importedCount@imported.com',
        guestName: guestName,
        guestPhone: guestPhone.isNotEmpty ? guestPhone : null,
        status: InvitationStatus.pending,
        invitationCode: 'code_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
        allowPlusOne: false,
        maxPlusOnes: 0,
        sentAt: DateTime.now(),
        plusOneNames: [],
        personalMessage: notes.isNotEmpty ? notes : null,
        additionalData: {
          'tableNumber': tableNum,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      invitationProvider.addInvitation(newInvitation);

      final newGuest = Guest(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}_$importedCount',
        eventId: _activeEventId ?? '',
        invitationId: newInvitation.id,
        name: guestName,
        email: guestEmail.isNotEmpty ? guestEmail : 'guest_${DateTime.now().millisecondsSinceEpoch}_$importedCount@imported.com',
        phone: guestPhone.isNotEmpty ? guestPhone : null,
        isAttending: false,
        numberOfGuests: 1,
        dietaryPreferences: dietary.isNotEmpty ? dietary : null,
        seatingPreference: tableNum,
        notes: notes.isNotEmpty ? notes : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      guestProvider.addGuest(newGuest);

      importedCount++;
    }

    _filterGuests();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported $importedCount guests from CSV!')),
      );
    }
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    result.add(currentField.toString());
    return result;
  }

  // --- Paste List Import ---
  void _showPasteImportDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Text / Copied List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste one contact per line in format:\nName, Email, Phone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'Example:\nJohn Doe, john@example.com, +60123456789\nJane Smith, jane@example.com',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste your list here...',
                border: OutlineInputBorder(),
              ),
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
              final content = textController.text.trim();
              Navigator.pop(context);
              if (content.isNotEmpty) {
                await _parseAndAddCSVGuests(content);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

// --- Stateful Dialog to Search & Select multiple Device Contacts ---
class PhoneContactsSelectorDialog extends StatefulWidget {
  final List<Contact> contacts;
  const PhoneContactsSelectorDialog({super.key, required this.contacts});

  @override
  State<PhoneContactsSelectorDialog> createState() => _PhoneContactsSelectorDialogState();
}

class _PhoneContactsSelectorDialogState extends State<PhoneContactsSelectorDialog> {
  final List<Contact> _selectedContacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        return contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
               (contact.phones.isNotEmpty && contact.phones.any((p) => p.number.contains(query))) ||
               (contact.emails.isNotEmpty && contact.emails.any((e) => e.address.toLowerCase().contains(query.toLowerCase())));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Phone Contacts'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              onChanged: _filterContacts,
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _selectedContacts.length == _filteredContacts.length && _filteredContacts.isNotEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedContacts.clear();
                        _selectedContacts.addAll(_filteredContacts);
                      } else {
                        _selectedContacts.clear();
                      }
                    });
                  },
                ),
                const Text('Select All Filtered'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  final isSelected = _selectedContacts.contains(contact);
                  final phone = contact.phones.isNotEmpty ? contact.phones.first.number : 'No Phone';
                  final email = contact.emails.isNotEmpty ? contact.emails.first.address : '';

                  return CheckboxListTile(
                    title: Text(contact.displayName),
                    subtitle: Text(email.isNotEmpty ? '$phone\n$email' : phone),
                    isThreeLine: email.isNotEmpty,
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedContacts.add(contact);
                        } else {
                          _selectedContacts.remove(contact);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedContacts),
          child: Text('Import (${_selectedContacts.length})'),
        ),
      ],
    );
  }
}









