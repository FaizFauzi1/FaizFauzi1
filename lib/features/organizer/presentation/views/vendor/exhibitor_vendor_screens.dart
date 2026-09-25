import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:intl/intl.dart';

Future<List<ExhibitorVendor>> _loadExhibitors({ExhibitorStatus? status}) async {
  final expoId = await OrganizerRepository.instance.resolveExpoId();
  if (expoId == null) return [];
  return OrganizerRepository.instance.fetchExhibitors(expoId, status: status);
}

// --- Vendor Application (organizer view of incoming) ---

class VendorApplicationScreen extends StatelessWidget {
  const VendorApplicationScreen({super.key});
  static const routeName = '/organizer/vendor-application';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Applications'),
      body: OrganizerAsyncBody<List<ExhibitorVendor>>(
        loader: () => _loadExhibitors(status: ExhibitorStatus.pending),
        isEmpty: (list) => list.isEmpty,
        emptyWidget: const Center(child: Text('No pending applications')),
        builder: (context, pending) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final v = pending[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(v.companyName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${v.category} · ${v.packageName ?? 'Standard'}\nRequested: ${v.boothNumber ?? 'TBD'}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, VendorApprovalScreen.routeName),
            ),
          );
            },
          );
        },
      ),
    );
  }
}

// --- Vendor Approval ---

class VendorApprovalScreen extends StatefulWidget {
  const VendorApprovalScreen({super.key});
  static const routeName = '/organizer/vendor-approval';

  @override
  State<VendorApprovalScreen> createState() => _VendorApprovalScreenState();
}

