import 'dart:convert';

import 'package:eventease/shared/models/region.dart';
import 'package:eventease/shared/models/seed_data.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/models/service_template_models.dart';
import 'package:eventease/shared/models/sample_service_packages.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:eventease/features/vendor/data/models/subscription_model.dart';
import 'package:eventease/features/vendor/data/models/subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';
import 'package:eventease/core/services/bypass_incident_recorder.dart';
import 'package:eventease/core/services/payment_service.dart';
import 'package:eventease/shared/models/bank_account.dart';

enum VendorStatus { pending, approved, suspended }

enum DocumentType {
  businessLicense,
  taxCertificate,
  insuranceCertificate,
  identification,
  bankStatement,
  other
}

class VendorDocument {
  final String id;
  final DocumentType type;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  bool isVerified;
  String? verificationNotes;
  DateTime? verifiedAt;

  VendorDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    this.isVerified = false,
    this.verificationNotes,
    this.verifiedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isVerified': isVerified,
      'verificationNotes': verificationNotes,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory VendorDocument.fromJson(Map<String, dynamic> json) {
    return VendorDocument(
      id: json['id'],
      type: DocumentType.values.firstWhere(
        (e) => e.toString() == json['type'] || e.toString().split('.').last == json['document_type'],
        orElse: () => DocumentType.other,
      ),
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      fileUrl: json['file_url'] ?? json['fileUrl'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? json['uploadedAt']),
      isVerified: (json['status'] == 'approved') || (json['is_verified'] == true) || (json['verified'] == true) || (json['isVerified'] == true),
      verificationNotes: json['rejection_reason'] ?? json['verificationNotes'],
      verifiedAt: (json['reviewed_at'] ?? json['verified_at'] ?? json['verifiedAt'] ?? json['verification_date']) != null 
          ? DateTime.parse(json['reviewed_at'] ?? json['verified_at'] ?? json['verifiedAt'] ?? json['verification_date']) 
          : null,
    );
  }
}

class AdminVendor {
  final String id;
  String name;
  String category;
  bool verified;
  bool suspended;
  double rating;
  int reviews;
  int bookings;
  List<String> serviceAreas;
  bool pendingApproval;
  String? contactInfo;

  // Document-related fields
  List<VendorDocument> documents;
  bool documentsVerified;
  String? documentVerificationNotes;
  DateTime? documentsVerifiedAt;
  String subscriptionTier; // starter, pro, business
  DateTime? subscriptionExpiry;
  bool isClaimed;
  String? claimCode;
  double? commissionRate;
  bool commissionOverride;
  double priorityScore;
  String registrationSource; // 'admin' or 'self'
  // Extended Profile Fields
  String? phone;
  String? email;
  String? address;
  String? ssmNumber;
  String? legalName;
  String? businessType;
  double? startingPrice;
  int completionPercentage;
  List<String> subcategories;

  AdminVendor(
    this.id,
    this.name,
    this.category,
    this.verified,
    this.suspended,
    this.rating,
    this.reviews,
    this.bookings,
    this.serviceAreas,
    this.pendingApproval, {
    this.contactInfo,
    this.documents = const [],
    this.documentsVerified = false,
    this.documentVerificationNotes,
    this.documentsVerifiedAt,
    this.subscriptionTier = 'starter',
    this.subscriptionExpiry,
    this.isClaimed = true,
    this.claimCode,
    this.commissionRate,
    this.commissionOverride = false,
    this.priorityScore = 0.0,
    this.registrationSource = 'self',
    this.phone,
    this.email,
    this.address,
    this.ssmNumber,
    this.legalName,
    this.businessType,
    this.startingPrice,
    this.completionPercentage = 0,
    this.subcategories = const [],
  });
}

class AppUser {
  final String id;
  String name;
  String email;
  String role; // bride, groom, planner, guest
  String status; // active, banned
  String subscriptionTier; // free, wedding_pass
  DateTime? subscriptionExpiry;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
  });
}

class Booking {
  final String id;
  String userName;
  String vendorName;
  String vendorId; // Added for invoicing
  String packageName; // Added for invoicing
  String date; // simplified
  double amount;
  String status; // pending, confirmed, cancelled
  bool priority;
  final dynamic installmentPlan; // Added for installment visibility

  Booking({
    required this.id,
    required this.userName,
    required this.vendorName,
    required this.vendorId,
    required this.packageName,
    required this.date,
    required this.amount,
    required this.status,
    required this.priority,
    this.installmentPlan,
  });
}

class TransactionEntry {
  final String id;
  String party;
  double amount;
  String status; // paid, pending, refunded
  String date;
  String? serviceId;
  String? vendorId;

  TransactionEntry({
    required this.id,
    required this.party,
    required this.amount,
    required this.status,
    required this.date,
    this.serviceId,
    this.vendorId,
  });

  get title => null;
}

// Additional classes needed by admin dashboard
class ReportedUser {
  final String user;
  final String reason;
  ReportedUser({required this.user, required this.reason});
}

class Invitation {
  final String name;
  final String status;
  Invitation({required this.name, required this.status});
}

class Appointment {
  final String type;
  final String title;
  final String date;
  final String vendor;
  Appointment(
      {required this.type,
      required this.title,
      required this.date,
      required this.vendor});
}

class Rental {
  final String item;
  final String user;
  final int deposit;
  final String status;
  Rental({
    required this.item,
    required this.user,
    required this.deposit,
    required this.status,
  });
}

class Payout {
  final String id;
  final String vendor;
  final String? vendorId;
  final String? bankAccountId;
  final double amount;
  final String status;
  final String date;

  Payout({
    required this.id,
    required this.vendor,
    this.vendorId,
    this.bankAccountId,
    required this.amount,
    required this.status,
    required this.date,
  });
}

class OverduePayment {
  final String user;
  final int amount;
  final int days;
  OverduePayment(
      {required this.user, required this.amount, required this.days});
}

class Listing {
  final String id;
  final String title;
  final String category;
  final int price;
  final String status; // pending, approved, rejected, suspended
  final bool isVerified;
  final bool isPinned;
  final int views;
  final int bookings;
  final double conversionRate;
  final String? vendorId;
  final String? vendorName;
  final DateTime? createdAt;

  Listing({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    this.status = 'pending',
    this.isVerified = false,
    this.isPinned = false,
    this.views = 0,
    this.bookings = 0,
    this.conversionRate = 0.0,
    this.vendorId,
    this.vendorName,
    this.createdAt,
  });

