import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class ExpoListScreen extends StatefulWidget {
  const ExpoListScreen({super.key});

  static const routeName = '/organizer/expo-list';

  @override
  State<ExpoListScreen> createState() => _ExpoListScreenState();
}

class _ExpoListScreenState extends State<ExpoListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<ExpoSummary> _filtered(List<ExpoSummary> expos, int index) {
    return switch (index) {
      0 => expos
          .where((e) => e.status == ExpoStatus.upcoming || e.status == ExpoStatus.draft)
          .toList(),
      1 => expos.where((e) => e.status == ExpoStatus.ongoing).toList(),
      _ => expos
          .where((e) => e.status == ExpoStatus.past || e.status == ExpoStatus.cancelled)
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expos'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, '/organizer/create-expo');
          if (res == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Create expo'),
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoSummary>>(
          loader: () => OrganizerRepository.instance.fetchExpoSummaries(),
          builder: (context, expos) {
            return TabBarView(
              controller: _tabs,
              children: List.generate(3, (index) {
                final list = _filtered(expos, index);
                if (list.isEmpty) {
                  return const Center(child: Text('No expos in this category'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ExpoListTile(expo: list[i]),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _ExpoListTile extends StatelessWidget {
  final ExpoSummary expo;
  const _ExpoListTile({required this.expo});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(expo.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${expo.venue}\n${dateFmt.format(expo.startAt)} – ${dateFmt.format(expo.endAt)}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currency.format(expo.revenueRm), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${expo.boothsBooked}/${expo.boothCapacity} booths', style: const TextStyle(fontSize: 11)),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/organizer/expo-detail', arguments: expo.id),
      ),
    );
  }
}
