import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
    );
  }
}

class Invitation {
  final String id;
  final String name;
  final String status;

  Invitation({
    required this.id,
    required this.name,
    required this.status,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      name: json['name'],
      status: json['status'],
    );
  }
}

class ReportedUser {
  final String id;
  final String user;
  final String reason;

  ReportedUser({
    required this.id,
    required this.user,
    required this.reason,
  });

  factory ReportedUser.fromJson(Map<String, dynamic> json) {
    return ReportedUser(
      id: json['id'],
      user: json['user'],
      reason: json['reason'],
    );
  }
}

class UserGuestProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<AppUser> _users = [];
  List<Invitation> _guestInvitations = [];
  List<ReportedUser> _reportedUsers = [];
  bool _isLoading = false;
  String? _error;

  List<AppUser> get users => _users;
  List<Invitation> get guestInvitations => _guestInvitations;
  List<ReportedUser> get reportedUsers => _reportedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserGuestProvider() {
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch users
      final userResponse = await _supabase.from('users').select('*');
      _users = (userResponse as List).map((e) => AppUser.fromJson(e)).toList();

      // Fetch guest invitations
      final guestResponse = await _supabase.from('guest_invitations').select('*');
      _guestInvitations = (guestResponse as List).map((e) => Invitation.fromJson(e)).toList();

      // Fetch reported users
      final reportResponse = await _supabase.from('reported_users').select('*');
      _reportedUsers = (reportResponse as List).map((e) => ReportedUser.fromJson(e)).toList();

    } catch (e) {
      _error = 'Failed to load data: $e';
      _users = [];
      _guestInvitations = [];
      _reportedUsers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> banUser(String userId) async {
    try {
      await _supabase.from('users').update({'status': 'banned'}).eq('id', userId);
      fetchAllData();
    } catch (e) {
      _error = 'Failed to ban user: $e';
      notifyListeners();
    }
  }

  Future<void> activateUser(String userId) async {
    try {
      await _supabase.from('users').update({'status': 'active'}).eq('id', userId);
      fetchAllData();
    } catch (e) {
      _error = 'Failed to activate user: $e';
      notifyListeners();
    }
  }
}
