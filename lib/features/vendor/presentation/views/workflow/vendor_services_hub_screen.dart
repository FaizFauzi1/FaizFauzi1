import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/presentation/views/service_creation/open_vendor_service_creation.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_responsive_scaffold.dart';
import 'appointment_detail_and_outcome_screen.dart';

class VendorServicesHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const VendorServicesHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<VendorServicesHubScreen> createState() => _VendorServicesHubScreenState();
}

class _VendorServicesHubScreenState extends State<VendorServicesHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  ServiceCategoryType? _filterCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendor = Provider.of<VendorProvider>(context, listen: false).currentVendor;
      if (vendor != null) {
        Provider.of<VendorWorkflowProvider>(context, listen: false)
            .loadLiveData(vendor.id, vendor.name);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VendorResponsiveScaffold(
      title: 'Services & Appointments',
      actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            tooltip: 'Add New Service',
            onPressed: () => openVendorServiceCreation(context),
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
            Tab(text: 'My Services'),
            Tab(text: 'Add Service'),
            Tab(text: 'Service Packages'),
            Tab(text: 'Availability'),
            Tab(text: 'Appointments'),
          ],
          onTap: (index) {
            if (index == 1) {
              openVendorServiceCreation(context);
              _tabController.index = 0;
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyServicesTab(),
          const Center(child: CircularProgressIndicator()), // Add Service dummy while navigating
          _buildServicePackagesTab(),
          _buildAvailabilityTab(),
          _buildAppointmentsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: MY SERVICES
  // ==========================================
  Widget _buildMyServicesTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final services = provider.services.where((s) {
          final matchesQuery = _searchQuery.isEmpty ||
              s.serviceName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.description.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCat = _filterCategory == null || s.category == _filterCategory;
          return matchesQuery && matchesCat;
        }).toList();

        return Column(
          children: [
            // Search & Category Filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search my services...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Categories'),
                          selected: _filterCategory == null,
                          onSelected: (_) => setState(() => _filterCategory = null),
                        ),
                        ...ServiceCategoryType.values.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: FilterChip(
                              label: Text(cat.displayName),
                              selected: _filterCategory == cat,
                              onSelected: (_) => setState(() => _filterCategory = cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Services List
            Expanded(
              child: services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No Services Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Create your first service to start offering to customers.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => openVendorServiceCreation(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Service'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: services.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final s = services[index];
                        final packages = provider.getPackagesForService(s.id);
                        final appts = provider.getAppointmentTypesForService(s.id);

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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: s.category.brandColor.withOpacity(0.12),
                                    child: Icon(s.category.iconData, color: s.category.brandColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              s.category.displayName.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: s.category.brandColor,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: s.status.color.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                s.status.displayName,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: s.status.color,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          s.serviceName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (s.subcategory.isNotEmpty)
                                          Text(
                                            s.subcategory,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 12),

                              // Quick metrics
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.sell_outlined, size: 12, color: AppTheme.primaryColor),
                                        const SizedBox(width: 4),
                                        Text('From RM ${s.startingPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.inventory_2_outlined, size: 12, color: AppTheme.primaryColor),
                                        const SizedBox(width: 4),
                                        Text('${packages.length} Packages', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: appts.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined,
                                            size: 12, color: appts.isNotEmpty ? Colors.blue.shade700 : Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${appts.length} Appt Types',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: appts.isNotEmpty ? Colors.blue.shade700 : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              // Action Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () => openVendorServiceCreation(context, serviceId: s.id),
                                        icon: const Icon(Icons.edit, size: 14),
                                        label: const Text('Edit Service', style: TextStyle(fontSize: 11)),
                                      ),
                                      const SizedBox(width: 8),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18),
                                        onSelected: (val) {
                                          if (val == 'pause') {
                                            provider.updateServiceStatus(
                                              s.id,
                                              s.status == ServiceStatus.published ? ServiceStatus.paused : ServiceStatus.published,
                                            );
                                          } else if (val == 'delete') {
                                            provider.deleteService(s.id);
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'pause',
                                            child: Text(s.status == ServiceStatus.published ? 'Pause Service' : 'Publish Service'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete Service', style: TextStyle(color: AppTheme.errorColor)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {
                                      _tabController.animateTo(2); // Jump to packages tab
                                    },
                                    child: const Text('Manage Packages', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 3: SERVICE PACKAGES
  // ==========================================
  Widget _buildServicePackagesTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final services = provider.services;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, idx) {
            final s = services[idx];
            final packages = provider.getPackagesForService(s.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                      Row(
                        children: [
                          Icon(s.category.iconData, color: s.category.brandColor, size: 20),
                          const SizedBox(width: 8),
                          Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => openVendorServiceCreation(context, serviceId: s.id),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Package Tier', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (packages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No tiered packages defined for this service.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    )
                  else
                    ...packages.map((pkg) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pkg.packageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(pkg.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Text('Duration: ${pkg.duration}', style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(
                              'RM ${pkg.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 4: AVAILABILITY & WORKING HOURS
  // ==========================================
  Widget _buildAvailabilityTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final services = provider.services;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = services[index];
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
                  Text(s.serviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text('Working Hours: ${s.workingHoursStart} - ${s.workingHoursEnd}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.date_range, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text('Min Notice: ${s.minBookingNoticeDays} days', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: s.availableDays.map((d) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      );
                    }).toList(),
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
  // TAB 5: APPOINTMENTS
  // ==========================================
  Widget _buildAppointmentsTab() {
    return Consumer<VendorWorkflowProvider>(
      builder: (context, provider, _) {
        final appointments = provider.appointments;
        final dateFormat = DateFormat('EEE, dd MMM yyyy');

        return appointments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Appointments Scheduled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Customer consultations, food tastings, and fittings will appear here.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final appt = appointments[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailAndOutcomeScreen(appointment: appt),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
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
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: appt.status.color.withOpacity(0.12),
                                    child: Icon(appt.purpose.iconData, size: 14, color: appt.status.color),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appt.appointmentTypeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: appt.status.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  appt.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: appt.status.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Client: ${appt.customerName} · Event: ${appt.eventName ?? "Event"}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.event, size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(dateFormat.format(appt.scheduledDate), style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 14),
                              const Icon(Icons.access_time, size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text('${appt.scheduledTime} (${appt.durationMinutes} min)', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                appt.fee > 0 ? 'Fee: RM ${appt.fee.toStringAsFixed(0)} (Creditable)' : 'Free Session',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: appt.fee > 0 ? Colors.amber.shade800 : Colors.green.shade800,
                                ),
                              ),
                              Row(
                                children: [
                                  if (appt.outcomeStatus != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                      child: Text(
                                        'Outcome: ${appt.outcomeStatus}',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                ],
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
    );
  }
}
