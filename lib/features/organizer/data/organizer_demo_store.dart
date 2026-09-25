import 'package:eventease/features/organizer/data/models/booth.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_lead.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/models/expo_ticket.dart';
import 'package:eventease/features/organizer/data/models/expo_visitor.dart';
import 'package:eventease/features/organizer/data/models/live_expo.dart';
import 'package:eventease/features/organizer/data/organizer_scope.dart';

/// Mutable in-memory store mirroring organizer UI sample data (demo mode).
class OrganizerDemoStore {
  OrganizerDemoStore._() {
    reset();
  }

  static final OrganizerDemoStore instance = OrganizerDemoStore._();

  static const String defaultExpoId = 'expo-001';

  late List<ExpoSummary> expos;
  late List<Booth> booths;
  late List<ExhibitorVendor> exhibitors;
  late List<ExpoLead> leads;
  late List<ExpoVisitor> visitors;
  late List<ExpoTicketType> ticketTypes;
  late List<TicketSale> ticketSales;
  late List<ExpoIncident> incidents;
  late List<ExpoTimelineItem> timeline;
  late List<EmergencyAlert> emergencyAlerts;

  void reset() {
    expos = List<ExpoSummary>.from(ExpoSummary.sampleData());
    booths = List<Booth>.from(Booth.sampleData());
    exhibitors = List<ExhibitorVendor>.from(ExhibitorVendor.sampleData());
    leads = List<ExpoLead>.from(ExpoLead.sampleData());
    visitors = List<ExpoVisitor>.from(ExpoVisitor.sampleData());
    ticketTypes = List<ExpoTicketType>.from(ExpoTicketType.sampleData());
    ticketSales = List<TicketSale>.from(TicketSale.sampleData());
    incidents = List<ExpoIncident>.from(ExpoIncident.sampleData());
    timeline = List<ExpoTimelineItem>.from(ExpoTimelineItem.sampleData());
    emergencyAlerts = List<EmergencyAlert>.from(EmergencyAlert.sampleHistory());
  }

  Future<String?> resolveExpoId({String? preferredId}) async {
    if (preferredId != null && preferredId.isNotEmpty) {
      await OrganizerScope.setActiveExpoId(preferredId);
      return preferredId;
    }
    final stored = await OrganizerScope.getActiveExpoId();
    if (stored != null && expos.any((e) => e.id == stored)) return stored;
    final ongoing = expos.where((e) => e.status == ExpoStatus.ongoing).toList();
    final id = ongoing.isNotEmpty ? ongoing.first.id : defaultExpoId;
    await OrganizerScope.setActiveExpoId(id);
    return id;
  }

  List<ExpoSummary> fetchExpoSummaries() => List.unmodifiable(expos);

  ExpoSummary? fetchExpoSummary(String expoId) {
    for (final e in expos) {
      if (e.id == expoId) return e;
    }
    return null;
  }

  void addExpo(ExpoSummary expo) {
    expos.insert(0, expo);
  }

  String? fetchExpoName(String expoId) => fetchExpoSummary(expoId)?.name;

  List<Booth> fetchBooths(String expoId) => List.unmodifiable(booths);

  List<ExhibitorVendor> fetchExhibitors(String expoId, {ExhibitorStatus? status}) {
    var list = exhibitors;
    if (status != null) list = list.where((v) => v.status == status).toList();
    return List.unmodifiable(list);
  }

  ExhibitorVendor? fetchExhibitor(String id) {
    for (final v in exhibitors) {
      if (v.id == id) return v;
    }
    return null;
  }

  void addExhibitor(ExhibitorVendor exhibitor) {
    exhibitors.insert(0, exhibitor);
  }

  List<ExhibitorVendor> fetchVendorApplications(String emailOrVendorId) {
    return exhibitors.where((v) =>
      v.email.toLowerCase() == emailOrVendorId.toLowerCase() ||
      v.id == emailOrVendorId
    ).toList();
  }

  void updateExhibitorStatus(String id, ExhibitorStatus status) {
    final i = exhibitors.indexWhere((v) => v.id == id);
    if (i < 0) return;
    exhibitors[i] = exhibitors[i].copyWith(status: status);
  }

  void requestMoreInfo(String id, String message) {
    final i = exhibitors.indexWhere((v) => v.id == id);
    if (i < 0) return;
    exhibitors[i] = exhibitors[i].copyWith(
      status: ExhibitorStatus.infoRequested,
      infoRequestMessage: message,
    );
  }

