import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/organizer_scope.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class ExpoDetailScreen extends StatelessWidget {
  const ExpoDetailScreen({super.key, this.expoId});

  final String? expoId;

  static const routeName = '/organizer/expo-detail';

  String? _resolveId(BuildContext context) =>
      expoId ?? ModalRoute.of(context)?.settings.arguments as String?;

  @override
  Widget build(BuildContext context) {
    final id = _resolveId(context);
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expo detail')),
        body: const OrganizerScreenBody(child: Center(child: Text('No expo selected'))),
      );
    }

    OrganizerScope.setActiveExpoId(id);

    return OrganizerAsyncBody<ExpoSummary?>(
      loader: () => OrganizerRepository.instance.fetchExpoSummary(id),
      isEmpty: (expo) => expo == null,
      emptyWidget: const Center(child: Text('Expo not found')),
      builder: (context, expo) {
        final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
        final dateFmt = DateFormat('d MMM yyyy, HH:mm');

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            appBar: AppBar(
              title: Text(expo!.name, overflow: TextOverflow.ellipsis),
              backgroundColor: const Color(0xFF1E1B4B),
              foregroundColor: Colors.white,
              bottom: const TabBar(
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Booths'),
                  Tab(text: 'Vendors'),
                  Tab(text: 'Visitors'),
                  Tab(text: 'Revenue'),
                  Tab(text: 'Staff'),
                ],
              ),
            ),
            body: OrganizerScreenBody(
              child: TabBarView(
                children: [
                  _OverviewTab(expo: expo, currency: currency, dateFmt: dateFmt),
                  _LinkTab(
                    title: 'Booth layout',
                    routes: ['/organizer/booth-layout-designer', '/organizer/booth-list', '/organizer/booth-pricing'],
                    labels: ['Layout designer', 'Booth list', 'Pricing'],
                  ),
                  _LinkTab(
                    title: 'Vendors',
                    routes: ['/organizer/vendor-directory', '/organizer/vendor-approval', '/organizer/vendor-payment'],
                    labels: ['Directory', 'Approvals', 'Payments'],
                  ),
                  _LinkTab(
                    title: 'Visitors',
                    routes: ['/organizer/visitor-registration', '/organizer/attendance-dashboard', '/organizer/expo-map'],
                    labels: ['Registration', 'Attendance', 'Expo map'],
                  ),
                  _RevenueTab(expo: expo, currency: currency),
                  _LinkTab(
                    title: 'Staff',
                    routes: ['/organizer/staff-assignment', '/organizer/staff-roles', '/organizer/live-staff-tracking'],
                    labels: ['Assignment', 'Roles', 'Live tracking'],
                  ),
                ],
              ),
            ),
            floatingActionButton: expo.status == ExpoStatus.ongoing
                ? FloatingActionButton.extended(
                    onPressed: () => Navigator.pushNamed(context, '/organizer/live-expo-dashboard'),
                    backgroundColor: Colors.redAccent,
                    icon: const Icon(Icons.sensors),
                    label: const Text('Live command'),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ExpoSummary expo;
  final NumberFormat currency;
  final DateFormat dateFmt;

  const _OverviewTab({
    required this.expo,
    required this.currency,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatGrid(),
        const SizedBox(height: 24),
        _buildInfoSection(
          'Location & Time',
          [
            _InfoTile(Icons.location_on, 'Venue', expo.venue),
            _InfoTile(Icons.calendar_today, 'Starts', dateFmt.format(expo.startAt)),
            _InfoTile(Icons.event, 'Ends', dateFmt.format(expo.endAt)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoSection(
          'Performance',
          [
            _InfoTile(
              Icons.pie_chart,
              'Booth occupancy',
              '${(expo.boothSalesProgress * 100).toStringAsFixed(1)}%',
              trailing: '${expo.boothsBooked} / ${expo.boothCapacity}',
            ),
            _InfoTile(
              Icons.trending_up,
              'Revenue per booth',
              currency.format(expo.boothsBooked > 0 ? expo.revenueRm / expo.boothsBooked : 0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard('Vendors', expo.vendorCount.toString(), Colors.blue),
        _StatCard('Visitors', expo.visitorRegistrations.toString(), Colors.orange),
        _StatCard('Tickets sold', expo.ticketsSold.toString(), Colors.green),
        _StatCard('Status', expo.status.name.toUpperCase(), Colors.purple),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailing;

  const _InfoTile(this.icon, this.label, this.value, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppTheme.primaryColor),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: trailing != null ? Text(trailing!, style: const TextStyle(fontSize: 13, color: Colors.grey)) : null,
      dense: true,
    );
  }
}

class _LinkTab extends StatelessWidget {
  final String title;
  final List<String> routes;
  final List<String> labels;

  const _LinkTab({
    required this.title,
    required this.routes,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...List.generate(routes.length, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(labels[index]),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.pushNamed(context, routes[index]),
            ),
          );
        }),
      ],
    );
  }
}

class _RevenueTab extends StatelessWidget {
  final ExpoSummary expo;
  final NumberFormat currency;

  const _RevenueTab({required this.expo, required this.currency});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('TOTAL REVENUE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(
                currency.format(expo.revenueRm),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildRevenueDetail('Payment Breakdown', [
          _RevenueRow('Received', expo.revenueRm - expo.pendingPaymentsRm, Colors.green, currency),
          _RevenueRow('Pending', expo.pendingPaymentsRm, Colors.orange, currency),
        ]),
        const SizedBox(height: 16),
        _buildRevenueDetail('Sales Metrics', [
          _RevenueRow('Tickets', (expo.ticketsSold * 10).toDouble(), Colors.blue, currency), // Assume RM10 per ticket
          _RevenueRow('Booths', expo.revenueRm - (expo.ticketsSold * 10), Colors.indigo, currency),
        ]),
      ],
    );
  }

  Widget _buildRevenueDetail(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;

  const _RevenueRow(this.label, this.amount, this.color, this.currency);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      title: Text(label),
      trailing: Text(currency.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
