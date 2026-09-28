import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_profile_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_document_management_screen_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';

/// Actionable "what you still need to do" card for incomplete vendor profiles.
class VendorSetupChecklist extends StatelessWidget {
  const VendorSetupChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<VendorProfileProvider, VendorProvider>(
      builder: (context, profileProvider, vendorProvider, _) {
        final status = profileProvider.profileStatus;
        if (status == 'approved' || status == 'complete') {
          // Still show if checklist has incomplete service task
        }

        final serviceCount = vendorProvider.getCurrentVendorServices().length;
        final tasks = profileProvider.getSetupChecklist(serviceCount: serviceCount);
        if (tasks.isEmpty) return const SizedBox.shrink();

        final incomplete = tasks.where((t) => !t.done).toList();
        if (incomplete.isEmpty) return const SizedBox.shrink();

        // Hide when fully approved and only cosmetic leftovers — still show pending_review / incomplete
        if (status != 'incomplete' && status != 'pending_review' && incomplete.every((t) => t.id == 'first_service') == false) {
          if (status == 'approved' && incomplete.isEmpty) return const SizedBox.shrink();
        }
        if (status == 'approved' && incomplete.isEmpty) return const SizedBox.shrink();

        final doneCount = tasks.where((t) => t.done).length;
        final pct = (doneCount / tasks.length * 100).round();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist, color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Complete your profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: doneCount / tasks.length,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${incomplete.length} step${incomplete.length == 1 ? '' : 's'} remaining',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              ...incomplete.take(5).map((task) => _TaskTile(task: task)),
            ],
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final VendorSetupTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        task.done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: task.done ? AppTheme.successColor : AppTheme.primaryColor,
        size: 22,
      ),
      title: Text(
        task.label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _openTask(context, task),
    );
  }

  void _openTask(BuildContext context, VendorSetupTask task) {
    final vendor = Provider.of<VendorProvider>(context, listen: false).currentVendor;

    switch (task.deepLink) {
      case VendorSetupDeepLink.profileTab:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorProfileScreen()),
        );
        break;
      case VendorSetupDeepLink.documents:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VendorDocumentManagementScreenEnhanced()),
        );
        break;
      case VendorSetupDeepLink.addService:
        if (vendor == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedServiceCreationScreen(vendorId: vendor.id),
          ),
        );
        break;
    }
  }
}