  void respondToMoreInfo(String id, String response) {
    final i = exhibitors.indexWhere((v) => v.id == id);
    if (i < 0) return;
    exhibitors[i] = exhibitors[i].copyWith(
      status: ExhibitorStatus.underReview,
      infoResponseMessage: response,
    );
  }

  void approveExhibitor(String id, {String? boothNumber, DateTime? paymentDeadline}) {
    final i = exhibitors.indexWhere((v) => v.id == id);
    if (i < 0) return;
    final deadline = paymentDeadline ?? DateTime.now().add(const Duration(days: 7));
    exhibitors[i] = exhibitors[i].copyWith(
      status: ExhibitorStatus.approved,
      boothNumber: boothNumber ?? exhibitors[i].boothNumber ?? 'B04',
      paymentDeadline: deadline,
    );
  }

  void payExhibitorFee(String id, double amount) {
    final i = exhibitors.indexWhere((v) => v.id == id);
    if (i < 0) return;
    final ex = exhibitors[i];
    final newPaid = (ex.paidRm + amount).clamp(0.0, ex.boothFeeRm);
    final isFull = newPaid >= ex.boothFeeRm;
    exhibitors[i] = ex.copyWith(
      paidRm: newPaid,
      paymentStatus: isFull ? PaymentStatus.paid : PaymentStatus.partial,
      status: isFull ? ExhibitorStatus.confirmed : ExhibitorStatus.paymentPending,
    );
  }

  void addStaffPass(String exhibitorId, ExhibitorStaffPass pass) {
    final i = exhibitors.indexWhere((v) => v.id == exhibitorId);
    if (i < 0) return;
    final updatedList = List<ExhibitorStaffPass>.from(exhibitors[i].staffPasses)..add(pass);
    exhibitors[i] = exhibitors[i].copyWith(staffPasses: updatedList);
  }

  void submitPostEventReview(String exhibitorId, double rating, String comment) {
    final i = exhibitors.indexWhere((v) => v.id == exhibitorId);
    if (i < 0) return;
    exhibitors[i] = exhibitors[i].copyWith(
      eventRating: rating,
      reviewComment: comment,
    );
  }

  List<ExpoLead> fetchLeads(String expoId) => List.unmodifiable(leads);

  ExpoLead? fetchLead(String id) {
    for (final l in leads) {
      if (l.id == id) return l;
    }
    return null;
  }

  void assignLead(String leadId, String exhibitorId) {
    final li = leads.indexWhere((l) => l.id == leadId);
    final vi = exhibitors.indexWhere((v) => v.id == exhibitorId);
    if (li < 0 || vi < 0) return;
    final lead = leads[li];
    final vendor = exhibitors[vi];
    leads[li] = ExpoLead(
      id: lead.id,
      visitorName: lead.visitorName,
      phone: lead.phone,
      weddingDate: lead.weddingDate,
      budgetRange: lead.budgetRange,
      interests: lead.interests,
      assignedVendorId: exhibitorId,
      assignedVendorName: vendor.companyName,
      temperature: lead.temperature,
      stage: LeadStage.contacted,
      sourceBooth: lead.sourceBooth,
      capturedAt: lead.capturedAt,
      notes: lead.notes,
    );
  }

  void createLead({
    required String expoId,
    required String visitorName,
    required String phone,
    String? budgetRange,
    String? sourceBooth,
    List<String> interests = const [],
  }) {
    leads.insert(
      0,
      ExpoLead(
        id: 'l-${DateTime.now().millisecondsSinceEpoch}',
        visitorName: visitorName,
        phone: phone,
        budgetRange: budgetRange ?? '—',
        interests: interests,
        temperature: LeadTemperature.warm,
        stage: LeadStage.newLead,
        sourceBooth: sourceBooth ?? 'Registration',
        capturedAt: DateTime.now(),
      ),
    );
  }

  List<ExpoVisitor> fetchVisitors(String expoId) => List.unmodifiable(visitors);

  ExpoVisitor? fetchVisitor(String id) {
    for (final v in visitors) {
      if (v.id == id) return v;
    }
    return null;
  }

  int countCheckedInToday(String expoId) =>
      visitors.where((v) => v.status == VisitorCheckInStatus.checkedIn).length;

  ExpoVisitor? checkInNextRegistered(String expoId) {
    final i = visitors.indexWhere((v) => v.status == VisitorCheckInStatus.registered);
    if (i < 0) return null;
    final v = visitors[i];
    visitors[i] = ExpoVisitor(
      id: v.id,
      name: v.name,
      phone: v.phone,
      weddingDate: v.weddingDate,
      budgetRange: v.budgetRange,
      interests: v.interests,
      savedVendorIds: v.savedVendorIds,
      visitedBooths: v.visitedBooths,
      status: VisitorCheckInStatus.checkedIn,
      registeredAt: v.registeredAt,
      checkedInAt: DateTime.now(),
      ticketCode: v.ticketCode,
    );
    return visitors[i];
  }