class _VendorApprovalScreenState extends State<VendorApprovalScreen> {
  Future<void> _reject(ExhibitorVendor v) async {
    try {
      await OrganizerRepository.instance.updateExhibitorStatus(v.id, ExhibitorStatus.rejected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected ${v.companyName}')));
      setState(() {});
    } catch (e, st) {
      debugPrint('Reject exhibitor failed: $e\\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject ${v.companyName}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _openRequestInfoDialog(ExhibitorVendor v) async {
    final messageCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request More Info: ${v.companyName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify what documents or details the exhibitor needs to submit:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Please provide SSM registration copy and product catalog with price list.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, messageCtrl.text.trim()),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await OrganizerRepository.instance.requestMoreInfo(v.id, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Information request sent to ${v.companyName}')),
        );
        setState(() {});
      } catch (e, st) {
        debugPrint('Request info failed: $e\\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send info request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _openApproveDialog(ExhibitorVendor v) async {
    final boothCtrl = TextEditingController(text: v.boothNumber ?? 'A-05');
    DateTime deadline = DateTime.now().add(const Duration(days: 7));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Approve ${v.companyName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assign booth number and payment deadline for this vendor:'),
              const SizedBox(height: 12),
              TextField(
                controller: boothCtrl,
                decoration: const InputDecoration(
                  labelText: 'Assigned Booth Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Due: ${DateFormat('dd MMM yyyy').format(deadline)}'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deadline,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) setModalState(() => deadline = picked);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor),
              child: const Text('Confirm Approval'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await OrganizerRepository.instance.approveExhibitor(
          v.id,
          boothNumber: boothCtrl.text.trim().isNotEmpty ? boothCtrl.text.trim() : null,
          paymentDeadline: deadline,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved ${v.companyName}')),
        );
        setState(() {});
      } catch (e, st) {
        debugPrint('Approve exhibitor failed: $e\\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve ${v.companyName}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Review Exhibitor Applications'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExhibitorVendor>>(
          loader: () async {
            final all = await _loadExhibitors();
            return all.where((v) =>
                v.status == ExhibitorStatus.pending ||
                v.status == ExhibitorStatus.underReview ||
                v.status == ExhibitorStatus.infoRequested).toList();
          },
          isEmpty: (list) => list.isEmpty,
          emptyWidget: const Center(child: Text('No applications awaiting review')),
          builder: (context, pending) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, i) {
                final v = pending[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                v.companyName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            ),
                            ExhibitorStatusChip(status: v.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${v.category} · Contact: ${v.contactName}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                        Text('${v.phone} · ${v.email}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('Package: ${v.packageName ?? "Standard"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(width: 12),
                            Text('Preferred: ${v.boothNumber ?? "Any"}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),

                        // Info requested or vendor response notes
                        if (v.infoResponseMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Vendor Clarification Response:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF065F46))),
                                const SizedBox(height: 2),
                                Text(v.infoResponseMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFF047857))),
                              ],
                            ),
                          ),
                        ] else if (v.infoRequestMessage != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pending Information from Vendor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF92400E))),
                                const SizedBox(height: 2),
                                Text(v.infoRequestMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => _reject(v),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _openRequestInfoDialog(v),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('Request Info'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => _openApproveDialog(v),
                              icon: const Icon(Icons.check, size: 16),
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor),
                              label: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- Vendor Directory ---

class VendorDirectoryScreen extends StatefulWidget {
  const VendorDirectoryScreen({super.key});
  static const routeName = '/organizer/vendor-directory';

  @override
  State<VendorDirectoryScreen> createState() => _VendorDirectoryScreenState();
}

class _VendorDirectoryScreenState extends State<VendorDirectoryScreen> {
  String _query = '';

  List<ExhibitorVendor> _filtered(List<ExhibitorVendor> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((v) =>
            v.companyName.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Directory'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExhibitorVendor>>(
          loader: () => _loadExhibitors(status: ExhibitorStatus.approved),
          builder: (context, all) {
            final filtered = _filtered(all);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search exhibitors...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final v = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: Text(v.companyName[0], style: const TextStyle(color: AppTheme.primaryColor)),
                          ),
                          title: Text(v.companyName),
                          subtitle: Text('${v.category} · Booth ${v.boothNumber ?? '—'}'),
                          trailing: PaymentStatusChip(status: v.paymentStatus),
                          onTap: () => Navigator.pushNamed(context, VendorDetailScreen.routeName, arguments: v.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- Vendor Detail ---

class VendorDetailScreen extends StatelessWidget {
  const VendorDetailScreen({super.key, this.vendorId});

  final String? vendorId;
  static const routeName = '/organizer/vendor-detail';

  @override
  Widget build(BuildContext context) {
    final id = vendorId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vendor')),
        body: OrganizerScreenBody(child: const Center(child: Text('No vendor selected'))),
      );
    }

    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return OrganizerAsyncBody<ExhibitorVendor?>(
      loader: () => OrganizerRepository.instance.fetchExhibitor(id),
      isEmpty: (v) => v == null,
      emptyWidget: const Center(child: Text('Vendor not found')),
      builder: (context, v) {
        return Scaffold(
          appBar: AppBar(
            title: Text(v!.companyName, overflow: TextOverflow.ellipsis),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  ExhibitorStatusChip(status: v.status),
                  const SizedBox(width: 8),
                  PaymentStatusChip(status: v.paymentStatus),
                ],
              ),
              const SizedBox(height: 20),
              _InfoSection('Company', [
                _InfoRow('Category', v.category),
                _InfoRow('Contact', v.contactName),
                _InfoRow('Phone', v.phone),
                _InfoRow('Email', v.email),
              ]),
              _InfoSection('Expo participation', [
                _InfoRow('Booth', v.boothNumber ?? 'Not assigned'),
                _InfoRow('Package', v.packageName ?? '—'),
                _InfoRow('Booth fee', currency.format(v.boothFeeRm)),
                _InfoRow('Paid', currency.format(v.paidRm)),
                if (v.outstandingRm > 0) _InfoRow('Outstanding', currency.format(v.outstandingRm)),
              ]),
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.description_outlined,
                title: 'Participation contract',
                onTap: () => Navigator.pushNamed(context, VendorContractScreen.routeName, arguments: v.id),
              ),
              _NavTile(
                icon: Icons.payments_outlined,
                title: 'Payment & booth fees',
                onTap: () => Navigator.pushNamed(context, VendorPaymentScreen.routeName, arguments: v.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoSection(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(leading: Icon(icon, color: AppTheme.primaryColor), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap),
    );
  }
}

// --- Vendor Contract ---

class VendorContractScreen extends StatelessWidget {
  const VendorContractScreen({super.key});
  static const routeName = '/organizer/vendor-contract';

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;

    return OrganizerAsyncBody<ExhibitorVendor?>(
      loader: () => id != null ? OrganizerRepository.instance.fetchExhibitor(id) : Future.value(null),
      isEmpty: (v) => v == null,
      emptyWidget: const Center(child: Text('Vendor not found')),
      builder: (context, v) {
        return Scaffold(
          appBar: const OrganizerAppBar(title: 'Vendor Contract'),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Expo Participation Agreement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${v!.companyName} · Booth ${v.boothNumber ?? 'TBD'}'),
              const SizedBox(height: 24),
              const Text(
                'This agreement confirms exhibitor participation in the bridal fair, including booth allocation, setup/teardown windows, lead data policies, and payment terms.\n\n'
                '[Contract body placeholder — connect to document generator and e-sign.]',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      icon: const Icon(Icons.draw),
                      label: const Text('Send for sign'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Vendor Payment ---

class VendorPaymentScreen extends StatelessWidget {
  const VendorPaymentScreen({super.key});
  static const routeName = '/organizer/vendor-payment';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Payments'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExhibitorVendor>>(
          loader: () => _loadExhibitors(status: ExhibitorStatus.approved),
          builder: (context, all) {
            final vendors = all.where((v) => v.paymentStatus != PaymentStatus.paid).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppTheme.warningColor.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppTheme.warningColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${vendors.length} vendors with outstanding booth fees',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...vendors.map((v) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(v.companyName),
                        subtitle: Text(
                          'Booth ${v.boothNumber ?? '—'} · Paid ${currency.format(v.paidRm)} / ${currency.format(v.boothFeeRm)}',
                        ),
                        trailing: PaymentStatusChip(status: v.paymentStatus),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Record payment for ${v.companyName}')),
                          );
                        },
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}
