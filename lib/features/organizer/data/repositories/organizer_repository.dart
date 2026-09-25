import 'package:flutter/foundation.dart';
import 'package:eventease/features/organizer/data/models/booth.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_lead.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/models/expo_ticket.dart';
import 'package:eventease/features/organizer/data/models/expo_visitor.dart';
import 'package:eventease/features/organizer/data/models/live_expo.dart';
import 'package:eventease/features/organizer/data/organizer_data_mode.dart';
import 'package:eventease/features/organizer/data/organizer_demo_store.dart';
import 'package:eventease/features/organizer/data/organizer_scope.dart';
import 'package:eventease/core/services/admin_notification_service.dart';
import 'package:eventease/shared/models/admin_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizerRepository {
  OrganizerRepository._();

  static final OrganizerRepository instance = OrganizerRepository._();

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  OrganizerDemoStore get _demo => OrganizerDemoStore.instance;

  Future<bool> _isDemo() => OrganizerDataMode.isDemo;

  Future<String?> getCompanyId() async {
    if (await _isDemo()) return 'demo-company';
    final uid = _userId;
    if (uid == null) return null;

    final owner = await _client
        .from('organizer_companies')
        .select('id')
        .eq('owner_user_id', uid)
        .maybeSingle();
    if (owner != null) return owner['id'] as String;

    final staff = await _client
        .from('organizer_staff_members')
        .select('company_id')
        .eq('user_id', uid)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (staff != null) return staff['company_id'] as String?;

    // Auto-provision company if missing for active organizer
    try {
      final userEmail = _client.auth.currentUser?.email ?? 'organizer';
      final defaultName = userEmail.split('@').first.replaceAll('.', ' ');
      final inserted = await _client
          .from('organizer_companies')
          .insert({
            'owner_user_id': uid,
            'legal_name': '${defaultName.toUpperCase()} Events',
            'display_name': '${defaultName.toUpperCase()} Events',
            'contact_email': userEmail,
            'is_verified': true,
            'setup_completed': true,
          })
          .select('id')
          .maybeSingle();
      if (inserted != null) return inserted['id'] as String;
    } catch (_) {}

    return null;
  }

  Future<String?> createExpo({
    required String name,
    required String venue,
    String? venueAddress,
    required DateTime startAt,
    required DateTime endAt,
    required int boothCapacity,
    String ticketStrategy = 'free_and_paid',
    String pricingStrategy = 'tiered_zones',
  }) async {
    if (await _isDemo()) {
      final newId = 'expo-${DateTime.now().millisecondsSinceEpoch}';
      final summary = ExpoSummary(
        id: newId,
        name: name,
        venue: venue,
        status: ExpoStatus.upcoming,
        startAt: startAt,
        endAt: endAt,
        boothsBooked: 0,
        boothCapacity: boothCapacity,
        vendorCount: 0,
        visitorRegistrations: 0,
        ticketsSold: 0,
        revenueRm: 0,
        pendingPaymentsRm: 0,
      );
      _demo.addExpo(summary);
      await OrganizerScope.setActiveExpoId(newId);
      return newId;
    }

    final companyId = await getCompanyId();
    if (companyId == null) {
      throw 'Could not resolve organizer company ID. Please ensure your profile is active.';
    }

    final cleanSlug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final slug = '$cleanSlug-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    const validTicketStrategies = {'free_only', 'paid_only', 'free_and_paid'};
    final sanitizedTicketStrategy = validTicketStrategies.contains(ticketStrategy)
        ? ticketStrategy
        : 'free_and_paid';

    final res = await _client.from('organizer_expos').insert({
      'company_id': companyId,
      'name': name,
      'slug': slug,
      'venue': venue,
      'venue_address': venueAddress ?? venue,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'status': 'upcoming',
      'booth_capacity': boothCapacity,
      'ticket_strategy': sanitizedTicketStrategy,
      'pricing_strategy': pricingStrategy,
      'is_platform_hosted': false,
    }).select('id').single();

    final expoId = res['id'] as String;
    await OrganizerScope.setActiveExpoId(expoId);

    // Seed default booths for zone A, B, VIP
    final zoneACount = (boothCapacity * 0.5).round();
    final zoneBCount = (boothCapacity * 0.4).round();
    final vipCount = (boothCapacity * 0.1).round().clamp(2, 20);

    final List<Map<String, dynamic>> booths = [];
    for (int i = 1; i <= zoneACount; i++) {
      booths.add({
        'expo_id': expoId,
        'number': 'A${i.toString().padLeft(2, '0')}',
        'zone': 'a',
        'size_label': '3Ã—3m',
        'early_bird_price_rm': 1800,
        'normal_price_rm': 2200,
        'status': 'available',
      });
    }
    for (int i = 1; i <= zoneBCount; i++) {
      booths.add({
        'expo_id': expoId,
        'number': 'B${i.toString().padLeft(2, '0')}',
        'zone': 'b',
        'size_label': '3Ã—3m',
        'early_bird_price_rm': 1400,
        'normal_price_rm': 1700,
        'status': 'available',
      });
    }
    for (int i = 1; i <= vipCount; i++) {
      booths.add({
        'expo_id': expoId,
        'number': 'VIP${i.toString().padLeft(2, '0')}',
        'zone': 'vip',
        'size_label': '6Ã—6m Island',
        'early_bird_price_rm': 3200,
        'normal_price_rm': 3800,
        'status': 'available',
      });
    }

    try {
      await _client.from('organizer_booths').insert(booths);
    } catch (_) {}

    return expoId;
  }

  Future<String?> resolveExpoId({String? preferredId}) async {
    if (await _isDemo()) return _demo.resolveExpoId(preferredId: preferredId);
    if (preferredId != null && preferredId.isNotEmpty) {
      await OrganizerScope.setActiveExpoId(preferredId);
      return preferredId;
    }

    final stored = await OrganizerScope.getActiveExpoId();
    if (stored != null && stored.isNotEmpty) return stored;

    final companyId = await getCompanyId();
    if (companyId == null) return null;

    for (final status in ['ongoing', 'upcoming', 'draft']) {
      final row = await _client
          .from('organizer_expos')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', status)
          .order('start_at')
          .limit(1)
          .maybeSingle();
      if (row != null) {
        final id = row['id'] as String;
        await OrganizerScope.setActiveExpoId(id);
        return id;
      }
    }
    return null;
  }

  /// Same `organizer_expos` rows admin manages (upcoming/ongoing). Never demo or `events`.
  Future<List<ExpoSummary>> fetchPublicExpoSummaries() async {
    try {
      final rows = await _client
          .from('organizer_expos')
          .select()
          .inFilter('status', ['upcoming', 'ongoing'])
          .order('start_at', ascending: true);

      Map<String, String> companyNames = {};
      try {
        final companies = await _client
            .from('organizer_companies')
            .select('id, display_name, legal_name');
        for (final c in companies) {
          if (c['id'] != null) {
            companyNames[c['id'] as String] =
                (c['display_name'] ?? c['legal_name'] ?? 'Event Organizer') as String;
          }
        }
      } catch (_) {}

      return (rows as List).cast<Map<String, dynamic>>().map((r) {
        final cid = r['company_id'] as String? ?? '';
        final orgName = companyNames[cid] ??
            r['organizer_name'] ??
            (r['is_platform_hosted'] == true
                ? 'EventEase Official (Platform Event)'
                : 'EventEase Partner');
        return ExpoSummary.fromRow({
          ...r,
          'organizer_name': orgName,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching organizer_expos from Supabase: $e');
      return [];
    }
  }

  Future<List<ExpoSummary>> fetchExpoSummaries() async {
    if (await _isDemo()) return _demo.fetchExpoSummaries();
    final companyId = await getCompanyId();
    if (companyId == null) return [];

    try {
      final rows = await _client
          .from('organizer_expo_dashboard_stats')
          .select()
          .eq('company_id', companyId)
          .order('start_at', ascending: false);

      if ((rows as List).isNotEmpty) {
        return (rows as List)
            .cast<Map<String, dynamic>>()
            .map(ExpoSummary.fromRow)
            .toList();
      }
    } catch (_) {}

    // Direct fallback to organizer_expos
    try {
      final rows = await _client
          .from('organizer_expos')
          .select()
          .eq('company_id', companyId)
          .order('start_at', ascending: false);

      return (rows as List).cast<Map<String, dynamic>>().map((r) {
        return ExpoSummary(
          id: r['id'] as String,
          name: r['name'] as String? ?? 'Untitled Expo',
          venue: r['venue'] as String? ?? '',
          status: ExpoSummary.statusFromDb(r['status'] as String?),
          startAt: DateTime.tryParse(r['start_at'] ?? '') ?? DateTime.now(),
          endAt: DateTime.tryParse(r['end_at'] ?? '') ?? DateTime.now().add(const Duration(days: 3)),
          boothsBooked: 0,
          boothCapacity: (r['booth_capacity'] as num?)?.toInt() ?? 0,
          vendorCount: 0,
          visitorRegistrations: 0,
          ticketsSold: 0,
          revenueRm: 0,
          pendingPaymentsRm: 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<ExpoSummary?> fetchExpoSummary(String expoId) async {
    if (await _isDemo()) return _demo.fetchExpoSummary(expoId);
    final row = await _client
        .from('organizer_expo_dashboard_stats')
        .select()
        .eq('expo_id', expoId)
        .maybeSingle();
    if (row == null) return null;
    return ExpoSummary.fromRow(row);
  }

  Future<String?> fetchExpoName(String expoId) async {
    if (await _isDemo()) return _demo.fetchExpoName(expoId);
    final row = await _client.from('organizer_expos').select('name').eq('id', expoId).maybeSingle();
    return row?['name'] as String?;
  }

  Future<void> assignBooth(String boothId, {String? exhibitorId}) async {
    if (await _isDemo()) {
      _demo.assignBooth(boothId, exhibitorId: exhibitorId);
      return;
    }
    await _client.from('organizer_booths').update({
      'exhibitor_id': exhibitorId,
      'status': exhibitorId != null ? 'booked' : 'available',
    }).eq('id', boothId);
    if (exhibitorId != null) {
      await _client.from('organizer_exhibitors').update({'booth_id': boothId}).eq('id', exhibitorId);
    }
  }

  Future<List<Booth>> fetchBooths(String expoId) async {
    if (await _isDemo()) return _demo.fetchBooths(expoId);
    final rows = await _client
        .from('organizer_booths')
        .select('*, exhibitor:organizer_exhibitors!exhibitor_id(company_name)')
        .eq('expo_id', expoId)
        .order('number');

    return (rows as List).map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final exhibitor = map.remove('exhibitor') as Map<String, dynamic>?;
      return Booth.fromRow(map, vendorName: exhibitor?['company_name'] as String?);
    }).toList();
  }

  Future<List<ExhibitorVendor>> fetchExhibitors(
    String expoId, {
    ExhibitorStatus? status,
  }) async {
    if (await _isDemo()) return _demo.fetchExhibitors(expoId, status: status);
    var query = _client
        .from('organizer_exhibitors')
        .select('*, booth:organizer_booths!booth_id(number)')
        .eq('expo_id', expoId);

    if (status != null) {
      final dbStatus = switch (status) {
        ExhibitorStatus.approved => 'approved',
        ExhibitorStatus.rejected => 'rejected',
        ExhibitorStatus.underReview => 'under_review',
        ExhibitorStatus.infoRequested => 'info_requested',
        ExhibitorStatus.paymentPending => 'payment_pending',
        ExhibitorStatus.confirmed => 'confirmed',
        ExhibitorStatus.completed => 'completed',
        ExhibitorStatus.pending => 'pending',
      };
      query = query.eq('status', dbStatus);
    }

    final rows = await query.order('applied_at', ascending: false);
    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ExhibitorVendor.fromRow)
        .toList();
  }

  Future<ExhibitorVendor?> fetchExhibitor(String exhibitorId) async {
    if (await _isDemo()) return _demo.fetchExhibitor(exhibitorId);
    final row = await _client
        .from('organizer_exhibitors')
        .select('*, booth:organizer_booths!booth_id(number)')
        .eq('id', exhibitorId)
        .maybeSingle();
    if (row == null) return null;
    return ExhibitorVendor.fromRow(row);
  }

  Future<void> submitExhibitorApplication({
    required String expoId,
    String? expoName,
    required String companyName,
    required String category,
    required String contactName,
    required String phone,
    required String email,
    String? businessRegistration,
    String? website,
    String? socialMedia,
    String? description,
    required String packageName,
    required double boothFeeRm,
    String? preferredBooth,
    String? preferredZone,
    String? exhibitingCategory,
    String? preferredLocation,
    List<String> requirements = const [],
    bool marketingOptIn = true,
    List<String> tags = const [],
    String? vendorId,
  }) async {
    final payload = <String, dynamic>{
      'expo_id': expoId,
      'company_name': companyName,
      'category': category,
      'contact_name': contactName,
      'phone': phone,
      'email': email,
      'package_name': packageName,
      'booth_fee_rm': boothFeeRm,
      'paid_rm': 0,
      'status': 'pending',
      'payment_status': 'unpaid',
      'applied_at': DateTime.now().toUtc().toIso8601String(),
    };
    // Guard: vendorId must be a valid UUID before using it in uuid columns
    // or querying uuid columns (avoids 22P02 invalid input syntax for uuid,
    // e.g. when an email like info@grand20.com is passed instead).
    final isUuid = vendorId != null &&
        vendorId.isNotEmpty &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(vendorId);
    if (isUuid) {
      payload['vendor_id'] = vendorId;
      try {
        final profile = await _client
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();
        if (profile?['id'] != null) {
          payload['vendor_profile_id'] = profile!['id'];
        }
      } catch (_) {}
    }
    if (preferredBooth != null && preferredBooth.isNotEmpty) {
      payload['preferred_booth'] = preferredBooth;
    }
    if (preferredZone != null && preferredZone.isNotEmpty) {
      payload['preferred_zone'] = preferredZone;
    }
    if (tags.isNotEmpty) payload['tags'] = tags;

    try {
      await _client.from('organizer_exhibitors').insert(payload);
    } catch (e) {
      debugPrint('Exhibitor apply insert failed: $e');
      payload.remove('preferred_booth');
      payload.remove('preferred_zone');
      payload.remove('tags');
      payload.remove('vendor_id');
      try {
        // Do NOT re-add a non-UUID vendor_id here â€” that caused 22P02 retries.
        if (isUuid) payload['vendor_id'] = vendorId;
        await _client.from('organizer_exhibitors').insert(payload);
      } catch (retryError) {
        debugPrint('Exhibitor apply retry failed: $retryError');
        rethrow;
      }
    }

    await AdminNotificationService().createAdminNotification(
      type: AdminNotificationType.vendor,
      severity: AdminNotificationSeverity.medium,
      title: 'New exhibitor application',
      message: '$companyName applied to join ${expoName ?? 'an expo'} as an exhibitor.',
      relatedVendorId: vendorId,
      actionUrl: '/admin/expos',
    );
  }

  Future<List<ExhibitorVendor>> fetchVendorApplications(String emailOrVendorId) async {
    try {
      final idOrEmail = emailOrVendorId.trim();
      final bool isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(idOrEmail);
      // Emails must NOT be compared against the uuid vendor_id column (22P02).
      final rows = isUuid
          ? await _client
              .from('organizer_exhibitors')
              .select('*, booth:organizer_booths!booth_id(number)')
              .or('vendor_id.eq.$idOrEmail,email.eq.$idOrEmail')
              .order('applied_at', ascending: false)
          : await _client
              .from('organizer_exhibitors')
              .select('*, booth:organizer_booths!booth_id(number)')
              .eq('email', idOrEmail)
              .order('applied_at', ascending: false);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(ExhibitorVendor.fromRow)
          .toList();
    } catch (e) {
      debugPrint('Error fetching vendor applications: $e');
      return [];
    }
  }

  Future<void> updateExhibitorStatus(String exhibitorId, ExhibitorStatus status) async {
    if (await _isDemo()) {
      _demo.updateExhibitorStatus(exhibitorId, status);
      return;
    }
    final dbStatus = switch (status) {
      ExhibitorStatus.approved => 'approved',
      ExhibitorStatus.rejected => 'rejected',
      ExhibitorStatus.underReview => 'under_review',
      ExhibitorStatus.infoRequested => 'info_requested',
      ExhibitorStatus.paymentPending => 'payment_pending',
      ExhibitorStatus.confirmed => 'confirmed',
      ExhibitorStatus.completed => 'completed',
      ExhibitorStatus.pending => 'pending',
    };
    try {
      await _client.from('organizer_exhibitors').update({
        'status': dbStatus,
        if (status == ExhibitorStatus.approved) 'approved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', exhibitorId);
    } catch (e, st) {
      debugPrint('[OrganizerRepo] updateExhibitorStatus($dbStatus) failed for $exhibitorId: $e\n$st');
      rethrow;
    }
  }

  Future<void> requestMoreInfo(String exhibitorId, String message) async {
    if (await _isDemo()) {
      _demo.requestMoreInfo(exhibitorId, message);
      return;
    }
    try {
      await _client.from('organizer_exhibitors').update({
        'status': 'info_requested',
        'info_request_message': message,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', exhibitorId);
    } catch (e, st) {
      debugPrint('[OrganizerRepo] requestMoreInfo failed for $exhibitorId: $e\n$st');
      rethrow;
    }
  }

  Future<void> respondToMoreInfo(String exhibitorId, String response) async {
    if (await _isDemo()) {
      _demo.respondToMoreInfo(exhibitorId, response);
      return;
    }
    await _client.from('organizer_exhibitors').update({
      'status': 'under_review',
      'info_response_message': response,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', exhibitorId);
  }

  Future<void> approveExhibitor(
    String exhibitorId, {
    String? boothNumber,
    DateTime? paymentDeadline,
  }) async {
    if (await _isDemo()) {
      _demo.approveExhibitor(
        exhibitorId,
        boothNumber: boothNumber,
        paymentDeadline: paymentDeadline,
      );
      return;
    }
    final deadline = paymentDeadline ?? DateTime.now().add(const Duration(days: 7));
    try {
      await _client.from('organizer_exhibitors').update({
        'status': 'approved',
        if (boothNumber != null) 'preferred_booth': boothNumber,
        'payment_deadline': deadline.toUtc().toIso8601String(),
        'approved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', exhibitorId);
    } catch (e, st) {
      debugPrint('[OrganizerRepo] approveExhibitor failed for $exhibitorId: $e\n$st');
      rethrow;
    }
  }

  Future<void> payExhibitorFee(
    String exhibitorId, {
    required double amount,
    required String paymentMethod,
  }) async {
    if (await _isDemo()) {
      _demo.payExhibitorFee(exhibitorId, amount);
      return;
    }
    final ex = await fetchExhibitor(exhibitorId);
    final currentPaid = ex?.paidRm ?? 0;
    final totalFee = ex?.boothFeeRm ?? amount;
    final newPaid = (currentPaid + amount).clamp(0.0, totalFee);
    final isFull = newPaid >= totalFee;

    await _client.from('organizer_exhibitors').update({
      'paid_rm': newPaid,
      'payment_status': isFull ? 'paid' : 'partial',
      'status': isFull ? 'confirmed' : 'payment_pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', exhibitorId);
  }

  Future<void> addStaffPass(String exhibitorId, ExhibitorStaffPass pass) async {
    if (await _isDemo()) {
      _demo.addStaffPass(exhibitorId, pass);
      return;
    }
  }

  Future<void> submitPostEventReview(
    String exhibitorId, {
    required double rating,
    required String comment,
  }) async {
    if (await _isDemo()) {
      _demo.submitPostEventReview(exhibitorId, rating, comment);
      return;
    }
    await _client.from('organizer_exhibitors').update({
      'event_rating': rating,
      'review_comment': comment,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', exhibitorId);
  }

  Future<List<ExpoLead>> fetchLeads(String expoId) async {
    if (await _isDemo()) return _demo.fetchLeads(expoId);
    final rows = await _client
        .from('organizer_expo_leads')
        .select('*, exhibitor:organizer_exhibitors!assigned_exhibitor_id(company_name)')
        .eq('expo_id', expoId)
        .order('captured_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ExpoLead.fromRow)
        .toList();
  }

  Future<ExpoLead?> fetchLead(String leadId) async {
    if (await _isDemo()) return _demo.fetchLead(leadId);
    final row = await _client
        .from('organizer_expo_leads')
        .select('*, exhibitor:organizer_exhibitors!assigned_exhibitor_id(company_name)')
        .eq('id', leadId)
        .maybeSingle();
    if (row == null) return null;
    return ExpoLead.fromRow(row);
  }

  Future<void> assignLead(String leadId, String exhibitorId) async {
    if (await _isDemo()) {
      _demo.assignLead(leadId, exhibitorId);
      return;
    }
    await _client.from('organizer_expo_leads').update({
      'assigned_exhibitor_id': exhibitorId,
      'stage': 'contacted',
    }).eq('id', leadId);
  }

  Future<void> createLead({
    required String expoId,
    required String visitorName,
    required String phone,
    String? budgetRange,
    String? sourceBooth,
    List<String> interests = const [],
  }) async {
    if (await _isDemo()) {
      _demo.createLead(
        expoId: expoId,
        visitorName: visitorName,
        phone: phone,
        budgetRange: budgetRange,
        sourceBooth: sourceBooth,
        interests: interests,
      );
      return;
    }
    await _client.from('organizer_expo_leads').insert({
      'expo_id': expoId,
      'visitor_name': visitorName,
      'phone': phone,
      if (budgetRange != null) 'budget_range': budgetRange,
      if (sourceBooth != null) 'source_booth': sourceBooth,
      'interests': interests,
      'temperature': 'warm',
      'stage': 'new',
    });
  }

  Future<List<ExpoVisitor>> fetchVisitors(String expoId) async {
    if (await _isDemo()) return _demo.fetchVisitors(expoId);
    final rows = await _client
        .from('organizer_expo_visitors')
        .select()
        .eq('expo_id', expoId)
        .order('registered_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => ExpoVisitor.fromRow(r))
        .toList();
  }

  Future<ExpoVisitor?> fetchVisitor(String visitorId) async {
    if (await _isDemo()) return _demo.fetchVisitor(visitorId);
    final row = await _client
        .from('organizer_expo_visitors')
        .select()
        .eq('id', visitorId)
        .maybeSingle();
    if (row == null) return null;

    final savedRows = await _client
        .from('organizer_visitor_saved_vendors')
        .select('exhibitor_id')
        .eq('visitor_id', visitorId);
    final savedIds = (savedRows as List)
        .map((r) => (r as Map)['exhibitor_id'] as String)
        .toList();

    final visitRows = await _client
        .from('organizer_visitor_booth_visits')
        .select('booth:organizer_booths(number)')
        .eq('visitor_id', visitorId);
    final booths = (visitRows as List)
        .map((r) => ((r as Map)['booth'] as Map?)?['number'] as String?)
        .whereType<String>()
        .toList();

    return ExpoVisitor.fromRow(row, savedVendorIds: savedIds, visitedBooths: booths);
  }

  Future<int> countCheckedInToday(String expoId) async {
    if (await _isDemo()) return _demo.countCheckedInToday(expoId);
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day).toUtc().toIso8601String();
    final rows = await _client
        .from('organizer_expo_visitors')
        .select('id')
        .eq('expo_id', expoId)
        .eq('status', 'checked_in')
        .gte('checked_in_at', dayStart);
    return (rows as List).length;
  }

  Future<ExpoVisitor?> checkInNextRegistered(String expoId) async {
    if (await _isDemo()) return _demo.checkInNextRegistered(expoId);
    final row = await _client
        .from('organizer_expo_visitors')
        .select()
        .eq('expo_id', expoId)
        .eq('status', 'registered')
        .order('registered_at')
        .limit(1)
        .maybeSingle();
    if (row == null) return null;

    final id = row['id'] as String;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from('organizer_expo_visitors').update({
      'status': 'checked_in',
      'checked_in_at': now,
    }).eq('id', id);

    return fetchVisitor(id);
  }

  Future<void> registerVisitor({
    required String expoId,
    required String name,
    required String phone,
    String? budgetRange,
    DateTime? weddingDate,
  }) async {
    if (await _isDemo()) {
      _demo.registerVisitor(
        expoId: expoId,
        name: name,
        phone: phone,
        budgetRange: budgetRange,
        weddingDate: weddingDate,
      );
      return;
    }
    await _client.from('organizer_expo_visitors').insert({
      'expo_id': expoId,
      'name': name,
      'phone': phone,
      if (budgetRange != null) 'budget_range': budgetRange,
      if (weddingDate != null) 'wedding_date': weddingDate.toIso8601String().split('T').first,
      'status': 'registered',
      'ticket_code': 'EXPO-${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<List<ExpoMapVendor>> fetchExpoMapVendors(String expoId) async {
    if (await _isDemo()) return _demo.fetchExpoMapVendors(expoId);
    final rows = await _client
        .from('organizer_exhibitors')
        .select('company_name, category, booth:organizer_booths!booth_id(number, map_x, map_y)')
        .eq('expo_id', expoId)
        .eq('status', 'approved');

    return (rows as List)
        .where((r) => (r as Map)['booth'] != null)
        .cast<Map<String, dynamic>>()
        .map(ExpoMapVendor.fromRow)
        .toList();
  }

  Future<List<ExpoTicketType>> fetchTicketTypes(String expoId) async {
    if (await _isDemo()) return _demo.fetchTicketTypes(expoId);
    final rows = await _client
        .from('organizer_ticket_types')
        .select()
        .eq('expo_id', expoId)
        .order('tier');

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ExpoTicketType.fromRow)
        .toList();
  }

  Future<TicketSale?> fetchTicketSaleByCode(String expoId, String code) async {
    if (await _isDemo()) return _demo.fetchTicketSaleByCode(expoId, code);
    final row = await _client
        .from('organizer_ticket_sales')
        .select('*, ticket_type:organizer_ticket_types(tier)')
        .eq('expo_id', expoId)
        .eq('ticket_code', code)
        .maybeSingle();
    if (row == null) return null;
    return TicketSale.fromRow(row);
  }

  Future<void> checkInTicketSale(String saleId) async {
    if (await _isDemo()) {
      _demo.checkInTicketSale(saleId);
      return;
    }
    await _client.from('organizer_ticket_sales').update({
      'checked_in': true,
      'checked_in_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', saleId);
  }

  Future<List<TicketSale>> fetchTicketSales(String expoId) async {
    if (await _isDemo()) return _demo.fetchTicketSales(expoId);
    final rows = await _client
        .from('organizer_ticket_sales')
        .select('*, ticket_type:organizer_ticket_types(tier)')
        .eq('expo_id', expoId)
        .order('purchased_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(TicketSale.fromRow)
        .toList();
  }

  Future<AttendanceSnapshot> fetchAttendanceSnapshot(String expoId) async {
    if (await _isDemo()) return _demo.fetchAttendanceSnapshot(expoId);
    final visitors = await _client
        .from('organizer_expo_visitors')
        .select('status')
        .eq('expo_id', expoId);

    final sales = await _client
        .from('organizer_ticket_sales')
        .select('checked_in, ticket_type:organizer_ticket_types(tier)')
        .eq('expo_id', expoId);

    final visitorList = visitors as List;
    final saleList = sales as List;

    final totalRegistered = visitorList.length;
    final checkedInNow =
        visitorList.where((v) => (v as Map)['status'] == 'checked_in').length;
    final vipCheckedIn = saleList.where((s) {
      final m = s as Map;
      return m['checked_in'] == true && (m['ticket_type'] as Map?)?['tier'] == 'vip';
    }).length;

    return AttendanceSnapshot(
      totalRegistered: totalRegistered,
      checkedInNow: checkedInNow,
      vipCheckedIn: vipCheckedIn,
      hourlyRate: checkedInNow > 0 ? (checkedInNow ~/ 8).clamp(1, 999) : 0,
      hourlyTrend: List.generate(10, (i) => ((checkedInNow / 10) * (i + 1)).round()),
    );
  }

  Future<List<ExpoIncident>> fetchIncidents(String expoId) async {
    if (await _isDemo()) return _demo.fetchIncidents(expoId);
    final rows = await _client
        .from('organizer_expo_incidents')
        .select('*, staff:organizer_staff_members!assigned_staff_id(full_name)')
        .eq('expo_id', expoId)
        .order('reported_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ExpoIncident.fromRow)
        .toList();
  }

  Future<void> updateIncidentStatus(String incidentId, IncidentStatus status) async {
    if (await _isDemo()) {
      _demo.updateIncidentStatus(incidentId, status);
      return;
    }
    final dbStatus = switch (status) {
      IncidentStatus.inProgress => 'in_progress',
      IncidentStatus.resolved => 'resolved',
      IncidentStatus.open => 'open',
    };
    await _client.from('organizer_expo_incidents').update({
      'status': dbStatus,
      if (status == IncidentStatus.resolved)
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', incidentId);
  }

  Future<List<ExpoTimelineItem>> fetchTimeline(String expoId) async {
    if (await _isDemo()) return _demo.fetchTimeline(expoId);
    final rows = await _client
        .from('organizer_expo_timeline_items')
        .select()
        .eq('expo_id', expoId)
        .order('start_at');

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(ExpoTimelineItem.fromRow)
        .toList();
  }

  Future<List<EmergencyAlert>> fetchEmergencyAlerts(String expoId) async {
    if (await _isDemo()) return _demo.fetchEmergencyAlerts(expoId);
    final rows = await _client
        .from('organizer_emergency_alerts')
        .select()
        .eq('expo_id', expoId)
        .order('sent_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(EmergencyAlert.fromRow)
        .toList();
  }

  Future<void> sendEmergencyAlert({
    required String expoId,
    required String message,
    required List<String> recipientGroups,
  }) async {
    if (await _isDemo()) {
      _demo.sendEmergencyAlert(
        expoId: expoId,
        message: message,
        recipientGroups: recipientGroups,
      );
      return;
    }
    await _client.from('organizer_emergency_alerts').insert({
      'expo_id': expoId,
      'message': message,
      'recipient_groups': recipientGroups,
      'sent_by': _userId,
    });
  }

  Future<List<LiveBoothActivity>> fetchLiveBoothActivity(String expoId) async {
    if (await _isDemo()) return _demo.fetchLiveBoothActivity(expoId);
    final booths = await fetchBooths(expoId);
    final booked = booths.where((b) => b.status == BoothStatus.booked && b.vendorName != null);

    final dayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .toUtc()
        .toIso8601String();
    final leadRows = await _client
        .from('organizer_expo_leads')
        .select('source_booth')
        .eq('expo_id', expoId)
        .gte('captured_at', dayStart);

    final counts = <String, int>{};
    for (final row in leadRows as List) {
      final booth = (row as Map)['source_booth'] as String?;
      if (booth != null) counts[booth] = (counts[booth] ?? 0) + 1;
    }

    return booked
        .map(
          (b) => LiveBoothActivity(
            boothNumber: b.number,
            vendorName: b.vendorName!,
            leadsToday: counts[b.number] ?? 0,
            isActive: b.status == BoothStatus.booked,
            statusNote: counts[b.number] != null && counts[b.number]! > 10 ? 'Busy' : 'Active',
          ),
        )
        .toList();
  }

  Future<LiveExpoStats> fetchLiveExpoStats(String expoId) async {
    if (await _isDemo()) return _demo.fetchLiveExpoStats(expoId);
    final snapshot = await fetchAttendanceSnapshot(expoId);
    final booths = await fetchBooths(expoId);
    final activeBooths = booths.where((b) => b.status == BoothStatus.booked).length;
    final dayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
        .toUtc()
        .toIso8601String();
    final leadsToday = await _client
        .from('organizer_expo_leads')
        .select('id')
        .eq('expo_id', expoId)
        .gte('captured_at', dayStart);

    return LiveExpoStats(
      visitorsNow: snapshot.checkedInNow,
      activeBooths: activeBooths,
      hourlyRate: snapshot.hourlyRate,
      leadsToday: (leadsToday as List).length,
    );
  }
}