  Listing copyWith({
    String? id, String? title, String? category, int? price,
    String? status, bool? isVerified, bool? isPinned,
    int? views, int? bookings, double? conversionRate,
    String? vendorId, String? vendorName, DateTime? createdAt,
  }) {
    return Listing(
      id: id ?? this.id, title: title ?? this.title,
      category: category ?? this.category, price: price ?? this.price,
      status: status ?? this.status, isVerified: isVerified ?? this.isVerified,
      isPinned: isPinned ?? this.isPinned, views: views ?? this.views,
      bookings: bookings ?? this.bookings, conversionRate: conversionRate ?? this.conversionRate,
      vendorId: vendorId ?? this.vendorId, vendorName: vendorName ?? this.vendorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Promotion {
  final String id;
  final String title;
  final String validTill;
  final String? campaignType; // platform_wide, vendor, flash_deal
  final String? description;
  final double? discountPercent;
  final String? targetRegion; // state-based targeting
  final String? targetCategory; // photography, catering, etc.
  final String status; // draft, active, expired, paused
  final DateTime? startDate;
  final DateTime? endDate;
  final int redemptions;

  Promotion({
    required this.id,
    required this.title,
    required this.validTill,
    this.campaignType = 'vendor',
    this.description,
    this.discountPercent,
    this.targetRegion,
    this.targetCategory,
    this.status = 'active',
    this.startDate,
    this.endDate,
    this.redemptions = 0,
  });

  Promotion copyWith({
    String? id, String? title, String? validTill, String? campaignType,
    String? description, double? discountPercent, String? targetRegion,
    String? targetCategory, String? status, DateTime? startDate,
    DateTime? endDate, int? redemptions,
  }) {
    return Promotion(
      id: id ?? this.id, title: title ?? this.title,
      validTill: validTill ?? this.validTill, campaignType: campaignType ?? this.campaignType,
      description: description ?? this.description, discountPercent: discountPercent ?? this.discountPercent,
      targetRegion: targetRegion ?? this.targetRegion, targetCategory: targetCategory ?? this.targetCategory,
      status: status ?? this.status, startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate, redemptions: redemptions ?? this.redemptions,
    );
  }
}

class AdEntry {
  final String id;
  final String title;
  final String advertiser;
  /// UI uses "platform" terminology; keep a compatible field name here.
  final String platform; // landing_page, detail_view, search_results, etc.
  final String pricingTier; // basic, premium, elite
  final String status; // pending, approved, active, paused, expired
  final int impressions;
  final int clicks;
  final double budget;
  final double spent;
  final List<String> targetRegions;
  final List<String> targetCategories;
  final DateTime? startDate;
  final DateTime? endDate;

  AdEntry({
    required this.id,
    required this.title,
    required this.advertiser,
    String? platform,
    String? placementType,
    this.pricingTier = 'basic',
    this.status = 'pending',
    this.impressions = 0,
    this.clicks = 0,
    this.budget = 0,
    this.spent = 0,
    this.targetRegions = const [],
    this.targetCategories = const [],
    this.startDate,
    this.endDate,
  }) : platform = platform ?? placementType ?? 'search_results';

  /// Backwards-compatible alias for older code paths.
  String get placementType => platform;

  double get ctr => impressions > 0 ? (clicks / impressions * 100) : 0;

  AdEntry copyWith({
    String? id,
    String? title,
    String? advertiser,
    String? platform,
    String? placementType,
    String? pricingTier,
    String? status,
    int? impressions,
    int? clicks,
    double? budget,
    double? spent,
    List<String>? targetRegions,
    List<String>? targetCategories,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AdEntry(
      id: id ?? this.id, title: title ?? this.title,
      advertiser: advertiser ?? this.advertiser,
      platform: platform ?? placementType ?? this.platform,
      pricingTier: pricingTier ?? this.pricingTier, status: status ?? this.status,
      impressions: impressions ?? this.impressions, clicks: clicks ?? this.clicks,
      budget: budget ?? this.budget, spent: spent ?? this.spent,
      targetRegions: targetRegions ?? this.targetRegions,
      targetCategories: targetCategories ?? this.targetCategories,
      startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
    );
  }
}

class Article {
  final String id;
  final String title;
  final String author;
  final String? content;
  final String status;
  final String? category; // event_guide, vendor_tips, budgeting, general
  final String? linkedVendorId;
  final String? linkedVendorName;
  final String? ctaType; // book_vendor, view_package, get_quote, none
  final String? ctaLink;
  final String? featuredImage;
  final int views;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  Article({
    required this.id,
    required this.title,
    required this.author,
    this.content,
    this.status = 'draft',
    this.category,
    this.linkedVendorId,
    this.linkedVendorName,
    this.ctaType,
    this.ctaLink,
    this.featuredImage,
    this.views = 0,
    this.publishedAt,
    this.createdAt,
  });

  Article copyWith({
    String? id, String? title, String? author, String? content,
    String? status, String? category, String? linkedVendorId,
    String? linkedVendorName, String? ctaType, String? ctaLink,
    String? featuredImage, int? views, DateTime? publishedAt, DateTime? createdAt,
  }) {
    return Article(
      id: id ?? this.id, title: title ?? this.title,
      author: author ?? this.author, content: content ?? this.content,
      status: status ?? this.status, category: category ?? this.category,
      linkedVendorId: linkedVendorId ?? this.linkedVendorId,
      linkedVendorName: linkedVendorName ?? this.linkedVendorName,
      ctaType: ctaType ?? this.ctaType, ctaLink: ctaLink ?? this.ctaLink,
      featuredImage: featuredImage ?? this.featuredImage,
      views: views ?? this.views, publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BudgetSummary {
  final String couple;
  final int total;
  final int spent;
  BudgetSummary(
      {required this.couple, required this.total, required this.spent});
}

class RSVPEntry {
  final String event;
  final int yes;
  final int no;
  final int pending;
  RSVPEntry(
      {required this.event,
      required this.yes,
      required this.no,
      required this.pending});
}

class Suggestion {
  final String couple;
  final String suggestion;
  Suggestion({required this.couple, required this.suggestion});
}

class Dispute {
  final String caseId;
  final String parties;
  final String status;
  final String severity;
  final String comments;
  final String note;
  Dispute({
    required this.caseId,
    required this.parties,
    required this.status,
    this.severity = 'Medium',
    this.comments = '',
    this.note = '',
  });
}

class ReviewModeration {
  final String id;
  final String reviewer;
  final String reason;
  ReviewModeration(
      {required this.id, required this.reviewer, required this.reason});
}

class Appeal {
  final String caseId;
  final String status;
  final String comments;
  final String reason;
  Appeal({
    required this.caseId,
    required this.status,
    this.comments = '',
    this.reason = '',
  });
}

class Announcement {
  final String message;
  final String date;
  final String audience;
  bool pinned;
  Announcement({
    required this.message,
    required this.date,
    required this.audience,
    this.pinned = false,
  });
}

class LoginEvent {
  final String user;
  final String time;
  final String ip;
  LoginEvent({required this.user, required this.time, required this.ip});
}

class RoleAssignment {
  final String user;
  final String role;
  RoleAssignment({required this.user, required this.role});
}

class ActivityLog {
  final String title;
  final String subtitle;
  final String time;
  final String type; // 'registration', 'payment', 'dispute', 'system'
  final String? action;

  ActivityLog({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.action,
  });
}

class ApiIntegration {
  final String name;
  final String status;
  ApiIntegration({required this.name, required this.status});
}

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // Real-time subscriptions
  RealtimeChannel? _vendorsChannel;
  RealtimeChannel? _bookingsChannel;
  RealtimeChannel? _transactionsChannel;
  RealtimeChannel? _regionsChannel;
  RealtimeChannel? _serviceCategoriesChannel;

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Single declarations of cached data
  List<AppUser> _users = [];
  List<AdminVendor> _vendors = [];
  List<Region> _regions = [];
  List<VendorService> _allServices = [];
  List<ServiceCategory> _serviceCategories = [];
  List<Booking> _bookings = [];
  List<TransactionEntry> _transactions = [];
  List<Appointment> _appointments = [];
  List<Rental> _rentals = [];
  List<Payout> _payouts = [];
  List<OverduePayment> _overdues = [];
  List<Listing> _listings = [];
  List<Promotion> _promotions = [];
  List<AdEntry> _ads = [];
  List<Article> _articles = [];
  List<BudgetSummary> _budgets = [];
  List<RSVPEntry> _rsvps = [];
  List<Suggestion> _suggestions = [];
  List<Dispute> _disputes = [];
  List<ReviewModeration> _reviewQueue = [];
  List<Appeal> _appeals = [];
  List<Announcement> _announcements = [];
  List<LoginEvent> _logins = [];
  List<RoleAssignment> _roles = [];
  List<ActivityLog> _activity = [];
  List<ApiIntegration> _apis = [];
  List<SubscriptionPayment> _allSubscriptionPayments = [];
  



  // Vendor user documents cache
  Map<String, List<VendorDocument>> _vendorUserDocuments = {};

  // Total documents counters
  int _totalDocuments = 0;
  int _verifiedDocuments = 0;

  // Getter for vendor user documents
  List<VendorDocument> getVendorUserDocuments(String userId) {
    return _vendorUserDocuments[userId] ?? [];
  }

  // Pending services
  List<VendorService> _pendingServices = [];
  List<VendorService> get pendingServices => _pendingServices;

  Future<void> _loadPendingServices() async {
    try {
      final response = await _supabase
          .from('vendor_services')
          .select('*, vendor:vendor_profiles(business_name)')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);

      final List<VendorService> services = [];
      for (final json in (response as List)) {
        try {
          if (json['vendor'] != null) {
            json['vendor_name'] = json['vendor']['business_name'];
          }
           services.add(VendorService.fromJson(json));
        } catch (e, st) {
          print('Error parsing pending service from JSON: $e\n$st');
        }
      }

      // Load structured data for each service
      _pendingServices = await _loadStructuredDataForServices(services);
      
      notifyListeners();
    } catch (e) {
      print('Error loading pending services: $e');
    }
  }

  Future<List<VendorService>> _loadStructuredDataForServices(List<VendorService> services) async {
    if (services.isEmpty) return [];
    
    final List<VendorService> enrichedServices = [];
    
    for (var service in services) {
      try {
        // Load tiers
        final tiersData = await _supabase
            .from('service_pricing_tiers')
            .select()
            .eq('service_id', service.id);
            
        final tiers = (tiersData as List).map((t) => ServicePricingTier(
          id: t['id'],
          name: t['name'],
          minPax: t['min_pax'],
          maxPax: t['max_pax'],
          price: (t['price'] as num).toDouble(),
          description: t['description'],
        )).toList();

        // Load components
        final componentsData = await _supabase
            .from('service_components')
            .select('*, service_items(*)')
            .eq('service_id', service.id);
            
        final components = (componentsData as List).map((c) {
          final itemsData = c['service_items'] as List;
          final items = itemsData.map((i) => ServiceItem(
            id: i['id'],
            name: i['name'],
            quantity: i['quantity'],
            unitPrice: (i['unit_price'] as num?)?.toDouble() ?? 0.0,
            description: i['description'],
          )).toList();

          return ServiceComponent(
            id: c['id'],
            name: c['name'],
            componentType: c['component_type'],
            items: items,
          );
        }).toList();

        enrichedServices.add(service.copyWith(
          pricingTiers: tiers,
          components: components,
        ));
      } catch (e) {
        print('Error loading structured data for service ${service.id}: $e');
        enrichedServices.add(service);
      }
    }
    
    return enrichedServices;
  }

  Future<void> approveService(String serviceId) async {
    try {
      // Find service details for notification
      VendorService? service;
      try {
        service = _allServices.firstWhere(
          (s) => s.id == serviceId,
          orElse: () => _pendingServices.firstWhere((s) => s.id == serviceId),
        );
      } catch (_) {
        // If not in lists, we might need a fetch, but usually it is in pending
      }

      await _supabase
          .from('vendor_services')
          .update({'approval_status': 'approved'})
          .eq('id', serviceId);
      
      if (service != null) {
        await _notificationService.sendServiceApprovedNotification(
          vendorId: service.vendorId,
          serviceId: serviceId,
          serviceName: service.name,
        );
      }
      
      await _loadPendingServices();
      await _loadAllServices(); // Refresh all services list
    } catch (e) {
      throw Exception('Failed to approve service: $e');
    }
  }

  Future<void> rejectService(String serviceId, String reason) async {
    try {
      // Find service details for notification
      VendorService? service;
      try {
        service = _allServices.firstWhere(
          (s) => s.id == serviceId,
          orElse: () => _pendingServices.firstWhere((s) => s.id == serviceId),
        );
      } catch (_) {}

      await _supabase
          .from('vendor_services')
          .update({
            'approval_status': 'rejected',
            'rejection_reason': reason,
          })
          .eq('id', serviceId);
      
      if (service != null) {
        await _notificationService.sendServiceRejectedNotification(
          vendorId: service.vendorId,
          serviceId: serviceId,
          serviceName: service.name,
          reason: reason,
        );
      }
      
      await _loadPendingServices();
      await _loadAllServices();
    } catch (e) {
      throw Exception('Failed to reject service: $e');
    }
  }

  Future<void> updateVendorPriorityScore(String vendorId, double newScore) async {
    try {
      await _supabase
          .from('vendor_profiles')
          .update({'priority_score': newScore})
          .eq('id', vendorId);
      
      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        _vendors[index].priorityScore = newScore;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating vendor priority score: $e');
      throw Exception('Failed to update priority score: $e');
    }
  }

  Future<void> updateVendorServiceAreas(String vendorId, List<String> areas) async {
    try {
      final areasString = areas.join(', ');
      await _supabase
          .from('vendor_profiles')
          .update({
            'coverage_area_state': areasString,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        _vendors[index].serviceAreas = areas;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating vendor service areas: $e');
      throw Exception('Failed to update service areas: $e');
    }
  }


  Future<String> createUnclaimedVendor({
    required String name,
    required List<String> categories,
    required String description,
    required String address,
    required List<String> serviceAreas,
    required List<String> serviceCities,
    String? email,
    required String phone,
  }) async {
    try {
      final claimCode = _generateClaimCode();
      
      final response = await _supabase.from('vendor_profiles').insert({
        'business_name': name,
        'categories': categories,
        'description': description,
        'address': address,
        'coverage_area_state': serviceAreas.join(', '),
        'coverage_area_city': serviceCities.join(', '),
        'email': email,
        'phone': phone,
        'is_claimed': false,
        'claim_code': claimCode,
        'registration_source': 'admin',
        'profile_completion_status': 'incomplete',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      await refreshAllData();
      return claimCode;
    } catch (e) {
      print('ERROR: Failed to create unclaimed vendor: $e');
      throw Exception('Failed to create unclaimed vendor: $e');
    }
  }

  String _generateClaimCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[(rnd + index) % chars.length]).join();
  }

  // System Metrics
  Map<String, String> getSystemMetrics() {
    // These would ideally be fetched from a specific dashboard_stats RPC or similar
    // For now we calculate from loaded data where possible
    int failedLogins = _logins.where((l) => l.user == 'Failed Login').length; // Mock logic
    int suspicious = _activity.where((a) => a.type == 'suspicious').length;
    
    return {
      'failed_logins': failedLogins.toString(),
      'suspicious_activities': suspicious.toString(),
      'blocked_ips': '0', // Valid real data needed
    };
  }

  // Mock data for additional admin features
  final List<ReportedUser> _reportedUsers = [
    ReportedUser(user: 'Spam Bot', reason: 'Spam messages'),
    ReportedUser(user: 'ToxicUser99', reason: 'Inappropriate language'),
  ];

  List<Invitation> _guestInvitations = [];

  Future<void> _loadGuestInvitations() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('role', 'guest')
          .order('created_at', ascending: false);

      _guestInvitations = response.map((json) {
        return Invitation(
          name: json['name'] ?? json['email']?.split('@')[0] ?? 'Unknown',
          status: 'active', // You may want to map user status if available
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      // Keep existing guests list on error
      _error = 'Failed to load guest invitations: $e';
      notifyListeners();
    }
  }

  double _commissionPercent = 10.0;
  bool _isMaintenanceMode = false;
  Map<String, bool> _featureFlags = {
    'Vendor Registration': true,
    'Booking System': true,
    'In-App Messaging': true,
    'Reviews & Ratings': true,
    'Promotions & Ads': true,
    'Articles & Content': true,
    'Payment System': true,
  };

  AdminProvider() {
    _initializeData();
    _loadMaintenanceMode();
  }

  /// Manually refreshes all admin data from Supabase
  Future<void> refreshAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadUsers(),
        _loadGuestInvitations(),
        _loadVendors(),
        _loadRegions(),
        _loadServiceCategories(),
        _loadAllServices(),
        _loadBookings(),
        _loadTransactions(),
        _loadAppointments(),
        _loadRentals(),
        _loadPayouts(),
        _loadOverduePayments(),
        _loadListings(),
        _loadPromotions(),
        _loadAds(),
        _loadArticles(),
        _loadBudgets(),
        _loadRsvps(),
        _loadSuggestions(),
        _loadDisputes(),
        _loadReviewQueue(),
        _loadAppeals(),
        _loadAnnouncements(),
        _loadLoginEvents(),
        _loadRoleAssignments(),
        _loadActivityLogs(),
        _loadApiIntegrations(),
        _loadPendingServices(),
        _loadAllSubscriptionPayments(),
      ]);
    } catch (e) {
      _error = 'Failed to refresh admin data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _vendorsChannel?.unsubscribe();
    _bookingsChannel?.unsubscribe();
    _transactionsChannel?.unsubscribe();
    _regionsChannel?.unsubscribe();
    _serviceCategoriesChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscriptions() {
    // Note: Real-time subscriptions are commented out due to API compatibility issues
    // TODO: Implement real-time subscriptions when Supabase Flutter SDK is updated
    /*
    _vendorsChannel = _supabase
        .channel('admin_vendors')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'admin_vendors',
          callback: (payload) {
            // Handle vendor changes
            _loadVendors();
          },
        )
        .subscribe();
    */
  }

  Future<void> _loadAllSubscriptionPayments() async {
    try {
      final response = await _supabase
          .from('subscription_payments')
          .select('*, vendor:vendor_profiles(business_name)')
          .order('created_at', ascending: false);

      _allSubscriptionPayments = (response as List).map((json) {
        return SubscriptionPayment(
          id: json['id'],
          vendorId: json['vendor_id'],
          tierId: json['tier_id'],
          amount: (json['amount'] as num).toDouble(),
          status: json['payment_status'] ?? 'unknown',
          createdAt: DateTime.parse(json['created_at']),
          periodStart: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
          periodEnd: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading global subscription payments: $e');
    }
  }

  Map<String, dynamic> getSubscriptionAnalytics() {
    final activePayments = _allSubscriptionPayments.where((p) => p.status == 'completed').toList();
    
    double totalMRR = 0;
    Map<String, int> tierDistribution = {};

    for (var payment in activePayments) {
      // Simple logic: if it's within the last 30 days, count it towards MRR
      if (payment.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
        totalMRR += payment.amount;
      }
    }

    for (var vendor in _vendors) {
      final tier = vendor.subscriptionTier;
      tierDistribution[tier] = (tierDistribution[tier] ?? 0) + 1;
    }

    return {
      'totalActive': _vendors.where((v) => v.subscriptionTier != 'starter' && v.subscriptionTier != 'free').length,
      'mrr': totalMRR,
      'distribution': tierDistribution,
      'upcomingExpirations': _vendors.where((v) => v.subscriptionExpiry != null && 
          v.subscriptionExpiry!.isAfter(DateTime.now()) && 
          v.subscriptionExpiry!.isBefore(DateTime.now().add(const Duration(days: 30)))).length,
    };
  }


  Future<void> _initializeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadUsers(),
        _loadGuestInvitations(),
        _loadVendors(),
        _loadRegions(),
        _loadServiceCategories(),
        _loadAllServices(),
        _loadBookings(),
        _loadTransactions(),
        _loadAppointments(),
        _loadRentals(),
        _loadPayouts(),
        _loadOverduePayments(),
        _loadListings(),
        _loadPromotions(),
        _loadAds(),
        _loadArticles(),
        _loadBudgets(),
        _loadRsvps(),
        _loadSuggestions(),
        _loadDisputes(),
        _loadReviewQueue(),
        _loadAppeals(),
        _loadAnnouncements(),
        _loadLoginEvents(),
        _loadRoleAssignments(),
        _loadActivityLogs(),
        _loadApiIntegrations(),
        _loadPendingServices(),
      ]);

      // Set up real-time subscriptions after initial data load
      _setupRealtimeSubscriptions();
    } catch (e) {
      _error = 'Failed to load admin data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUsers() async {
    try {
      final adminUsers = await _loadAdminUsers();
      final vendorUsers = await _loadVendorUsers();
      final customerUsers = await _loadCustomerUsers();

      _users = [...adminUsers, ...vendorUsers, ...customerUsers];

      if (_users.isEmpty) {
        try {
          final profilesResponse = await _supabase
              .from('profiles')
              .select('*')
              .order('created_at', ascending: false);
          if (profilesResponse.isNotEmpty) {
            _users = (profilesResponse as List).map<AppUser>((json) {
              return AppUser(
                id: json['id'] ?? '',
                name: json['name'] ?? json['full_name'] ?? json['username'] ?? json['email']?.split('@')[0] ?? 'User',
                email: json['email'] ?? '',
                role: json['role'] ?? 'customer',
                status: json['status'] ?? 'active',
                subscriptionTier: json['subscription_tier'] ?? 'free',
              );
            }).toList();
          }
        } catch (_) {}
      }

      if (_users.isEmpty) {
        _users = [
          AppUser(id: 'u1', name: 'Farah Nadia', email: 'farah@eventease.my', role: 'customer', status: 'active', subscriptionTier: 'wedding_pass'),
          AppUser(id: 'u2', name: 'Sarah Lim', email: 'sarah@bridalelegance.my', role: 'vendor', status: 'active', subscriptionTier: 'business'),
          AppUser(id: 'u3', name: 'Admin Account', email: 'admin@eventease.my', role: 'admin', status: 'active', subscriptionTier: 'admin'),
          AppUser(id: 'u4', name: 'Ahmad Rizal', email: 'ahmad@royalcatering.my', role: 'vendor', status: 'active', subscriptionTier: 'pro'),
          AppUser(id: 'u5', name: 'Chloe Wong', email: 'chloe.wong@gmail.com', role: 'customer', status: 'active', subscriptionTier: 'free'),
        ];
      }

      notifyListeners();
    } catch (e) {
      _users = [
        AppUser(id: 'u1', name: 'Farah Nadia', email: 'farah@eventease.my', role: 'customer', status: 'active', subscriptionTier: 'wedding_pass'),
        AppUser(id: 'u2', name: 'Sarah Lim', email: 'sarah@bridalelegance.my', role: 'vendor', status: 'active', subscriptionTier: 'business'),
        AppUser(id: 'u3', name: 'Admin Account', email: 'admin@eventease.my', role: 'admin', status: 'active', subscriptionTier: 'admin'),
        AppUser(id: 'u4', name: 'Ahmad Rizal', email: 'ahmad@royalcatering.my', role: 'vendor', status: 'active', subscriptionTier: 'pro'),
        AppUser(id: 'u5', name: 'Chloe Wong', email: 'chloe.wong@gmail.com', role: 'customer', status: 'active', subscriptionTier: 'free'),
      ];
      _error = 'Failed to load users: $e';
      notifyListeners();
    }
  }

  Future<List<AppUser>> _loadAdminUsers() async {
    try {
      final response = await _supabase
          .from('admin_user')
          .select('*')
          .order('created_at', ascending: false);

      return response.map<AppUser>((json) => AppUser(
        id: json['id'],
        name: json['name'] ?? json['email']?.split('@')[0] ?? 'Unknown',
        email: json['email'],
        role: json['role'] ?? 'admin',
        status: json['status'] ?? 'active',
        subscriptionTier: 'admin',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<AppUser>> _loadVendorUsers() async {
    try {
      final response = await _supabase
          .from('vendor_user')
          .select('*')
          .order('created_at', ascending: false);

      final users = response.map<AppUser>((json) => AppUser(
        id: json['id'],
        name: json['name'] ?? json['email']?.split('@')[0] ?? 'Unknown',
        email: json['email'],
        role: json['role'] ?? 'vendor',
        status: json['status'] ?? 'active',
        subscriptionTier: 'vendor', // Specific tiered subscriptions will map to AdminVendor instead
      )).toList();

      // Load documents for vendor users
      for (final user in users) {
        // Get the profile for this vendor user
        final profileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', user.id)
            .maybeSingle();

        if (profileResponse != null) {
          final docs = await getVendorDocuments(profileResponse['id']);
          _vendorUserDocuments[user.id] = docs;
        } else {
          _vendorUserDocuments[user.id] = [];
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  Future<List<AppUser>> _loadCustomerUsers() async {
    try {
      final response = await _supabase
          .from('customer_user')
          .select('*')
          .order('created_at', ascending: false);

      return response.map<AppUser>((json) {
        String tier = 'free';
        // Mocking Wedding Pass flag detection for DB json response logic based on existing customer plan checks.
        if (json['subscription_tier'] == 'wedding_pass' || json['has_wedding_pass'] == true) {
             tier = 'wedding_pass';
        }
        
        return AppUser(
          id: json['id'],
          name: json['name'] ?? json['email']?.split('@')[0] ?? 'Unknown',
          email: json['email'],
          role: json['role'] ?? 'customer',
          status: json['status'] ?? 'active',
          subscriptionTier: tier,
          subscriptionExpiry: json['subscription_expiry'] != null
              ? DateTime.parse(json['subscription_expiry'])
              : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadVendors() async {
    try {
      // 1. Load from admin_dashboard_vendors (Admin-created vendors)
      final adminResponse = await _supabase
          .from('admin_dashboard_vendors')
          .select('*')
          .order('created_at', ascending: false);

      final List<AdminVendor> vendors = [];

      for (final json in adminResponse) {
        final docs = await getVendorDocuments(json['id']);
        vendors.add(AdminVendor(
          json['id'],
          json['name'],
          json['category'],
          json['verified'] ?? false,
          json['suspended'] ?? false,
          (json['rating'] ?? 0.0).toDouble(),
          json['reviews'] ?? 0,
          json['bookings'] ?? 0,
          (json['service_areas'] != null 
              ? (json['service_areas'] is String 
                  ? json['service_areas'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                  : List<String>.from(json['service_areas']))
              : []),
          json['pending_approval'] ?? false,
          documents: docs,
          documentsVerified: json['documents_verified'] ?? false,
          documentVerificationNotes: json['document_verification_notes'],
          documentsVerifiedAt: json['documents_verified_at'] != null
              ? DateTime.parse(json['documents_verified_at'])
              : null,
          subscriptionTier: json['subscription_tier'] ?? 'starter',
          subscriptionExpiry: json['subscription_expiry'] != null
              ? DateTime.parse(json['subscription_expiry'])
              : null,
          priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.0,
          isClaimed: json['is_claimed'] ?? true,
          claimCode: json['claim_code'],
          registrationSource: json['registration_source'] ?? 'admin',
          phone: json['phone'] ?? json['contact_info'],
          email: json['email'] ?? json['contact_info'],
          address: json['address'],
          ssmNumber: json['ssm_number'],
          legalName: json['legal_name'],
          businessType: json['business_type'],
          startingPrice: (json['starting_price'] as num?)?.toDouble(),
          completionPercentage: json['completion_percentage'] ?? 0,
          subcategories: (json['subcategories'] is List)
              ? List<String>.from(json['subcategories'])
              : [],
        ));
      }

      // 2. Load from vendor_profiles (User-created vendors)
      final profileResponse = await _supabase
          .from('vendor_profiles')
          .select('*, vendor_user(name, status)')
          .order('created_at', ascending: false);

      for (final profile in profileResponse) {
        final userId = profile['user_id'] ?? profile['id']; // fallback to profile id for unclaimed vendors
        
        // Avoid duplicates if they exist in both
        if (vendors.any((v) => v.id == userId || v.id == profile['id'])) continue;

        final docs = await getVendorDocuments(profile['id']);
        final status = profile['profile_completion_status'];
        final isApproved = status == 'approved';
        final isPending = status == 'pending_review';
        
        // Categories can be a JSON string or a list
        String category = 'Vendor';
        final cats = profile['categories'];
        if (cats is List && cats.isNotEmpty) {
          category = cats.first.toString();
        } else if (cats is String && cats.isNotEmpty) {
          try {
            final decoded = jsonDecode(cats);
            if (decoded is List && decoded.isNotEmpty) {
              category = decoded.first.toString();
            }
          } catch (_) {}
        }

        List<String> parsedServiceAreas = [];
        if (profile['coverage_area_state'] != null && profile['coverage_area_state'].toString().isNotEmpty) {
          parsedServiceAreas = profile['coverage_area_state'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } else if (profile['service_areas'] != null) {
          parsedServiceAreas = List<String>.from(profile['service_areas']);
        }

        vendors.add(AdminVendor(
          userId.toString(),
          profile['business_name'] ?? (profile['vendor_user']?['name'] ?? 'Unnamed Vendor'),
          category,
          isApproved,
          profile['vendor_user']?['status'] == 'suspended',
          0.0, 0, 0, parsedServiceAreas, // Added parsed service areas here
          isPending,
          documents: docs,
          documentsVerified: docs.isNotEmpty && docs.every((d) => d.isVerified),
          subscriptionTier: profile['subscription_tier'] ?? 'starter',
          subscriptionExpiry: profile['subscription_expiry'] != null
              ? DateTime.parse(profile['subscription_expiry'])
              : null,
          isClaimed: profile['is_claimed'] ?? true,
          claimCode: profile['claim_code'],
          registrationSource: profile['registration_source'] ?? 'self',
          commissionRate: (profile['commission_rate'] as num?)?.toDouble(),
          commissionOverride: profile['commission_override'] ?? false,
          priorityScore: (profile['priority_score'] as num?)?.toDouble() ?? 0.0,
          phone: profile['phone'] ?? profile['business_phone'],
          email: profile['email'] ?? profile['business_email'],
          address: profile['address'] ?? profile['operating_address'] ?? profile['business_address'],
          ssmNumber: profile['ssm_number'],
          legalName: profile['legal_business_name'],
          businessType: profile['business_type'],
          startingPrice: (profile['starting_price'] as num?)?.toDouble(),
          completionPercentage: profile['profile_completion_percentage'] ?? 0,
          subcategories: (profile['subcategories'] is List) 
              ? List<String>.from(profile['subcategories']) 
              : [],
        ));

      }

      _vendors = vendors;
      _error = null;
    } catch (e) {
      print('Error loading vendors: $e');
      _vendors = [];
      _error = 'Failed to load vendors: $e';
    }
    notifyListeners();
  }

  Future<void> _loadRegions() async {
    try {
      // 1. Fetch Countries (from 'countries' table)
      final countriesResponse = await _supabase
          .from('countries')
          .select('*')
          .order('name', ascending: true);
      
      // 2. Fetch States (from 'regions' table)
      final statesResponse = await _supabase
          .from('regions')
          .select('*')
          .order('name', ascending: true);
      
      // 3. Fetch Cities (from 'cities' table)
      final citiesResponse = await _supabase
          .from('cities')
          .select('*')
          .order('name', ascending: true);

      final List<Region> allRegions = [];

      // Map Countries
      for (final json in countriesResponse) {
        allRegions.add(Region(
          id: 'country_${json['id']}',
          name: json['name'],
          type: RegionType.country,
          code: json['code'],
          isActive: json['is_active'] ?? true,
          createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        ));
      }

      // Map States
      for (final json in statesResponse) {
        allRegions.add(Region(
          id: 'state_${json['id']}',
          name: json['name'],
          type: RegionType.state,
          parentId: json['country_id'] != null ? 'country_${json['country_id']}' : null,
          code: json['code'],
          isActive: json['is_active'] ?? true,
          createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        ));
      }

      // Map Cities
      for (final json in citiesResponse) {
        allRegions.add(Region(
          id: 'city_${json['id']}',
          name: json['name'],
          type: RegionType.city,
          parentId: json['region_id'] != null ? 'state_${json['region_id']}' : null,
          isActive: json['is_active'] ?? true,
          createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        ));
      }

      _regions = allRegions;
    } catch (e) {
      print('Error loading regions: $e');
      // If error, keeping empty or fallback is debated. 
      // Let's fallback to sample only if list is empty to avoid complete blank screen if DB fails
      if (_regions.isEmpty) {
        _regions = Region.getSampleRegions();
      }
      _error = 'Failed to load regions: $e';
    }
  }

  Future<void> _loadServiceCategories() async {
    try {
      final response = await _supabase
          .from('service_categories')
          .select('*')
          .order('name', ascending: true);

      _serviceCategories = response.map((json) => ServiceCategory.fromMap(json)).toList();
      
      _error = null;
    } catch (e) {
      print('Error loading service categories: $e');
      _error = 'Failed to load categories: $e';
      // Keep existing list or set to empty if first load
      if (_serviceCategories.isEmpty) {
        _serviceCategories = [];
      }
    }
    notifyListeners();
  }

  List<VendorService> get allServices => _allServices;

  Future<void> _loadAllServices() async {
    try {
      final response = await _supabase
          .from('vendor_services')
          .select('*, vendor:vendor_profiles(business_name)')
          .order('created_at', ascending: false);

      final List<VendorService> services = [];
      for (final json in (response as List)) {
        try {
           if (json['vendor'] != null) {
            json['vendor_name'] = json['vendor']['business_name'];
          }
          services.add(VendorService.fromJson(json));
        } catch (e, st) {
          print('Error parsing service from JSON: $e\n$st');
        }
      }
      
      // Load structured data for each service
      _allServices = await _loadStructuredDataForServices(services);
      
      _error = null;
    } catch (e) {
      print('Error loading services: $e');
      _allServices = [];
      _error = 'Failed to load services: $e';
    }
    notifyListeners();
  }

  Future<bool> updateServiceStatus(String serviceId, ApprovalStatus status) async {
    try {
      await _supabase
          .from('vendor_services')
          .update({'approval_status': status.name})
          .eq('id', serviceId);
      
      // Update local state
      final index = _allServices.indexWhere((s) => s.id == serviceId);
      if (index != -1) {
        _allServices[index] = _allServices[index].copyWith(approvalStatus: status);
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Error updating service status: $e');
      return false;
    }
  }

  Future<void> _loadBookings() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('*, customer_user(name), vendor_profiles(business_name), installment_plans(*, installment_payments(*))')
          .order('created_at', ascending: false);

      _bookings = (response as List).map((json) {
        // Safe access to nested data
        String customerName = 'Unknown User';
        if (json['customer_user'] != null) {
           final cu = json['customer_user'];
           if (cu is Map) {
             customerName = cu['name'] ?? 'Unknown User';
           } else if (cu is List && cu.isNotEmpty) {
             customerName = cu[0]['name'] ?? 'Unknown User';
           }
        }

        String vendorName = 'Unknown Vendor';
        if (json['vendor_profiles'] != null) {
           final vp = json['vendor_profiles'];
           if (vp is Map) {
             vendorName = vp['business_name'] ?? 'Unknown Vendor';
           } else if (vp is List && vp.isNotEmpty) {
             vendorName = vp[0]['business_name'] ?? 'Unknown Vendor';
           }
        }

        return Booking(
          id: json['id'],
          userName: customerName,
          vendorName: vendorName,
          vendorId: json['vendor_id'] ?? '',
          packageName: json['package_name'] ?? 'Custom Service',
          date: json['booking_date'],
          amount: (json['total_amount'] ?? 0).toDouble(),
          status: json['status'],
          priority: false,
          installmentPlan: json['installment_plans'] != null && (json['installment_plans'] as List).isNotEmpty 
              ? json['installment_plans'][0] 
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error loading admin bookings: $e');
      _bookings = [];
      _error = 'Failed to load bookings: $e';
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('*, customer_user(name), vendor_profiles(business_name)')
          .order('created_at', ascending: false);

      _transactions = (response as List).map((json) {
        String vendorName = 'Unknown Vendor';
        if (json['vendor_profiles'] != null) {
           final vp = json['vendor_profiles'];
           if (vp is Map) {
             vendorName = vp['business_name'] ?? 'Unknown Vendor';
           } else if (vp is List && vp.isNotEmpty) {
             vendorName = vp[0]['business_name'] ?? 'Unknown Vendor';
           }
        }

        return TransactionEntry(
          id: json['id'],
          party: vendorName,
          amount: (json['total_amount'] ?? 0).toDouble(),
          status: _mapToTransactionStatus(json['status'], json['payment_status']),
          date: json['created_at'] ?? json['booking_date'],
          serviceId: json['service_id'],
          vendorId: json['vendor_id'],
        );
      }).toList();
    } catch (e) {
      print('Error loading admin transactions: $e');
      _transactions = [];
      _error = 'Failed to load transactions: $e';
    }
  }

  String _mapToTransactionStatus(String bookingStatus, String? paymentStatus) {
    // Priority 1: If payment is refunded
    if (paymentStatus == 'refunded') return 'refunded';
    
    // Priority 2: Use payment status for 'paid' logic
    if (paymentStatus == 'deposit_paid' || paymentStatus == 'partially_paid' || paymentStatus == 'fully_paid') {
      return 'paid';
    }

    // Priority 3: Fallback to booking status
    switch (bookingStatus.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return 'paid';
      case 'pending':
      case 'pending_vendor':
      case 'awaiting_payment':
      case 'pending_payment':
        return 'pending';
      case 'cancelled':
      case 'rejected':
      case 'cancelled_by_user':
      case 'cancelled_by_vendor':
      case 'expired':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await _supabase
          .from('admin_appointments')
          .select('*')
          .order('created_at', ascending: false);

      _appointments = response.map((json) => Appointment(
        type: json['type'],
        title: json['title'],
        date: json['appointment_date'],
        vendor: json['vendor_name'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _appointments = [
        Appointment(type: 'Food Testing', title: 'Menu tasting with Elegant Catering', date: 'Mar 20, 2025', vendor: 'Elegant Catering'),
        Appointment(type: 'Fitting', title: 'Gown fitting - Lisa', date: 'Mar 22, 2025', vendor: 'Dress4U'),
      ];
    }
  }

  Future<void> _loadRentals() async {
    try {
      final response = await _supabase
          .from('admin_rentals')
          .select('*')
          .order('created_at', ascending: false);

      _rentals = response.map((json) => Rental(
        item: json['item_name'],
        user: json['user_name'],
        deposit: json['deposit_amount'],
        status: json['status'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _rentals = [
        Rental(item: 'Gown A12', user: 'Sarah', deposit: 500, status: 'borrowed'),
        Rental(item: 'Suit M5', user: 'Ahmad', deposit: 300, status: 'returned'),
      ];
    }
  }

  Future<void> _loadPayouts() async {
    try {
      final response = await _supabase
          .from('admin_payouts')
          .select('*')
          .order('created_at', ascending: false);

      _payouts = response.map((json) => Payout(
        id: json['id'],
        vendor: json['vendor_name'] ?? 'Unknown Vendor',
        vendorId: json['vendor_id'],
        bankAccountId: json['bank_account_id'],
        amount: (json['amount'] as num).toDouble(),
        status: json['status'],
        date: json['created_at'] ?? DateTime.now().toIso8601String(),
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _payouts = [
        Payout(id: 'p1', vendor: 'Grand Ballroom KL', amount: 4500, status: 'pending', date: '2025-03-01'),
        Payout(id: 'p2', vendor: 'Perfect Photography', amount: 800, status: 'pending', date: '2025-03-05'),
      ];
    }
  }

  Future<void> _loadOverduePayments() async {
    try {
      final response = await _supabase
          .from('admin_overdue_payments')
          .select('*')
          .order('created_at', ascending: false);

      _overdues = response.map((json) => OverduePayment(
        user: json['user_name'],
        amount: json['amount'],
        days: json['days_overdue'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _overdues = [
        OverduePayment(user: 'Corporate XYZ', amount: 12000, days: 14),
      ];
    }
  }

  Future<void> _loadListings() async {
    try {
      final response = await _supabase
          .from('admin_listings')
          .select('*')
          .order('created_at', ascending: false);

      _listings = response.map((json) => Listing(
        id: json['id'],
        title: json['title'],
        category: json['category'],
        price: json['price'],
        status: json['status'] ?? 'pending',
        isVerified: json['is_verified'] ?? false,
        isPinned: json['is_pinned'] ?? false,
        views: json['views'] ?? 0,
        bookings: json['bookings'] ?? 0,
        conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
        vendorId: json['vendor_id'],
        vendorName: json['vendor_name'],
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      )).toList();
    } catch (e) {
      _listings = [];
    }
  }

  Future<void> addListing(Listing listing) async {
    final response = await _supabase.from('admin_listings').insert({
      'title': listing.title,
      'category': listing.category,
      'price': listing.price,
      'status': listing.status,
      'is_verified': listing.isVerified,
      'is_pinned': listing.isPinned,
      'vendor_id': listing.vendorId,
      'vendor_name': listing.vendorName,
    }).select().single();
    _listings.insert(0, Listing(
      id: response['id'], title: response['title'],
      category: response['category'], price: response['price'],
      status: response['status'] ?? 'pending',
      isVerified: response['is_verified'] ?? false,
      isPinned: response['is_pinned'] ?? false,
    ));
    notifyListeners();
  }

  Future<void> updateListing(Listing listing) async {
    await _supabase.from('admin_listings').update({
      'title': listing.title,
      'category': listing.category,
      'price': listing.price,
      'status': listing.status,
      'is_verified': listing.isVerified,
      'is_pinned': listing.isPinned,
      'vendor_id': listing.vendorId,
      'vendor_name': listing.vendorName,
    }).eq('id', listing.id);
    final index = _listings.indexWhere((l) => l.id == listing.id);
    if (index >= 0) {
      _listings[index] = listing;
      notifyListeners();
    }
  }

  Future<void> toggleListingPin(String id) async {
    final index = _listings.indexWhere((l) => l.id == id);
    if (index >= 0) {
      final newPinned = !_listings[index].isPinned;
      await _supabase.from('admin_listings').update({'is_pinned': newPinned}).eq('id', id);
      _listings[index] = _listings[index].copyWith(isPinned: newPinned);
      notifyListeners();
    }
  }

  Future<void> toggleListingVerified(String id) async {
    final index = _listings.indexWhere((l) => l.id == id);
    if (index >= 0) {
      final newVerified = !_listings[index].isVerified;
      await _supabase.from('admin_listings').update({'is_verified': newVerified}).eq('id', id);
      _listings[index] = _listings[index].copyWith(isVerified: newVerified);
      notifyListeners();
    }
  }

  Future<void> updateListingStatus(String id, String status) async {
    await _supabase.from('admin_listings').update({'status': status}).eq('id', id);
    final index = _listings.indexWhere((l) => l.id == id);
    if (index >= 0) {
      _listings[index] = _listings[index].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> deleteListing(String id) async {
    await _supabase.from('admin_listings').delete().eq('id', id);
    _listings.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> _loadPromotions() async {
    try {
      final response = await _supabase
          .from('admin_promotions')
          .select('*')
          .order('created_at', ascending: false);

      _promotions = response.map((json) => Promotion(
        id: json['id'],
        title: json['title'],
        validTill: json['valid_until'] ?? '',
        campaignType: json['campaign_type'] ?? 'vendor',
        description: json['description'],
        discountPercent: (json['discount_percent'] as num?)?.toDouble(),
        targetRegion: json['target_region'],
        targetCategory: json['target_category'],
        status: json['status'] ?? 'active',
        startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
        endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
        redemptions: json['redemptions'] ?? 0,
      )).toList();
    } catch (e) {
      _promotions = [];
    }
  }

  Future<void> addPromotion(Promotion promotion) async {
    final response = await _supabase.from('admin_promotions').insert({
      'title': promotion.title,
      'valid_until': promotion.validTill,
      'campaign_type': promotion.campaignType,
      'description': promotion.description,
      'discount_percent': promotion.discountPercent,
      'target_region': promotion.targetRegion,
      'target_category': promotion.targetCategory,
      'status': promotion.status,
      'start_date': promotion.startDate?.toIso8601String(),
      'end_date': promotion.endDate?.toIso8601String(),
    }).select().single();
    _promotions.insert(0, Promotion(
      id: response['id'], title: response['title'],
      validTill: response['valid_until'] ?? '',
      campaignType: response['campaign_type'],
      status: response['status'] ?? 'active',
    ));
    notifyListeners();
  }

  Future<void> updatePromotion(Promotion promotion) async {
    await _supabase.from('admin_promotions').update({
      'title': promotion.title,
      'valid_until': promotion.validTill,
      'campaign_type': promotion.campaignType,
      'description': promotion.description,
      'discount_percent': promotion.discountPercent,
      'target_region': promotion.targetRegion,
      'target_category': promotion.targetCategory,
      'status': promotion.status,
      'start_date': promotion.startDate?.toIso8601String(),
      'end_date': promotion.endDate?.toIso8601String(),
    }).eq('id', promotion.id);
    final index = _promotions.indexWhere((p) => p.id == promotion.id);
    if (index >= 0) {
      _promotions[index] = promotion;
      notifyListeners();
    }
  }

  Future<void> deletePromotion(String id) async {
    await _supabase.from('admin_promotions').delete().eq('id', id);
    _promotions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> _loadAds() async {
    try {
      final response = await _supabase
          .from('admin_ads')
          .select('*')
          .order('created_at', ascending: false);

      _ads = response.map<AdEntry>((json) => AdEntry(
        id: json['id'],
        title: json['title'],
        advertiser: json['advertiser_name'],
        placementType: json['placement_type'] ?? 'search_boost',
        pricingTier: json['pricing_tier'] ?? 'basic',
        status: json['status'] ?? 'pending',
        impressions: json['impressions'] ?? 0,
        clicks: json['clicks'] ?? 0,
        budget: (json['budget'] as num?)?.toDouble() ?? 0,
        spent: (json['spent'] as num?)?.toDouble() ?? 0,
        startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
        endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      )).toList();
    } catch (e) {
      _ads = [];
    }
  }

  Future<void> addAdEntry(AdEntry ad) async {
    final response = await _supabase.from('admin_ads').insert({
      'title': ad.title,
      'advertiser_name': ad.advertiser,
      'placement_type': ad.placementType,
      'pricing_tier': ad.pricingTier,
      'status': ad.status,
      'budget': ad.budget,
      'start_date': ad.startDate?.toIso8601String(),
      'end_date': ad.endDate?.toIso8601String(),
    }).select().single();
    _ads.insert(0, AdEntry(
      id: response['id'], title: response['title'],
      advertiser: response['advertiser_name'],
      placementType: response['placement_type'] ?? 'search_boost',
      pricingTier: response['pricing_tier'] ?? 'basic',
      status: response['status'] ?? 'pending',
    ));
    notifyListeners();
  }

  Future<void> updateAdEntry(AdEntry ad) async {
    await _supabase.from('admin_ads').update({
      'title': ad.title,
      'advertiser_name': ad.advertiser,
      'placement_type': ad.placementType,
      'pricing_tier': ad.pricingTier,
      'status': ad.status,
      'budget': ad.budget,
      'start_date': ad.startDate?.toIso8601String(),
      'end_date': ad.endDate?.toIso8601String(),
    }).eq('id', ad.id);
    final index = _ads.indexWhere((a) => a.id == ad.id);
    if (index >= 0) {
      _ads[index] = ad;
      notifyListeners();
    }
  }

  Future<void> updateAdStatus(String id, String status) async {
    await _supabase.from('admin_ads').update({'status': status}).eq('id', id);
    final index = _ads.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _ads[index] = _ads[index].copyWith(status: status);
      notifyListeners();
    }
  }

  Future<void> deleteAdEntry(String id) async {
    await _supabase.from('admin_ads').delete().eq('id', id);
    _ads.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> _loadArticles() async {
    try {
      final response = await _supabase
          .from('admin_articles')
          .select('*')
          .order('created_at', ascending: false);

      _articles = response.map((json) => Article(
        id: json['id'],
        title: json['title'],
        author: json['author_name'],
        content: json['content'],
        status: json['status'] ?? 'draft',
        category: json['category'],
        linkedVendorId: json['linked_vendor_id'],
        linkedVendorName: json['linked_vendor_name'],
        ctaType: json['cta_type'],
        ctaLink: json['cta_link'],
        featuredImage: json['featured_image'],
        views: json['views'] ?? 0,
        publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at']) : null,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      )).toList();
    } catch (e) {
      _articles = [];
    }
  }

  Future<void> addArticle(Article article) async {
    try {
      final response = await _supabase.from('admin_articles').insert({
        'title': article.title,
        'author_name': article.author,
        'content': article.content ?? '',
        'status': article.status,
        'category': article.category,
        'linked_vendor_id': article.linkedVendorId,
        'linked_vendor_name': article.linkedVendorName,
        'cta_type': article.ctaType,
        'cta_link': article.ctaLink,
        'featured_image': article.featuredImage,
      }).select().single();
      _articles.insert(0, Article(
        id: response['id'], 
        title: response['title'], 
        author: response['author_name'], 
        content: response['content'],
        status: response['status'] ?? 'draft',
        category: response['category'],
        ctaType: response['cta_type'],
      ));
      notifyListeners();
    } catch (e, stacktrace) {
      debugPrint('🔥 [AdminProvider] ERROR in addArticle: $e');
      debugPrint('🔥 [AdminProvider] StackTrace: $stacktrace');
      rethrow;
    }
  }

  Future<void> updateArticle(Article article) async {
    try {
      await _supabase.from('admin_articles').update({
        'title': article.title,
        'author_name': article.author,
        'content': article.content ?? '',
        'status': article.status,
        'category': article.category,
        'linked_vendor_id': article.linkedVendorId,
        'linked_vendor_name': article.linkedVendorName,
        'cta_type': article.ctaType,
        'cta_link': article.ctaLink,
        'featured_image': article.featuredImage,
      }).eq('id', article.id);
      final index = _articles.indexWhere((a) => a.id == article.id);
      if (index >= 0) {
        _articles[index] = article;
        notifyListeners();
      }
    } catch (e, stacktrace) {
      debugPrint('🔥 [AdminProvider] ERROR in updateArticle: $e');
      debugPrint('🔥 [AdminProvider] StackTrace: $stacktrace');
      rethrow;
    }
  }

  Future<void> publishArticle(String id) async {
    try {
      await _supabase.from('admin_articles').update({
        'status': 'published',
        'published_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      
      final index = _articles.indexWhere((a) => a.id == id);
      if (index >= 0) {
        _articles[index] = _articles[index].copyWith(
          status: 'published',
          publishedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e, stacktrace) {
      debugPrint('🔥 [AdminProvider] ERROR in publishArticle: $e');
      debugPrint('🔥 [AdminProvider] StackTrace: $stacktrace');
      rethrow;
    }
  }

  Future<void> deleteArticle(String id) async {
    try {
      await _supabase.from('admin_articles').delete().eq('id', id);
      _articles.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e, stacktrace) {
      debugPrint('🔥 [AdminProvider] ERROR in deleteArticle: $e');
      debugPrint('🔥 [AdminProvider] StackTrace: $stacktrace');
      rethrow;
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final response = await _supabase
          .from('admin_budgets')
          .select('*')
          .order('created_at', ascending: false);

      _budgets = response.map((json) => BudgetSummary(
        couple: json['couple_name'],
        total: json['total_budget'],
        spent: json['amount_spent'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _budgets = [
        BudgetSummary(couple: 'Ahmad & Sarah', total: 30000, spent: 18500),
      ];
    }
  }

  Future<void> _loadRsvps() async {
    try {
      final response = await _supabase
          .from('admin_rsvps')
          .select('*')
          .order('created_at', ascending: false);

      _rsvps = response.map((json) => RSVPEntry(
        event: json['event_name'],
        yes: json['yes_count'],
        no: json['no_count'],
        pending: json['pending_count'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _rsvps = [
        RSVPEntry(event: 'Ahmad & Sarah Wedding', yes: 120, no: 15, pending: 40),
      ];
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final response = await _supabase
          .from('admin_suggestions')
          .select('*')
          .order('created_at', ascending: false);

      _suggestions = response.map((json) => Suggestion(
        couple: json['couple_name'],
        suggestion: json['suggestion_text'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _suggestions = [
        Suggestion(couple: 'Ahmad & Sarah', suggestion: 'Venues in KL under RM100/pax'),
      ];
    }
  }

  Future<void> _loadDisputes() async {
    try {
      final response = await _supabase
          .from('admin_disputes')
          .select('*')
          .order('created_at', ascending: false);

      _disputes = response.map((json) => Dispute(
        caseId: json['case_id'],
        parties: json['parties_involved'],
        status: json['status'],
        severity: json['severity'],
        comments: json['comments'],
        note: json['notes'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _disputes = [
        Dispute(caseId: 'D-001', parties: 'Ahmad vs Catering', status: 'open', severity: 'High', comments: 'Payment dispute', note: 'Requires immediate attention'),
      ];
    }
  }

  Future<void> _loadReviewQueue() async {
    try {
      final response = await _supabase
          .from('admin_review_moderation')
          .select('*')
          .order('created_at', ascending: false);

      _reviewQueue = response.map((json) => ReviewModeration(
        id: json['id'],
        reviewer: json['reviewer_name'],
        reason: json['moderation_reason'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _reviewQueue = [
        ReviewModeration(id: 'R-001', reviewer: 'Anon123', reason: 'Suspicious pattern'),
      ];
    }
  }

  Future<void> _loadAppeals() async {
    try {
      final response = await _supabase
          .from('admin_appeals')
          .select('*')
          .order('created_at', ascending: false);

      _appeals = response.map((json) => Appeal(
        caseId: json['case_id'],
        status: json['status'],
        comments: json['comments'],
        reason: json['appeal_reason'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _appeals = [
        Appeal(caseId: 'D-001', status: 'pending', comments: 'Requesting review of dispute resolution', reason: 'Unfair decision'),
      ];
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      final response = await _supabase
          .from('admin_announcements')
          .select('*')
          .order('created_at', ascending: false);

      _announcements = response.map((json) => Announcement(
        message: json['message'],
        date: json['announcement_date'],
        audience: json['audience'],
        pinned: json['is_pinned'] ?? false,
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _announcements = [
        Announcement(message: 'Peak season approaching, update availability!', date: 'Mar 01, 2025', audience: 'All', pinned: true),
      ];
    }
  }

  Future<void> _loadLoginEvents() async {
    try {
      final response = await _supabase
          .from('admin_login_events')
          .select('*')
          .order('created_at', ascending: false);

      _logins = response.map((json) => LoginEvent(
        user: json['user_name'],
        time: json['login_time'],
        ip: json['ip_address'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _logins = [
        LoginEvent(user: 'admin', time: 'Mar 10, 10:45', ip: '192.168.1.8'),
      ];
    }
  }

  Future<void> _loadRoleAssignments() async {
    try {
      final response = await _supabase
          .from('admin_role_assignments')
          .select('*')
          .order('created_at', ascending: false);

      _roles = response.map((json) => RoleAssignment(
        user: json['user_name'],
        role: json['role_name'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _roles = [
        RoleAssignment(user: 'admin', role: 'super-admin'),
        RoleAssignment(user: 'sarah.ops', role: 'support'),
      ];
    }
  }

  Future<void> _loadActivityLogs() async {
    try {
      final response = await _supabase
          .from('admin_activity_log')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);

      _activity = response.map((json) {
        // Simple relative time for now, or use a proper lib later
        final createdAt = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
        final diff = DateTime.now().difference(createdAt);
        String timeAgo;
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours} hours ago';
        } else {
          timeAgo = '${diff.inDays} days ago';
        }

        return ActivityLog(
          title: json['title'] ?? 'Unknown Activity',
          subtitle: json['description'] ?? json['subtitle'] ?? json['details'] ?? '',
          time: timeAgo,
          type: json['activity_type'] ?? json['type'] ?? 'system',
          action: json['action'],
        );
      }).toList();
    } catch (e) {
      print('Error loading admin activity logs: $e');
      // Fallback to mock data to keep UI alive
      _activity = [
        ActivityLog(title: 'New vendor registered: Grand Ballroom KL', subtitle: 'Venues category', time: '5 mins ago', type: 'registration'),
        ActivityLog(title: 'Payment received: RM 8,500 from Ahmad Faiz', subtitle: 'Wedding booking confirmed', time: '1 hour ago', type: 'payment'),
        ActivityLog(title: 'Dispute resolved: Refund processed', subtitle: 'Catering service issue', time: '2 hours ago', type: 'dispute'),
        ActivityLog(title: 'New customer registered: Sarah Johnson', subtitle: 'Customer account created', time: '3 hours ago', type: 'registration'),
      ];
    }
  }


  Future<void> _loadApiIntegrations() async {
    try {
      final response = await _supabase
          .from('admin_api_integrations')
          .select('*')
          .order('created_at', ascending: false);

      _apis = response.map((json) => ApiIntegration(
        name: json['integration_name'],
        status: json['status'],
      )).toList();
    } catch (e) {
      // Fallback to mock data
      _apis = [
        ApiIntegration(name: 'PaymentGatewayX', status: 'active'),
      ];
    }
  }

  Future<void> _loadMaintenanceMode() async {
    try {
      // Try to load from Supabase first
      final response = await _supabase
          .from('admin_system_settings')
          .select('maintenance_mode, feature_flags')
          .single();

      _isMaintenanceMode = response['maintenance_mode'] ?? false;
      if (response['feature_flags'] != null) {
        _featureFlags = Map<String, bool>.from(response['feature_flags']);
      }
    } catch (e) {
      print('Error loading maintenance mode: $e');
      // Fallback to shared preferences or default to false
      // For now, we'll default to false since we don't have persistent storage
      _isMaintenanceMode = false;
    }
  }

  // Maintenance mode management
  bool get isMaintenanceMode => _isMaintenanceMode;

  Future<void> setMaintenanceMode(bool enabled) async {
    try {
      _isMaintenanceMode = enabled;

      // Try to save to Supabase
      await _supabase
          .from('admin_system_settings')
          .upsert({
            'id': 'system_settings',
            'maintenance_mode': enabled,
            'updated_at': DateTime.now().toIso8601String(),
          });

      notifyListeners();
    } catch (e) {
      // If Supabase fails, still update local state
      _isMaintenanceMode = enabled;
      notifyListeners();
      _error = 'Failed to save maintenance mode setting: $e';
    }
  }

  // Feature flags management
  Map<String, bool> get featureFlags => _featureFlags;

  Future<void> updateFeatureFlag(String featureName, bool isEnabled) async {
    try {
      _featureFlags[featureName] = isEnabled;

      // Try to save to Supabase
      await _supabase
          .from('admin_system_settings')
          .upsert({
            'id': 'system_settings',
            'feature_flags': _featureFlags,
            'updated_at': DateTime.now().toIso8601String(),
          });

      notifyListeners();
    } catch (e) {
      // If Supabase fails, still update local state
      _featureFlags[featureName] = isEnabled;
      notifyListeners();
      _error = 'Failed to save feature flag: $e';
    }
  }

  // Regions data and methods
  List<Region> get regions => _regions;

  List<AdminVendor> getVendorsInRegion(String regionId) {
    // For simplicity, return vendors whose serviceAreas contain the region name
    try {
      final region = _regions.firstWhere((r) => r.id == regionId, orElse: () => throw StateError('Region not found'));
      return _vendors.where((v) => v.serviceAreas.contains(region.name)).toList();
    } on StateError {
      return [];
    }
  }

  Future<void> addRegion({
    required String name,
    required RegionType type,
    String? parentId,
    String? code,
  }) async {
    print('DEBUG: addRegion called with name: $name, type: $type, parentId: $parentId, code: $code');
    try {
      if (type == RegionType.country) {
        // Add country to 'countries' table
        print('DEBUG: Attempting to insert into countries...');
        final response = await _supabase.from('countries').insert({
          'name': name,
          'code': code,
          'is_active': true,
        }).select();
        print('DEBUG: Insert country response: $response');

      } else if (type == RegionType.state) {
        // Add state to 'regions' table
        print('DEBUG: Attempting to insert into regions (state)...');
        final data = {
          'name': name,
          'code': code,
          'is_active': true,
        };
        // If parentId provided, link to country
        if (parentId != null) {
          data['country_id'] = _getDbId(parentId);
        }
        final response = await _supabase.from('regions').insert(data).select();
        print('DEBUG: Insert region response: $response');

      } else if (type == RegionType.city) {
        if (parentId == null) {
          throw Exception('Parent region ID is required for cities');
        }
        
        // Validate that parent region (state) exists
        print('DEBUG: Validating parent region exists...');
        final dbParentId = _getDbId(parentId);
        final regionCheck = await _supabase
            .from('regions')
            .select('id')
            .eq('id', dbParentId)
            .maybeSingle();
        
        if (regionCheck == null) {
          throw Exception('Parent region with ID $dbParentId does not exist. Please create the state/region first.');
        }
        
        print('DEBUG: Parent region validated. Attempting to insert city...');
        final response = await _supabase.from('cities').insert({
          'name': name,
          'region_id': dbParentId,
          'is_active': true,
        }).select();
        print('DEBUG: Insert city response: $response');

      } else {
        throw Exception('Invalid region type: $type');
      }
      
      print('DEBUG: Reloading regions...');
      await _loadRegions(); // Refresh list
      print('DEBUG: Regions reloaded successfully');

    } catch (e) {
      print('DEBUG: Failed to add region - Exception: $e');
      _error = 'Failed to add region: $e';
      notifyListeners();
      rethrow; // Re-throw to let UI handle the error
    }
  }

  Future<void> updateRegion(String id, {required String name, String? code}) async {
    try {
      // Find region to determine type
      final region = _regions.firstWhere((r) => r.id == id, orElse: () => throw Exception('Region not found'));
      final dbId = _getDbId(id);
      
      if (region.type == RegionType.country) {
        await _supabase.from('countries').update({
          'name': name,
          'code': code,
        }).eq('id', dbId);
      } else if (region.type == RegionType.state) {
        await _supabase.from('regions').update({
          'name': name,
          'code': code,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', dbId);
      } else if (region.type == RegionType.city) {
        final data = {'name': name, 'updated_at': DateTime.now().toIso8601String()};
        await _supabase.from('cities').update(data).eq('id', dbId);
      }
      await _loadRegions();
    } catch (e) {
      _error = 'Failed to update region: $e';
      notifyListeners();
    }
  }

  Future<void> toggleRegionStatus(String id) async {
    try {
      final region = _regions.firstWhere((r) => r.id == id, orElse: () => throw Exception('Region not found'));
      final newStatus = !region.isActive;
      final dbId = _getDbId(id);

      if (region.type == RegionType.country) {
        await _supabase.from('countries').update({'is_active': newStatus}).eq('id', dbId);
      } else if (region.type == RegionType.state) {
        await _supabase.from('regions').update({'is_active': newStatus}).eq('id', dbId);
      } else if (region.type == RegionType.city) {
        await _supabase.from('cities').update({'is_active': newStatus}).eq('id', dbId);
      }
      await _loadRegions();
    } catch (e) {
      _error = 'Failed to toggle region status: $e';
      notifyListeners();
    }
  }

  Future<void> deleteRegion(String id) async {
    try {
      final region = _regions.firstWhere((r) => r.id == id, orElse: () => throw Exception('Region not found'));
      final dbId = _getDbId(id);

      if (region.type == RegionType.country) {
        await _supabase.from('countries').delete().eq('id', dbId);
      } else if (region.type == RegionType.state) {
        await _supabase.from('regions').delete().eq('id', dbId);
      } else if (region.type == RegionType.city) {
        await _supabase.from('cities').delete().eq('id', dbId);
      }
      await _loadRegions();
    } catch (e) {
      _error = 'Failed to delete region: $e';
      notifyListeners();
    }
  }

  // Helper to strip prefix from ID
  String _getDbId(String prefixedId) {
    if (prefixedId.startsWith('country_')) return prefixedId.replaceFirst('country_', '');
    if (prefixedId.startsWith('state_')) return prefixedId.replaceFirst('state_', '');
    if (prefixedId.startsWith('city_')) return prefixedId.replaceFirst('city_', '');
    return prefixedId;
  }

  // Service Categories data and methods

  List<ServiceCategory> get serviceCategories => _serviceCategories;

  Future<void> addServiceCategory({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
  }) async {
    try {
      await _supabase.from('service_categories').insert({
        'name': name,
        'description': description,
        'slug': name.toLowerCase().replaceAll(' ', '-'),
        'icon_name': icon.codePoint.toString(),
        'category_type': 'service', // Default
        'pricing_model': 'fixed', // Default
        'is_active': true,
      });
      await _loadServiceCategories();
    } catch (e) {
      _error = 'Failed to category: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateServiceCategory(
    String id, {
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (icon != null) updates['icon_name'] = icon.codePoint.toString();
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _supabase.from('service_categories').update(updates).eq('id', id).select();
      
      if (response == null || (response as List).isEmpty) {
        throw Exception('Failed to update category: No record found with ID $id');
      }
      
      await _loadServiceCategories();
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteServiceCategory(String id) async {
    try {
      final response = await _supabase.from('service_categories').delete().eq('id', id).select();
      
      if (response == null || (response as List).isEmpty) {
        throw Exception('Failed to delete category: No record found with ID $id');
      }
      
      await _loadServiceCategories();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleServiceCategoryStatus(String id) async {
    try {
      final category = _serviceCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Category with ID $id not found in local state'),
      );
      
      final response = await _supabase
          .from('admin_service_categories')
          .update({'is_active': !category.isActive})
          .eq('id', id)
          .select();
      
      if (response == null || (response as List).isEmpty) {
        throw Exception('Failed to update category status in database (0 rows affected).');
      }
          
      await _loadServiceCategories();
    } catch (e) {
      _error = 'Failed to toggle category status: $e';
      print('DEBUG: toggleServiceCategoryStatus error: $e');
      notifyListeners();
      rethrow;
    }
  }


  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AppUser> get users => _users;
  List<AdminVendor> get vendors => _vendors;
  List<Booking> get bookings => _bookings;
  List<TransactionEntry> get transactions => _transactions;
  List<SubscriptionPayment> get allSubscriptionPayments => _allSubscriptionPayments;

  // Additional getters for admin features
  List<ReportedUser> get reportedUsers => _reportedUsers;
  List<Invitation> get guestInvitations => _guestInvitations;
  List<Appointment> get appointments => _appointments;
  List<Rental> get rentals => _rentals;
  List<Payout> get payouts => _payouts;
  List<OverduePayment> get overdues => _overdues;
  List<Listing> get listings => _listings;
  List<Promotion> get promotions => _promotions;
  List<AdEntry> get ads => _ads;
  List<Article> get articles => _articles;
  List<BudgetSummary> get budgets => _budgets;
  List<RSVPEntry> get rsvps => _rsvps;
  List<Suggestion> get suggestions => _suggestions;
  List<Dispute> get disputes => _disputes;
  List<ReviewModeration> get reviewQueue => _reviewQueue;
  List<Appeal> get appeals => _appeals;
  List<Announcement> get announcements => _announcements;
  List<LoginEvent> get logins => _logins;
  List<RoleAssignment> get roles => _roles;
  List<ActivityLog> get activity => _activity;
  List<ApiIntegration> get apis => _apis;

  AdminVendor? getVendorById(String vendorId) {
    try {
      return _vendors.firstWhere((vendor) => vendor.id == vendorId);
    } on StateError {
      return null;
    }
  }

  // Computed properties
  int get totalUsers => _users.length;
  int get totalVendors => _vendors.length;
  double get totalRevenue => _transactions
      .where((t) => t.status == 'paid')
      .fold(0.0, (sum, t) => sum + t.amount);

  // New Fee Split Getters (11% markup: Total = Base * 1.11)
  double get totalGrossRevenue => totalRevenue;
  
  double get totalVendorPayouts => totalGrossRevenue / 1.11;
  
  double get totalPlatformFees => totalGrossRevenue - totalVendorPayouts;
      
  double get globalAverageRating {
    if (_allServices.isEmpty) return 0.0;
    final ratedServices = _allServices.where((s) => s.reviews != null && s.reviews!.isNotEmpty).toList();
    if (ratedServices.isEmpty) return 0.0;
    final sum = ratedServices.fold<double>(0.0, (acc, s) => acc + s.averageRating);
    return sum / ratedServices.length;
  }
  List<AdminVendor> get pendingApprovalVendors =>
      _vendors.where((v) => v.pendingApproval).toList();
  int get activeBookings =>
      _bookings.where((b) => b.status == 'confirmed').length;
  double get monthlyGrowth => 15.5;

  // Marketplace metrics (MVP dashboard)
  /// GMV = total booking value (customer payment total) from paid/confirmed bookings
  double get gmv => _transactions
      .where((t) => t.status == 'paid')
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Platform revenue (commission) from take rate
  double get platformRevenue => totalPlatformFees;

  /// Total number of bookings (confirmed or completed)
  int get totalBookingsCount => _bookings
      .where((b) =>
          b.status == 'confirmed' ||
          b.status == 'completed' ||
          b.status == 'paid')
      .length;

  /// Average order value = GMV / total bookings
  double get aov => totalBookingsCount > 0 ? gmv / totalBookingsCount : 0.0;

  /// Take rate as percentage (platform revenue / GMV)
  double get takeRatePercent => gmv > 0 ? (platformRevenue / gmv) * 100 : 0.0;

  /// Active vendors (verified, not suspended)
  int get activeVendorsCount =>
      _vendors.where((v) => v.verified && !v.suspended).length;

  /// Active customers (users with role customer)
  int get activeCustomersCount =>
      _users.where((u) => u.role.toLowerCase() == 'customer').length;

  /// Conversion rate: bookings / (estimated views or sessions). Placeholder when no analytics.
  double get conversionRatePercent {
    if (activeCustomersCount == 0) return 0.0;
    final estimatedViews = totalBookingsCount * 20; // placeholder: 20 views per booking
    if (estimatedViews == 0) return 0.0;
    return (totalBookingsCount / estimatedViews * 100).clamp(0.0, 100.0);
  }

  /// Top categories by booking value (GMV per category) for dashboard
  List<Map<String, dynamic>> get topCategoriesForDashboard {
    final paidBookings =
        _bookings.where((b) => b.status == 'confirmed' || b.status == 'completed' || b.status == 'paid').toList();
    final Map<String, double> categoryAmount = {};
    final Map<String, int> categoryCount = {};
    for (final b in paidBookings) {
      AdminVendor? vendor;
      try {
        vendor = _vendors.firstWhere((v) => v.id == b.vendorId);
      } catch (_) {}
      if (vendor != null) {
        final cat = vendor.category.isEmpty ? 'Other' : vendor.category;
        categoryAmount[cat] = (categoryAmount[cat] ?? 0) + b.amount;
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }
    }
    if (categoryAmount.isEmpty) {
      for (final v in _vendors) {
        final cat = v.category.isEmpty ? 'Other' : v.category;
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }
      return categoryCount.entries
          .map((e) => {
                'category': e.key,
                'count': e.value,
                'gmv': 0.0,
                'percent': 0.0,
              })
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    }
    final total = categoryAmount.values.fold(0.0, (a, b) => a + b);
    return categoryAmount.entries
        .map((e) => {
              'category': e.key,
              'count': categoryCount[e.key] ?? 0,
              'gmv': e.value,
              'percent': total > 0 ? (e.value / total * 100) : 0.0,
            })
        .toList()
      ..sort((a, b) => (b['gmv'] as double).compareTo(a['gmv'] as double));
  }

  // Product usage metrics (MAU, DAU, retention - use proxies when no activity table)
  int get mau => _users.length; // proxy: total registered users as MAU until we have last_active
  int get dau => (mau * 0.15).round().clamp(0, mau); // proxy: ~15% of MAU as DAU
  double get retentionRatePercent {
    if (activeCustomersCount == 0) return 0.0;
    final withBookings = totalBookingsCount > 0 ? (activeCustomersCount * 0.4).round().clamp(1, activeCustomersCount) : 0;
    return activeCustomersCount > 0 ? (withBookings / activeCustomersCount * 100).clamp(0.0, 100.0) : 0.0;
  }

  // Vendor performance metrics
  double get vendorAcceptanceRatePercent {
    final requested = _bookings.length;
    if (requested == 0) return 0.0;
    final accepted = _bookings.where((b) => b.status == 'confirmed' || b.status == 'completed' || b.status == 'paid').length;
    return (accepted / requested * 100).clamp(0.0, 100.0);
  }

  /// Top vendors by revenue (from paid/confirmed bookings)
  List<Map<String, dynamic>> get topVendorsByRevenue {
    final paid = _bookings.where((b) => b.status == 'confirmed' || b.status == 'completed' || b.status == 'paid').toList();
    final Map<String, double> revenue = {};
    final Map<String, String> names = {};
    for (final b in paid) {
      revenue[b.vendorId] = (revenue[b.vendorId] ?? 0) + b.amount;
      names[b.vendorId] = b.vendorName;
    }
    return revenue.entries
        .map((e) => {'vendorId': e.key, 'vendorName': names[e.key] ?? 'Unknown', 'revenue': e.value})
        .toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
  }

  /// Vendor response time placeholder (hrs) - N/A until we have message timestamps
  String get vendorResponseTimeDisplay => '—'; // or fetch from support/chat when available

  // EventEase-specific: peak event dates, average event budget
  List<Map<String, dynamic>> get peakEventDates {
    final paid = _bookings.where((b) => b.status == 'confirmed' || b.status == 'completed' || b.status == 'paid').toList();
    final Map<String, int> dateCount = {};
    final Map<String, double> dateAmount = {};
    for (final b in paid) {
      final d = b.date is String ? (b.date as String).split('T').first : b.date.toString();
      dateCount[d] = (dateCount[d] ?? 0) + 1;
      dateAmount[d] = (dateAmount[d] ?? 0) + b.amount;
    }
    return dateCount.entries
        .map((e) => {'date': e.key, 'count': e.value, 'gmv': dateAmount[e.key] ?? 0})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  double get averageEventBudget => aov; // same as AOV for event bookings

  // Marketing metrics (placeholders until ad/cost data)
  double get cac => 0.0; // Customer Acquisition Cost - set when you have ad spend
  double get ltv => activeCustomersCount > 0 ? (platformRevenue / activeCustomersCount) : 0.0; // LTV = platform revenue per customer
  bool get hasCacData => false; // toggle to show CAC when available

  // Vendor management methods
  Future<void> approveVendor(String vendorId) async {
    try {
      // 1. Try to update vendor_profiles if it exists (for regular vendor users)
      final profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id, user_id')
          .or('id.eq.$vendorId,user_id.eq.$vendorId')
          .maybeSingle();

      String? targetUserId;

      if (profileResponse != null) {
        final profileId = profileResponse['id'];
        targetUserId = profileResponse['user_id'];
        
        await _supabase
            .from('vendor_profiles')
            .update({
              'profile_completion_percentage': 100,
              'profile_completion_status': 'approved',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', profileId);
            
        if (targetUserId != null) {
          await _supabase
              .from('vendor_user')
              .update({'status': 'active'})
              .eq('id', targetUserId!);
        }
      }

      // 2. Note: We do not update admin_vendors here as it's a junction table
      // that doesn't hold status/verification columns. Those are in vendor_profiles.

      // Log the activity
      final vendorName = _vendors.firstWhere((v) => v.id == vendorId, orElse: () => AdminVendor(vendorId, 'Vendor', '', false, false, 0, 0, 0, [], false)).name;
      await _logActivity(
        title: 'Vendor Approved: $vendorName',
        subtitle: 'Application processed successfully',
        type: 'registration',
        action: 'vendor_approved',
      );

      // Update local state
      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        _vendors[index] = AdminVendor(
          _vendors[index].id,
          _vendors[index].name,
          _vendors[index].category,
          true,
          false,
          _vendors[index].rating,
          _vendors[index].reviews,
          _vendors[index].bookings,
          _vendors[index].serviceAreas,
          false,
          contactInfo: _vendors[index].contactInfo,
          documents: _vendors[index].documents,
          documentsVerified: _vendors[index].documentsVerified,
          documentVerificationNotes: _vendors[index].documentVerificationNotes,
          documentsVerifiedAt: _vendors[index].documentsVerifiedAt,
        );
        notifyListeners();

        // Send notification to vendor if we found a user ID
        if (targetUserId != null) {
          await _notificationService.createNotification(
            userId: targetUserId!, // Use resolved userId, not vendorId which might be a profileId
            title: 'Vendor Application Approved',
            message: 'Congratulations! Your vendor application has been approved. You can now start offering your services on EventEase.',
            type: NotificationType.vendorApproval,
            priority: NotificationPriority.high,
          );
        }
      }
    } catch (e) {
      print('Error approving vendor: $e');
      _error = 'Failed to approve vendor: $e';
      notifyListeners();
    } finally {
      // Refresh to ensure everything is in sync
      await _loadVendors();
      await _loadUsers();
    }
  }

  Future<void> rejectVendor(String vendorId) async {
    try {
      // 1. Try to update vendor_profiles if it exists (for regular vendor users)
      final profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id, user_id')
          .or('id.eq.$vendorId,user_id.eq.$vendorId')
          .maybeSingle();

      String? targetUserId;

      if (profileResponse != null) {
        final profileId = profileResponse['id'];
        targetUserId = profileResponse['user_id'];
        
        await _supabase
            .from('vendor_profiles')
            .update({
              'profile_completion_status': 'rejected',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', profileId);
      }

      // 2. Note: We do not update admin_vendors here as it's a junction table
      // that doesn't hold status/verification columns. Those are in vendor_profiles.

      // Log the activity
      final vendorName = _vendors.firstWhere((v) => v.id == vendorId, orElse: () => AdminVendor(vendorId, 'Vendor', '', false, false, 0, 0, 0, [], false)).name;
      await _logActivity(
        title: 'Vendor Rejected: $vendorName',
        subtitle: 'Application was declined',
        type: 'registration',
        action: 'vendor_rejected',
      );

      // Update local state for vendors
      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        _vendors[index] = AdminVendor(
          _vendors[index].id,
          _vendors[index].name,
          _vendors[index].category,
          false,
          false,
          _vendors[index].rating,
          _vendors[index].reviews,
          _vendors[index].bookings,
          _vendors[index].serviceAreas,
          false,
          contactInfo: _vendors[index].contactInfo,
          documents: _vendors[index].documents,
          documentsVerified: _vendors[index].documentsVerified,
          documentVerificationNotes: _vendors[index].documentVerificationNotes,
          documentsVerifiedAt: _vendors[index].documentsVerifiedAt,
        );
      }

      // Update local state for users
      final userIndex = _users.indexWhere((u) => u.id == vendorId);
      if (userIndex != -1) {
        _users[userIndex].status = 'pending'; // Or whatever status rejection should set
      }

      notifyListeners();

      // Send notification to vendor if we found a user ID
      if (targetUserId != null) {
        await _notificationService.createNotification(
          userId: targetUserId!,
          title: 'Vendor Application Rejected',
          message: 'Unfortunately, your vendor application has been rejected. Please review the requirements and apply again.',
          type: NotificationType.vendorRejection,
          priority: NotificationPriority.normal,
        );
      }
    } catch (e) {
      print('Error rejecting vendor: $e');
      _error = 'Failed to reject vendor: $e';
      notifyListeners();
    } finally {
      // Refresh to ensure everything is in sync
      await _loadVendors();
      await _loadUsers();
    }
  }

  Future<void> toggleVendorSuspension(String vendorId) async {
    try {
      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        final currentVendor = _vendors[index];
        _vendors[index] = AdminVendor(
          currentVendor.id,
          currentVendor.name,
          currentVendor.category,
          currentVendor.verified,
          !currentVendor.suspended,
          currentVendor.rating,
          currentVendor.reviews,
          currentVendor.bookings,
          currentVendor.serviceAreas,
          currentVendor.pendingApproval,
          contactInfo: currentVendor.contactInfo,
          documents: currentVendor.documents,
          documentsVerified: currentVendor.documentsVerified,
          documentVerificationNotes: currentVendor.documentVerificationNotes,
          documentsVerifiedAt: currentVendor.documentsVerifiedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle vendor suspension: $e';
      notifyListeners();
    }
  }

  Future<void> activateVendor(String vendorId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.from('vendor_user').update({
        'status': 'active',
      }).eq('id', vendorId);

      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        final currentVendor = _vendors[index];
        _vendors[index] = AdminVendor(
          currentVendor.id,
          currentVendor.name,
          currentVendor.category,
          currentVendor.verified,
          false,
          currentVendor.rating,
          currentVendor.reviews,
          currentVendor.bookings,
          currentVendor.serviceAreas,
          currentVendor.pendingApproval,
          contactInfo: currentVendor.contactInfo,
          documents: currentVendor.documents,
          documentsVerified: currentVendor.documentsVerified,
          documentVerificationNotes: currentVendor.documentVerificationNotes,
          documentsVerifiedAt: currentVendor.documentsVerifiedAt,
        );
        notifyListeners();

        // Send notification to vendor
        await _notificationService.createNotification(
          userId: vendorId,
          title: 'Vendor Account Activated',
          message: 'Your vendor account has been activated. You can now resume offering your services on EventEase.',
          type: NotificationType.vendorActivation,
          priority: NotificationPriority.high,
        );
      }
      
      await _logActivity(
        title: 'Vendor Activated',
        subtitle: 'Status updated to active',
        type: 'system',
        action: 'vendor_activation',
      );
    } catch (e) {
      _error = 'Failed to activate vendor: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> suspendVendor(String vendorId, {bool suspended = true}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.from('vendor_user').update({
        'status': suspended ? 'suspended' : 'active',
      }).eq('id', vendorId);

      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        final currentVendor = _vendors[index];
        _vendors[index] = AdminVendor(
          currentVendor.id,
          currentVendor.name,
          currentVendor.category,
          currentVendor.verified,
          suspended,
          currentVendor.rating,
          currentVendor.reviews,
          currentVendor.bookings,
          currentVendor.serviceAreas,
          currentVendor.pendingApproval,
          contactInfo: currentVendor.contactInfo,
          documents: currentVendor.documents,
          documentsVerified: currentVendor.documentsVerified,
          documentVerificationNotes: currentVendor.documentVerificationNotes,
          documentsVerifiedAt: currentVendor.documentsVerifiedAt,
        );
        notifyListeners();

        // Send notification to vendor
        if (suspended) {
          await _notificationService.createNotification(
            userId: vendorId,
            title: 'Vendor Account Suspended',
            message: 'Your vendor account has been suspended. Please contact support for more information.',
            type: NotificationType.vendorSuspension,
            priority: NotificationPriority.high,
          );
        }
      }
      
      await _logActivity(
        title: suspended ? 'Vendor Suspended' : 'Vendor Un-suspended',
        subtitle: suspended ? 'Access restricted' : 'Access restored',
        type: 'system',
        action: suspended ? 'vendor_suspension' : 'vendor_unsuspension',
      );
    } catch (e) {
      _error = 'Failed to suspend vendor: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> _logActivity({
    required String title,
    required String subtitle,
    required String type,
    String? action,
  }) async {
    try {
      await _supabase.from('admin_activity_log').insert({
        'title': title,
        'subtitle': subtitle,
        'activity_type': type,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _activity.insert(0, ActivityLog(
        title: title,
        subtitle: subtitle,
        time: 'Just now',
        type: type,
        action: action,
      ));
      notifyListeners();
    } catch (e) {
      print('Failed to log admin activity: $e');
    }
  }



  Future<void> updateVendor(String vendorId, {
    String? name,
    String? category,
    bool? verified,
    bool? suspended,
    double? rating,
    int? reviews,
    int? bookings,
    List<String>? serviceAreas,
    bool? pendingApproval,
    bool? documentsVerified,
    String? documentVerificationNotes,
    DateTime? documentsVerifiedAt,
  }) async {
    try {
      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        final currentVendor = _vendors[index];
        _vendors[index] = AdminVendor(
          currentVendor.id,
          name ?? currentVendor.name,
          category ?? currentVendor.category,
          verified ?? currentVendor.verified,
          suspended ?? currentVendor.suspended,
          rating ?? currentVendor.rating,
          reviews ?? currentVendor.reviews,
          bookings ?? currentVendor.bookings,
          serviceAreas ?? currentVendor.serviceAreas,
          pendingApproval ?? currentVendor.pendingApproval,
          contactInfo: currentVendor.contactInfo,
          documents: currentVendor.documents,
          documentsVerified: documentsVerified ?? currentVendor.documentsVerified,
          documentVerificationNotes: documentVerificationNotes ?? currentVendor.documentVerificationNotes,
          documentsVerifiedAt: documentsVerifiedAt ?? currentVendor.documentsVerifiedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update vendor: $e';
      notifyListeners();
    }
  }

  Future<List<VendorDocument>> getVendorDocuments(String vendorId) async {
    // Check cache first for vendor users
    if (_vendorUserDocuments.containsKey(vendorId)) {
      return _vendorUserDocuments[vendorId]!;
    }

    try {
      // First check if this vendorId exists as a profile id (vendor user)
      final profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('id', vendorId)
          .maybeSingle();

      if (profileResponse != null) {
        // This is a vendor user profile id, get documents from vendor_documents
        final documentsResponse = await _supabase
            .from('vendor_documents')
            .select('*')
            .eq('vendor_profile_id', vendorId)
            .order('uploaded_at', ascending: false);

        final docs = documentsResponse.map((json) => VendorDocument(
          id: json['id'],
          type: _mapDocumentTypeFromString(json['document_type']),
          fileName: json['file_name'],
          fileUrl: json['file_url'],
          uploadedAt: DateTime.parse(json['uploaded_at']),
          isVerified: json['status'] == 'approved',
          verificationNotes: json['rejection_reason'],
          verifiedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
        )).toList();

        // Cache the documents
        _vendorUserDocuments[vendorId] = docs;
        return docs;
      } else {
        // Check if this vendorId is a user id (for vendor users)
        final userProfileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();

        if (userProfileResponse != null) {
          // This is a vendor user id, get documents using profile id
          final documentsResponse = await _supabase
              .from('vendor_documents')
              .select('*')
              .eq('vendor_profile_id', userProfileResponse['id'])
              .order('uploaded_at', ascending: false);

          final docs = documentsResponse.map((json) => VendorDocument(
            id: json['id'],
            type: _mapDocumentTypeFromString(json['document_type']),
            fileName: json['file_name'],
            fileUrl: json['file_url'],
            uploadedAt: DateTime.parse(json['uploaded_at']),
            isVerified: json['status'] == 'approved',
            verificationNotes: json['rejection_reason'],
            verifiedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
          )).toList();

          // Cache the documents
          _vendorUserDocuments[vendorId] = docs;
          return docs;
        } else {
          // Debug: Check if this user has a profile but no documents
          print('No profile found for vendorId: $vendorId');

          // This is an admin vendor, get documents from admin_vendor_documents
          final response = await _supabase
              .from('admin_vendor_documents')
              .select('*')
              .eq('admin_vendor_id', vendorId)
              .order('uploaded_at', ascending: false);

          return response.map((json) => VendorDocument.fromJson(json)).toList();
        }
      }
    } catch (e, stack) {
      print('DEBUG: Error getting vendor documents for $vendorId: $e');
      print('DEBUG: Stack trace: $stack');
      // Return empty list if Supabase fails
      return [];
    }
  }

  DocumentType _mapDocumentTypeFromString(String type) {
    switch (type) {
      case 'business_license':
        return DocumentType.businessLicense;
      case 'tax_registration':
      case 'tax_certificate':
        return DocumentType.taxCertificate;
      case 'insurance_certificate':
        return DocumentType.insuranceCertificate;
      case 'identification':
      case 'owner_identification':
      case 'halal_certificate':
        return DocumentType.identification;
      case 'bank_statement':
        return DocumentType.bankStatement;
      default:
        return DocumentType.other;
    }
  }

  Future<void> verifyVendorDocument(String vendorId, String documentId, bool isVerified, {String? notes}) async {
    try {
      await _supabase
          .from('admin_vendor_documents')
          .update({
            'status': isVerified ? 'approved' : 'rejected',
            'rejection_reason': notes,
            'reviewed_at': isVerified ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', documentId)
          .eq('admin_vendor_id', vendorId);
    } catch (e) {
      _error = 'Failed to verify document: $e';
      notifyListeners();
    }
  }

  // Additional computed properties for dashboard
  // Removed serviceCount aggregation as it is no longer stored in category model
  int get totalServices => 0; 
  // TODO: Implement separate service count fetching if needed
  int get totalProducts => _listings.length;
  int get totalPackages => _promotions.length;

  // Document verification status tracking
  Future<Map<String, dynamic>> getDocumentVerificationStatus() async {
    try {
      final totalDocuments = await getTotalDocumentsFromSupabase();
      final verifiedDocuments = await getVerifiedDocumentsFromSupabase();
      final documentDetails = await getDocumentDetailsByVendorFromSupabase();

      return {
        'totalDocuments': totalDocuments,
        'verifiedDocuments': verifiedDocuments,
        'pendingDocuments': totalDocuments - verifiedDocuments,
        'verificationRate': totalDocuments > 0 ? (verifiedDocuments / totalDocuments) * 100 : 0.0,
        'vendorDetails': documentDetails,
        'isWorking': true, // Verification system is operational
      };
    } catch (e) {
      return {
        'totalDocuments': totalDocuments,
        'verifiedDocuments': verifiedDocuments,
        'pendingDocuments': totalDocuments - verifiedDocuments,
        'verificationRate': totalDocuments > 0 ? (verifiedDocuments / totalDocuments) * 100 : 0.0,
        'vendorDetails': [],
        'isWorking': false, // Verification system has issues
        'error': e.toString(),
      };
    }
  }

  // Service review status tracking
  Future<Map<String, dynamic>> getServiceReviewStatus() async {
    try {
      // Get services that need review (pending approval or recently submitted)
      final pendingServices = _vendors
          .where((v) => v.pendingApproval)
          .length;

      final totalServices = _vendors.length;
      final approvedServices = _vendors
          .where((v) => v.verified && !v.pendingApproval)
          .length;

      return {
        'totalServices': totalServices,
        'approvedServices': approvedServices,
        'pendingServices': pendingServices,
        'reviewRate': totalServices > 0 ? (approvedServices / totalServices) * 100 : 0.0,
        'servicesNeedingReview': _vendors.where((v) => v.pendingApproval).toList(),
        'isWorking': true, // Review system is operational
      };
    } catch (e) {
      return {
        'totalServices': 0,
        'approvedServices': 0,
        'pendingServices': 0,
        'reviewRate': 0.0,
        'servicesNeedingReview': [],
        'isWorking': false, // Review system has issues
        'error': e.toString(),
      };
    }
  }

  // Async methods to get document counts directly from Supabase
  Future<int> getTotalDocumentsFromSupabase() async {
    try {
      final response = await _supabase.from('vendor_documents').select('id');
      return response.length;
    } catch (e) {
      // Return mock data if Supabase fails
      return 4; // vendor user docs only
    }
  }

  Future<int> getVerifiedDocumentsFromSupabase() async {
    try {
      final response = await _supabase
          .from('vendor_documents')
          .select('id')
          .eq('verified', true);
      return response.length;
    } catch (e) {
      // Return mock data if Supabase fails
      return 3; // verified vendor user docs only
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentDetailsByVendorFromSupabase() async {
    try {
      final List<Map<String, dynamic>> vendorDetails = [];

      // Get vendor users with their documents from vendor_documents table
      final vendorUserData = await _supabase
          .from('vendor_documents')
          .select('''
            vendor_profile_id,
            verified,
            vendor_profiles!inner(user_id, business_name, email)
          ''');

      // Group by vendor profile
      final Map<String, Map<String, dynamic>> vendorProfileMap = {};
      for (final doc in vendorUserData) {
        final profileId = doc['vendor_profile_id'] as String;
        final profileData = doc['vendor_profiles'] as Map<String, dynamic>;
        final businessName = profileData['business_name'] as String?;
        final email = profileData['email'] as String?;
        final vendorName = businessName ?? email ?? 'Unknown Vendo';
        final verified = doc['verified'] as bool;

        if (!vendorProfileMap.containsKey(profileId)) {
          vendorProfileMap[profileId] = {
            'name': vendorName,
            'totalDocuments': 0,
            'verifiedDocuments': 0,
          };
        }

        vendorProfileMap[profileId]!['totalDocuments'] = (vendorProfileMap[profileId]!['totalDocuments'] as int) + 1;
        if (verified == true) {
          vendorProfileMap[profileId]!['verifiedDocuments'] = (vendorProfileMap[profileId]!['verifiedDocuments'] as int) + 1;
        }
      }

      // Add vendor profiles to results
      for (final profile in vendorProfileMap.values) {
        vendorDetails.add({
          'name': profile['name'],
          'type': 'Vendor User',
          'totalDocuments': profile['totalDocuments'],
          'verifiedDocuments': profile['verifiedDocuments'],
        });
      }

      return vendorDetails;
    } catch (e) {
      // Return empty list if Supabase fails
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getDocumentDetailsFallback() async {
    try {
      final List<Map<String, dynamic>> vendorDetails = [];

      // Get admin vendors with document counts
      final adminVendors = await _supabase
          .from('admin_vendors')
          .select('id, name');

      for (final vendor in adminVendors) {
        final docResponse = await _supabase
            .from('admin_vendor_documents')
            .select('id, is_verified')
            .eq('vendor_id', vendor['id']);

        if (docResponse.isNotEmpty) {
          vendorDetails.add({
            'name': vendor['name'],
            'type': 'Admin Vendor',
            'totalDocuments': docResponse.length,
            'verifiedDocuments': docResponse.where((doc) => doc['is_verified'] == true).length,
          });
        }
      }

      // Get vendor users with document counts
      final vendorUsers = await _supabase
          .from('vendor_user')
          .select('id, name');

      for (final user in vendorUsers) {
        // Check if user has a profile
        final profileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', user['id'])
            .maybeSingle();

        if (profileResponse != null) {
          final docResponse = await _supabase
              .from('vendor_documents')
              .select('id, verified')
              .eq('vendor_profile_id', profileResponse['id']);

          if (docResponse.isNotEmpty) {
            vendorDetails.add({
              'name': user['name'],
              'type': 'Vendor User',
              'totalDocuments': docResponse.length,
              'verifiedDocuments': docResponse.where((doc) => doc['verified'] == true).length,
            });
          }
        }
      }

      return vendorDetails;
    } catch (e) {
      return [];
    }
  }

  // Keep cached getters for backward compatibility
  int get totalDocuments {
    int count = 0;
    // Count documents from regular vendors
    for (final vendor in _vendors) {
      count += vendor.documents.length;
    }
    // Count documents from vendor users
    for (final user in _users.where((u) => u.role == 'vendor')) {
      count += _vendorUserDocuments[user.id]?.length ?? 0;
    }
    return count;
  }

  int get verifiedDocuments {
    int count = 0;
    // Count verified documents from regular vendors
    for (final vendor in _vendors) {
      count += vendor.documents.where((doc) => doc.isVerified).length;
    }
    // Count verified documents from vendor users
    for (final user in _users.where((u) => u.role == 'vendor')) {
      final docs = _vendorUserDocuments[user.id] ?? [];
      count += docs.where((doc) => doc.isVerified).length;
    }
    return count;
  }


  // Commission management
  double get commissionPercent => _commissionPercent;
  void updateCommissionPercent(double percent) {
    _commissionPercent = percent;
    notifyListeners();
  }

  // Announcement management
  Future<void> addAnnouncement(String message, String audience) async {
    try {
      await _supabase.from('admin_announcements').insert({
        'message': message,
        'audience': audience.toLowerCase(),
        'channel': 'in_app',
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
        'created_by': _supabase.auth.currentUser?.id,
      });
      await _loadAnnouncements();
    } catch (e) {
      final newAnnouncement = Announcement(
        message: message,
        date: DateTime.now().toIso8601String().split('T')[0],
        audience: audience,
        pinned: false,
      );
      _announcements.add(newAnnouncement);
      notifyListeners();
    }
  }

  Future<void> pinAnnouncement(Announcement announcement) async {
    try {
      final index = _announcements.indexWhere((a) => a.message == announcement.message && a.date == announcement.date);
      if (index != -1) {
        _announcements[index] = Announcement(
          message: announcement.message,
          date: announcement.date,
          audience: announcement.audience,
          pinned: !announcement.pinned,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to pin announcement: $e';
      notifyListeners();
    }
  }

  Future<void> removeAnnouncement(Announcement announcement) async {
    try {
      _announcements.removeWhere((a) => a.message == announcement.message && a.date == announcement.date);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove announcement: $e';
      notifyListeners();
    }
  }



  // Document verification
  Future<void> verifyDocument(String vendorId, String documentId, {String? notes}) async {
    print('DEBUG: verifyDocument called for vendorId: $vendorId, documentId: $documentId');
    try {
      var profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('id', vendorId)
          .maybeSingle();

      String? actualProfileId;
      if (profileResponse != null) {
        actualProfileId = profileResponse['id'];
        print('DEBUG: Found regular vendor profile with ID: $actualProfileId');
      } else {
        // Check if it's a user id for a vendor
        final userProfileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();
        if (userProfileResponse != null) {
          actualProfileId = userProfileResponse['id'];
          print('DEBUG: Found vendor profile via user_id, actual profile ID: $actualProfileId');
        }
      }

      if (actualProfileId != null) {
        print('DEBUG: Updating vendor_documents table for documentId: $documentId');
        final updateData = {
          'status': 'approved',
          'rejection_reason': notes,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': _supabase.auth.currentUser?.id,
        };
        print('DEBUG: Update data: $updateData');
        
        await _supabase
            .from('vendor_documents')
            .update(updateData)
            .eq('id', documentId);
            
        print('DEBUG: vendor_documents update successful');
            
        // Update vendor profile completion status
        await _updateVendorProfileCompletion(actualProfileId);
        print('DEBUG: Profile completion updated for: $actualProfileId');
      } else {
        print('DEBUG: No regular vendor profile found, attempting to update admin_vendor_documents for admin_vendor_id: $vendorId');
        final updateData = {
          'status': 'approved',
          'rejection_reason': notes,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': _supabase.auth.currentUser?.id,
        };
        print('DEBUG: Update data: $updateData');

        await _supabase
            .from('admin_vendor_documents')
            .update(updateData)
            .eq('id', documentId)
            .eq('admin_vendor_id', vendorId);
        
        print('DEBUG: admin_vendor_documents update successful');
      }

      await VerificationEventLogger.log(
        vendorId: vendorId,
        eventType: 'approved',
        documentId: documentId,
        notes: notes,
      );

      // Update cache for vendor users
      if (_vendorUserDocuments.containsKey(vendorId)) {
        final docs = _vendorUserDocuments[vendorId]!;
        final docIndex = docs.indexWhere((d) => d.id == documentId);
        if (docIndex != -1) {
          docs[docIndex] = VendorDocument(
            id: docs[docIndex].id,
            type: docs[docIndex].type,
            fileName: docs[docIndex].fileName,
            fileUrl: docs[docIndex].fileUrl,
            uploadedAt: docs[docIndex].uploadedAt,
            isVerified: true,
            verificationNotes: notes,
            verifiedAt: DateTime.now(),
          );
        }
      }



      // Send notification to vendor
      await _notificationService.createNotification(
        userId: vendorId,
        title: 'Document Verified',
        message: 'Your document has been successfully verified by our admin team.',
        type: NotificationType.vendorDocumentVerification,
        priority: NotificationPriority.high,
      );

      // Update local state if vendor exists
      final vendorIndex = _vendors.indexWhere((v) => v.id == vendorId);
      if (vendorIndex != -1) {
        final docIndex = _vendors[vendorIndex].documents.indexWhere((d) => d.id == documentId);
        if (docIndex != -1) {
          final updatedDoc = VendorDocument(
            id: _vendors[vendorIndex].documents[docIndex].id,
            type: _vendors[vendorIndex].documents[docIndex].type,
            fileName: _vendors[vendorIndex].documents[docIndex].fileName,
            fileUrl: _vendors[vendorIndex].documents[docIndex].fileUrl,
            uploadedAt: _vendors[vendorIndex].documents[docIndex].uploadedAt,
            isVerified: true,
            verificationNotes: notes,
            verifiedAt: DateTime.now(),
          );
          _vendors[vendorIndex].documents[docIndex] = updatedDoc;
          notifyListeners();
        }
      }
    } catch (e) {
      print('DEBUG ERROR: verifyDocument failed: $e');
      _error = 'Failed to verify document: $e';
      notifyListeners();
    }
  }

  Future<void> verifyAllDocuments(String vendorId, {String? notes}) async {
    print('DEBUG: verifyAllDocuments called for vendorId: $vendorId');
    try {
      // First check if this vendorId exists as a profile id (vendor user)
      var profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('id', vendorId)
          .maybeSingle();

      String? actualProfileId;
      if (profileResponse != null) {
        actualProfileId = profileResponse['id'];
        print('DEBUG: Found regular vendor profile with ID: $actualProfileId');
      } else {
        // Check if it's a user id for a vendor
        final userProfileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();
        if (userProfileResponse != null) {
          actualProfileId = userProfileResponse['id'];
          print('DEBUG: Found vendor profile via user_id, actual profile ID: $actualProfileId');
        }
      }

      if (actualProfileId != null) {
        print('DEBUG: Updating all docs in vendor_documents for vendor_profile_id: $actualProfileId');
        final updateData = {
          'status': 'approved',
          'rejection_reason': notes,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': _supabase.auth.currentUser?.id,
        };
        print('DEBUG: Update data: $updateData');

        await _supabase
            .from('vendor_documents')
            .update(updateData)
            .eq('vendor_profile_id', actualProfileId);
        
        print('DEBUG: vendor_documents update successful');
            
        // Update vendor profile completion status
        await _updateVendorProfileCompletion(actualProfileId);
        print('DEBUG: Profile completion updated for: $actualProfileId');
      } else {
        print('DEBUG: No regular vendor profile found, attempting to update all docs in admin_vendor_documents for admin_vendor_id: $vendorId');
        final updateData = {
          'status': 'approved',
          'rejection_reason': notes,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': _supabase.auth.currentUser?.id,
        };
        print('DEBUG: Update data: $updateData');

        await _supabase
            .from('admin_vendor_documents')
            .update(updateData)
            .eq('admin_vendor_id', vendorId);
        
        print('DEBUG: admin_vendor_documents update successful');
      }

      // Update cache for vendor users
      if (_vendorUserDocuments.containsKey(vendorId)) {
        _vendorUserDocuments[vendorId] = _vendorUserDocuments[vendorId]!.map((doc) => VendorDocument(
          id: doc.id,
          type: doc.type,
          fileName: doc.fileName,
          fileUrl: doc.fileUrl,
          uploadedAt: doc.uploadedAt,
          isVerified: true,
          verificationNotes: notes,
          verifiedAt: DateTime.now(),
        )).toList();
      }

      // Send notification to vendor
      await _notificationService.createNotification(
        userId: vendorId,
        title: 'All Documents Verified',
        message: 'All your submitted documents have been successfully verified by our admin team.',
        type: NotificationType.vendorDocumentVerification,
        priority: NotificationPriority.high,
      );

      // Update local state if vendor exists
      final vendorIndex = _vendors.indexWhere((v) => v.id == vendorId);
      if (vendorIndex != -1) {
        final updatedDocs = _vendors[vendorIndex].documents.map((doc) => VendorDocument(
          id: doc.id,
          type: doc.type,
          fileName: doc.fileName,
          fileUrl: doc.fileUrl,
          uploadedAt: doc.uploadedAt,
          isVerified: true,
          verificationNotes: notes,
          verifiedAt: DateTime.now(),
        )).toList();
        _vendors[vendorIndex] = AdminVendor(
          _vendors[vendorIndex].id,
          _vendors[vendorIndex].name,
          _vendors[vendorIndex].category,
          _vendors[vendorIndex].verified,
          _vendors[vendorIndex].suspended,
          _vendors[vendorIndex].rating,
          _vendors[vendorIndex].reviews,
          _vendors[vendorIndex].bookings,
          _vendors[vendorIndex].serviceAreas,
          _vendors[vendorIndex].pendingApproval,
          contactInfo: _vendors[vendorIndex].contactInfo,
          documents: updatedDocs,
          documentsVerified: true,
          documentVerificationNotes: notes,
          documentsVerifiedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG ERROR: verifyAllDocuments failed: $e');
      _error = 'Failed to verify all documents: $e';
      notifyListeners();
    }
  }

  Future<void> rejectDocument(String vendorId, String documentId, {String? notes}) async {
    print('DEBUG: rejectDocument called for vendorId: $vendorId, documentId: $documentId');
    try {
      var profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('id', vendorId)
          .maybeSingle();

      String? actualProfileId;
      if (profileResponse != null) {
        actualProfileId = profileResponse['id'];
      } else {
        final userProfileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();
        if (userProfileResponse != null) {
          actualProfileId = userProfileResponse['id'];
        }
      }

      if (actualProfileId != null) {
        await _supabase
            .from('vendor_documents')
            .update({
              'status': 'rejected',
              'rejection_reason': notes,
              'reviewed_at': DateTime.now().toIso8601String(),
              'reviewed_by': _supabase.auth.currentUser?.id,
            })
            .eq('id', documentId);
        
        await _updateVendorProfileCompletion(actualProfileId);
      } else {
        await _supabase
            .from('admin_vendor_documents')
            .update({
              'status': 'rejected',
              'rejection_reason': notes,
              'reviewed_at': DateTime.now().toIso8601String(),
              'reviewed_by': _supabase.auth.currentUser?.id,
            })
            .eq('id', documentId)
            .eq('admin_vendor_id', vendorId);
      }

      // Send notification
      await _notificationService.createNotification(
        userId: vendorId,
        title: 'Document Rejected',
        message: 'One of your documents was rejected: $notes',
        type: NotificationType.vendorDocumentVerification,
        priority: NotificationPriority.high,
      );

      // Update local state
      final vendorIndex = _vendors.indexWhere((v) => v.id == vendorId);
      if (vendorIndex != -1) {
        final docIndex = _vendors[vendorIndex].documents.indexWhere((d) => d.id == documentId);
        if (docIndex != -1) {
          _vendors[vendorIndex].documents[docIndex].isVerified = false;
          _vendors[vendorIndex].documents[docIndex].verificationNotes = notes;
          notifyListeners();
        }
      }
    } catch (e) {
      print('DEBUG ERROR: rejectDocument failed: $e');
      _error = 'Failed to reject document: $e';
      notifyListeners();
    }
  }

  Future<void> rejectAllDocuments(String vendorId, {String? notes}) async {
    print('DEBUG: rejectAllDocuments called for vendorId: $vendorId');
    try {
      var profileResponse = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('id', vendorId)
          .maybeSingle();

      String? actualProfileId;
      if (profileResponse != null) {
        actualProfileId = profileResponse['id'];
      } else {
        final userProfileResponse = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();
        if (userProfileResponse != null) {
          actualProfileId = userProfileResponse['id'];
        }
      }

      if (actualProfileId != null) {
        await _supabase
            .from('vendor_documents')
            .update({
              'status': 'rejected',
              'rejection_reason': notes,
              'reviewed_at': DateTime.now().toIso8601String(),
              'reviewed_by': _supabase.auth.currentUser?.id,
            })
            .eq('vendor_profile_id', actualProfileId);
        
        await _updateVendorProfileCompletion(actualProfileId);
      } else {
        await _supabase
            .from('admin_vendor_documents')
            .update({
              'status': 'rejected',
              'rejection_reason': notes,
              'reviewed_at': DateTime.now().toIso8601String(),
              'reviewed_by': _supabase.auth.currentUser?.id,
            })
            .eq('admin_vendor_id', vendorId);
      }

      // Send notification
      await _notificationService.createNotification(
        userId: vendorId,
        title: 'Documents Rejected',
        message: 'Your documents were rejected: $notes',
        type: NotificationType.vendorDocumentVerification,
        priority: NotificationPriority.high,
      );

      // Update local state
      final vendorIndex = _vendors.indexWhere((v) => v.id == vendorId);
      if (vendorIndex != -1) {
        for (var doc in _vendors[vendorIndex].documents) {
          doc.isVerified = false;
          doc.verificationNotes = notes;
        }
        _vendors[vendorIndex].documentsVerified = false;
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG ERROR: rejectAllDocuments failed: $e');
      _error = 'Failed to reject all documents: $e';
      notifyListeners();
    }
  }

  // Booking management
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = Booking(
          id: _bookings[index].id,
          userName: _bookings[index].userName,
          vendorName: _bookings[index].vendorName,
          vendorId: _bookings[index].vendorId,
          packageName: _bookings[index].packageName,
          date: _bookings[index].date,
          amount: _bookings[index].amount,
          status: status,
          priority: _bookings[index].priority,
          installmentPlan: _bookings[index].installmentPlan,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update booking status: $e';
      notifyListeners();
    }
  }

  Future<void> toggleBookingPriority(String bookingId) async {
    try {
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = Booking(
          id: _bookings[index].id,
          userName: _bookings[index].userName,
          vendorName: _bookings[index].vendorName,
          vendorId: _bookings[index].vendorId,
          packageName: _bookings[index].packageName,
          date: _bookings[index].date,
          amount: _bookings[index].amount,
          status: _bookings[index].status,
          priority: !_bookings[index].priority,
          installmentPlan: _bookings[index].installmentPlan,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle booking priority: $e';
      notifyListeners();
    }
  }

  // Rental management
  Future<void> markRentalReturned(String itemName) async {
    try {
      final index = _rentals.indexWhere((r) => r.item == itemName);
      if (index != -1) {
        _rentals[index] = Rental(
          item: _rentals[index].item,
          user: _rentals[index].user,
          deposit: _rentals[index].deposit,
          status: 'returned',
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark rental returned: $e';
      notifyListeners();
    }
  }

  Future<void> addRental(Rental rental) async {
    try {
      _rentals.add(rental);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add rental: $e';
      notifyListeners();
    }
  }

  Future<void> updateRental(String itemName, {String? item, String? user, int? deposit, String? status}) async {
    try {
      final index = _rentals.indexWhere((r) => r.item == itemName);
      if (index != -1) {
        _rentals[index] = Rental(
          item: item ?? _rentals[index].item,
          user: user ?? _rentals[index].user,
          deposit: deposit ?? _rentals[index].deposit,
          status: status ?? _rentals[index].status,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update rental: $e';
      notifyListeners();
    }
  }

  // Appointment management
  Future<void> addAppointment(Appointment appointment) async {
    try {
      _appointments.add(appointment);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add appointment: $e';
      notifyListeners();
    }
  }

  Future<void> updateAppointmentById(String title, {String? type, String? newTitle, String? date, String? vendor}) async {
    try {
      final index = _appointments.indexWhere((a) => a.title == title);
      if (index != -1) {
        _appointments[index] = Appointment(
          type: type ?? _appointments[index].type,
          title: newTitle ?? _appointments[index].title,
          date: date ?? _appointments[index].date,
          vendor: vendor ?? _appointments[index].vendor,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update appointment: $e';
      notifyListeners();
    }
  }

  Future<void> deleteAppointmentById(String title) async {
    try {
      _appointments.removeWhere((a) => a.title == title);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete appointment: $e';
      notifyListeners();
    }
  }

  // User management
  Future<void> banUser(String userId, {String reason = 'Violated platform policies', String banType = 'permanent'}) async {
    final adminId = _supabase.auth.currentUser?.id;
    print('ADMIN: Banning user $userId. Reason: $reason, Type: $banType. Admin performing action: $adminId');
    
    await updateUser(userId, status: 'banned');
    
    if (adminId != null) {
      try {
        print('SUPABASE: Inserting record into banned_users for $userId');
        await _supabase.from('banned_users').insert({
          'user_id': userId,
          'ban_type': banType,
          'reason': reason,
          'banned_by': adminId,
          'ban_start': DateTime.now().toIso8601String(),
          'is_active': true,
        });
        print('SUPABASE: Record inserted successfully into banned_users');
      } catch (e) {
        print('SUPABASE ERROR: Error inserting into banned_users: $e');
      }
    } else {
      print('ADMIN ERROR: No logged-in admin found to record the ban in banned_users table');
    }
  }

  Future<void> activateUser(String userId) async {
    print('ADMIN: Activating user $userId');
    await updateUser(userId, status: 'active');
    
    try {
      print('SUPABASE: Deactivating any active ban records for $userId');
      await _supabase.from('banned_users')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_active', true);
      print('SUPABASE: Ban records deactivated successfully');
    } catch (e) {
      print('SUPABASE ERROR: Error deactivating ban record: $e');
    }
  }

  Future<void> updateUser(String userId, {String? name, String? email, String? role, String? status}) async {
    final updateData = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updateData['name'] = name;
    if (email != null) updateData['email'] = email;
    if (role != null) updateData['role'] = role;
    if (status != null) updateData['status'] = status;

    print('ADMIN: Attempting to update user $userId with data: $updateData');

    final tablesToCheck = ['admin_user', 'vendor_user', 'customer_user', 'users'];
    bool updated = false;

    for (final table in tablesToCheck) {
      try {
        // Use select() to see if any row was actually updated
        final response = await _supabase.from(table).update(updateData).eq('id', userId).select();
        
        if (response.isNotEmpty) {
          print('SUPABASE: Successfully updated user $userId in $table table');
          updated = true;
          // We continue to 'users' table if we updated one of the role tables
          if (table == 'users') break;
        }
      } catch (e) {
        print('SUPABASE: Failed to update in $table: $e');
      }
    }

    if (!updated) {
      print('SUPABASE WARNING: User $userId was not found in any table (admin_user, vendor_user, customer_user, users)');
      _error = 'User not found in database';
      notifyListeners();
      return;
    }

    // Update local list
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = AppUser(
        id: _users[index].id,
        name: name ?? _users[index].name,
        email: email ?? _users[index].email,
        role: role ?? _users[index].role,
        status: status ?? _users[index].status,
        subscriptionTier: _users[index].subscriptionTier,
        subscriptionExpiry: _users[index].subscriptionExpiry,
      );
      notifyListeners();
    }
  }

  Future<void> updateUserSubscription(String userId, String tier, DateTime? expiry) async {
    try {
      final updateData = {
        'subscription_tier': tier,
        'subscription_expiry': expiry?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('customer_user').update(updateData).eq('id', userId);
      
      // Update local list
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        // Create new object to trigger listeners if necessary, though this provider usually just notifies
        _users[index] = AppUser(
          id: _users[index].id,
          name: _users[index].name,
          email: _users[index].email,
          role: _users[index].role,
          status: _users[index].status,
          subscriptionTier: tier,
          subscriptionExpiry: expiry,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update customer subscription: $e';
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<void> updateVendorSubscription(String vendorId, String tier, DateTime? expiry) async {
    try {
      final updateData = {
        'subscription_tier': tier,
        'subscription_expiry': expiry?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Try vendor_profiles first (claimed vendors)
      final profileResponse = await _supabase.from('vendor_profiles').update(updateData).eq('id', vendorId).select();
      
      if (profileResponse.isEmpty) {
        // Try admin_dashboard_vendors (unclaimed vendors)
        await _supabase.from('admin_dashboard_vendors').update(updateData).eq('id', vendorId);
      }
      
      // Update local list
      final index = _vendors.indexWhere((v) => v.id == vendorId);
      if (index != -1) {
        // Update the existing mutable object
        _vendors[index].subscriptionTier = tier;
        _vendors[index].subscriptionExpiry = expiry;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update vendor subscription: $e';
      notifyListeners();
      throw Exception(_error);
    }
  }

  Future<void> addGuest(String name, String email) async {
    try {
      await _supabase.from('users').insert({
        'name': name,
        'email': email,
        'role': 'guest',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _loadGuestInvitations();
    } catch (e) {
      _error = 'Failed to add guest: $e';
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('admin_user').delete().eq('id', userId);
    } catch (e) {
      try {
        await _supabase.from('vendor_user').delete().eq('id', userId);
      } catch (e) {
        try {
          await _supabase.from('customer_user').delete().eq('id', userId);
        } catch (e) {
          try {
            await _supabase.from('users').delete().eq('id', userId);
          } catch (e) {
            _error = 'Failed to delete user: $e';
            notifyListeners();
            return;
          }
        }
      }
    }
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  Future<void> resetUserPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      _error = 'Failed to send reset email: $e';
      notifyListeners();
    }
  }

  // Dispute management
  Future<void> resolveDispute(String caseId) async {
    try {
      await _supabase.from('admin_disputes').update({
        'status': 'resolved',
        'resolved_by': _supabase.auth.currentUser?.id,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('case_id', caseId);

      final index = _disputes.indexWhere((d) => d.caseId == caseId);
      if (index != -1) {
        _disputes[index] = Dispute(
          caseId: _disputes[index].caseId,
          parties: _disputes[index].parties,
          status: 'resolved',
          severity: _disputes[index].severity,
          comments: _disputes[index].comments,
          note: _disputes[index].note,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to resolve dispute: $e';
      notifyListeners();
    }
  }

  Future<void> dismissDispute(String caseId) async {
    try {
      final index = _disputes.indexWhere((d) => d.caseId == caseId);
      if (index != -1) {
        _disputes[index] = Dispute(
          caseId: _disputes[index].caseId,
          parties: _disputes[index].parties,
          status: 'dismissed',
          severity: _disputes[index].severity,
          comments: _disputes[index].comments,
          note: _disputes[index].note,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to dismiss dispute: $e';
      notifyListeners();
    }
  }

  Future<void> escalateDispute(String caseId) async {
    try {
      final index = _disputes.indexWhere((d) => d.caseId == caseId);
      if (index != -1) {
        _disputes[index] = Dispute(
          caseId: _disputes[index].caseId,
          parties: _disputes[index].parties,
          status: 'escalated',
          severity: 'High',
          comments: _disputes[index].comments,
          note: _disputes[index].note,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to escalate dispute: $e';
      notifyListeners();
    }
  }

  // Review moderation
  Future<void> approveReview(String reviewId) async {
    try {
      final index = _reviewQueue.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviewQueue.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to approve review: $e';
      notifyListeners();
    }
  }

  Future<void> rejectReview(String reviewId) async {
    try {
      final index = _reviewQueue.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        _reviewQueue.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to reject review: $e';
      notifyListeners();
    }
  }

  // Appeal management
  Future<void> approveAppeal(String caseId) async {
    try {
      final index = _appeals.indexWhere((a) => a.caseId == caseId);
      if (index != -1) {
        _appeals[index] = Appeal(
          caseId: _appeals[index].caseId,
          status: 'approved',
          comments: _appeals[index].comments,
          reason: _appeals[index].reason,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to approve appeal: $e';
      notifyListeners();
    }
  }

  Future<void> rejectAppeal(String caseId) async {
    try {
      final index = _appeals.indexWhere((a) => a.caseId == caseId);
      if (index != -1) {
        _appeals[index] = Appeal(
          caseId: _appeals[index].caseId,
          status: 'rejected',
          comments: _appeals[index].comments,
          reason: _appeals[index].reason,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to reject appeal: $e';
      notifyListeners();
    }
  }

  // Transaction management
  Future<void> updateTransactionStatus(String transactionId, String status) async {
    try {
      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index] = TransactionEntry(
          id: _transactions[index].id,
          party: _transactions[index].party,
          amount: _transactions[index].amount,
          status: status,
          date: _transactions[index].date,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update transaction status: $e';
      notifyListeners();
    }
  }

  Future<void> updatePayoutStatus(String payoutId, String status) async {
    try {
      // Update in Supabase
      await _supabase
          .from('admin_payouts')
          .update({'status': status})
          .eq('id', payoutId);

      // Update in local state
      final index = _payouts.indexWhere((p) => p.id == payoutId);
      if (index != -1) {
        _payouts[index] = Payout(
          id: _payouts[index].id,
          vendor: _payouts[index].vendor,
          vendorId: _payouts[index].vendorId,
          bankAccountId: _payouts[index].bankAccountId,
          amount: _payouts[index].amount,
          status: status,
          date: _payouts[index].date,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating payout status: $e');
      _error = 'Failed to update payout status: $e';
      notifyListeners();
    }
  }

  Future<bool> processAutomatedPayout(Payout payout) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Get Bank Account Details from vendor_banking table
      BankAccount? bankAccount;
      
      // Try lookup by bank_account_id if provided
      if (payout.bankAccountId != null) {
        final response = await _supabase
            .from('vendor_banking')
            .select('*')
            .eq('id', payout.bankAccountId!)
            .limit(1)
            .maybeSingle();
        
        if (response != null) {
          bankAccount = BankAccount(
            id: response['id'],
            userId: response['vendor_id'],
            bankName: response['bank_name'],
            accountHolderName: response['account_holder_name'],
            accountNumber: response['account_number'],
            status: BankAccountStatus.verified,
            isPrimary: true,
            verificationData: {},
            createdAt: DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(response['updated_at'] ?? '') ?? DateTime.now(),
          );
        }
      }

      // FALLBACK: If bank account not found by ID, try finding by vendor_id
      if (bankAccount == null && payout.vendorId != null) {
        final response = await _supabase
            .from('vendor_banking')
            .select('*')
            .eq('vendor_id', payout.vendorId!)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
            
        if (response != null) {
          bankAccount = BankAccount(
            id: response['id'],
            userId: response['vendor_id'],
            bankName: response['bank_name'],
            accountHolderName: response['account_holder_name'],
            accountNumber: response['account_number'],
            status: BankAccountStatus.verified,
            isPrimary: true,
            verificationData: {},
            createdAt: DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(response['updated_at'] ?? '') ?? DateTime.now(),
          );
        }
      }

      if (bankAccount == null) {
        throw Exception(
          'No bank account details found for ${payout.vendor}. '
          '(IDs used: Vendor: ${payout.vendorId}, Bank: ${payout.bankAccountId})'
        );
      }

      // 2. Call Billplz API via PaymentService
      final result = await PaymentService.createPayout(
        bankCode: bankAccount.bankName,
        bankAccountNumber: bankAccount.accountNumber,
        name: bankAccount.accountHolderName,
        amount: payout.amount,
        description: 'Automated Payout for ID: ${payout.id}',
      );

      // 3. Update Payout Status on Success
      if (result['id'] != null || result['status'] == 'success' || result['status'] == 'processed') {
        await updatePayoutStatus(payout.id, 'completed');
        
        await _logActivity(
          title: 'Automated Payout Processed',
          subtitle: 'RM ${payout.amount} sent to ${payout.vendor}',
          type: 'payment',
          action: 'automated_payout',
        );
        
        return true;
      } else {
        throw Exception('Billplz Payout failed: ${result['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Automated Payout Error: $e');
      _error = 'Automated Payout Failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to get bank account details for a payout (used for manual payouts)
  Future<BankAccount?> getBankAccount(Payout payout) async {
    try {
      if (payout.bankAccountId != null) {
        final response = await _supabase
            .from('vendor_banking')
            .select('*')
            .eq('id', payout.bankAccountId!)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          return BankAccount(
            id: response['id'],
            userId: response['vendor_id'],
            bankName: response['bank_name'],
            accountHolderName: response['account_holder_name'],
            accountNumber: response['account_number'],
            status: BankAccountStatus.verified,
            isPrimary: true,
            verificationData: {},
            createdAt: DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(response['updated_at'] ?? '') ?? DateTime.now(),
          );
        }
      }

      if (payout.vendorId != null) {
        final response = await _supabase
            .from('vendor_banking')
            .select('*')
            .eq('vendor_id', payout.vendorId!)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          return BankAccount(
            id: response['id'],
            userId: response['vendor_id'],
            bankName: response['bank_name'],
            accountHolderName: response['account_holder_name'],
            accountNumber: response['account_number'],
            status: BankAccountStatus.verified,
            isPrimary: true,
            verificationData: {},
            createdAt: DateTime.tryParse(response['created_at'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(response['updated_at'] ?? '') ?? DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching bank account: $e');
      return null;
    }
  }

  // Commission management
  Future<void> setCommissionPercent(double percent) async {
    try {
      _commissionPercent = percent;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to set commission percent: $e';
      notifyListeners();
    }
  }

  double getVendorCommission(String vendorId) {
    final vendor = getVendorById(vendorId);
    if (vendor == null) return 0.0;

    final vendorTransactions = _transactions
        .where((t) => t.status == 'paid' && (t.vendorId == vendorId || t.party == vendor.name))
        .toList();

    double totalCommission = 0.0;
    for (var transaction in vendorTransactions) {
      double rate = _commissionPercent; // Default Global

      // 1. Check Service Hierarchy
      if (transaction.serviceId != null) {
        try {
          final service = _allServices.firstWhere((s) => s.id == transaction.serviceId);
          if (service.commissionRate != null) {
            rate = service.commissionRate!;
            if (service.commissionOverride) {
              // Service Override locked
              totalCommission += transaction.amount * (rate / 100);
              continue; 
            }
          }
        } catch (_) {}
      }

      // 2. Check Vendor Hierarchy
      if (vendor.commissionRate != null) {
        rate = vendor.commissionRate!;
        // If vendor has override, it was already used or is the fallback
      }

      totalCommission += transaction.amount * (rate / 100);
    }

    return totalCommission;
  }

  // --- Commission & Fee Management ---

  Future<void> updateVendorCommission(String vendorId, {double? rate, bool? override}) async {
    try {
      final Map<String, dynamic> updates = {};
      if (rate != null) updates['commission_rate'] = rate;
      if (override != null) updates['commission_override'] = override;

      if (updates.isEmpty) return;

      await _supabase
          .from('vendor_profiles')
          .update(updates)
          .eq('id', vendorId);

      // Refresh local state
      await _loadVendors();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update vendor commission: $e';
      notifyListeners();
    }
  }

  Future<void> updateServiceCommission(String serviceId, {double? rate, bool? override}) async {
    try {
      final Map<String, dynamic> updates = {};
      if (rate != null) updates['commission_rate'] = rate;
      if (override != null) updates['commission_override'] = override;

      if (updates.isEmpty) return;

      await _supabase
          .from('vendor_services')
          .update(updates)
          .eq('id', serviceId);

      // Refresh local state
      await _loadAllServices();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update service commission: $e';
      notifyListeners();
    }
  }

  Future<void> updateServiceFeeTransparency(String serviceId, {
    bool? transport,
    bool? accommodation,
    bool? setup,
    String? other,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (transport != null) updates['is_transport_included'] = transport;
      if (accommodation != null) updates['is_accommodation_included'] = accommodation;
      if (setup != null) updates['is_setup_included'] = setup;
      if (other != null) updates['other_fees_description'] = other;

      if (updates.isEmpty) return;

      await _supabase
          .from('vendor_services')
          .update(updates)
          .eq('id', serviceId);

      // Refresh local state
      await _loadAllServices();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update fee transparency: $e';
      notifyListeners();
    }
  }

  // Bulk notification management
  Future<void> sendBulkNotificationToVendors(
    String title,
    String message,
    NotificationType type,
    NotificationPriority priority,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final notificationFutures = _vendors.map((vendor) =>
        _notificationService.createNotification(
          userId: vendor.id,
          title: title,
          message: message,
          type: type,
          priority: priority,
        ),
      ).toList();

      await Future.wait(notificationFutures);
    } catch (e) {
      _error = 'Failed to send bulk notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendBulkNotificationToUsers(
    String title,
    String message,
    NotificationType type,
    NotificationPriority priority,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final notificationFutures = _users.map((user) =>
        _notificationService.createNotification(
          userId: user.id,
          title: title,
          message: message,
          type: type,
          priority: priority,
        ),
      ).toList();

      await Future.wait(notificationFutures);
    } catch (e) {
      _error = 'Failed to send bulk notifications to users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Custom vendor notification methods
  Future<void> sendCustomNotificationToVendor(
    String vendorId,
    String title,
    String message,
    NotificationType type,
    NotificationPriority priority,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _notificationService.createNotification(
        userId: vendorId,
        title: title,
        message: message,
        type: type,
        priority: priority,
      );
    } catch (e) {
      _error = 'Failed to send custom notification to vendor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bulk notification to all users (both AppUser and AdminVendor)
  Future<void> sendBulkNotificationToAllUsers(
    String title,
    String message,
    NotificationType type,
    NotificationPriority priority,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userNotificationFutures = _users.map((user) =>
        _notificationService.createNotification(
          userId: user.id,
          title: title,
          message: message,
          type: type,
          priority: priority,
        ),
      ).toList();

      final vendorNotificationFutures = _vendors.map((vendor) =>
        _notificationService.createNotification(
          userId: vendor.id,
          title: title,
          message: message,
          type: type,
          priority: priority,
        ),
      ).toList();

      final allNotificationFutures = [...userNotificationFutures, ...vendorNotificationFutures];

      await Future.wait(allNotificationFutures);
    } catch (e) {
      _error = 'Failed to send bulk notifications to all users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update vendor profile completion status
  Future<void> _updateVendorProfileCompletion(String vendorId) async {
    try {
      // Get the current profile
      final profileResponse = await _supabase
          .from('vendor_profiles')
          .select()
          .eq('id', vendorId)
          .single();

      if (profileResponse == null) return;

      // Get documents count
      final documentsResponse = await _supabase
          .from('vendor_documents')
          .select('id, status')
          .eq('vendor_profile_id', vendorId);

      final totalDocuments = documentsResponse.length;
      final verifiedDocuments = documentsResponse.where((doc) => doc['status'] == 'approved').length;

      // Calculate completion percentage based on documents and profile data
      int completionPercentage = 0;
      if (totalDocuments > 0) {
        completionPercentage = ((verifiedDocuments / totalDocuments) * 100).round();
      }

      // Ensure minimum completion for basic profile info
      final profile = Map<String, dynamic>.from(profileResponse);
      bool hasBasicInfo = profile['business_name']?.isNotEmpty == true &&
          profile['description']?.isNotEmpty == true &&
          profile['phone']?.isNotEmpty == true &&
          profile['email']?.isNotEmpty == true;

      if (hasBasicInfo) {
        completionPercentage = completionPercentage.clamp(20, 100);
      }

      // Update the profile
      await _supabase.from('vendor_profiles').update({
        'profile_completion_percentage': completionPercentage,
        'profile_completion_status': completionPercentage == 100 ? 'complete' : 'incomplete',
      }).eq('id', vendorId);

    } catch (e) {
      // Silently fail for profile completion updates
      print('Failed to update vendor profile completion: $e');
    }
  }
}
