import 'package:flutter/material.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';

class AdminMarketplaceProvider with ChangeNotifier {
  // Current active admin role
  AdminRole _currentRole = AdminRole.superAdmin;
  AdminRole get currentRole => _currentRole;

  void setAdminRole(AdminRole role) {
    _currentRole = role;
    notifyListeners();
  }

  // Active saved view
  String _activeSavedView = 'Default';
  String get activeSavedView => _activeSavedView;

  final List<String> savedViews = [
    'Default',
    'My Pending Approvals',
    'Expiring Documents',
    'Unresolved Package Issues',
    'Failed Payments',
    'High Priority Cases',
    'Services Missing Photos',
    'Vendors Awaiting Documents',
    'Booking Exceptions',
  ];

  void setSavedView(String view) {
    _activeSavedView = view;
    notifyListeners();
  }

  // Safe read-only impersonation mode
  String? _readOnlyPreviewMode; // null, 'customer', 'vendor'
  String? get readOnlyPreviewMode => _readOnlyPreviewMode;

  void setReadOnlyPreviewMode(String? mode) {
    _readOnlyPreviewMode = mode;
    notifyListeners();
  }

  // Support cases
  final List<AdminSupportCase> _supportCases = [];
  List<AdminSupportCase> get supportCases => List.unmodifiable(_supportCases);

  CategoryDynamicConfig? getCategoryConfig(String categoryName) {
    return _categoryConfigs.firstWhere(
      (config) => config.categoryName.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => _categoryConfigs.first,
    );
  }

  void publishNewVersion({
    required String categoryName,
    required String versionNumber,
    required String changelog,
    required String publishedBy,
    List<String>? fields,
    List<String>? appointmentTypes,
    Map<String, dynamic>? packageRules,
    Map<String, dynamic>? bookingRules,
    Map<String, dynamic>? pricingRules,
    Map<String, dynamic>? travelRules,
  }) {
    final index = _categoryConfigs.indexWhere((c) => c.categoryName.toLowerCase() == categoryName.toLowerCase());
    if (index < 0) return;

    final config = _categoryConfigs[index];
    final newVersion = CategoryConfigVersion(
      version: versionNumber,
      publishedAt: DateTime.now(),
      publishedBy: publishedBy,
      changelog: changelog,
      isLive: true,
      fields: fields ?? config.currentVersion.fields,
      appointmentTypes: appointmentTypes ?? config.currentVersion.appointmentTypes,
      packageRules: packageRules ?? config.currentVersion.packageRules,
      bookingRules: bookingRules ?? config.currentVersion.bookingRules,
      pricingRules: pricingRules ?? config.currentVersion.pricingRules,
      travelRules: travelRules ?? config.currentVersion.travelRules,
    );

    _categoryConfigs[index] = CategoryDynamicConfig(
      id: config.id,
      categoryName: config.categoryName,
      icon: config.icon,
      color: config.color,
      activeVersion: versionNumber,
      versions: [newVersion, ...config.versions],
    );
    notifyListeners();
  }

  void migrateServicesToLatestVersion(String categoryName) {
    // Compatibility no-op for the admin workflow UI.
    final config = getCategoryConfig(categoryName);
    if (config == null) return;
    notifyListeners();
  }

  void addCaseTimelineItem(String caseId, AdminCaseTimelineItem item) {
    final index = _supportCases.indexWhere((c) => c.id == caseId);
    if (index < 0) return;

    final caseItem = _supportCases[index];
    _supportCases[index] = caseItem.copyWith(
      timeline: [...caseItem.timeline, item],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // Booking exceptions
  final List<BookingExceptionItem> _bookingExceptions = [];
  List<BookingExceptionItem> get bookingExceptions => List.unmodifiable(_bookingExceptions);

  // Audit logs
  final List<AdminAuditLogEntry> _auditLogs = [];
  List<AdminAuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);

  // Dynamic Category Configurations
  final List<CategoryDynamicConfig> _categoryConfigs = [];
  List<CategoryDynamicConfig> get categoryConfigs => List.unmodifiable(_categoryConfigs);

  // Potential Duplicates
  final List<DuplicateMatch> _duplicateMatches = [];
  List<DuplicateMatch> get duplicateMatches => List.unmodifiable(_duplicateMatches);

  // GLOBAL SEARCH ENGINE
  // ==========================================
  List<AdminSearchResult> searchMarketplace({
    required String query,
    required AdminProvider admin,
    required List<CommonServiceInfo> workflowServices,
    required List<CollaborativePackage> workflowPackages,
    required List<ServiceAppointmentBooking> workflowAppointments,
  }) {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    final List<AdminSearchResult> results = [];

    // 1. Search Vendors
    for (final v in admin.vendors) {
      if (v.name.toLowerCase().contains(q) ||
          v.category.toLowerCase().contains(q) ||
          v.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: v.id,
          title: v.name,
          subtitle: '${v.category} • Rating: ${v.rating} (${v.reviews} reviews)',
          type: MarketplaceEntityType.vendor,
          status: v.suspended ? 'Suspended' : (v.verified ? 'Verified' : 'Pending'),
          metadata: {'vendorId': v.id, 'vendor': v},
        ));
      }
    }

