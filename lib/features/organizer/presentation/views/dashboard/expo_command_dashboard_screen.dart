import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/organizer_screen_catalog.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_responsive_scaffold.dart';
import 'package:intl/intl.dart';

class ExpoCommandDashboardScreen extends StatelessWidget {
  const ExpoCommandDashboardScreen({super.key});

  static const routeName = '/organizer/expo-command-dashboard';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return OrganizerResponsiveScaffold(
      title: 'Expo Command',
      actions: [
        IconButton(
          tooltip: 'Company Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(
            context,
            '${OrganizerScreenCatalog.routePrefix}/company-settings',
          ),
        ),
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
                content: const Text('Are you sure you want to sign out from the Organizer Portal?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (confirmed == true && context.mounted) {
              await context.read<AuthProvider>().signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/organizer/login', (route) => false);
            }
          },
        ),
      ],
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoSummary>>(
          loader: () => OrganizerRepository.instance.fetchExpoSummaries(),
          isEmpty: (list) => false,
          builder: (context, expos) {
            final active = expos.where((e) => e.status == ExpoStatus.ongoing).toList();
            final upcoming = expos
                .where((e) => e.status == ExpoStatus.upcoming || e.status == ExpoStatus.draft)
                .toList();
            final totalRevenue = expos.fold<double>(0, (s, e) => s + e.revenueRm);
            final pending = expos.fold<double>(0, (s, e) => s + e.pendingPaymentsRm);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wedding Event Organizer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  Text(
                    'Operations overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _KpiGrid(
                    items: [
                      _KpiItem('Revenue', currency.format(totalRevenue), Icons.payments_outlined, AppTheme.successColor),
                      _KpiItem('Pending', currency.format(pending), Icons.pending_actions, AppTheme.warningColor),
                      _KpiItem('Active expos', '${active.length}', Icons.event_available, AppTheme.primaryColor),
                      _KpiItem('Upcoming', '${upcoming.length}', Icons.calendar_month, AppTheme.secondaryColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Active expos',
                    actionLabel: active.isNotEmpty ? 'View all' : null,
                    onAction: active.isNotEmpty ? () => Navigator.pushNamed(context, '/organizer/expo-list') : null,
                  ),
                  if (active.isEmpty)
                    const _EmptyCard(message: 'No expos running right now')
                  else
                    ...active.map((e) => _ExpoOverviewCard(expo: e)),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Upcoming expos',
                    actionLabel: upcoming.isNotEmpty ? 'View all' : null,
                    onAction: upcoming.isNotEmpty ? () => Navigator.pushNamed(context, '/organizer/expo-list') : null,
                  ),
                  if (upcoming.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                'No upcoming expos yet',
                                style: TextStyle(color: AppTheme.textSecondaryColor),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/organizer/create-expo'),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Create Your First Expo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...upcoming.take(2).map((e) => _ExpoOverviewCard(expo: e, compact: true)),
                  const SizedBox(height: 24),
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      label: 'Create expo',
                      icon: Icons.add_circle_outline,
                      onTap: () => Navigator.pushNamed(context, '/organizer/create-expo'),
                    ),
                    _QuickAction(
                      label: 'Manage booths',
                      icon: Icons.grid_view,
                      onTap: () => Navigator.pushNamed(context, '/organizer/booth-list'),
                    ),
                    _QuickAction(
                      label: 'Approve vendors',
                      icon: Icons.verified_user_outlined,
                      onTap: () => Navigator.pushNamed(context, '/organizer/vendor-approval'),
                    ),
                    _QuickAction(
                      label: 'View leads',
                      icon: Icons.people_alt_outlined,
                      onTap: () => Navigator.pushNamed(context, '/organizer/lead-collection'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiItem(this.label, this.value, this.icon, this.color);
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiItem> items;
  const _KpiGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: ResponsiveUtils.getGridColumnCount(context, mobile: 2, tablet: 4, desktop: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.6 : 1.8,
      children: items
          .map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: item.color, size: 22),
                    const Spacer(),
                    Text(
                      item.value,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(item.label, style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ExpoOverviewCard extends StatelessWidget {
  final ExpoSummary expo;
  final bool compact;
  const _ExpoOverviewCard({required this.expo, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final dateFmt = DateFormat('d MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/organizer/expo-detail',
          arguments: expo.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expo.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _StatusBadge(status: expo.status),
                ],
              ),
              const SizedBox(height: 4),
              Text('${expo.venue} · ${dateFmt.format(expo.startAt)}',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
              if (!compact) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: expo.boothSalesProgress,
                  backgroundColor: AppTheme.borderColor,
                  color: AppTheme.primaryColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  'Booths ${expo.boothsBooked}/${expo.boothCapacity} · ${currency.format(expo.revenueRm)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat(Icons.storefront, '${expo.vendorCount} vendors'),
                    const SizedBox(width: 16),
                    _MiniStat(Icons.person_add, '${expo.visitorRegistrations} regs'),
                    const SizedBox(width: 16),
                    _MiniStat(Icons.confirmation_number, '${expo.ticketsSold} tickets'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ExpoStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ExpoStatus.ongoing => ('Live', Colors.green),
      ExpoStatus.upcoming => ('Upcoming', AppTheme.primaryColor),
      ExpoStatus.draft => ('Draft', AppTheme.warningColor),
      ExpoStatus.cancelled => ('Cancelled', AppTheme.errorColor),
      ExpoStatus.past => ('Past', AppTheme.textSecondaryColor),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryColor),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.borderColor),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(message, style: TextStyle(color: AppTheme.textSecondaryColor))),
      ),
    );
  }
}
