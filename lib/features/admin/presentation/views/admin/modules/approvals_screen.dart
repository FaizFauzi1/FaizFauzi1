import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('All Approvals',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: admin.pendingApprovalVendors
            .map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ]),
                  child: ListTile(
                    leading: const Icon(Icons.business, color: AppTheme.primaryColor),
                    title: Text(v.name),
                    subtitle: Text('Category: ${v.category}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                          onPressed: () => admin.rejectVendor(v.id),
                          child: const Text('Reject',
                              style: TextStyle(color: AppTheme.errorColor))),
                      const SizedBox(width: 6),
                      ElevatedButton(
                          onPressed: () => admin.approveVendor(v.id),
                          child: const Text('Approve')),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }
}