    // 2. Search Services
    for (final s in workflowServices) {
      if (s.serviceName.toLowerCase().contains(q) ||
          s.category.displayName.toLowerCase().contains(q) ||
          s.vendorName.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: s.id,
          title: s.serviceName,
          subtitle: 'Vendor: ${s.vendorName} • Category: ${s.category.displayName} • RM ${s.startingPrice.toStringAsFixed(0)}',
          type: MarketplaceEntityType.service,
          status: s.status.displayName,
          metadata: {'serviceId': s.id, 'service': s},
        ));
      }
    }

    // 3. Search Packages
    for (final p in workflowPackages) {
      if (p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: p.id,
          title: p.title,
          subtitle: 'RM ${p.basePrice.toStringAsFixed(0)} • ${p.components.length} components • Events: ${p.eventTypes.join(", ")}',
          type: MarketplaceEntityType.package,
          status: p.status.displayName,
          metadata: {'packageId': p.id, 'package': p},
        ));
      }
    }

    // 4. Search Appointments
    for (final a in workflowAppointments) {
      if (a.appointmentTypeName.toLowerCase().contains(q) ||
          a.customerName.toLowerCase().contains(q) ||
          a.vendorName.toLowerCase().contains(q) ||
          a.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: a.id,
          title: '${a.appointmentTypeName} (${a.customerName})',
          subtitle: 'Vendor: ${a.vendorName} • Date: ${a.scheduledDate.toString().split(" ")[0]} at ${a.scheduledTime}',
          type: MarketplaceEntityType.appointment,
          status: a.status.displayName,
          metadata: {'appointmentId': a.id, 'appointment': a},
        ));
      }
    }

    // 5. Search Bookings
    for (final b in admin.bookings) {
      if (b.id.toLowerCase().contains(q) ||
          b.userName.toLowerCase().contains(q) ||
          b.vendorName.toLowerCase().contains(q) ||
          b.packageName.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: b.id,
          title: 'Booking ${b.id} — ${b.userName}',
          subtitle: 'Vendor: ${b.vendorName} • Package: ${b.packageName} • RM ${b.amount.toStringAsFixed(0)}',
          type: MarketplaceEntityType.booking,
          status: b.status.toUpperCase(),
          metadata: {'bookingId': b.id, 'booking': b},
        ));
      }
    }

    // 6. Search Transactions
    for (final t in admin.transactions) {
      if (t.id.toLowerCase().contains(q) ||
          t.party.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: t.id,
          title: 'Transaction ${t.id} — RM ${t.amount.toStringAsFixed(2)}',
          subtitle: 'Party: ${t.party} • Date: ${t.date}',
          type: MarketplaceEntityType.payment,
          status: t.status.toUpperCase(),
          metadata: {'transactionId': t.id, 'transaction': t},
        ));
      }
    }

    // 7. Search Support Cases
    for (final c in _supportCases) {
      if (c.id.toLowerCase().contains(q) ||
          c.subject.toLowerCase().contains(q) ||
          c.customerName.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: c.id,
          title: '${c.id}: ${c.subject}',
          subtitle: 'Customer: ${c.customerName} • Category: ${c.category} • Priority: ${c.priority}',
          type: MarketplaceEntityType.supportCase,
          status: c.status,
          metadata: {'caseId': c.id, 'case': c},
        ));
      }
    }

    // 8. Search Users / Customers
    for (final u in admin.users) {
      if (u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: u.id,
          title: u.name,
          subtitle: '${u.email} • Role: ${u.role.toUpperCase()}',
          type: MarketplaceEntityType.customer,
          status: u.status.toUpperCase(),
          metadata: {'userId': u.id, 'user': u},
        ));
      }
    }

    return results;
  }

  // ==========================================
  // CASE ACTIONS
  // ==========================================
  void updateCaseStatus(String caseId, String newStatus, [String adminName = 'System']) {
    final index = _supportCases.indexWhere((c) => c.id == caseId);
    if (index >= 0) {
      final oldCase = _supportCases[index];
      final newTimeline = List<AdminCaseTimelineItem>.from(oldCase.timeline)
        ..add(AdminCaseTimelineItem(
          actor: adminName,
          role: 'Admin',
          action: 'Updated Status',
          details: 'Status changed from ${oldCase.status} to $newStatus',
          timestamp: DateTime.now(),
        ));
      _supportCases[index] = oldCase.copyWith(status: newStatus, timeline: newTimeline);
      logAdminAction(
        adminName: adminName,
        action: 'Updated Support Case Status',
        entityType: 'Support Case',
        entityId: caseId,
        entityName: oldCase.subject,
        details: 'Changed status to $newStatus',
      );
      notifyListeners();
    }
  }

  void addCaseMessage({
    required String caseId,
    required String actor,
    required String role,
    required String action,
    required String message,
  }) {
    final index = _supportCases.indexWhere((c) => c.id == caseId);
    if (index >= 0) {
      final oldCase = _supportCases[index];
      final newTimeline = List<AdminCaseTimelineItem>.from(oldCase.timeline)
        ..add(AdminCaseTimelineItem(
          actor: actor,
          role: role,
          action: action,
          details: message,
          timestamp: DateTime.now(),
        ));
      _supportCases[index] = oldCase.copyWith(timeline: newTimeline);
      notifyListeners();
    }
  }

  // ==========================================
  // AUDIT LOG RECORDER
  // ==========================================
  void logAdminAction({
    required String adminName,
    required String action,
    required String entityType,
    required String entityId,
    required String entityName,
    required String details,
  }) {
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        id: 'LOG-${DateTime.now().millisecondsSinceEpoch % 100000}',
        adminName: adminName,
        role: _currentRole.title,
        action: action,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        details: details,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // DUPLICATE ACTIONS
  // ==========================================
  void resolveDuplicate(String duplicateId, String resolution) {
    _duplicateMatches.removeWhere((d) => d.id == duplicateId);
    logAdminAction(
      adminName: 'Admin',
      action: 'Resolved Duplicate',
      entityType: 'Duplicate Detection',
      entityId: duplicateId,
      entityName: duplicateId,
      details: 'Resolution chosen: $resolution',
    );
    notifyListeners();
  }

  // ==========================================
  // CATEGORY CONFIG PUBLISHING
  // ==========================================
  void publishCategoryVersion({
    required String categoryId,
    required String newVersionNumber,
    required String changelog,
    required List<String> fields,
    required List<String> appointmentTypes,
    required String adminName,
  }) {
    final index = _categoryConfigs.indexWhere((c) => c.id == categoryId);
    if (index >= 0) {
      final oldConfig = _categoryConfigs[index];
      final newVersion = CategoryConfigVersion(
        version: newVersionNumber,
        publishedAt: DateTime.now(),
        publishedBy: adminName,
        changelog: changelog,
        isLive: true,
        fields: fields,
        appointmentTypes: appointmentTypes,
        packageRules: oldConfig.currentVersion.packageRules,
        bookingRules: oldConfig.currentVersion.bookingRules,
        pricingRules: oldConfig.currentVersion.pricingRules,
        travelRules: oldConfig.currentVersion.travelRules,
      );

      final updatedVersions = [newVersion, ...oldConfig.versions];
      _categoryConfigs[index] = CategoryDynamicConfig(
        id: oldConfig.id,
        categoryName: oldConfig.categoryName,
        icon: oldConfig.icon,
        color: oldConfig.color,
        activeVersion: newVersionNumber,
        versions: updatedVersions,
      );

      logAdminAction(
        adminName: adminName,
        action: 'Published Category Version',
        entityType: 'Category',
        entityId: categoryId,
        entityName: oldConfig.categoryName,
        details: 'Published version $newVersionNumber: $changelog',
      );
      notifyListeners();
    }
  }
}
