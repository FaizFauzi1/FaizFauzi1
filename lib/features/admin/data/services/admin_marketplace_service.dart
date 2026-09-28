import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';

/// Admin Role definition with associated permissions
enum AdminRole {
  superAdmin('Super Admin', 'Full unrestricted platform access'),
  marketplaceAdmin('Marketplace Admin', 'Catalog, services, packages, categories'),
  vendorAdmin('Vendor Admin', 'Vendor onboarding, verification, documents'),
  financeAdmin('Finance Admin', 'Payments, payouts, refunds, commission'),
  customerSupport('Customer Support', 'Disputes, requests, customer inquiries'),
  contentModerator('Content Moderator', 'Reviews, listings, reports, media'),
  eventAdmin('Event Admin', 'Events oversight, expos, organizers'),
  analyticsAdmin('Analytics Admin', 'Read-only business analytics & reports');

  final String title;
  final String description;
  const AdminRole(this.title, this.description);
}

/// Unified Entity Types in the marketplace
enum MarketplaceEntityType {
  customer('Customer', Icons.person_outline, Color(0xFF3B82F6)),
  vendor('Vendor', Icons.storefront_outlined, Color(0xFF8B5CF6)),
  organizer('Organizer', Icons.festival_outlined, Color(0xFFEC4899)),
  event('Event', Icons.event_outlined, Color(0xFF10B981)),
  service('Service', Icons.design_services_outlined, Color(0xFFF59E0B)),
  product('Product', Icons.inventory_2_outlined, Color(0xFF06B6D4)),
  rental('Rental', Icons.chair_outlined, Color(0xFFF97316)),
  package('Package', Icons.all_inbox_outlined, Color(0xFF6366F1)),
  appointment('Appointment', Icons.calendar_month_outlined, Color(0xFF14B8A6)),
  booking('Booking', Icons.confirmation_number_outlined, Color(0xFF059669)),
  payment('Payment / Transaction', Icons.payments_outlined, Color(0xFF84CC16)),
  supportCase('Support Case', Icons.support_agent_outlined, Color(0xFFEF4444)),
  document('Vendor Document', Icons.description_outlined, Color(0xFF64748B)),
  category('Category', Icons.category_outlined, Color(0xFF14B8A6));

  final String label;
  final IconData icon;
  final Color color;
  const MarketplaceEntityType(this.label, this.icon, this.color);
}

/// Entity Search Result Item for Global Admin Search
class AdminSearchResult {
  final String id;
  final String title;
  final String subtitle;
  final MarketplaceEntityType type;
  final String? status;
  final Map<String, dynamic> metadata;

  AdminSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.status,
    this.metadata = const {},
  });
}

/// Support Case Model for Admin Case Management
class AdminSupportCase {
  final String id;
  final String customerName;
  final String customerEmail;
  final String? vendorId;
  final String? vendorName;
  final String? bookingId;
  final String? packageId;
  final String? eventName;
  final String subject;
  final String category; // 'Booking Problem', 'Payment Problem', 'Vendor Issue', 'Cancellation', 'Refund', etc.
  final String priority; // 'Urgent', 'High', 'Medium', 'Low'
  final String status; // 'New', 'In Progress', 'Waiting for Vendor', 'Waiting for Customer', 'Escalated', 'Resolved', 'Closed'
  final String assignedAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminCaseTimelineItem> timeline;
  final String internalNotes;
  final String? resolution;

  AdminSupportCase({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    this.vendorId,
    this.vendorName,
    this.bookingId,
    this.packageId,
    this.eventName,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.assignedAdmin,
    required this.createdAt,
    required this.updatedAt,
    required this.timeline,
    this.internalNotes = '',
    this.resolution,
  });

  AdminSupportCase copyWith({
    String? status,
    String? assignedAdmin,
    String? internalNotes,
    String? resolution,
    List<AdminCaseTimelineItem>? timeline,
  }) {
    return AdminSupportCase(
      id: id,
      customerName: customerName,
      customerEmail: customerEmail,
      vendorId: vendorId,
      vendorName: vendorName,
      bookingId: bookingId,
      packageId: packageId,
      eventName: eventName,
      subject: subject,
      category: category,
      priority: priority,
      status: status ?? this.status,
      assignedAdmin: assignedAdmin ?? this.assignedAdmin,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      timeline: timeline ?? this.timeline,
      internalNotes: internalNotes ?? this.internalNotes,
      resolution: resolution ?? this.resolution,
    );
  }
}