  void registerVisitor({
    required String expoId,
    required String name,
    required String phone,
    String? budgetRange,
    DateTime? weddingDate,
  }) {
    visitors.insert(
      0,
      ExpoVisitor(
        id: 'vis-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        weddingDate: weddingDate,
        budgetRange: budgetRange ?? '—',
        interests: const [],
        savedVendorIds: const [],
        visitedBooths: const [],
        status: VisitorCheckInStatus.registered,
        registeredAt: DateTime.now(),
        ticketCode: 'EXPO-DEMO-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  List<ExpoMapVendor> fetchExpoMapVendors(String expoId) =>
      List.unmodifiable(ExpoMapVendor.sampleData());

  List<ExpoTicketType> fetchTicketTypes(String expoId) => List.unmodifiable(ticketTypes);

  List<TicketSale> fetchTicketSales(String expoId) => List.unmodifiable(ticketSales);

  TicketSale? fetchTicketSaleByCode(String expoId, String code) {
    for (final s in ticketSales) {
      if (s.ticketCode == code) return s;
    }
    return null;
  }

  void checkInTicketSale(String saleId) {
    final i = ticketSales.indexWhere((s) => s.id == saleId);
    if (i < 0) return;
    final s = ticketSales[i];
    ticketSales[i] = TicketSale(
      id: s.id,
      ticketCode: s.ticketCode,
      buyerName: s.buyerName,
      tier: s.tier,
      amountRm: s.amountRm,
      channel: s.channel,
      purchasedAt: s.purchasedAt,
      checkedIn: true,
    );
  }

  AttendanceSnapshot fetchAttendanceSnapshot(String expoId) => AttendanceSnapshot.sample();

  List<ExpoIncident> fetchIncidents(String expoId) => List.unmodifiable(incidents);

  void updateIncidentStatus(String incidentId, IncidentStatus status) {
    final i = incidents.indexWhere((inc) => inc.id == incidentId);
    if (i < 0) return;
    final inc = incidents[i];
    incidents[i] = ExpoIncident(
      id: inc.id,
      type: inc.type,
      title: inc.title,
      description: inc.description,
      location: inc.location,
      status: status,
      priority: inc.priority,
      reportedBy: inc.reportedBy,
      reportedAt: inc.reportedAt,
      assignedStaff: inc.assignedStaff,
    );
  }

  List<ExpoTimelineItem> fetchTimeline(String expoId) => List.unmodifiable(timeline);

  List<EmergencyAlert> fetchEmergencyAlerts(String expoId) => List.unmodifiable(emergencyAlerts);

  void sendEmergencyAlert({
    required String expoId,
    required String message,
    required List<String> recipientGroups,
  }) {
    emergencyAlerts.insert(
      0,
      EmergencyAlert(
        id: 'ea-${DateTime.now().millisecondsSinceEpoch}',
        message: message,
        sentAt: DateTime.now(),
        recipientGroups: recipientGroups,
        acknowledged: false,
      ),
    );
  }

  List<LiveBoothActivity> fetchLiveBoothActivity(String expoId) =>
      List.unmodifiable(LiveBoothActivity.sampleData());

  LiveExpoStats fetchLiveExpoStats(String expoId) {
    final snap = fetchAttendanceSnapshot(expoId);
    return LiveExpoStats(
      visitorsNow: snap.checkedInNow,
      activeBooths: booths.where((b) => b.status == BoothStatus.booked).length,
      hourlyRate: snap.hourlyRate,
      leadsToday: leads.length,
    );
  }

  void assignBooth(String boothId, {String? exhibitorId}) {
    final bi = booths.indexWhere((b) => b.id == boothId);
    if (bi < 0) return;
    final b = booths[bi];
    final vendorName = exhibitorId != null ? fetchExhibitor(exhibitorId)?.companyName : null;
    booths[bi] = Booth(
      id: b.id,
      number: b.number,
      zone: b.zone,
      size: b.size,
      earlyBirdPriceRm: b.earlyBirdPriceRm,
      normalPriceRm: b.normalPriceRm,
      status: exhibitorId != null ? BoothStatus.booked : BoothStatus.available,
      vendorId: exhibitorId,
      vendorName: vendorName,
      gridX: b.gridX,
      gridY: b.gridY,
      gridW: b.gridW,
      gridH: b.gridH,
    );
  }
}
