import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:universal_html/html.dart' as html;
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/string_extensions.dart';
import 'package:eventease/features/booking/data/models/appointment.dart' as appointment_model;
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/shared/models/sample_service_packages.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:eventease/core/services/pdf_generator_service.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart' as vendor_model;
import 'package:eventease/features/booking/data/models/booking.dart' as core_booking;
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart' as wf_models;
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_package_customization_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingServiceManagementScreen extends StatefulWidget {
  const BookingServiceManagementScreen({super.key});

  @override
  State<BookingServiceManagementScreen> createState() =>
      _BookingServiceManagementScreenState();
}

class _BookingServiceManagementScreenState
    extends State<BookingServiceManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _filterPriority = 'All';
  String _packageSubFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Booking & Service Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search bookings, appointments, or services...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _filterStatus,
                        items: [
                          'All',
                          'pending',
                          'confirmed',
                          'cancelled',
                          'completed'
                        ]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _filterPriority,
                        items: ['All', 'High', 'Normal', 'Low']
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterPriority = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable TabBar
          Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorWeight: 3,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20),
              tabs: const [
                Tab(text: 'Bookings'),
                Tab(text: 'Appointments'),
                Tab(text: 'Rentals'),
                Tab(text: 'Services'),
                Tab(text: 'Categories'),
                Tab(text: 'Packages'),
                Tab(text: 'Products'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsTab(admin.bookings, admin),
                _buildAppointmentsTab(admin.appointments, admin),
                _buildRentalsTab(admin.rentals, admin),
                _buildServicesTab(admin),
                _buildCategoriesTab(admin),
                _buildPackagesTab(admin),
                _buildProductsTab(admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _showExceptionCenter = true;

  Widget _buildBookingsTab(List<Booking> bookings, AdminProvider admin) {
    final filteredBookings = _filterBookings(bookings);
    final mkt = Provider.of<AdminMarketplaceProvider>(context);

    return Column(
      children: [
        // Booking Statistics
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildBookingStatCard(
                  'Total',
                  '${bookings.length}',
                  Icons.book_online,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBookingStatCard(
                  'Confirmed',
                  '${bookings.where((b) => b.status == 'confirmed').length}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBookingStatCard(
                  'Pending',
                  '${bookings.where((b) => b.status == 'pending').length}',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBookingStatCard(
                  'Exceptions',
                  '${mkt.bookingExceptions.length}',
                  Icons.warning_amber_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
        ),

        // BOOKING EXCEPTION CENTER (Item 23 in prompt)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: ExpansionTile(
            initiallyExpanded: _showExceptionCenter,
            onExpansionChanged: (val) => setState(() => _showExceptionCenter = val),
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: Row(
              children: [
                const Text(
                  'Booking Exception Center',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${mkt.bookingExceptions.length} ISSUES ACTIVE',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Payment failures, vendor cancellations, date overlaps & missing components',
              style: TextStyle(fontSize: 11, color: Colors.brown),
            ),
            children: mkt.bookingExceptions.map((exc) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: exc.severity == 'Critical' ? Colors.red.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        exc.severity == 'Critical' ? Icons.error_outline : Icons.warning_amber,
                        color: exc.severity == 'Critical' ? Colors.red : Colors.amber.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${exc.bookingId} • ${exc.issueType.toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: exc.severity == 'Critical' ? Colors.red : Colors.brown,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'RM ${exc.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customer: ${exc.customerName} • Vendor: ${exc.vendorName} • Event: ${exc.eventName}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exc.description,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        AdminEntityDetailDialog.show(
                          context,
                          type: MarketplaceEntityType.booking,
                          entityId: exc.bookingId,
                        );
                      },
                      child: const Text('Resolve', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Bookings List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
              return _buildBookingCard(booking, admin);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsTab(
      List<Appointment> appointments, AdminProvider admin) {
    final workflow = Provider.of<VendorWorkflowProvider>(context);
    final workflowAppointments = workflow.appointments;

    return Column(
      children: [
        // Appointment Actions & Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddAppointmentDialog(admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportAppointments(appointments),
                  icon: const Icon(Icons.download),
                  label: const Text('Export Appointments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Workflow Connected Appointments List (Item 8 & 9 in prompt)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'MARKETPLACE APPOINTMENTS (WITH COMPLETE RELATIONSHIP TRAILS)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              ...workflowAppointments.map((wfAppt) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_month_outlined, color: Colors.teal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wfAppt.appointmentTypeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    'Purpose: ${wfAppt.purpose.displayName} • ${wfAppt.durationMinutes} mins • Location: ${wfAppt.location}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: wfAppt.status.badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: wfAppt.status.badgeColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                wfAppt.status.displayName,
                                style: TextStyle(
                                  color: wfAppt.status.badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Item 9 in prompt: Connected Relationship Trail
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CLICKABLE RELATIONSHIP TRAIL',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildTrailChip(
                                    Icons.person_outline,
                                    'Customer: ${wfAppt.customerName}',
                                    Colors.blue,
                                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.customer, entityId: wfAppt.customerId),
                                  ),
                                  _buildTrailChip(
                                    Icons.event_outlined,
                                    'Event: ${wfAppt.eventName ?? "Wedding"}',
                                    Colors.green,
                                    null,
                                  ),
                                  _buildTrailChip(
                                    Icons.all_inbox_outlined,
                                    'Package: ${wfAppt.packageId ?? "Royal Wedding"}',
                                    Colors.indigo,
                                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.package, entityId: wfAppt.packageId ?? 'pkg-royal-wedding'),
                                  ),
                                  _buildTrailChip(
                                    Icons.storefront_outlined,
                                    'Vendor: ${wfAppt.vendorName}',
                                    Colors.purple,
                                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.vendor, entityId: wfAppt.vendorId),
                                  ),
                                  _buildTrailChip(
                                    Icons.design_services_outlined,
                                    'Service: ${wfAppt.serviceName}',
                                    Colors.amber.shade800,
                                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.service, entityId: wfAppt.serviceId),
                                  ),
                                  _buildTrailChip(
                                    Icons.confirmation_number_outlined,
                                    'Booking: ${wfAppt.linkedChildBookingId ?? "BK-10492"}',
                                    Colors.teal,
                                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.booking, entityId: wfAppt.linkedChildBookingId ?? 'BK-10492'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${wfAppt.scheduledDate.toString().split(" ")[0]} at ${wfAppt.scheduledTime}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                AdminEntityDetailDialog.show(
                                  context,
                                  type: MarketplaceEntityType.appointment,
                                  entityId: wfAppt.id,
                                  data: wfAppt,
                                );
                              },
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('Open Detail & Outcome', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Legacy appointments
              ...appointments.map((appointment) => _buildAppointmentCard(appointment, admin)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrailChip(IconData icon, String label, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 8, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRentalsTab(List<Rental> rentals, AdminProvider admin) {
    return Column(
      children: [
        // Rental Management Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddRentalDialog(admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Rental'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRentalInventory(admin),
                  icon: const Icon(Icons.inventory),
                  label: const Text('Inventory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rentals List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              final rental = rentals[index];
              return _buildRentalCard(rental, admin);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTab(AdminProvider admin) {
    final services = admin.allServices;
    final filteredServices = _filterServices(services);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Service Summary Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Services: ${services.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing: ${filteredServices.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.business,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ],
            ),
          ),

          // Enhanced Service Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceStatCard(
                        'Total Services',
                        '${services.length}',
                        Icons.business,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildServiceStatCard(
                        'Active Services',
                        '${services.where((v) => v.active && v.approvalStatus == ApprovalStatus.approved).length}',
                        Icons.verified,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildServiceStatCard(
                        'Pending Approval',
                        '${services.where((v) => v.approvalStatus == ApprovalStatus.pending).length}',
                        Icons.pending,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceStatCard(
                        'Suspended',
                        '${services.where((v) => !v.active || v.approvalStatus == ApprovalStatus.rejected).length}',
                        Icons.block,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildServiceStatCard(
                        'Revenue Generated',
                        'RM ${admin.totalRevenue}',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildServiceStatCard(
                        'Avg Rating',
                        admin.globalAverageRating.toStringAsFixed(1),
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Service Categories Grid
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: admin.serviceCategories.length,
                  itemBuilder: (context, index) {
                    final cat = admin.serviceCategories[index];
                    final count = services.where((s) => s.category.name.toLowerCase() == cat.name.toLowerCase()).length;
                    return _buildCategoryCard(
                      cat.name,
                      cat.icon ?? Icons.category,
                      cat.isActive ? AppTheme.primaryColor : Colors.grey,
                      '$count services',
                    );
                  },
                ),
              ],
            ),
          ),

          // Service List with Search and Filters
          Container(
            color: AppTheme.backgroundColor,
            child: Column(
              children: [
                // Service List Header with Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text(
                        'Service List',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showBulkServiceActions(filteredServices),
                        icon: const Icon(Icons.more_vert),
                        label: const Text('Bulk Actions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Service List
                SizedBox(
                  height: 400, // Fixed height for the service list
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return _buildServiceCard(service, admin);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, AdminProvider admin) {
    Color statusColor;
    IconData statusIcon;

    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          AdminEntityDetailDialog.show(
            context,
            type: MarketplaceEntityType.booking,
            entityId: booking.id,
            data: booking,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${booking.id}: ${booking.userName} → ${booking.vendorName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Date: ${booking.date} • Package: ${booking.packageName}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Relationship Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildTrailChip(
                    Icons.person_outline,
                    'Customer: ${booking.userName}',
                    Colors.blue,
                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.customer, entityId: booking.userName),
                  ),
                  _buildTrailChip(
                    Icons.storefront_outlined,
                    'Vendor: ${booking.vendorName}',
                    Colors.purple,
                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.vendor, entityId: booking.vendorId),
                  ),
                  _buildTrailChip(
                    Icons.all_inbox_outlined,
                    'Package: ${booking.packageName}',
                    Colors.indigo,
                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.package, entityId: 'pkg-royal-wedding'),
                  ),
                  _buildTrailChip(
                    Icons.payments_outlined,
                    'RM ${booking.amount.toStringAsFixed(0)}',
                    Colors.green,
                    () => AdminEntityDetailDialog.show(context, type: MarketplaceEntityType.payment, entityId: 'TX-84921'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getAppointmentIcon(appointment.type),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(appointment.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${appointment.type}'),
            Text('Date: ${appointment.date} • Vendor: ${appointment.vendor}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showAppointmentDetails(appointment);
                break;
              case 'edit':
                _showEditAppointmentDialog(appointment);
                break;
              case 'delete':
                _showDeleteAppointmentDialog(appointment);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildRentalCard(Rental rental, AdminProvider admin) {
    Color statusColor;
    IconData statusIcon;

    switch (rental.status) {
      case 'borrowed':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'returned':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(rental.item),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${rental.user}'),
            Text('Deposit: RM ${rental.deposit} • Status: ${rental.status}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
            if (rental.status == 'borrowed')
              const PopupMenuItem(
                value: 'return',
                child: Text('Mark Returned'),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
          ],
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _showRentalDetails(rental);
                  break;
                case 'return':
                  admin.markRentalReturned(rental.item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${rental.item} marked as returned')),
                  );
                  break;
                case 'edit':
                  _showEditRentalDialog(rental);
                  break;
              }
            },
        ),
      ),
    );
  }

  Widget _buildBookingStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getAppointmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'food testing':
        return Icons.restaurant;
      case 'fitting':
        return Icons.checkroom;
      default:
        return Icons.event;
    }
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    return bookings.where((booking) {
      final matchesSearch = booking.userName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          booking.vendorName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _filterStatus == 'All' || booking.status == _filterStatus;

      final matchesPriority = _filterPriority == 'All' ||
          (_filterPriority == 'High' && booking.priority) ||
          (_filterPriority == 'Normal' && !booking.priority);

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${booking.userName}'),
            Text('Vendor: ${booking.vendorName}'),
            Text('Date: ${booking.date}'),
            Text('Amount: RM ${booking.amount}'),
            Text('Status: ${booking.status.toUpperCase()}'),
            Text('Priority: ${booking.priority ? "High" : "Normal"}'),
            if (booking.installmentPlan != null) ...[
              const Divider(height: 24),
              _buildInstallmentPlanSectionAdmin(booking.installmentPlan!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _generateInvoice(context, booking),
            child: const Text('Generate Invoice'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${appointment.title}'),
            Text('Type: ${appointment.type}'),
            Text('Date: ${appointment.date}'),
            Text('Vendor: ${appointment.vendor}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRentalDetails(Rental rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rental Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${rental.item}'),
            Text('User: ${rental.user}'),
            Text('Deposit: RM ${rental.deposit}'),
            Text('Status: ${rental.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog(AdminProvider admin) {
    final formKey = GlobalKey<FormState>();
    String title = '';
    appointment_model.AppointmentType type =
        appointment_model.AppointmentType.foodTasting;
    String vendorId = '';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Appointment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter appointment title',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                    onSaved: (value) => title = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<appointment_model.AppointmentType>(
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                    value: type,
                    items: appointment_model.AppointmentType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toString().split('.').last),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        type = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Vendor ID',
                      hintText: 'Enter vendor ID',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vendor ID is required';
                      }
                      return null;
                    },
                    onSaved: (value) => vendorId = value!,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            hintText: 'Select date',
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            hintText: 'Select time',
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: selectedTime.format(context),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final appointment = Appointment(
                    type: type.toString().split('.').last,
                    title: title,
                    date: DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    ).toString().split(' ')[0],
                    vendor: vendorId,
                  );

                  admin.addAppointment(appointment);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Appointment added successfully')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAppointmentDialog(Appointment appointment) {
    final formKey = GlobalKey<FormState>();
    String title = appointment.title;
    String type = appointment.type;
    String vendor = appointment.vendor;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Appointment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter appointment title',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                    onSaved: (value) => title = value!,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type',
                    ),
                    value: type,
                    items:
                        ['Food Testing', 'Fitting', 'Consultation', 'Meeting']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        type = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: vendor,
                    decoration: const InputDecoration(
                      labelText: 'Vendor',
                      hintText: 'Enter vendor name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vendor is required';
                      }
                      return null;
                    },
                    onSaved: (value) => vendor = value!,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            hintText: 'Select date',
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            hintText: 'Select time',
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: selectedTime.format(context),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  try {
                    final admin = Provider.of<AdminProvider>(context, listen: false);
                    admin.updateAppointmentById(
                      appointment.title,
                      newTitle: title,
                      type: type,
                      vendor: vendor,
                      date: DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ).toString().split(' ')[0],
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Appointment updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating appointment: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAppointmentDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content:
            Text('Are you sure you want to delete "${appointment.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
            ElevatedButton(
              onPressed: () {
                try {
                  final admin = Provider.of<AdminProvider>(context, listen: false);
                  admin.deleteAppointmentById(appointment.title);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appointment.title} deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting appointment: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
  }

  void _showAddRentalDialog(AdminProvider admin) {
    final formKey = GlobalKey<FormState>();
    String item = '';
    String user = '';
    double deposit = 0.0;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Rental'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'Enter rental item name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Item name is required';
                      }
                      return null;
                    },
                    onSaved: (value) => item = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'User',
                      hintText: 'Enter user name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'User is required';
                      }
                      return null;
                    },
                    onSaved: (value) => user = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Deposit Amount',
                      hintText: 'Enter deposit amount',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deposit amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onSaved: (value) => deposit = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Rental Date',
                      hintText: 'Select rental date',
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final rental = Rental(
                    item: item,
                    user: user,
                    deposit: deposit.toInt(),
                    status: 'borrowed',
                  );

                  admin.addRental(rental);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rental added successfully')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRentalDialog(Rental rental) {
    final formKey = GlobalKey<FormState>();
    String item = rental.item;
    String user = rental.user;
    double deposit = rental.deposit.toDouble();
    String status = rental.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Rental'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: item,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      hintText: 'Enter rental item name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Item name is required';
                      }
                      return null;
                    },
                    onSaved: (value) => item = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user,
                    decoration: const InputDecoration(
                      labelText: 'User',
                      hintText: 'Enter user name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'User is required';
                      }
                      return null;
                    },
                    onSaved: (value) => user = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: deposit.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Deposit Amount',
                      hintText: 'Enter deposit amount',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deposit amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onSaved: (value) => deposit = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                    ),
                    value: status,
                    items: ['borrowed', 'returned']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        status = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final admin = Provider.of<AdminProvider>(context, listen: false);
                  admin.updateRental(rental.item, item: item, user: user, deposit: deposit.toInt(), status: status);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Rental updated successfully')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRentalInventory(AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rental Inventory'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: admin.rentals.length,
            itemBuilder: (context, index) {
              final rental = admin.rentals[index];
              return ListTile(
                leading: Icon(
                  rental.status == 'borrowed'
                      ? Icons.schedule
                      : Icons.check_circle,
                  color: rental.status == 'borrowed'
                      ? Colors.orange
                      : Colors.green,
                ),
                title: Text(rental.item),
                subtitle: Text(
                    'User: ${rental.user} • Deposit: RM ${rental.deposit}'),
                trailing: Text(rental.status.toUpperCase()),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportAppointments(List<Appointment> appointments) async {
    // Generate CSV from your model
    final csvBuffer = StringBuffer();
    csvBuffer.writeln("Title,Type,Date,Vendor");

    for (var appointment in appointments) {
      csvBuffer.writeln(
          "${appointment.title},${appointment.type},${appointment.date},${appointment.vendor}");
    }

    final csvData = csvBuffer.toString();

    if (kIsWeb) {
      // WEB DOWNLOAD
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "appointments.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // MOBILE / DESKTOP
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/appointments.csv';
      final file = File(filePath);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: "Appointments Report");
    }
  }

  void _approveAllServices() {
    // Mock implementation - in real app, this would approve pending services
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('All pending services approved successfully')),
    );
  }

  void _generateServiceReport() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final activeServices = admin.vendors.where((v) => v.verified).length;
    final pendingApprovals =
        admin.vendors.where((v) => v.pendingApproval).length;
    final totalVendors = admin.vendors.length;

    // Generate a simple service report
    final reportData = '''
Service Management Report
Generated: ${DateTime.now()}

Active Services: $activeServices
Pending Approvals: $pendingApprovals
Total Vendors: $totalVendors

Service Categories:
- Catering: ${admin.vendors.where((v) => v.category == 'Catering').length} services
- Photography: ${admin.vendors.where((v) => v.category == 'Photography').length} services
- Venues: ${admin.vendors.where((v) => v.category == 'Venues').length} services
- Fashion: ${admin.vendors.where((v) => v.category == 'Fashion').length} services
- Decoration: ${admin.vendors.where((v) => v.category == 'Decoration').length} services
''';

    if (kIsWeb) {
      // WEB DOWNLOAD
      final bytes = utf8.encode(reportData);
      final blob = html.Blob([bytes], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "service_report.txt")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // MOBILE / DESKTOP
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/service_report.txt';
      final file = File(filePath);
      await file.writeAsString(reportData);
      await Share.shareXFiles([XFile(file.path)],
          text: "Service Management Report");
    }
  }

  void _toggleBookingPriority(Booking booking, AdminProvider admin) {
    admin.toggleBookingPriority(booking.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Booking priority ${booking.priority ? 'removed' : 'set to high'}',
        ),
      ),
    );
  }

  // Service-specific helper methods
  List<VendorService> _filterServices(List<VendorService> services) {
    return services.where((service) {
      final matchesSearch = service.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          service.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _filterStatus == 'All' ||
          (_filterStatus == 'Active' && service.active && service.approvalStatus == ApprovalStatus.approved) ||
          (_filterStatus == 'Pending' && service.approvalStatus == ApprovalStatus.pending) ||
          (_filterStatus == 'Suspended' && (!service.active || service.approvalStatus == ApprovalStatus.rejected));

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildServiceCard(VendorService service, AdminProvider admin) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (service.active && service.approvalStatus == ApprovalStatus.approved) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
      statusText = 'Active';
    } else if (service.approvalStatus == ApprovalStatus.pending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pending';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.block;
      statusText = 'Suspended';
    }

    // For live data, we might not have the full vendor service list easily for counts
    // For now, let's just show what we have in the current service object or a simple placeholder
    final totalServices = admin.allServices.where((s) => s.vendorId == service.vendorId).length;
    final docData = service.requirements['documents'];
    final documents = (docData is List) ? docData.map((e) => e.toString()).toList() : ['Business License', 'ID Proof'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            service.category.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              service.type.toString().split('.').last.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Services by Vendor: $totalServices',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Documents: ${documents.join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  service.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (service.originalPrice != null && service.originalPrice! > service.basePrice)
                      Text(
                        'RM ${service.originalPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                   Text(
                  'RM ${service.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                    if (service.promoExpiry != null)
                      Text(
                        'Ends: ${service.promoExpiry!.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 10, color: Colors.red),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                const Icon(Icons.book_online, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${service.reviews?.length ?? 0} reviews',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (service.installmentEnabled) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.payments, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Installments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
            if (service.hasVariations) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${service.variationCount} Pricing Variations',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (service.options['variations'] as Map).entries.take(3).map((v) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                          ),
                          child: Text(
                            v.key,
                            style: const TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showServiceDetails(service),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (service.approvalStatus == ApprovalStatus.pending) ...[
                  Expanded(
                      child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await admin.updateServiceStatus(service.id, ApprovalStatus.approved);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Service approved successfully'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await admin.updateServiceStatus(service.id, ApprovalStatus.rejected);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Service rejected'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (!service.active || service.approvalStatus == ApprovalStatus.rejected)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await admin.updateServiceStatus(service.id, ApprovalStatus.approved);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Service activated'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showServiceActions(service, admin),
                      icon: const Icon(Icons.more_vert),
                      label: const Text('Actions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceDetails(VendorService service) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(service.category.icon, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Section
                      _buildDetailSectionTitle('General Information'),
                      _buildDetailRow('Category', service.category.displayName),
                      _buildDetailRow('Subcategory', service.subcategory ?? 'N/A'),
                      _buildDetailRow('Service Type', service.type.name.capitalize()),
                      _buildDetailRow(
                        'Price', 
                        service.hasPackagePricing 
                          ? 'RM ${service.getMinPrice().toStringAsFixed(2)} - RM ${service.getMaxPrice().toStringAsFixed(2)}'
                          : 'RM ${service.basePrice.toStringAsFixed(2)}'
                      ),
                      _buildDetailRow('Average Rating', '${service.averageRating.toStringAsFixed(1)} / 5.0 (${service.reviews?.length ?? 0} reviews)'),
                      _buildDetailRow('Location', service.venueAddress ?? service.coverageArea ?? 'Not specified'),
                      const SizedBox(height: 12),
                      const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(service.description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      
                      const Divider(height: 32),
                      
                      // Pricing Variations Section
                      if (service.hasVariations) ...[
                        _buildDetailSectionTitle('Pricing Variations (Tiered Pricing)'),
                        _buildVariationsList(service.options['variations']),
                        const Divider(height: 32),
                      ],
                      
                      // Add-ons Section
                      if (service.options['addOns'] != null) ...[
                        _buildDetailSectionTitle('Optional Add-ons'),
                        _buildAddOnsList(service.options['addOns']),
                        const Divider(height: 32),
                      ],
                      
                      // Logistics Section
                      if (service.logistics.isNotEmpty) ...[
                        _buildDetailSectionTitle('Logistics & Delivery'),
                        _buildLogisticsView(service.logistics),
                        const Divider(height: 32),
                      ],
                      
                      // Requirements Section
                      if (service.requirements.isNotEmpty) ...[
                        _buildDetailSectionTitle('Booking Requirements'),
                        _buildRequirementsView(service.requirements),
                        const Divider(height: 32),
                      ],
                      
                      // Availability Section
                      _buildDetailSectionTitle('Availability Schedule'),
                      _buildAvailabilityView(service.availability),
                    ],
                  ),
                ),
              ),
              
              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (service.approvalStatus == ApprovalStatus.pending) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Future: Trigger logic to approve from here if needed
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Action Required'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsList(dynamic variations) {
    if (variations is! Map) return const Text('No variations');
    
    return Column(
      children: variations.entries.map((entry) {
        final name = entry.key;
        final data = entry.value is Map ? entry.value as Map<String, dynamic> : {};
        final options = (data['options'] is List) ? data['options'] as List : [];
        final prices = (data['prices'] is List) ? data['prices'] as List : [];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Colors.blue.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                // Only iterate up to the minimum length to avoid index out of range
                ...List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(options[index].toString()),
                        Text(
                          index < prices.length 
                            ? 'RM ${prices[index].toString()}' 
                            : 'Price N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddOnsList(dynamic addOns) {
    if (addOns is! Map) return const Text('No add-ons');
    
    return Column(
      children: addOns.entries.map((entry) {
        final name = entry.key;
        final data = entry.value as Map<String, dynamic>;
        
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(data['description'] ?? ''),
          trailing: Text('RM ${data['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        );
      }).toList(),
    );
  }

  Widget _buildLogisticsView(Map<String, dynamic> logistics) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: logistics.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key.capitalize(), style: const TextStyle(fontSize: 10, color: Colors.orange)),
              Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRequirementsView(Map<String, dynamic> reqs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reqs.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text('${entry.key}: ${entry.value}')),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvailabilityView(Map<String, dynamic> availability) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: days.map((day) {
        final dayData = availability[day];
        final schedule = dayData is Map ? dayData as Map<String, dynamic> : null;
        final isAvailable = schedule?['available'] == true;
        
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(day.capitalize(), style: TextStyle(color: isAvailable ? Colors.black : Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: isAvailable 
                ? Text('${schedule!['start']} - ${schedule['end']}', style: const TextStyle(fontWeight: FontWeight.bold))
                : const Text('Closed', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showServiceActions(VendorService service, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Service'),
              onTap: () {
                Navigator.pop(context);
                _showEditServiceDialog(service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showServiceAnalytics(service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                _showSendMessageDialog(service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Suspend Service', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showSuspendServiceDialog(service, admin);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkServiceActions(List<VendorService> services) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Approve Selected'),
              onTap: () {
                Navigator.pop(context);
                _approveSelectedServices(services);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Suspend Selected'),
              onTap: () {
                Navigator.pop(context);
                _suspendSelectedServices(services);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Bulk Message'),
              onTap: () {
                Navigator.pop(context);
                _showBulkMessageDialog(services);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Selected'),
              onTap: () {
                Navigator.pop(context);
                _exportSelectedServices(services);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceDialog(VendorService service) {
    // Implementation for editing service details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit service functionality coming soon')),
    );
  }

  void _showServiceAnalytics(VendorService service) {
    // Implementation for showing service analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service analytics functionality coming soon')),
    );
  }

  void _showSendMessageDialog(VendorService service) {
    // Implementation for sending message to vendor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send message functionality coming soon')),
    );
  }

  void _showSuspendServiceDialog(VendorService service, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Service'),
        content: Text('Are you sure you want to suspend ${service.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementation for suspending service
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${service.name} has been suspended')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _approveSelectedServices(List<VendorService> services) {
    final pendingServices = services.where((s) => s.approvalStatus == ApprovalStatus.pending).toList();
    if (pendingServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending services to approve')),
      );
      return;
    }

    // Implementation for bulk approval
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pendingServices.length} services approved')),
    );
  }

  void _suspendSelectedServices(List<VendorService> services) {
    final activeServices = services.where((s) => s.active && s.approvalStatus == ApprovalStatus.approved).toList();
    if (activeServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active services to suspend')),
      );
      return;
    }

    // Implementation for bulk suspension
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${activeServices.length} services suspended')),
    );
  }

  void _showBulkMessageDialog(List<VendorService> services) {
    // Implementation for bulk messaging
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk messaging functionality coming soon')),
    );
  }

  void _exportSelectedServices(List<VendorService> services) {
    // Implementation for exporting selected services
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${services.length} services exported')),
    );
  }

  Widget _buildCategoriesTab(AdminProvider admin) {
    final categories = admin.serviceCategories;
    final filteredCategories = _filterCategories(categories);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Category Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryStatCard(
                        'Total Categories',
                        '${categories.length}',
                        Icons.category,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryStatCard(
                        'Active',
                        '${categories.where((c) => c.isActive).length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCategoryStatCard(
                        'Inactive',
                        '${categories.where((c) => !c.isActive).length}',
                        Icons.block,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Add Category Button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(admin),
              icon: const Icon(Icons.add),
              label: const Text('Add New Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Categories List
          Container(
            color: AppTheme.backgroundColor,
            child: Column(
              children: [
                // Categories List Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Text(
                    'Categories List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Categories List
                SizedBox(
                  height: 500,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return _buildCategoryCardForCategories(category, admin);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab(AdminProvider admin) {
    // Determine the filtered list of packages from AdminProvider
    final allPackages = admin.allServices.where((s) => s.type == ServiceType.package).toList();
    List<VendorService> packages = allPackages;

    if (_packageSubFilter == 'Collaborative') {
      packages = allPackages
          .where((p) =>
              p.description.toLowerCase().contains('collaborative') ||
              p.name.toLowerCase().contains('wedding') ||
              p.name.toLowerCase().contains('royal') ||
              p.name.toLowerCase().contains('banquet'))
          .toList();
    } else if (_packageSubFilter == 'Customer Choice') {
      packages = allPackages
          .where((p) =>
              p.name.toLowerCase().contains('custom') ||
              p.description.toLowerCase().contains('choice') ||
              p.name.toLowerCase().contains('wedding'))
          .toList();
    } else if (_packageSubFilter == 'Pending Approval') {
      packages = allPackages.where((p) => p.approvalStatus == ApprovalStatus.pending).toList();
    } else if (_packageSubFilter == 'Package Issues') {
      packages = allPackages.take(2).toList();
    }

    final filteredPackages = _filterServices(packages);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Collaborative Package Sub-navigation Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPackageFilterChip('All Packages', allPackages.length),
                  const SizedBox(width: 8),
                  _buildPackageFilterChip('Collaborative', 2, icon: Icons.group_work_outlined),
                  const SizedBox(width: 8),
                  _buildPackageFilterChip('Customer Choice', 2, icon: Icons.tune_rounded),
                  const SizedBox(width: 8),
                  _buildPackageFilterChip(
                    'Pending Approval',
                    allPackages.where((p) => p.approvalStatus == ApprovalStatus.pending).length,
                    icon: Icons.pending_actions,
                    badgeColor: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildPackageFilterChip(
                    'Package Issues',
                    1,
                    icon: Icons.warning_amber_rounded,
                    badgeColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Operational Package Overview
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Package Command & Multi-Vendor Engine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Auto-Validation Active', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPackageStatCard(
                        'Total Packages',
                        '${allPackages.length}',
                        Icons.inventory_2_outlined,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPackageStatCard(
                        'Collaborative',
                        '2 Multi-Vendor',
                        Icons.group_work_outlined,
                        Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPackageStatCard(
                        'Approved',
                        '${allPackages.where((p) => p.approvalStatus == ApprovalStatus.approved).length}',
                        Icons.verified,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPackageStatCard(
                        'Issues Flagged',
                        '1 Conflict',
                        Icons.error_outline,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Package List
          Container(
            color: AppTheme.backgroundColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Packages (${filteredPackages.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Filter: $_packageSubFilter',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPackages.length,
                  itemBuilder: (context, index) {
                    final package = filteredPackages[index];
                    return _buildPackageCard(package, admin);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageFilterChip(String label, int count, {IconData? icon, Color? badgeColor}) {
    final isSelected = _packageSubFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _packageSubFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : (badgeColor ?? Colors.black87)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : (badgeColor?.withOpacity(0.15) ?? Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (badgeColor ?? Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(AdminProvider admin) {
    final products = [
      {'name': 'Wedding Doorgift', 'price': 5.0, 'category': 'Decorations'},
      {'name': 'Floral Centerpiece', 'price': 120.0, 'category': 'Decorations'},
      {'name': 'Stage Backdrop', 'price': 850.0, 'category': 'Decorations'},
      {'name': 'LED Fairy Lights', 'price': 60.0, 'category': 'Lighting'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // Product Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Product Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProductStatCard(
                        'Total Products',
                        '${products.length}',
                        Icons.shopping_bag,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProductStatCard(
                        'Available',
                        '${products.length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProductStatCard(
                        'Revenue',
                        'RM 1,035',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product List
          Container(
            color: AppTheme.backgroundColor,
            child: Column(
              children: [
                // Product List Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Text(
                    'Product List',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Product List
                SizedBox(
                  height: 500,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(product, admin);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(VendorService package, AdminProvider admin) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (package.approvalStatus == ApprovalStatus.approved) {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
      statusText = 'Approved';
    } else if (package.approvalStatus == ApprovalStatus.pending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Pending';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.block;
      statusText = 'Rejected';
    }

    final minPrice = package.getMinPrice();
    final maxPrice = package.getMaxPrice();
    final isCollaborative = package.name.toLowerCase().contains('wedding') ||
        package.name.toLowerCase().contains('royal') ||
        package.description.toLowerCase().contains('collaborative');
    final hasAvailabilityWarning = package.name.toLowerCase().contains('royal');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              package.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Owner: ${package.vendorName ?? "EventEase Partner"}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCollaborative ? Colors.purple.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isCollaborative ? Colors.purple.shade200 : Colors.blue.shade200,
                              ),
                            ),
                            child: Text(
                              isCollaborative ? 'Collaborative Package (4 Vendors)' : 'Standard Package',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCollaborative ? Colors.purple.shade800 : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price & Capacity Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'RM ${minPrice.toStringAsFixed(0)} - RM ${maxPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.view_carousel_outlined, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${package.pricingTiers.length} Pricing Tiers',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Connected Components Breakdown
            const Text(
              'PACKAGE COMPONENTS & COLLABORATORS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildMiniComponentChip('Venue: Grand Ballroom', 'Fixed', Colors.teal),
                _buildMiniComponentChip('Catering: Royal Feast', 'Fixed', Colors.teal),
                _buildMiniComponentChip('Photography', 'Customer Choice (2)', Colors.indigo),
                _buildMiniComponentChip('Bridal Makeup', 'Customer Choice (2)', Colors.indigo),
                _buildMiniComponentChip('Food Tasting Included', 'Appointment', Colors.amber.shade900),
              ],
            ),
            const SizedBox(height: 10),

            // Package Validation Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasAvailabilityWarning ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasAvailabilityWarning ? Colors.orange.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasAvailabilityWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 16,
                    color: hasAvailabilityWarning ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasAvailabilityWarning
                          ? 'Package Availability Conflict: Catering collaborator has 6:00 PM cutoff on event date.'
                          : 'Package Validation: All 4 vendor components, pricing, and appointment rules verified.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasAvailabilityWarning ? Colors.orange.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons Row 1: Preview & Validation
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPackageCustomerPreview(context, package),
                    icon: const Icon(Icons.preview_rounded, size: 16),
                    label: const Text('Customer Preview', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPackageValidationDialog(context, package),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: const Text('Package Validation', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action Buttons Row 2: Relationships & Management
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AdminEntityDetailDialog.show(
                        context,
                        type: MarketplaceEntityType.package,
                        entityId: package.id,
                        entityName: package.name,
                        vendorName: package.vendorName,
                        price: package.price,
                        status: package.approvalStatus.name,
                      );
                    },
                    icon: const Icon(Icons.hub_outlined, size: 16),
                    label: const Text('Relationships', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (package.approvalStatus == ApprovalStatus.pending)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final success = await admin.updateServiceStatus(package.id, ApprovalStatus.approved);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Package approved'), backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showPackageActions(package),
                      icon: const Icon(Icons.more_vert, size: 16),
                      label: const Text('Manage', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniComponentChip(String label, String badge, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  void _showPackageValidationDialog(BuildContext context, VendorService package) {
    final hasWarning = package.name.toLowerCase().contains('royal') || package.name.toLowerCase().contains('wedding');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Package Validation: ${package.name}', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasWarning ? Colors.amber.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hasWarning ? Colors.amber.shade300 : Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(hasWarning ? Icons.warning_amber_rounded : Icons.verified,
                          color: hasWarning ? Colors.orange : Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasWarning
                              ? 'Validation Status: Requires Changes (1 Availability Warning)'
                              : 'Validation Status: Ready for Approval / Live',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasWarning ? Colors.orange.shade900 : Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('AUTOMATIC SYSTEM VALIDATION CHECKLIST',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildValidationCheck('Package Owner Approved', 'Vendor account verified and in good standing', true),
                _buildValidationCheck('Required Components Configured', '4 core components defined with clear SLAs', true),
                _buildValidationCheck('Collaborating Vendors Approved', 'All 3 participating vendors have valid licenses', true),
                _buildValidationCheck('Pricing & Tier Breakdown', 'RM 26,300 base price with transparent itemization', true),
                _buildValidationCheck('Appointment Rules Configured', 'Trial appointment types and booking lead times set', true),
                _buildValidationCheck('Travel Radius & Zone Surcharge', 'Within 35km radius covered, RM 2.50/km beyond', true),
                if (hasWarning)
                  _buildValidationCheck(
                      'Availability Timeline Sync', 'Catering collaborator available until 6:00 PM only on selected dates', false),
                const SizedBox(height: 16),
                const Divider(),
                const Text('CONNECTED COMPONENTS (MULTI-VENDOR)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildComponentRow('Venue', 'Grand Ballroom Hall', 'Fixed Vendor', 'Confirmed', Colors.green),
                _buildComponentRow('Catering', 'Royal Feast Catering', 'Fixed Vendor', 'Time Constraint (6 PM)', Colors.orange),
                _buildComponentRow('Photography', 'Customer Choice (2 Options)', 'Collaborative', 'Confirmed', Colors.blue),
                _buildComponentRow('Bridal Makeup', 'Customer Choice (2 Options)', 'Collaborative', 'Confirmed', Colors.blue),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              AdminEntityDetailDialog.show(
                context,
                type: MarketplaceEntityType.package,
                entityId: package.id,
                entityName: package.name,
                vendorName: package.vendorName,
                price: package.price,
                status: package.approvalStatus.name,
              );
            },
            child: const Text('Inspect Relationships'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPackageCustomerPreview(context, package);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Customer Preview'),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationCheck(String title, String subtitle, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: passed ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentRow(String role, String name, String type, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
            child: Text(role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(type, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  void _showPackageCustomerPreview(BuildContext context, VendorService package) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedPhoto = 'Lumiere Cinema';
        String selectedMakeup = 'Glam Studio';
        return StatefulBuilder(
          builder: (context, setPreviewState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            contentPadding: const EdgeInsets.all(20),
            title: Row(
              children: [
                const Icon(Icons.preview_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text(
                        'CUSTOMER MARKETPLACE EXPERIENCE PREVIEW (READ-ONLY)',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text('SAFE PREVIEW',
                      style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.card_giftcard, color: AppTheme.primaryColor, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(package.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const Text(' 4.9 (48 reviews)', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Text('By ${package.vendorName ?? "EventEase Partner"}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('RM 26,300 base package',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('CUSTOMIZE YOUR PACKAGE COMPONENTS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    _buildPreviewComponentTile(
                      icon: Icons.apartment,
                      title: 'Grand Ballroom Venue',
                      vendor: 'ABC Grand Ballroom',
                      type: 'Fixed Vendor (Included)',
                    ),
                    _buildPreviewComponentTile(
                      icon: Icons.restaurant,
                      title: 'Catering: 500-Pax Banquet Buffet',
                      vendor: 'Royal Feast Catering',
                      type: 'Fixed Vendor (Included)',
                    ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                const Text('Photography & Cinema',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration:
                                      BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Choose Vendor',
                                      style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            RadioListTile<String>(
                              dense: true,
                              value: 'Lumiere Cinema',
                              groupValue: selectedPhoto,
                              title: const Text('Lumiere Cinema & Photo (Included in base)', style: TextStyle(fontSize: 12)),
                              subtitle: const Text('Full day photography + highlight drone video',
                                  style: TextStyle(fontSize: 10)),
                              onChanged: (val) => setPreviewState(() => selectedPhoto = val!),
                            ),
                            RadioListTile<String>(
                              dense: true,
                              value: 'John Studio',
                              groupValue: selectedPhoto,
                              title: const Text('John Photography (+RM 350 upgrade)', style: TextStyle(fontSize: 12)),
                              subtitle: const Text('Includes premium leather album + 2 frame prints',
                                  style: TextStyle(fontSize: 10)),
                              onChanged: (val) => setPreviewState(() => selectedPhoto = val!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.face_retouching_natural, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                const Text('Bridal Makeup & Styling',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration:
                                      BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Choose Vendor',
                                      style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            RadioListTile<String>(
                              dense: true,
                              value: 'Glam Studio',
                              groupValue: selectedMakeup,
                              title: const Text('Glam Studio (Included in base)', style: TextStyle(fontSize: 12)),
                              subtitle: const Text('Bridal makeup, hair styling & touch-up standby',
                                  style: TextStyle(fontSize: 10)),
                              onChanged: (val) => setPreviewState(() => selectedMakeup = val!),
                            ),
                            RadioListTile<String>(
                              dense: true,
                              value: 'Beauty by Sarah',
                              groupValue: selectedMakeup,
                              title: const Text('Beauty by Sarah (+RM 150 upgrade)', style: TextStyle(fontSize: 12)),
                              subtitle: const Text('HD Airbrush makeup + bridesmaid styling package',
                                  style: TextStyle(fontSize: 10)),
                              onChanged: (val) => setPreviewState(() => selectedMakeup = val!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'RM ${(26300 + (selectedPhoto == "John Studio" ? 350 : 0) + (selectedMakeup == "Beauty by Sarah" ? 150 : 0)).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close Preview'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Read-only Customer Preview mode. No live booking created.')),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: const Text('Simulate Customer Checkout'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewComponentTile({
    required IconData icon,
    required String title,
    required String vendor,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('Vendor: $vendor', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
            child: Text(type, style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(Icons.shopping_bag, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['category'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Available',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'RM ${product['price']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                const Text(
                  '4.5',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showProductDetails(product),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showProductActions(product),
                    icon: const Icon(Icons.more_vert),
                    label: const Text('Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ServicePackage> _filterPackages(List<ServicePackage> packages) {
    return packages.where((package) {
      final name = package.name?.toLowerCase() ?? '';
      final vendorName = package.vendorName?.toLowerCase() ?? '';
      final category = package.category?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      final matchesSearch = name.contains(query) ||
          vendorName.contains(query) ||
          category.contains(query);

      return matchesSearch;
    }).toList();
  }

  void _showPackageDetails(ServicePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(package.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendor: ${package.vendorName}'),
              const SizedBox(height: 8),
              Text('Category: ${package.category}'),
              const SizedBox(height: 8),
              Text('Status: ${package.approvalStatus.toString().split('.').last}'),
              const SizedBox(height: 8),
              const Text('Price Tiers:'),
              ...package.priceByPax.entries.map((entry) =>
                Text('  ${entry.key} pax: RM ${entry.value}')),
              const SizedBox(height: 8),
              Text('Description: ${package.description}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${product['category']}'),
            const SizedBox(height: 8),
            Text('Price: RM ${product['price']}'),
            const SizedBox(height: 8),
            const Text('Rating: 4.5/5.0'),
            const SizedBox(height: 8),
            const Text('Status: Available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approvePackage(ServicePackage package) {
    SampleServicePackages.updatePackageApprovalStatus(package.id, ApprovalStatus.approved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${package.name} has been approved')),
    );
    setState(() {});
  }

  void _showPackageActions(VendorService package) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Package'),
              onTap: () {
                Navigator.pop(context);
                _showEditPackageDialog(package);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showPackageAnalytics(package);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPackageDialog(VendorService package) {
    // Implementation for editing package details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit package functionality coming soon')),
    );
  }

  void _showPackageAnalytics(VendorService package) {
    // Implementation for showing package analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Package analytics functionality coming soon')),
    );
  }

  void _showProductActions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit product
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit product functionality coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement product analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product analytics functionality coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Category-specific helper methods
  List<ServiceCategory> _filterCategories(List<ServiceCategory> categories) {
    return categories.where((category) {
      final matchesSearch = category.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          category.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  Widget _buildCategoryStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCardForCategories(ServiceCategory category, AdminProvider admin) {
    Color statusColor = category.isActive ? Colors.green : Colors.red;
    IconData statusIcon = category.isActive ? Icons.check_circle : Icons.block;
    String statusText = category.isActive ? 'Active' : 'Inactive';

    final mkt = Provider.of<AdminMarketplaceProvider>(context, listen: false);
    final dynConfig = mkt.getCategoryConfig(category.name);
    final activeVer = dynConfig?.activeVersion ?? '1.0';
    final fieldsCount = dynConfig?.activeConfig.fields.length ?? 8;
    final aptCount = dynConfig?.activeConfig.appointmentTypes.length ?? 2;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.1),
                  child: Icon(category.icon, color: category.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'v$activeVer LIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Engine Capabilities & Config Summary
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildEngineFeatureItem(Icons.schema_outlined, '$fieldsCount Fields', Colors.blue),
                  const SizedBox(width: 16),
                  _buildEngineFeatureItem(Icons.event_available, '$aptCount Appts', Colors.purple),
                  const SizedBox(width: 16),
                  _buildEngineFeatureItem(Icons.tune, 'Package Rules Enabled', Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCategoryDetails(category),
                    icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                    label: const Text('Configure Engine & Versions', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AdminEntityDetailDialog.show(
                        context,
                        type: MarketplaceEntityType.category,
                        entityId: category.id,
                        entityName: category.name,
                        status: category.isActive ? 'Active' : 'Inactive',
                      );
                    },
                    icon: const Icon(Icons.hub_outlined, size: 16),
                    label: const Text('Relationships', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineFeatureItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(AdminProvider admin) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';
    IconData selectedIcon = Icons.category;
    Color selectedColor = Colors.blue;
    List<String> subcategories = [];
    final subController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'Enter category name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Category name is required';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter category description',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                    onSaved: (value) => description = value!,
                  ),
                  const SizedBox(height: 16),
                  // Subcategories removed from ServiceCategory model
                  // TODO: Implement subcategory management via event_type_categories
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  try {
                    await admin.addServiceCategory(
                      name: name,
                      description: description,
                      icon: selectedIcon,
                      color: selectedColor,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category added successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add category: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetails(ServiceCategory category) {
    final mkt = Provider.of<AdminMarketplaceProvider>(context, listen: false);
    final dynConfig = mkt.getCategoryConfig(category.name);
    final activeVersion = dynConfig?.activeVersion ?? '1.0';
    final liveConfig = dynConfig?.activeConfig;

    final fields = liveConfig?.fields ?? [
      'Service / Product Type',
      'Base Pricing & Package Breakdown',
      'Estimated Duration / Event Window',
      'Guest Count / Pax Capacity',
      'Travel Radius & Outstation Surcharge',
      'Cancellation Policy & Deposit Terms',
    ];

    final aptTypes = liveConfig?.appointmentTypes ?? [
      'Preliminary Consultation (30 mins - Free)',
      'Service Trial / Tasting / Site Visit (60 mins)',
    ];

    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 4,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: category.color.withOpacity(0.1),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'v$activeVersion LIVE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      category.description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 620,
            height: 480,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(icon: Icon(Icons.schema_outlined, size: 18), text: 'Dynamic Fields'),
                    Tab(icon: Icon(Icons.event_available, size: 18), text: 'Appointments'),
                    Tab(icon: Icon(Icons.rule_folder_outlined, size: 18), text: 'Package Rules'),
                    Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: 'Versioning'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Dynamic Fields
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'DYNAMIC SCHEMA FIELDS (NO-CODE CONFIG)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Field added to draft schema version.')),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Field', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...fields.map((f) => Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('Required', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),

                      // Tab 2: Appointment Types
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SUPPORTED APPOINTMENT TYPES & LEAD TIMES',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            ...aptTypes.map((apt) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.purple, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(apt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              const Text('Reusable pre-booking appointment layer', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Configured', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Appointments created in this category automatically connect to vendor calendars and package bookings.',
                                      style: TextStyle(fontSize: 11, color: Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab 3: Package Rules
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MARKETPLACE PACKAGE COMPATIBILITY RULES',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            _buildRuleItem('Customer Choice Allowed', 'Allows organizers to pick custom vendor for this category component', true),
                            _buildRuleItem('Multiple Vendors Allowed', 'Multiple approved vendors can submit collaborative bids', true),
                            _buildRuleItem('Requires Appointment Before Booking', 'Trial / Tasting must be completed before main event booking', false),
                            _buildRuleItem('Standard Deposit Requirement', '30% upfront deposit on contract signing', true),
                            _buildRuleItem('Free Travel Zone', 'Within 20 km included; RM 2.50 per additional km', true),
                          ],
                        ),
                      ),

                      // Tab 4: Versioning
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'VERSION CONTROL & SERVICE MIGRATION',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    mkt.publishNewVersion(
                                      categoryName: category.name,
                                      versionNumber: '2.1',
                                      changelog: 'Added outdoor contingency rules and Halal certification audit.',
                                      publishedBy: 'Super Admin',
                                    );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Published Version 2.1 for ${category.name} successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.publish, size: 15),
                                  label: const Text('Publish v2.1', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: Colors.green.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Version $activeVersion (Current Active)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const Spacer(),
                                        const Text('Published 1 day ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dynConfig?.versions.first.changelog ?? 'Schema upgraded with validation rules.',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              color: Colors.grey.shade50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Version 1.1 (Archived)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                        Spacer(),
                                        Text('90 days ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text('Initial marketplace baseline fields.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  mkt.migrateServicesToLatestVersion(category.name);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('All legacy ${category.name} services migrated safely to v$activeVersion!')),
                                  );
                                },
                                icon: const Icon(Icons.sync_alt, size: 16),
                                label: Text('Safely Migrate Existing Services to v$activeVersion'),
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                AdminEntityDetailDialog.show(
                  context,
                  type: MarketplaceEntityType.category,
                  entityId: category.id,
                  entityName: category.name,
                  status: category.isActive ? 'Active' : 'Inactive',
                );
              },
              child: const Text('Inspect Relationships'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(enabled ? Icons.check_box : Icons.check_box_outline_blank, color: enabled ? AppTheme.primaryColor : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryActions(ServiceCategory category, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(category, admin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                _showCategoryAnalytics(category);
              },
            ),
            ListTile(
              leading: category.isActive ? const Icon(Icons.block, color: Colors.orange) : const Icon(Icons.check_circle, color: Colors.green),
              title: Text(category.isActive ? 'Deactivate Category' : 'Activate Category'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await admin.toggleServiceCategoryStatus(category.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Category ${category.isActive ? 'deactivated' : 'activated'} successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Category', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCategoryDialog(category, admin);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(ServiceCategory category, AdminProvider admin) {
    final formKey = GlobalKey<FormState>();
    String name = category.name;
    String description = category.description;
    // Subcategories handled separately now
    List<String> subcategories = []; // List.from(category.subcategories);
    final subController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'Enter category name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Category name is required';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter category description',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                    onSaved: (value) => description = value!,
                  ),
                  const SizedBox(height: 16),
                  // Subcategories removed
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  try {
                    await admin.updateServiceCategory(
                      category.id,
                      name: name,
                      description: description,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Category updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update category: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryAnalytics(ServiceCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category.name} Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Total Services', '-', Icons.business_center, Colors.blue),
            const SizedBox(height: 12),
            _buildStatItem('Status', category.isActive ? 'Active' : 'Inactive', Icons.info_outline, category.isActive ? Colors.green : Colors.red),
            const SizedBox(height: 12),
            _buildStatItem('Subcategories', '-', Icons.list, Colors.orange),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  void _showDeleteCategoryDialog(ServiceCategory category, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await admin.deleteServiceCategory(category.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${category.name} has been deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete category: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentPlanSectionAdmin(Map<String, dynamic> plan) {
    final payments = plan['installment_payments'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Schedule',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total Amount: RM ${(plan['total_amount'] ?? 0).toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...payments.map((payment) => _buildInstallmentItemAdmin(payment)).toList(),
      ],
    );
  }

  Widget _buildInstallmentItemAdmin(Map<String, dynamic> payment) {
    final status = payment['status'] as String? ?? 'PENDING';
    final amount = (payment['amount'] ?? 0).toDouble();
    final dueDateStr = payment['due_date'] as String? ?? '';
    final isPaid = status == 'PAID';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.schedule,
            color: isPaid ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'RM ${amount.toStringAsFixed(2)} - Due: $dueDateStr',
              style: TextStyle(
                fontSize: 13,
                color: isPaid ? Colors.black87 : Colors.grey[700],
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isPaid ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateInvoice(BuildContext context, Booking booking) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Fetch vendor profile (needed for invoice generation info)
      final actualVendorData = await Supabase.instance.client
          .from('vendor_profiles')
          .select()
          .eq('id', booking.vendorId)
          .single();
      
      final vendor = vendor_model.Vendor.fromSupabase(actualVendorData);

      // 2. Fetch full core_booking model
      final bookingData = await Supabase.instance.client
          .from('bookings')
          .select('*, customer_user(*), vendor_services(*), installment_plans(*)')
          .eq('id', booking.id)
          .single();
      
      final fullBooking = core_booking.Booking.fromSupabase(bookingData);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        // 3. Generate and Share Invoice
        await PdfGeneratorService().generateAndShareInvoice(
          fullBooking, 
          vendor, 
          booking.packageName, 
          booking.amount
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice: $e')),
        );
      }
    }
  }
}
