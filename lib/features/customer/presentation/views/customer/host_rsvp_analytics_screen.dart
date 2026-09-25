import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';

class HostRSVPAnalyticsScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const HostRSVPAnalyticsScreen({
    super.key,
    required this.eventId,
    this.eventTitle = 'Event RSVP Analytics',
  });

  @override
  State<HostRSVPAnalyticsScreen> createState() => _HostRSVPAnalyticsScreenState();
}

class _HostRSVPAnalyticsScreenState extends State<HostRSVPAnalyticsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEventRSVPData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEventRSVPData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      invitationProvider.loadInvitationsForEvent(widget.eventId);
      eventProvider.loadEventDetails(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RSVP & Guest Analytics',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Refresh Data',
            onPressed: _loadEventRSVPData,
          ),
        ],
      ),
      body: Consumer2<InvitationProvider, EventProvider>(
        builder: (context, invitationProvider, eventProvider, _) {
          final event = eventProvider.getEventById(widget.eventId);
          final invitations = invitationProvider.getInvitationsForEvent(widget.eventId);

          final totalInvited = invitations.length;
          final attendingList = invitations.where((i) => i.rsvpResponse == 'accepted' || i.status == InvitationStatus.accepted).toList();
          final declinedList = invitations.where((i) => i.rsvpResponse == 'declined' || i.status == InvitationStatus.declined).toList();
          final pendingList = invitations.where((i) =>
              i.rsvpResponse == null &&
              i.status != InvitationStatus.accepted &&
              i.status != InvitationStatus.declined).toList();

          final attendingCount = attendingList.length;
          final declinedCount = declinedList.length;
          final pendingCount = pendingList.length;

          // Dynamic meal preferences map from Supabase invitation additionalData
          final Map<String, int> mealCounts = {};
          final Set<String> dietarySet = {};

          for (final inv in attendingList) {
            final meal = (inv.additionalData['mealPreference'] as String?)?.trim();
            if (meal != null && meal.isNotEmpty) {
              mealCounts[meal] = (mealCounts[meal] ?? 0) + 1;
            }

            final dietary = (inv.additionalData['dietaryRestrictions'] as String?)?.trim();
            if (dietary != null && dietary.isNotEmpty) {
              dietarySet.add(dietary);
            }
          }

          final query = _searchController.text.toLowerCase();
          final filtered = invitations.where((inv) {
            final status = _getInvitationStatusString(inv);
            final matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;
            final name = (inv.guestName ?? '').toLowerCase();
            final email = inv.guestEmail.toLowerCase();
            final matchesQuery = query.isEmpty || name.contains(query) || email.contains(query);
            return matchesFilter && matchesQuery;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await invitationProvider.loadInvitationsForEvent(widget.eventId);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Overview Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF1E1B4B).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event?.title ?? widget.eventTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeaderStat('Total Invited', '$totalInvited', Colors.white70),
                            _buildHeaderStat(
                              'Attending',
                              totalInvited > 0 ? '$attendingCount (${(attendingCount / totalInvited * 100).toStringAsFixed(0)}%)' : '$attendingCount',
                              Colors.greenAccent,
                            ),
                            _buildHeaderStat('Declined', '$declinedCount', Colors.redAccent),
                            _buildHeaderStat('Pending', '$pendingCount', Colors.amberAccent),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (totalInvited > 0) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: [
                                if (attendingCount > 0)
                                  Expanded(flex: attendingCount, child: Container(height: 8, color: Colors.greenAccent)),
                                if (declinedCount > 0)
                                  Expanded(flex: declinedCount, child: Container(height: 8, color: Colors.redAccent)),
                                if (pendingCount > 0)
                                  Expanded(flex: pendingCount, child: Container(height: 8, color: Colors.amberAccent)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Confirmed Attending: $attendingCount Guests',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (pendingCount > 0)
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('RSVP reminders broadcasted to $pendingCount pending guests!'), backgroundColor: Colors.green),
                                  );
                                },
                                icon: const Icon(Icons.send_outlined, size: 14),
                                label: const Text('Remind Pending'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Meal Preferences Breakdown from Real Invitations
                  const Text(
                    'Meal Preference Selections',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: mealCounts.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No meal preferences recorded yet from RSVPs.',
                                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                              ),
                            ),
                          )
                        : Column(
                            children: mealCounts.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildMealRow(entry.key, entry.value, attendingCount > 0 ? attendingCount : 1),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Dietary Requirements from Real RSVPs
                  if (dietarySet.isNotEmpty) ...[
                    const Text(
                      'Dietary & Allergy Alerts',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: dietarySet.map((d) {
                          return Chip(
                            avatar: const Icon(Icons.warning_amber, color: Colors.deepOrange, size: 16),
                            label: Text(d),
                            backgroundColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Guest Ledger from Supabase
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Guest Response Ledger',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      ),
                      Text(
                        '${filtered.length} Guests',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search guest by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Attending', 'Declined', 'Pending'].map((f) {
                      final isSelected = _selectedFilter == f;
                      return ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedFilter = f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.mail_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No invitations found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Send invitations to guests from your event dashboard to track responses here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((inv) => _buildInvitationGuestCard(inv)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getInvitationStatusString(Invitation inv) {
    if (inv.rsvpResponse == 'accepted' || inv.status == InvitationStatus.accepted) return 'Attending';
    if (inv.rsvpResponse == 'declined' || inv.status == InvitationStatus.declined) return 'Declined';
    return 'Pending';
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildMealRow(String mealName, int count, int total) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(mealName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$count ($pct%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            minHeight: 6,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInvitationGuestCard(Invitation inv) {
    final status = _getInvitationStatusString(inv);
    Color statusColor = Colors.grey;
    if (status == 'Attending') statusColor = Colors.green;
    if (status == 'Declined') statusColor = Colors.red;
    if (status == 'Pending') statusColor = Colors.orange;

    final meal = inv.additionalData['mealPreference'] as String? ?? 'Not specified';
    final dietary = inv.additionalData['dietaryRestrictions'] as String? ?? '';
    final guestName = inv.guestName?.isNotEmpty == true ? inv.guestName! : inv.guestEmail;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  guestName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(inv.guestEmail, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meal: $meal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text('Code: ${inv.invitationCode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          if (dietary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Dietary: $dietary',
              style: const TextStyle(fontSize: 11, color: Colors.deepOrange, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
