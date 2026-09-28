import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/live_expo.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_floor_plan_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_requirements_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_staff_passes_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_post_event_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorExhibitionDashboardScreen extends StatefulWidget {
  final ExhibitorVendor exhibitor;

  const VendorExhibitionDashboardScreen({
    super.key,
    required this.exhibitor,
  });

  static const routeName = '/vendor-exhibition-dashboard';

  @override
  State<VendorExhibitionDashboardScreen> createState() => _VendorExhibitionDashboardScreenState();
}

class _VendorExhibitionDashboardScreenState extends State<VendorExhibitionDashboardScreen> {
  late ExhibitorVendor _exhibitor;
  bool _isLoading = false;
  DateTime? _expoStartAt;
  List<ExpoTimelineItem> _timeline = [];
  List<EmergencyAlert> _announcements = [];
  String? _organizerContactEmail;
  String? _organizerContactPhone;

  Map<String, bool> get _checklist => {
        'Booth Fee Paid': _exhibitor.paymentStatus == PaymentStatus.paid,
        'Contract & Terms Signed': _exhibitor.status == ExhibitorStatus.approved ||
            _exhibitor.status == ExhibitorStatus.confirmed ||
            _exhibitor.status == ExhibitorStatus.completed,
        'Staff Passes Registered': _exhibitor.staffPasses.isNotEmpty,
        'Power & Extra Furniture Request': _exhibitor.requirements.isNotEmpty,
        'Booth Fascia Name Confirmed': (_exhibitor.boothNumber ?? '').isNotEmpty,
        'Marketing Materials Uploaded': _exhibitor.marketingOptIn,
      };