/// Case Timeline Entry
class AdminCaseTimelineItem {
  final String actor;
  final String role; // 'Admin', 'Customer', 'Vendor', 'System'
  final String action;
  final String details;
  final DateTime timestamp;

  AdminCaseTimelineItem({
    required this.actor,
    required this.role,
    required this.action,
    required this.details,
    required this.timestamp,
  });
}

/// Audit Log Entry
class AdminAuditLogEntry {
  final String id;
  final String adminName;
  final String role;
  final String action; // 'Approved Service', 'Changed Package Price', 'Rejected Vendor', 'Processed Refund', etc.
  final String entityType; // 'Service', 'Package', 'Vendor', 'Booking', 'Category'
  final String entityId;
  final String entityName;
  final String details;
  final DateTime timestamp;

  AdminAuditLogEntry({
    required this.id,
    required this.adminName,
    required this.role,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.details,
    required this.timestamp,
  });
}

/// Category Dynamic Configuration Version
class CategoryConfigVersion {
  final String version; // '1.0', '1.1', '2.0'
  final DateTime publishedAt;
  final String publishedBy;
  final String changelog;
  final bool isLive;
  final List<String> fields;
  final List<String> appointmentTypes;
  final Map<String, dynamic> packageRules;
  final Map<String, dynamic> bookingRules;
  final Map<String, dynamic> pricingRules;
  final Map<String, dynamic> travelRules;

  CategoryConfigVersion({
    required this.version,
    required this.publishedAt,
    required this.publishedBy,
    required this.changelog,
    required this.isLive,
    required this.fields,
    required this.appointmentTypes,
    required this.packageRules,
    required this.bookingRules,
    required this.pricingRules,
    required this.travelRules,
  });
}

/// Category Dynamic Config Definition
class CategoryDynamicConfig {
  final String id;
  final String categoryName;
  final IconData icon;
  final Color color;
  final String activeVersion;
  final List<CategoryConfigVersion> versions;

  CategoryDynamicConfig({
    required this.id,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.activeVersion,
    required this.versions,
  });

  CategoryConfigVersion get currentVersion =>
      versions.firstWhere((v) => v.version == activeVersion, orElse: () => versions.first);

  CategoryConfigVersion get activeConfig => currentVersion;
}

/// Potential Duplicate Entity Item
class DuplicateMatch {
  final String id;
  final String entityType; // 'Vendor', 'Service', 'Package'
  final String name1;
  final String name2;
  final String id1;
  final String id2;
  final double similarityScore; // 0.0 - 1.0
  final String reason;
  final Map<String, dynamic> details1;
  final Map<String, dynamic> details2;

  DuplicateMatch({
    required this.id,
    required this.entityType,
    required this.name1,
    required this.name2,
    required this.id1,
    required this.id2,
    required this.similarityScore,
    required this.reason,
    required this.details1,
    required this.details2,
  });
}

/// Booking Exception Item
class BookingExceptionItem {
  final String id;
  final String bookingId;
  final String customerName;
  final String vendorName;
  final String eventName;
  final DateTime eventDate;
  final String issueType; // 'Payment Failed', 'Vendor Cancelled', 'Vendor Unavailable', 'Date Conflict', 'Component Missing', 'Refund Pending'
  final String description;
  final String severity; // 'Critical', 'Warning', 'Info'
  final double amount;
  final String status; // 'Unresolved', 'In Progress', 'Resolved'

  BookingExceptionItem({
    required this.id,
    required this.bookingId,
    required this.customerName,
    required this.vendorName,
    required this.eventName,
    required this.eventDate,
    required this.issueType,
    required this.description,
    required this.severity,
    required this.amount,
    this.status = 'Unresolved',
  });
}
