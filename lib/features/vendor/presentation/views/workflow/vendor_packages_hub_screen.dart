import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'collaborative_package_builder_screen.dart';
import 'collaborator_invitation_detail_screen.dart';

class VendorPackagesHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const VendorPackagesHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<VendorPackagesHubScreen> createState() => _VendorPackagesHubScreenState();
}

class _VendorPackagesHubScreenState extends State<VendorPackagesHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Collaborative Packages Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            tooltip: 'Create Package',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CollaborativePackageBuilderScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'My Packages'),
            Tab(text: 'Create Package'),
            Tab(text: 'Collaborative Packages'),
            Tab(text: 'Package Invitations'),
            Tab(text: 'Collaboration Requests'),
          ],
          onTap: (index) {
            if (index == 1) {
              // Create Package tab triggers the builder
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CollaborativePackageBuilderScreen()),
              );
              _tabController.index = 0;
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPackagesTab(),
          const Center(child: CircularProgressIndicator()), // Dummy tab for navigation
          _buildCollaborativePackagesTab(),
          _buildPackageInvitationsTab(),
          _buildCollaborationRequestsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: MY PACKAGES
  // ==========================================
  Widget _buildMyPackagesTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final packages = provider.packages;

        return packages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.all_inclusive, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Collaborative Packages Created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Bundle venue, catering, decor, and collaborator services.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CollaborativePackageBuilderScreen()),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Collaborative Package'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final pkg = packages[index];
                  final readyCount = pkg.readyComponentsCount;
                  final totalCount = pkg.totalComponentsCount;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: readyCount == totalCount ? Colors.green.shade50 : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$readyCount of $totalCount components ready',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: readyCount == totalCount ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ),
                            Text(
                              'Base: RM ${pkg.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(pkg.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(pkg.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCount == 0 ? 0 : readyCount / totalCount,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(readyCount == totalCount ? AppTheme.successColor : AppTheme.accentColor),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Components tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: pkg.components.map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.isFixedVendor ? Colors.blue.shade50 : Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(c.category.iconData, size: 12, color: c.isFixedVendor ? Colors.blue : Colors.purple),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${c.componentName} (${c.isFixedVendor ? "Fixed" : "${c.approvedCollaborators.length} choices"})',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: c.isFixedVendor ? Colors.blue.shade900 : Colors.purple.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const Divider(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CollaborativePackageBuilderScreen(existingPackage: pkg),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit Package & Collaborators', style: TextStyle(fontSize: 11)),
                            ),
                            Text(
                              'Created by ${pkg.ownerVendorName}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
      },
    );
  }

  // ==========================================
  // TAB 3: COLLABORATIVE PACKAGES (Participating)
  // ==========================================
  Widget _buildCollaborativePackagesTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final acceptedInvites = provider.invitations.where((i) => i.status == CollaborationStatus.offerSubmitted).toList();

        return acceptedInvites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handshake_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Joint Packages Active', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Accept invitations from other vendors to contribute your service.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: acceptedInvites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inv = acceptedInvites[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                              child: const Text('Active Collaborator', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            ),
                            Text('Allowance: RM ${inv.packageAllowance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(inv.packageName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Owner: ${inv.ownerVendorName} · Role: ${inv.roleComponentName}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Offered: ${inv.offeredServiceName ?? inv.roleComponentName}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('Partner Price: RM ${inv.partnerPriceOffered?.toStringAsFixed(0) ?? inv.packageAllowance.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
      },
    );
  }

  // ==========================================
  // TAB 4: PACKAGE INVITATIONS (Incoming)
  // ==========================================
  Widget _buildPackageInvitationsTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final incoming = provider.invitations;

        return incoming.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Incoming Invitations', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Invitations from other vendors to join packages will appear here.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: incoming.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inv = incoming[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CollaboratorInvitationDetailScreen(invitation: inv),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: inv.status.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  inv.status.displayName,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: inv.status.color),
                                ),
                              ),
                              Text(
                                'RM ${inv.packageAllowance.toStringAsFixed(0)} allowance',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(inv.packageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Host: ${inv.ownerVendorName} · Target Role: ${inv.roleComponentName}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.event_outlined, size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(inv.eventDate, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 14),
                              const Icon(Icons.place_outlined, size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(inv.location, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                inv.requestedAppointmentTypes.isNotEmpty
                                    ? 'Appts requested: ${inv.requestedAppointmentTypes.join(", ")}'
                                    : 'No pre-booking appts requested',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
      },
    );
  }

  // ==========================================
  // TAB 5: COLLABORATION REQUESTS (Sent)
  // ==========================================
  Widget _buildCollaborationRequestsTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final packages = provider.packages;
        final List<Map<String, dynamic>> sentRequests = [];

        for (final p in packages) {
          for (final comp in p.components) {
            for (final col in comp.approvedCollaborators) {
              sentRequests.add({
                'packageName': p.title,
                'componentName': comp.componentName,
                'vendorName': col.vendorName,
                'partnerPrice': col.partnerPrice,
                'priceDelta': col.priceDelta,
                'status': 'Approved in Package',
              });
            }
          }
        }

        return sentRequests.isEmpty
            ? const Center(child: Text('No outgoing requests sent yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sentRequests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final req = sentRequests[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req['vendorName'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('${req['componentName']} · ${req['packageName']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text(req['status'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ),
                  );
                },
              );
      },
    );
  }
}