  @override
  void initState() {
    super.initState();
    _exhibitor = widget.exhibitor;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final updated = await OrganizerRepository.instance.fetchExhibitor(_exhibitor.id);
      if (updated != null && mounted) {
        setState(() => _exhibitor = updated);
      }
      final expoId = _exhibitor.expoId;
      if (expoId != null && expoId.isNotEmpty) {
        final expo = await OrganizerRepository.instance.fetchExpoSummary(expoId);
        final timeline = await OrganizerRepository.instance.fetchTimeline(expoId);
        final announcements =
            await OrganizerRepository.instance.fetchEmergencyAlerts(expoId);

        Map<String, dynamic>? organizer;
        try {
          final expoRow = await Supabase.instance.client
              .from('organizer_expos')
              .select('company_id')
              .eq('id', expoId)
              .maybeSingle();
          final companyId = expoRow?['company_id']?.toString();
          if (companyId != null && companyId.isNotEmpty) {
            organizer = await Supabase.instance.client
                .from('organizer_companies')
                .select('contact_email, contact_phone')
                .eq('id', companyId)
                .maybeSingle();
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _expoStartAt = expo?.startAt;
            _timeline = timeline;
            _announcements = announcements;
            _organizerContactEmail = organizer?['contact_email']?.toString();
            _organizerContactPhone = organizer?['contact_phone']?.toString();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  int get _completedChecklistCount => _checklist.values.where((v) => v).length;

  int get _daysUntilEvent {
    final start = _expoStartAt ?? _exhibitor.paymentDeadline;
    if (start == null) return 0;
    return start.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Exhibition Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () => _showContactOrganizerModal(context),
            tooltip: 'Contact Organiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner with Countdown & Booth Lock
                    _buildHeroBanner(),
                    const SizedBox(height: 20),

                    // Quick Stats & Status Bar
                    _buildStatusPills(),
                    const SizedBox(height: 24),

                    // Feature Hub / Action Grid
                    const Text(
                      'Exhibitor Management',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 14),
                    _buildManagementGrid(context),
                    const SizedBox(height: 24),

                    // Readiness Checklist
                    _buildChecklistCard(),
                    const SizedBox(height: 24),

                    // Official Organiser Bulletins
                    _buildOrganiserAnnouncements(),
                    const SizedBox(height: 24),

                    // Move-in / Event Schedule
                    _buildScheduleCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'CONFIRMED EXHIBITOR',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$_daysUntilEvent days to go',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _exhibitor.expoName ?? 'Exhibition',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _heroItem('BOOTH NUMBER', _exhibitor.boothNumber ?? 'Not assigned', isAccent: true),
              _heroItem('LOCATION', '${_exhibitor.boothHall} · ${_exhibitor.boothZone}'),
              _heroItem('SIZE', _exhibitor.boothSize ?? 'Not provided'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroItem(String label, String value, {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isAccent ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isAccent ? const Color(0xFF67E8F9) : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPills() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF3B82F6), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Package', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        _exhibitor.packageName ?? 'Not selected',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_score_rounded, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text(
                        _exhibitor.paymentStatus == PaymentStatus.paid ? 'Fully Paid' : 'Deposit Paid',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementGrid(BuildContext context) {
    final tiles = [
      {
        'title': 'Floor Plan & Neighbors',
        'subtitle': 'Locate booth, see who is around you',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendorFloorPlanScreen(exhibitor: _exhibitor)),
            ),
      },
      {
        'title': 'Booth Requirements',
        'subtitle': 'Power, extra table, carpet, rules',
        'icon': Icons.electrical_services_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendorRequirementsScreen(exhibitor: _exhibitor)),
            ),
      },
      {
        'title': 'Staff Passes & Badges',
        'subtitle': 'Assign crew & generate QR access passes',
        'icon': Icons.badge_rounded,
        'color': const Color(0xFF10B981),
        'bg': const Color(0xFFECFDF5),
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendorStaffPassesScreen(exhibitor: _exhibitor)),
            ),
      },
      {
        'title': 'Post-Event & Leads',
        'subtitle': 'Visitor stats, review & analytics',
        'icon': Icons.insights_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'route': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendorPostEventScreen(exhibitor: _exhibitor)),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: tiles.length,
      itemBuilder: (ctx, i) {
        final t = tiles[i];
        return InkWell(
          onTap: t['route'] as VoidCallback,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t['bg'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(t['icon'] as IconData, color: t['color'] as Color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['subtitle'] as String,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChecklistCard() {
    final progress = _completedChecklistCount / _checklist.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Readiness Checklist',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_completedChecklistCount of ${_checklist.length} Done',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF10B981) : AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          ..._checklist.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    entry.value ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: entry.value ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: entry.value ? FontWeight.w500 : FontWeight.normal,
                      color: entry.value ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                      decoration: entry.value ? TextDecoration.none : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrganiserAnnouncements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Official Bulletins',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        if (_announcements.isEmpty)
          const Text(
            'No organizer bulletins have been published.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ..._announcements.map((announcement) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Organizer Alert',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ),
                          Text(
                            DateFormat('d MMM, h:mm a').format(announcement.sentAt.toLocal()),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement.message,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Color(0xFF334155), size: 20),
              SizedBox(width: 8),
              Text(
                'Key Dates & Move-in Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_timeline.isEmpty)
            const Text(
              'No schedule has been published for this expo.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ..._timeline.map((item) {
            final isLive = item.status == TimelineItemStatus.live;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('EEE, d MMM').format(item.startAt.toLocal()),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isLive ? const Color(0xFF059669) : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(item.startAt.toLocal())} - ${DateFormat('HH:mm').format(item.endAt.toLocal())} · ${item.location}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showContactOrganizerModal(BuildContext context) {
    final email = _organizerContactEmail?.trim();
    final phone = _organizerContactPhone?.trim();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Expo Committee',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Need assistance with your booth, power supply, or badge registration?',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            if ((phone == null || phone.isEmpty) &&
                (email == null || email.isEmpty))
              const Text(
                'Organizer contact details have not been published.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            if (phone != null && phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone_rounded, color: Color(0xFF10B981)),
                title: const Text('Call Organizer'),
                subtitle: Text(phone),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            if (email != null && email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email_rounded, color: Color(0xFFF59E0B)),
                title: const Text('Email Organizer'),
                subtitle: Text(email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final uri = Uri(scheme: 'mailto', path: email);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
