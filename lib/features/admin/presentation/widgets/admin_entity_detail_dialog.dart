import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_package_customization_screen.dart';

/// Modal dialog that shows any Marketplace Entity with full relationships & operations
class AdminEntityDetailDialog extends StatefulWidget {
  final MarketplaceEntityType initialType;
  final String entityId;
  final dynamic initialData;

  const AdminEntityDetailDialog({
    super.key,
    required this.initialType,
    required this.entityId,
    this.initialData,
  });

  static void show(
    BuildContext context, {
    MarketplaceEntityType? type,
    String? entityId,
    String? entityName,
    String? entityType,
    dynamic data,
    String? vendorName,
    String? customerName,
    String? bookingId,
    String? status,
    double? price,
    String? category,
  }) {
    final resolvedType = type ?? MarketplaceEntityType.values.firstWhere(
      (candidate) => candidate.label.toLowerCase() == (entityType ?? '').toLowerCase() || candidate.name.toLowerCase() == (entityType ?? '').toLowerCase(),
      orElse: () => MarketplaceEntityType.service,
    );

    final resolvedId = entityId ?? entityName ?? 'unknown';
    final payload = data ?? {
      'entityName': entityName,
      'vendorName': vendorName,
      'customerName': customerName,
      'bookingId': bookingId,
      'status': status,
      'price': price,
      'category': category,
    };

    showDialog(
      context: context,
      builder: (ctx) => AdminEntityDetailDialog(
        initialType: resolvedType,
        entityId: resolvedId,
        initialData: payload,
      ),
    );
  }

  @override
  State<AdminEntityDetailDialog> createState() => _AdminEntityDetailDialogState();
}

