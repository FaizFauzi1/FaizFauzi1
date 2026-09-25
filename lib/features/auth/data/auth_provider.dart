import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:eventease/core/services/security_service.dart';
import 'package:eventease/core/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String _userRole = '';
  String _userName = '';
  String _userEmail = '';
  String? _userId;
  Map<String, dynamic> _userData = {};
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  String _profileTableForRole(String role) {
    switch (role) {
      case 'admin':
      case 'super_admin':
        return 'admin_user';
      case 'organizer':
        return 'organizer_user';
      case 'vendor':
        return 'vendor_user';
      default:
        return 'customer_user';
    }
  }

  /// Prefer public.users.role and privileged profile tables over customer_user.
  /// The signup trigger historically dumped organizers into customer_user.
  Future<({String role, Map<String, dynamic>? record})> _loadRoleProfile(
    String userId, {
    String? metadataRole,
    String? preferredRole,
  }) async {
    String? usersRole;
    try {
      final users = await SupabaseService.select(
        table: 'users',
        filters: {'id': userId},
      );
      if (users.isNotEmpty) {
        usersRole = users.first['role']?.toString();
      }
    } catch (e) {
      debugPrint('AUTH: could not read users.role: $e');
    }

    final foundByTable = <String, Map<String, dynamic>>{};
    for (final table in ['admin_user', 'organizer_user', 'vendor_user', 'customer_user']) {
      try {
        final records = await SupabaseService.select(
          table: table,
          filters: {'id': userId},
        );
        if (records.isNotEmpty) {
          foundByTable[table] = records.first;
        }
      } catch (_) {}
    }

    final hinted = preferredRole ?? metadataRole;
    String role;
    if (foundByTable.containsKey('admin_user') ||
        usersRole == 'admin' ||
        usersRole == 'super_admin') {
      role = usersRole == 'super_admin' ? 'super_admin' : 'admin';
    } else if (foundByTable.containsKey('organizer_user') ||
        usersRole == 'organizer' ||
        hinted == 'organizer') {
      role = 'organizer';
    } else if (foundByTable.containsKey('vendor_user') ||
        usersRole == 'vendor' ||
        hinted == 'vendor') {
      role = 'vendor';
    } else if (usersRole != null && usersRole.isNotEmpty) {
      role = usersRole;
    } else if (hinted != null && hinted.isNotEmpty) {
      role = hinted;
    } else {
      role = 'customer';
    }

    final table = _profileTableForRole(role);
    final record = foundByTable[table] ??
        foundByTable['admin_user'] ??
        foundByTable['organizer_user'] ??
        foundByTable['vendor_user'] ??
        foundByTable['customer_user'];

    return (role: role, record: record);
  }

  // Store new users created during sign-up
  static final Map<String, Map<String, dynamic>> _newUsers = {};
  
  // Helper to check for persisted role without consuming it (for debug only)
  Future<bool> _hasPersistedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('social_login_role');
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final session = SupabaseService.client.auth.currentSession;
    final user = SupabaseService.client.auth.currentUser;

    if (session != null && user != null) {
      print('AUTH: Found existing session for ${user.email}');
      await _handleSocialSignInUser(user);
      // Track session on app launch
      SecurityService.recordCurrentSession();
    }

    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        print('AUTH: Auth state changed to signedIn');
        _handleSocialSignInUser(session.user);
      } else if (event == AuthChangeEvent.signedOut) {
        print('AUTH: Auth state changed to signedOut');
        _isAuthenticated = false;
        _userId = null;
        _userData = {};
        notifyListeners();
      }
    });

    _isInitialized = true;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String get userRole => _userRole;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get userId => _userId;
  Map<String, dynamic> get userData => _userData;


  Future<bool> signInWithPhone(String phoneNumber) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.signInWithPhone(phone: phoneNumber);
      return true;
    } catch (e) {
      print('AUTH ERROR: Phone Sign-In failed: $e');
      if (kDebugMode) {
        print('AUTH DEBUG: Phone OTP request fallback active in debug mode ($e). Test code: 123456');
        return true;
      }
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailOtp(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.signInWithEmailOtp(email: email);
      return true;
    } catch (e) {
      print('AUTH ERROR: Email OTP Sign-In failed: $e');
      if (kDebugMode) {
        print('AUTH DEBUG: Email OTP request fallback active in debug mode ($e). Test code: 123456');
        return true;
      }
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _syncUserProfileAndLogin({
    required String userId,
    required String identifier,
    String? preferredName,
    String? preferredRole,
    bool isPhoneAuth = false,
    bool isTestBypass = false,
  }) async {
    // If running in test bypass mode, authenticate purely in-memory
    if (isTestBypass) {
      final role = preferredRole ?? 'customer';
      final name = preferredName ?? (isPhoneAuth ? 'Test User' : identifier.split('@').first);
      final email = isPhoneAuth ? '' : identifier;
      final phone = isPhoneAuth ? identifier : '';

      _userData = {
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'isSeedUser': false,
      };
      _userRole = role;
      _userName = name;
      _userEmail = email.isNotEmpty ? email : phone;
      _userId = userId;
      _isAuthenticated = true;
      _error = null;
      notifyListeners();
      return true;
    }

    // 1. Consolidated ban check
    if (await _isUserBanned(userId)) {
      return false;
    }

    // 2. Resolve role from users + role tables (do not trust customer_user alone)
    final resolved = await _loadRoleProfile(
      userId,
      preferredRole: preferredRole,
    );
    final userRecord = resolved.record;
    final role = resolved.role;
    final name = userRecord?['name'] ?? preferredName ?? (isPhoneAuth ? 'User' : identifier.split('@').first);
    final email = isPhoneAuth ? (userRecord?['email'] ?? '') : identifier;
    final phone = isPhoneAuth ? identifier : (userRecord?['phone'] ?? '');

    // 3. If user doesn't exist yet, insert profile and public users row
    if (userRecord == null) {
      String tableName;
      switch (role) {
        case 'admin':
          tableName = 'admin_user';
          break;
        case 'vendor':
          tableName = 'vendor_user';
          break;
        case 'organizer':
          tableName = 'organizer_user';
          break;
        default:
          tableName = 'customer_user';
      }

      final profileData = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': role == 'vendor' ? 'pending' : 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      try {
        await SupabaseService.insert(table: tableName, data: profileData);
      } catch (e) {
        print('Error inserting initial profile into $tableName: $e');
      }

      try {
        await SupabaseService.insert(
          table: 'users',
          data: {
            'id': userId,
            'email': email,
            'role': role,
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        // Ignore if already present
      }
    }

    // 4. Update in-memory auth state
    _userData = {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'isSeedUser': false,
    };
    _userRole = role;
    _userName = name;
    _userEmail = email.isNotEmpty ? email : phone;
    _userId = userId;
    _isAuthenticated = true;
    _error = null;
    _startBanListener();

    // 5. Track security session & analytics
    SecurityService.recordCurrentSession();
    AnalyticsService().identify(
      userId: userId,
      email: email.isNotEmpty ? email : null,
      name: name.isNotEmpty ? name : null,
      userType: role,
    );
    AnalyticsService().trackLogin(userId: userId);

    return true;
  }

  Future<bool> verifyPhoneOtp({
    required String phone,
    required String token,
    String? name,
    String? role,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AuthResponse? authResponse;
      try {
        authResponse = await SupabaseService.verifyOtp(
          phone: phone,
          token: token,
        );
      } catch (e) {
        if (kDebugMode && token == '123456') {
          print('AUTH DEBUG: Using test OTP 123456 bypass for phone $phone');
        } else {
          rethrow;
        }
      }

      final isBypass = authResponse == null && kDebugMode && token == '123456';
      final userId = authResponse?.user?.id ?? (isBypass ? const Uuid().v4() : null);

      if (userId != null) {
        return await _syncUserProfileAndLogin(
          userId: userId,
          identifier: phone,
          preferredName: name,
          preferredRole: role,
          isPhoneAuth: true,
          isTestBypass: isBypass,
        );
      } else {
        _error = 'OTP verification failed';
        return false;
      }
    } catch (e) {
      print('AUTH ERROR: Phone OTP Verification failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
    String? name,
    String? role,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AuthResponse? authResponse;
      try {
        authResponse = await SupabaseService.verifyEmailOtp(
          email: email,
          token: token,
        );
      } catch (e) {
        if (kDebugMode && token == '123456') {
          print('AUTH DEBUG: Using test OTP 123456 bypass for email $email');
        } else {
          rethrow;
        }
      }

      final isBypass = authResponse == null && kDebugMode && token == '123456';
      final userId = authResponse?.user?.id ?? (isBypass ? const Uuid().v4() : null);

      if (userId != null) {
        return await _syncUserProfileAndLogin(
          userId: userId,
          identifier: email,
          preferredName: name,
          preferredRole: role,
          isPhoneAuth: false,
          isTestBypass: isBypass,
        );
      } else {
        _error = 'OTP verification failed';
        return false;
      }
    } catch (e) {
      print('AUTH ERROR: Email OTP Verification failed: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('AUTH: Supabase sign-in attempt for $email');
      final authResponse =
          await SupabaseService.signIn(email: email, password: password);
      if (authResponse.user != null) {
        final userId = authResponse.user!.id;

        // Consolidated ban check
        if (await _isUserBanned(userId)) {
          return false;
        }

        final userMetadata = authResponse.user!.userMetadata ?? {};
        final resolved = await _loadRoleProfile(
          userId,
          metadataRole: userMetadata['role']?.toString(),
        );
        final userRecord = resolved.record;
        final role = resolved.role;
        final name = userRecord?['name'] ?? userMetadata['name'] ?? '';
        final phone = userRecord?['phone'] ?? userMetadata['phone'] ?? '';

        _userData = {
          'name': name,
          'email': email,
          'role': role,
          'phone': phone,
          'isSeedUser': false,
        };
        _userRole = role;
        _userName = name;
        _userEmail = email;
        _userId = userId;
        _isAuthenticated = true;
        _error = null;
        _startBanListener();
        print('AUTH: Sign-in successful for $email ($userId) with role: $role');
        
        // Track session
        SecurityService.recordCurrentSession();
        
        // Identify user in analytics
        AnalyticsService().identify(
          userId: userId,
          email: email,
          name: _userName.isNotEmpty ? _userName : null,
          userType: _userRole.isNotEmpty ? _userRole : null,
        );
        AnalyticsService().trackLogin(userId: userId);
        
        return true;
      } else {
        _error = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      print('AUTH: Sign-in failed for $email: $e');
      _error = 'Invalid email or password';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle({String? role}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (kIsWeb) {
        // Save role to SharedPreferences before redirecting
        if (role != null) {
          print('DEBUG: Saving role $role to SharedPreferences before Google redirect');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('social_login_role', role);
        } else {
           // Clear any previous role if none specified
           final prefs = await SharedPreferences.getInstance();
           await prefs.remove('social_login_role');
        }

        await SupabaseService.signInWithGoogleWeb();
        return true; 
      }

      final authResponse = await SupabaseService.signInWithGoogle();
      return await _handleSocialSignInResponse(authResponse, role: role);
    } catch (e) {
      print('AUTH ERROR: Google Sign-In failed: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithFacebook({String? role}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (kIsWeb) {
         // Save role to SharedPreferences before redirecting
        if (role != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('social_login_role', role);
        } else {
           final prefs = await SharedPreferences.getInstance();
           await prefs.remove('social_login_role');
        }

        await SupabaseService.signInWithFacebookWeb();
        return true;
      }

      final authResponse = await SupabaseService.signInWithFacebook();
      return await _handleSocialSignInResponse(authResponse, role: role);
    } catch (e) {
      print('AUTH ERROR: Facebook Sign-In failed: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _handleSocialSignInResponse(AuthResponse response, {String? role}) async {
    if (response.user != null) {
      return await _handleSocialSignInUser(response.user!, role: role);
    }
    return false;
  }

  Future<bool> _handleSocialSignInUser(User user, {String? role}) async {
      print('DEBUG: _handleSocialSignInUser called with role: $role');
      final userId = user.id;
      final email = user.email ?? '';
      final name = user.userMetadata?['full_name'] ?? 'User';

      // Consolidated ban check
      if (await _isUserBanned(userId)) {
        return false;
      }

      final resolved = await _loadRoleProfile(
        userId,
        metadataRole: user.userMetadata?['role']?.toString(),
        preferredRole: role,
      );
      final userRecord = resolved.record;

      if (userRecord != null) {
        final resolvedRole = resolved.role;
        _userData = {
          'name': userRecord['name'] ?? name,
          'email': email,
          'role': resolvedRole,
          'phone': userRecord['phone'] ?? '',
          'isSeedUser': false,
        };
        _userRole = resolvedRole;
        _userName = userRecord['name'] ?? name;
        _userEmail = email;
        _userId = userId;
        
        // Debug warning if roles mismatch
        if ((role != null || await _hasPersistedRole()) && _userRole != (role ?? 'vendor')) {
           print('DEBUG WARNING: User requested role $role but found existing user with role $_userRole. Using existing role.');
        }
      } else {
        // New user from social login
        // Helper to get persisted role if null
        String effectiveRole = role ?? 'customer';
        
        if (role == null) {
           final prefs = await SharedPreferences.getInstance();
           final persistedRole = prefs.getString('social_login_role');
           print('DEBUG: Retrieved persisted role from SharedPreferences: $persistedRole');
           effectiveRole = persistedRole ?? 'customer';
           // Clear it after reading so subsequent logins don't inherit it unexpectedly
           await prefs.remove('social_login_role');
        }
        
        print('DEBUG: Creating new social user with role: $effectiveRole');
        final newUserRole = effectiveRole;
        _userData = {
          'name': name,
          'email': email,
          'role': newUserRole,
          'phone': '',
          'isSeedUser': false,
        };
        _userRole = newUserRole;
        _userName = name;
        _userEmail = email;
        _userId = userId;

        // 1. Update/Ensure 'users' table
        try {
          // Check if user exists in 'users' table (Trigger might have created it)
          final existingPublicUser = await SupabaseService.select(
            table: 'users',
            filters: {'id': userId},
          );

          if (existingPublicUser.isNotEmpty) {
            print('DEBUG: User already exists in public.users. Updating role to $newUserRole');
            await SupabaseService.update(
              table: 'users',
              data: {
                'role': newUserRole,
                'updated_at': DateTime.now().toIso8601String(),
              },
              column: 'id',
              value: userId,
            );
          } else {
            print('DEBUG: User not found in public.users. Inserting...');
            await SupabaseService.insert(
              table: 'users',
              data: {
                'id': userId,
                'email': email,
                'role': newUserRole,
                'status': 'active',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            );
          }
        } catch (e) {
             print('DEBUG ERROR: Failed to update/insert public.users: $e');
             // Proceeding because sometimes RLS is read-only but Triggers work
        }
          
        // 2. Insert into the matching role profile table
        final profileTable = _profileTableForRole(newUserRole);
        final profileData = {
              'id': userId,
              'name': name,
              'email': email,
              'role': newUserRole,
              'status': newUserRole == 'vendor' ? 'pending' : 'active', // Vendors might need approval
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await SupabaseService.insert(
            table: profileTable,
            data: profileData,
          );
        } catch (e) {
          print('Error creating social user profile in $profileTable: $e');
        }
      }

      _isAuthenticated = true;
      _error = null;
      _startBanListener();
      
      // Track session
      SecurityService.recordCurrentSession();
      
      // Identify user in PostHog analytics
      if (_userId != null) {
        AnalyticsService().identify(
          userId: _userId!,
          email: _userEmail.isNotEmpty ? _userEmail : null,
          name: _userName.isNotEmpty ? _userName : null,
          userType: _userRole.isNotEmpty ? _userRole : null,
        );
      }
      
      return true;
  }

  Future<bool> signUpWithEmailAndPassword(
      String email, String password, String name, String userType,
      {String? phone, String? countryCode}) async {
    print('Starting sign up process for email: $email, userType: $userType');
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Let Supabase handle duplicate email checking


      // Use Supabase authentication for both customers and vendors
      try {
        print('Attempting Supabase sign up...');
        // Sign up with Supabase Auth, passing user metadata for the trigger
        AuthResponse authResponse;
        try {
          authResponse = await SupabaseService.signUp(
            email: email,
            password: password,
            data: {
              'name': name,
              'role': userType,
              'phone': phone ?? '',
              'country_code': countryCode ?? 'MY',
            },
          );
        } catch (signUpError) {
          print('Sign up error details: $signUpError');
          // Check if it's a specific error we can handle
          final errorString = signUpError.toString().toLowerCase();
          if (errorString.contains('user already registered') ||
              errorString.contains('already registered')) {
            _error = 'An account with this email already exists.';
            return false;
          } else if (errorString.contains('invalid email')) {
            _error = 'Please enter a valid email address.';
            return false;
          } else if (errorString.contains('password')) {
            _error = 'Password does not meet requirements.';
            return false;
          } else {
            _error = 'Failed to create account: ${signUpError.toString()}';
            print('Full signup error: $signUpError');
            return false;
          }
        }

        // Check if user was created (even if email confirmation is required)
        if (authResponse.user == null && authResponse.session == null) {
          _error = 'Failed to create account. Please try again.';
          print('Supabase auth response user and session are null');
          return false;
        }

        // If email confirmation is required, user might be null but we should still proceed
        final userId = authResponse.user?.id;
        if (userId == null) {
          _error =
              'Account creation initiated. Please check your email to confirm your account.';
          print('User created but requires email confirmation');
          // Still return true - the account is being created
          return true;
        }

        print('Supabase auth successful, user ID: $userId');

        // Step 1: Ensure users table is populated
        print('Step 1: Updating users table...');
        try {
          await SupabaseService.insert(
            table: 'users',
            data: {
              'id': userId,
              'email': email,
              'role': userType,
              'status': 'active',
              'country_code': countryCode ?? 'MY',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
          print('✓ users table INSERT successful');
        } catch (usersInsertError) {
          print('users table INSERT failed (may already exist): $usersInsertError');
          // Try update if insert fails (user already exists)
          try {
            await SupabaseService.update(
              table: 'users',
              data: {
                'role': userType,
                'status': 'active',
                'updated_at': DateTime.now().toIso8601String(),
              },
              column: 'id',
              value: userId,
            );
            print('✓ users table UPDATE successful');
          } catch (usersUpdateError) {
            print('Warning: Could not insert or update users table: $usersUpdateError');
          }
        }

        // Step 2: Determine role-specific table and update it
        String tableName;
        switch (userType) {
          case 'admin':
            tableName = 'admin_user';
            break;
          case 'vendor':
            tableName = 'vendor_user';
            break;
          case 'organizer':
            tableName = 'organizer_user';
            break;
          case 'customer':
            tableName = 'customer_user';
            break;
          default:
            tableName = 'customer_user'; // Default to customer
        }

        print('Step 2: Updating $tableName table...');
        final roleSpecificData = {
          'id': userId,
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'role': userType,
          'country_code': countryCode ?? 'MY',
          'status': userType == 'vendor' ? 'pending' : 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        try {
          await SupabaseService.insert(
            table: tableName,
            data: roleSpecificData,
          );
          print('✓ $tableName INSERT successful');
        } catch (roleInsertError) {
          print('$tableName INSERT failed (may already exist): $roleInsertError');
          // Try update if insert fails
          try {
            await SupabaseService.update(
              table: tableName,
              data: {
                'name': name,
                'email': email,
                'phone': phone ?? '',
                'role': userType,
                'updated_at': DateTime.now().toIso8601String(),
              },
              column: 'id',
              value: userId,
            );
            print('✓ $tableName UPDATE successful');
          } catch (roleUpdateError) {
            print('Warning: Could not insert or update $tableName: $roleUpdateError');
          }
        }

        // Set current user data
        _userData = {
          'name': name,
          'email': email,
          'role': userType,
          'phone': phone ?? '',
          'createdAt': DateTime.now(),
          'isSeedUser': false,
        };
        _userRole = userType;
        _userName = name;
        _userEmail = email;
        _userId = userId;
        _isAuthenticated = true;
        _error = null;
        _startBanListener();
        print('Sign up process completed successfully');

        await ReferralProvider.applyPendingReferralOnSignup(userId);
        
        // Track session
        SecurityService.recordCurrentSession();
        
        return true;
      } catch (e) {
        // If database insertion fails, we should ideally clean up the auth user
        // For now, just return error
        print('Sign up failed with error: $e');
        _error = 'Failed to create account: ${e.toString()}';
        return false;
      }
    } catch (e) {
      print('Unexpected error in sign up: $e');
      _error = 'An error occurred. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Supabase for all authenticated users
      await SupabaseService.signOut();
      _clearUserData();
    } catch (e) {
      _error = 'Failed to sign out';
      notifyListeners();
    }
  }

  void _clearUserData() {
    _stopBanListener();
    _userRole = '';
    _userName = '';
    _userEmail = '';
    _userId = null;
    _userData = {};
    _isAuthenticated = false;
    _error = null;
    AnalyticsService().reset();
    notifyListeners();
  }

  // Check if user is admin
  bool get isAdmin => _userRole == 'admin' || _userRole == 'super_admin';

  // Check if user is super admin
  bool get isSuperAdmin => _userRole == 'super_admin';

  // Check if user is vendor
  bool get isVendor => _userRole == 'vendor';

  // Check if user is organizer
  bool get isOrganizer => _userRole == 'organizer';

  // Check if user is customer
  bool get isCustomer => _userRole == 'customer';

  // Get appropriate route based on user role
  String getRouteForUser() {
    if (isAdmin) {
      return '/admin';
    } else if (isVendor) {
      return '/vendor';
    } else if (isOrganizer) {
      return '/organizer/expo-command-dashboard';
    } else if (isCustomer) {
      return '/customer';
    } else {
      return '/login';
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.client.auth.resetPasswordForEmail(email);
      _error = null;
      return true;
    } catch (e) {
      _error = 'Failed to send reset email: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String otp) async {
    // When OTP verification is invoked, it should be validated with Supabase Auth or phone auth provider
    return otp.isNotEmpty;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Legacy test helpers - now return empty maps since data is Supabase-only
  Map<String, Map<String, String>> getAllUsers() {
    return const {};
  }

  Map<String, Map<String, String>> getUsersByRole(String role) {
    return const {};
  }

  RealtimeChannel? _banChannel;

  void _startBanListener() {
    if (_userId == null || _banChannel != null) return;

    print('AUTH: Starting real-time ban listener for user: $_userId');
    _banChannel = SupabaseService.client
        .channel('public:banned_users:$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'banned_users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (PostgresChangePayload payload) {
            print('AUTH: Real-time ban update received: ${payload.eventType}');
            final data = payload.newRecord;
            if (data['is_active'] == true) {
              print('AUTH: !!! User has been banned in real-time. Forcing logout.');
              _error = 'Your account has been banned: ${data['reason'] ?? 'Violated platform policies'}';
              signOut();
            }
          },
        )
        .subscribe();
  }

  void _stopBanListener() {
    if (_banChannel != null) {
      print('AUTH: Stopping real-time ban listener');
      SupabaseService.client.removeChannel(_banChannel!);
      _banChannel = null;
    }
  }

  /// Helper to check if a user is banned across all possible records.
  Future<bool> _isUserBanned(String userId) async {
    print('AUTH: Checking ban status for user: $userId');
    
    // 1. Check banned_users table for an active ban record
    try {
      print('AUTH: Querying banned_users table for active record...');
      final banRecord = await SupabaseService.select(
        table: 'banned_users',
        filters: {'user_id': userId, 'is_active': true},
      );
      
      if (banRecord.isNotEmpty) {
        final reason = banRecord.first['reason'] ?? 'Violated platform policies';
        _error = 'Your account is banned: $reason';
        print('AUTH: !!! ACTIVE BAN FOUND in banned_users table for $userId. Reason: $reason');
        return true;
      } else {
        print('AUTH: No active record found in banned_users table.');
      }
    } catch (e) {
      print('AUTH ERROR: Error checking banned_users table: $e');
    }

    // 2. Check status in user tables as a fallback/sync check
    print('AUTH: Checking status column in user tables as fallback...');
    final tablesToCheck = ['admin_user', 'vendor_user', 'customer_user', 'users'];
    for (final tableName in tablesToCheck) {
      try {
        print('AUTH: Checking table $tableName for user $userId status...');
        final records = await SupabaseService.select(
          table: tableName,
          filters: {'id': userId},
        );

        if (records.isNotEmpty) {
          final status = records.first['status']?.toString().toLowerCase();
          print('AUTH: Found user in $tableName. Status: $status');
          if (status == 'banned' || status == 'suspended') {
            _error = 'Your account has been $status. Please contact support.';
            print('AUTH: !!! USER MARKED AS $status in $tableName table.');
            return true;
          }
        }
      } catch (e) {
        print('AUTH ERROR: Error checking table $tableName: $e');
      }
    }

    print('AUTH: Final result - User is NOT banned.');
    return false;
  }
}
