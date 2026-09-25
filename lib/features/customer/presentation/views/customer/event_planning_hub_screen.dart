import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/customer/data/providers/customer_subscription_provider.dart';
import 'package:eventease/shared/widgets/upgrade_required_overlay.dart';

class EventPlanningHubScreen extends StatefulWidget {
  final String? eventId;

  const EventPlanningHubScreen({super.key, this.eventId});

  @override
  State<EventPlanningHubScreen> createState() => _EventPlanningHubScreenState();
}

class _EventPlanningHubScreenState extends State<EventPlanningHubScreen> {
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.eventId;
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.userId != null) {
        Provider.of<EventProvider>(context, listen: false).loadEvents(authProvider.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Planning Hub', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: Consumer3<EventProvider, AuthProvider, CustomerSubscriptionProvider>(
        builder: (context, eventProvider, authProvider, subProvider, child) {
          if (!authProvider.isAuthenticated) {
            return _buildLoginRequired();
          }

          final events = eventProvider.getEventsByHost(authProvider.userId ?? '');
          
          if (events.isEmpty) {
            return _buildNoEventsState();
          }

          // Auto-select first event if none selected
          if (_selectedEventId == null && events.isNotEmpty) {
            _selectedEventId = events.first.id;
          }

          final selectedEvent = events.firstWhere(
            (e) => e.id == _selectedEventId,
            orElse: () => events.first,
          );

          return UpgradeRequiredOverlay(
            isLocked: !subProvider.isPremium,
            title: 'Planning Tools Locked',
            description: 'Upgrade to Premium to unlock specialized planning tools for your ${selectedEvent.type.displayName}.',
            onUpgradePressed: () => Navigator.pushNamed(context, '/customer-subscription'),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventSelector(events, selectedEvent),
                  const SizedBox(height: 24),
                  _buildEventHeader(selectedEvent),
                  const SizedBox(height: 32),
                  const Text(
                    'Planning Tools',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildToolsGrid(selectedEvent),
                  const SizedBox(height: 32),
                  _buildProgressSummary(selectedEvent),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/event-create'),
        label: const Text('New Event'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Please login to access your Planning Hub'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
            const SizedBox(height: 24),
            const Text(
              'No Events to Plan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create your first event to unlock the planning hub tools tailored for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/event-create'),
              icon: const Icon(Icons.add),
              label: const Text('Create New Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventSelector(List<Event> events, Event selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.id,
          isExpanded: true,
          items: events.map((e) => DropdownMenuItem(
            value: e.id,
            child: Row(
              children: [
                Icon(e.type.icon, size: 18, color: e.type.color),
                const SizedBox(width: 12),
                Text(e.title, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList(),
          onChanged: (val) => setState(() => _selectedEventId = val),
        ),
      ),
    );
  }

  Widget _buildEventHeader(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [event.type.color, event.type.color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: event.type.color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type.displayName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      '${event.date.day}/${event.date.month}/${event.date.year}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(event.type.icon, size: 48, color: Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(Event event) {
    final tools = _getAvailableTools(event);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) => tools[index],
    );
  }

  List<Widget> _getAvailableTools(Event event) {
    final List<Widget> tools = [];
    final type = event.type;

    // 1. General Tools (Always available)
    tools.add(_buildToolItem('Checklist', Icons.checklist_rounded, Colors.blue, () {
      Navigator.pushNamed(context, '/planner', arguments: {'eventId': event.id, 'tab': 1});
    }));
    
    tools.add(_buildToolItem('Timeline', Icons.auto_graph_rounded, Colors.purple, () {
      Navigator.pushNamed(context, '/planner', arguments: {'eventId': event.id, 'tab': 0});
    }));

    tools.add(_buildToolItem('Budget', Icons.account_balance_wallet_rounded, Colors.green, () {
      Navigator.pushNamed(context, '/planner', arguments: {'eventId': event.id, 'tab': 2});
    }));

    tools.add(_buildToolItem('Collaborators', Icons.group_add_rounded, Colors.deepOrangeAccent, () {
      Navigator.pushNamed(context, '/event-collaboration', arguments: {'eventId': event.id});
    }));

    // 2. Conditional Tools based on EventType
    
    // Guest List - Social, Corporate, Community
    if (type.categoryGroup == 'social' || type.categoryGroup == 'corporate' || type.categoryGroup == 'community') {
      tools.add(_buildToolItem('Guest List', Icons.people_alt_rounded, Colors.orange, () {
        Navigator.pushNamed(context, '/guest-list', arguments: {'eventId': event.id});
      }));
    }

    // Gift Registry - Weddings, Baby Showers, Birthdays
    // 3. Category Specific Tools
    
    // Registry - All social celebration events
    if (type.categoryGroup == 'social' || type.categoryGroup == 'cultural') {
      tools.add(_buildToolItem('Registry', Icons.card_giftcard_rounded, Colors.pink, () {
        Navigator.pushNamed(context, '/registry-management', arguments: {'eventId': event.id});
      }));
    }

    // Wishes/Messages - Social and Memorial events
    if (type.categoryGroup == 'social' || type.categoryGroup == 'memorial' || type.categoryGroup == 'cultural') {
      tools.add(_buildToolItem('Wishes', Icons.favorite_rounded, Colors.redAccent, () {
        Navigator.pushNamed(context, '/event-wishes', arguments: {'eventId': event.id});
      }));
    }

    // Vendors - Corporate and Community might have different vendor needs
    tools.add(_buildToolItem('Vendors', Icons.storefront_rounded, Colors.teal, () {
      Navigator.pushNamed(context, '/shop');
    }));

    // 4. Corporate & Professional Tools
    if (type.categoryGroup == 'corporate' || type == EventType.seminar) {
      tools.add(_buildToolItem('Sponsors', Icons.handshake_rounded, Colors.brown, () {
         _showFeaturePlaceholder('Sponsor Management');
      }));
      tools.add(_buildToolItem('Attendees', Icons.assignment_ind_rounded, Colors.indigo, () {
         Navigator.pushNamed(context, '/guest-list', arguments: {'eventId': event.id});
      }));
      tools.add(_buildToolItem('Speaker List', Icons.mic_external_on_rounded, Colors.deepOrange, () {
         _showFeaturePlaceholder('Speaker Management');
      }));
    }

    // 5. Community & Public Events
    if (type.categoryGroup == 'community') {
      tools.add(_buildToolItem('Volunteer Hub', Icons.volunteer_activism_rounded, Colors.red, () {
         _showFeaturePlaceholder('Volunteer Management');
      }));
      tools.add(_buildToolItem('Public RSVP', Icons.confirmation_number_rounded, Colors.deepPurple, () {
         _showFeaturePlaceholder('Public Registration');
      }));
    }

    // 6. Educational Events
    if (type.categoryGroup == 'educational') {
      tools.add(_buildToolItem('Resource Hub', Icons.library_books_rounded, Colors.amber, () {
         _showFeaturePlaceholder('Educational Resources');
      }));
      tools.add(_buildToolItem('Certificates', Icons.card_membership_rounded, Colors.blueGrey, () {
         _showFeaturePlaceholder('Certificate Generation');
      }));
    }

    // 7. Memorial Events
    if (type.categoryGroup == 'memorial' || type == EventType.funeral) {
      tools.add(_buildToolItem('Tribute Wall', Icons.favorite_border_rounded, Colors.blueGrey, () {
         Navigator.pushNamed(context, '/event-wishes', arguments: {'eventId': event.id});
      }));
      tools.add(_buildToolItem('Obituary', Icons.auto_stories_rounded, Colors.black54, () {
         _showFeaturePlaceholder('Obituary Builder');
      }));
    }

    // 8. Cultural & Religious
    if (type.categoryGroup == 'cultural') {
      tools.add(_buildToolItem('Program', Icons.event_note_rounded, Colors.teal, () {
         _showFeaturePlaceholder('Ceremony Program');
      }));
    }

    return tools;
  }

  Widget _buildToolItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(Event event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planning Progress',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Tasks', 0.65, Colors.blue),
          const SizedBox(height: 12),
          _buildProgressRow('Budget', 0.42, Colors.green),
          const SizedBox(height: 12),
          _buildProgressRow('Vendors', 0.8, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double progress, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  void _showFeaturePlaceholder(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon for this event type!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