class _AdminEntityDetailDialogState extends State<AdminEntityDetailDialog> {
  late MarketplaceEntityType _currentType;
  late String _currentId;
  dynamic _currentData;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _currentId = widget.entityId;
    _currentData = widget.initialData;
  }

  void _navigateToEntity(MarketplaceEntityType type, String id, [dynamic data]) {
    setState(() {
      _currentType = type;
      _currentId = id;
      _currentData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 24,
      ),
      child: Container(
        width: isDesktop ? 860 : double.infinity,
        height: isDesktop ? 680 : MediaQuery.of(context).size.height * 0.85,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildDialogHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildEntityBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _currentType.color.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _currentType.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_currentType.icon, color: _currentType.color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_currentType.label.toUpperCase()} DETAIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: _currentType.color,
                ),
              ),
              Text(
                'ID: $_currentId',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildEntityBody(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final workflow = Provider.of<VendorWorkflowProvider>(context);
    final mkt = Provider.of<AdminMarketplaceProvider>(context);

    switch (_currentType) {
      case MarketplaceEntityType.service:
        return _buildServiceDetail(context, workflow, admin);
      case MarketplaceEntityType.package:
        return _buildPackageDetail(context, workflow, admin);
      case MarketplaceEntityType.appointment:
        return _buildAppointmentDetail(context, workflow, admin);
      case MarketplaceEntityType.booking:
        return _buildBookingDetail(context, admin, workflow);
      case MarketplaceEntityType.vendor:
        return _buildVendorDetail(context, admin, workflow);
      case MarketplaceEntityType.supportCase:
        return _buildSupportCaseDetail(context, mkt, admin, workflow);
      case MarketplaceEntityType.payment:
        return _buildTransactionDetail(context, admin);
      case MarketplaceEntityType.customer:
        return _buildCustomerDetail(context, admin);
      default:
        return Center(
          child: Text('Detail view for ${_currentType.label} (ID: $_currentId)'),
        );
    }
  }

  // ==========================================
  // SERVICE DETAIL VIEW
  // ==========================================
  Widget _buildServiceDetail(
    BuildContext context,
    VendorWorkflowProvider workflow,
    AdminProvider admin,
  ) {
    CommonServiceInfo? service;
    try {
      service = workflow.services.firstWhere((s) => s.id == _currentId);
    } catch (_) {
      if (_currentData is CommonServiceInfo) {
        service = _currentData;
      }
    }

    if (service == null) {
      return const Text('Service not found.');
    }

    final packagesUsingService = workflow.packages.where((p) {
      return p.components.any((c) => c.approvedCollaborators.any((collab) => collab.serviceId == service!.id) || c.category == service!.category);
    }).toList();

    final appointmentsForService = workflow.appointments.where((a) {
      return a.serviceId == service!.id;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Price
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vendor: ${service.vendorName} • Area: ${service.serviceArea}',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('STARTING FROM', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  Text('RM ${service.startingPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Clickable Relationship Bar
        _buildRelationshipSection([
          _RelationshipNode(
            label: 'Vendor',
            value: service.vendorName,
            icon: Icons.storefront_outlined,
            color: Colors.purple,
            onTap: () => _navigateToEntity(MarketplaceEntityType.vendor, service!.vendorId),
          ),
          _RelationshipNode(
            label: 'Category',
            value: service.category.displayName,
            icon: service.category.iconData,
            color: service.category.brandColor,
          ),
          _RelationshipNode(
            label: 'Linked Packages',
            value: '${packagesUsingService.length} Packages',
            icon: Icons.all_inbox_outlined,
            color: Colors.indigo,
            onTap: packagesUsingService.isNotEmpty
                ? () => _navigateToEntity(MarketplaceEntityType.package, packagesUsingService.first.id, packagesUsingService.first)
                : null,
          ),
          _RelationshipNode(
            label: 'Appointments',
            value: '${appointmentsForService.length} Booked',
            icon: Icons.calendar_month_outlined,
            color: Colors.teal,
            onTap: appointmentsForService.isNotEmpty
                ? () => _navigateToEntity(MarketplaceEntityType.appointment, appointmentsForService.first.id, appointmentsForService.first)
                : null,
          ),
        ]),
        const SizedBox(height: 20),

        // Description
        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Text(service.description, style: const TextStyle(color: Colors.black87, height: 1.4)),
        const SizedBox(height: 16),

        // Operational Specs
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSpecBadge(Icons.event_available, 'Min Notice: ${service.minBookingNoticeDays} days'),
            _buildSpecBadge(Icons.timer_outlined, 'Hours: ${service.workingHoursStart} - ${service.workingHoursEnd}'),
            _buildSpecBadge(Icons.security, 'Deposit: ${service.depositRequirementPercent.toStringAsFixed(0)}%'),
            _buildSpecBadge(Icons.group, 'Max per day: ${service.maxBookingsPerDay}'),
          ],
        ),
        const SizedBox(height: 20),

        // Policies
        const Text('Policies & Cancellation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(service.cancellationPolicy, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
        ),
      ],
    );
  }

  // ==========================================
  // PACKAGE DETAIL VIEW
  // ==========================================
  Widget _buildPackageDetail(
    BuildContext context,
    VendorWorkflowProvider workflow,
    AdminProvider admin,
  ) {
    CollaborativePackage? package;
    try {
      package = workflow.packages.firstWhere((p) => p.id == _currentId);
    } catch (_) {
      if (_currentData is CollaborativePackage) {
        package = _currentData;
      }
    }

    if (package == null) {
      return const Text('Package not found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${package.ownerVendorName} • Event Types: ${package.eventTypes.join(", ")}',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PACKAGE PRICE', style: TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                  Text('RM ${package.basePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Clickable Relationship Chain
        _buildRelationshipSection([
          _RelationshipNode(
            label: 'Owner Vendor',
            value: package.ownerVendorName,
            icon: Icons.storefront_outlined,
            color: Colors.purple,
            onTap: () => _navigateToEntity(MarketplaceEntityType.vendor, package!.ownerVendorId),
          ),
          _RelationshipNode(
            label: 'Components',
            value: '${package.components.length} Categories',
            icon: Icons.grid_view_outlined,
            color: Colors.blue,
          ),
          _RelationshipNode(
            label: 'Customer Preview',
            value: 'Preview Storefront',
            icon: Icons.visibility_outlined,
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerPackageCustomizationScreen(package: package!),
                ),
              );
            },
          ),
        ]),
        const SizedBox(height: 20),

        // Package Components List
        const Text('Package Components & Collaborators', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...package.components.map((comp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(comp.category.iconData, color: comp.category.brandColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          comp.componentName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: comp.isFixedVendor ? Colors.blue.shade50 : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        comp.isFixedVendor ? 'Fixed Vendor' : 'Customer Choice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: comp.isFixedVendor ? Colors.blue.shade700 : Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comp.description,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
                if (comp.approvedCollaborators.isNotEmpty) ...[
                  const Divider(height: 16),
                  const Text('Approved Collaborator Options:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: comp.approvedCollaborators.map((c) {
                      return InkWell(
                        onTap: () => _navigateToEntity(MarketplaceEntityType.vendor, c.vendorId),
                        child: Chip(
                          avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          label: Text('${c.vendorName} (RM ${c.priceDelta >= 0 ? "+" : ""}${c.priceDelta.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.grey.shade100,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // APPOINTMENT DETAIL VIEW
  // ==========================================
  Widget _buildAppointmentDetail(
    BuildContext context,
    VendorWorkflowProvider workflow,
    AdminProvider admin,
  ) {
    ServiceAppointmentBooking? appointment;
    try {
      appointment = workflow.appointments.firstWhere((a) => a.id == _currentId);
    } catch (_) {
      if (_currentData is ServiceAppointmentBooking) {
        appointment = _currentData;
      }
    }

    if (appointment == null) {
      return const Text('Appointment not found.');
    }

    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(appointment.scheduledDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.appointmentTypeName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purpose: ${appointment.purpose.displayName} • Duration: ${appointment.durationMinutes} mins',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
            _buildStatusPill(appointment.status.displayName, appointment.status.color),
          ],
        ),
        const SizedBox(height: 16),

        // FULL RELATIONSHIP TRAIL (As specified in prompt item 9 & 38)
        const Text(
          'CONNECTED RELATIONSHIP TRAIL',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        _buildRelationshipSection([
          _RelationshipNode(
            label: 'Customer',
            value: appointment.customerName,
            icon: Icons.person_outline,
            color: Colors.blue,
            onTap: () => _navigateToEntity(MarketplaceEntityType.customer, appointment!.customerId),
          ),
          _RelationshipNode(
            label: 'Event',
            value: appointment.eventName ?? 'Wedding 2026',
            icon: Icons.event_outlined,
            color: Colors.green,
          ),
          _RelationshipNode(
            label: 'Package',
            value: appointment.packageId ?? 'Royal Wedding',
            icon: Icons.all_inbox_outlined,
            color: Colors.indigo,
            onTap: () => _navigateToEntity(MarketplaceEntityType.package, appointment!.packageId ?? 'pkg-royal-wedding'),
          ),
          _RelationshipNode(
            label: 'Vendor',
            value: appointment.vendorName,
            icon: Icons.storefront_outlined,
            color: Colors.purple,
            onTap: () => _navigateToEntity(MarketplaceEntityType.vendor, appointment!.vendorId),
          ),
          _RelationshipNode(
            label: 'Service',
            value: appointment.serviceName,
            icon: Icons.design_services_outlined,
            color: Colors.amber.shade800,
            onTap: () => _navigateToEntity(MarketplaceEntityType.service, appointment!.serviceId),
          ),
          _RelationshipNode(
            label: 'Linked Booking',
            value: appointment.linkedChildBookingId ?? 'BK-10492',
            icon: Icons.confirmation_number_outlined,
            color: Colors.teal,
            onTap: () => _navigateToEntity(MarketplaceEntityType.booking, appointment!.linkedChildBookingId ?? 'BK-10492'),
          ),
        ]),
        const SizedBox(height: 20),

        // Schedule & Logistics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_filled, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('$dateStr at ${appointment.scheduledTime}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(appointment.location, style: const TextStyle(fontSize: 13))),
                ],
              ),
              if (appointment.customerNotes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Customer notes: "${appointment.customerNotes}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOOKING DETAIL VIEW
  // ==========================================
  Widget _buildBookingDetail(
    BuildContext context,
    AdminProvider admin,
    VendorWorkflowProvider workflow,
  ) {
    Booking? booking;
    try {
      booking = admin.bookings.firstWhere((b) => b.id == _currentId);
    } catch (_) {
      if (_currentData is Booking) {
        booking = _currentData;
      }
    }

    if (booking == null) {
      return const Text('Booking not found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking #${booking.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Customer: ${booking.userName} • Date: ${booking.date}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
              ],
            ),
            _buildStatusPill(booking.status.toUpperCase(), booking.status == 'confirmed' ? Colors.green : Colors.orange),
          ],
        ),
        const SizedBox(height: 16),

        _buildRelationshipSection([
          _RelationshipNode(
            label: 'Customer',
            value: booking.userName,
            icon: Icons.person_outline,
            color: Colors.blue,
            onTap: () => _navigateToEntity(MarketplaceEntityType.customer, booking!.userName),
          ),
          _RelationshipNode(
            label: 'Vendor',
            value: booking.vendorName,
            icon: Icons.storefront_outlined,
            color: Colors.purple,
            onTap: () => _navigateToEntity(MarketplaceEntityType.vendor, booking!.vendorId),
          ),
          _RelationshipNode(
            label: 'Package',
            value: booking.packageName,
            icon: Icons.all_inbox_outlined,
            color: Colors.indigo,
            onTap: () => _navigateToEntity(MarketplaceEntityType.package, 'pkg-royal-wedding'),
          ),
          _RelationshipNode(
            label: 'Amount',
            value: 'RM ${booking.amount.toStringAsFixed(0)}',
            icon: Icons.payments_outlined,
            color: Colors.green,
            onTap: () => _navigateToEntity(MarketplaceEntityType.payment, 'TX-84921'),
          ),
        ]),
        const SizedBox(height: 20),

        // Payment & Settlement Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn('Gross Amount', 'RM ${booking.amount.toStringAsFixed(0)}'),
              _buildMetricColumn('Platform Fee (11%)', 'RM ${(booking.amount * 0.11).toStringAsFixed(0)}'),
              _buildMetricColumn('Vendor Payout', 'RM ${(booking.amount * 0.89).toStringAsFixed(0)}'),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VENDOR DETAIL VIEW
  // ==========================================
  Widget _buildVendorDetail(
    BuildContext context,
    AdminProvider admin,
    VendorWorkflowProvider workflow,
  ) {
    AdminVendor? vendor;
    try {
      vendor = admin.vendors.firstWhere((v) => v.id == _currentId);
    } catch (_) {
      if (_currentData is AdminVendor) {
        vendor = _currentData;
      }
    }

    if (vendor == null) {
      return const Text('Vendor not found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${vendor.category} • SSM: ${vendor.ssmNumber ?? "202401089201 (1509201-X)"}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
            _buildStatusPill(vendor.verified ? 'VERIFIED' : 'PENDING', vendor.verified ? Colors.green : Colors.orange),
          ],
        ),
        const SizedBox(height: 16),

        // Vendor Health Indicators (Item 19 in prompt)
        const Text('VENDOR OPERATIONAL HEALTH INDICATORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildHealthCard('Avg Rating', '${vendor.rating} ★', '${vendor.reviews} reviews', Colors.amber.shade700),
            _buildHealthCard('Response Time', '< 15 mins', '98% within 1 hr', Colors.blue),
            _buildHealthCard('Cancellation Rate', '0.8%', 'Target < 3%', Colors.green),
            _buildHealthCard('No-Show Rate', '0.0%', '0 incidents reported', Colors.teal),
            _buildHealthCard('Refund Rate', '1.2%', 'Low dispute risk', Colors.indigo),
            _buildHealthCard('Policy Violations', '0', 'Clean record', Colors.emeraldAccent),
          ],
        ),
        const SizedBox(height: 20),

        // Vendor Documents
        const Text('Business & Compliance Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildDocTile('SSM Business Registration Certificate', 'Verified 12 Jan 2026', true),
              const Divider(height: 1),
              _buildDocTile('Public Liability Insurance (RM 1,000,000)', 'Expiring in 14 days (10 Oct 2026)', false, isWarning: true),
              const Divider(height: 1),
              _buildDocTile('Halal Jakim Kitchen Certificate', 'Valid until 30 Nov 2027', true),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SUPPORT CASE DETAIL VIEW
  // ==========================================
  Widget _buildSupportCaseDetail(
    BuildContext context,
    AdminMarketplaceProvider mkt,
    AdminProvider admin,
    VendorWorkflowProvider workflow,
  ) {
    AdminSupportCase? kase;
    try {
      kase = mkt.supportCases.firstWhere((c) => c.id == _currentId);
    } catch (_) {
      if (_currentData is AdminSupportCase) {
        kase = _currentData;
      }
    }

    if (kase == null) {
      return const Text('Support case not found.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${kase.id}: ${kase.subject}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Category: ${kase.category} • Priority: ${kase.priority} • Assigned: ${kase.assignedAdmin}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                ],
              ),
            ),
            _buildStatusPill(kase.status, kase.status == 'Resolved' ? Colors.green : Colors.red),
          ],
        ),
        const SizedBox(height: 16),

        // Clickable Relationship Entities
        _buildRelationshipSection([
          _RelationshipNode(
            label: 'Customer',
            value: kase.customerName,
            icon: Icons.person_outline,
            color: Colors.blue,
            onTap: () => _navigateToEntity(MarketplaceEntityType.customer, kase!.customerEmail),
          ),
          if (kase.vendorName != null)
            _RelationshipNode(
              label: 'Vendor',
              value: kase.vendorName!,
              icon: Icons.storefront_outlined,
              color: Colors.purple,
              onTap: () => _navigateToEntity(MarketplaceEntityType.vendor, kase!.vendorId ?? ''),
            ),
          if (kase.bookingId != null)
            _RelationshipNode(
              label: 'Booking',
              value: kase.bookingId!,
              icon: Icons.confirmation_number_outlined,
              color: Colors.teal,
              onTap: () => _navigateToEntity(MarketplaceEntityType.booking, kase!.bookingId!),
            ),
        ]),
        const SizedBox(height: 20),

        // Internal Notes
        if (kase.internalNotes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Internal Ops Note: ${kase.internalNotes}', style: const TextStyle(fontSize: 12, color: Colors.brown)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // CHRONOLOGICAL TIMELINE (Item 25 in prompt)
        const Text('CHRONOLOGICAL ACTIVITY TIMELINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey)),
        const SizedBox(height: 10),
        ...kase.timeline.map((item) {
          final timeStr = DateFormat('d MMM HH:mm').format(item.timestamp);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${item.actor} (${item.role})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text('• $timeStr', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.details, style: const TextStyle(fontSize: 12, color: Colors.black87)),
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

  // ==========================================
  // TRANSACTION DETAIL VIEW
  // ==========================================
  Widget _buildTransactionDetail(BuildContext context, AdminProvider admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transaction $_currentId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRelationshipSection([
          _RelationshipNode(label: 'Booking', value: 'BK-10492', icon: Icons.confirmation_number_outlined, color: Colors.teal, onTap: () => _navigateToEntity(MarketplaceEntityType.booking, 'BK-10492')),
          _RelationshipNode(label: 'Vendor Payout', value: 'PO-9019', icon: Icons.account_balance_outlined, color: Colors.purple),
          _RelationshipNode(label: 'Method', value: 'Credit Card (Stripe)', icon: Icons.credit_card, color: Colors.blue),
        ]),
      ],
    );
  }

  // ==========================================
  // CUSTOMER DETAIL VIEW
  // ==========================================
  Widget _buildCustomerDetail(BuildContext context, AdminProvider admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Customer: $_currentId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRelationshipSection([
          _RelationshipNode(label: 'Event', value: 'Grand Wedding 2026', icon: Icons.event_outlined, color: Colors.green),
          _RelationshipNode(label: 'Active Booking', value: 'BK-10492', icon: Icons.confirmation_number_outlined, color: Colors.teal, onTap: () => _navigateToEntity(MarketplaceEntityType.booking, 'BK-10492')),
          _RelationshipNode(label: 'Appointments', value: '1 Upcoming', icon: Icons.calendar_month_outlined, color: Colors.teal),
        ]),
      ],
    );
  }

  // ==========================================
  // COMMON HELPER WIDGETS
  // ==========================================
  Widget _buildRelationshipSection(List<_RelationshipNode> nodes) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONNECTED ENTITY RELATIONSHIPS (CLICK TO NAVIGATE)',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nodes.map((node) {
              return InkWell(
                onTap: node.onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: node.color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(node.icon, size: 14, color: node.color),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node.label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                          Text(node.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: node.color)),
                        ],
                      ),
                      if (node.onTap != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios, size: 10, color: node.color),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String title, String mainValue, String subValue, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 2),
          Text(mainValue, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(subValue, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDocTile(String title, String subtitle, bool isValid, {bool isWarning = false}) {
    return ListTile(
      dense: true,
      leading: Icon(
        isValid ? Icons.verified : (isWarning ? Icons.warning_amber_rounded : Icons.cancel),
        color: isValid ? Colors.green : (isWarning ? Colors.orange : Colors.red),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: isWarning ? Colors.orange.shade800 : Colors.grey)),
      trailing: isWarning
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange.shade800,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispatched document expiry renewal reminder to vendor.')),
                );
              },
              child: const Text('Notify Vendor', style: TextStyle(fontSize: 11)),
            )
          : null,
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}

class _RelationshipNode {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _RelationshipNode({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}
