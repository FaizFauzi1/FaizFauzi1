import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://lqvsavyfbnarwsunbfzm.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_tAUtEvgarcJEtlo50Bdtxg_m9SVzy_5';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Auth methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<void> signUpWithPhone({
    required String phone,
    Map<String, dynamic>? data,
  }) async {
    await client.auth.signInWithOtp(
      phone: phone,
      data: data,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signInWithPhone({
    required String phone,
  }) async {
    await client.auth.signInWithOtp(
      phone: phone,
    );
  }

  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  static Future<void> signInWithEmailOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {
    await client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
    );
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    // Supabase passwordless email OTP can be typed as magiclink, email, or signup
    // depending on whether the user is existing or newly created.
    try {
      return await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.magiclink,
      );
    } catch (e) {
      try {
        return await client.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.email,
        );
      } catch (e2) {
        return await client.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.signup,
        );
      }
    }
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<AuthResponse> signInWithGoogle() async {
    try {
      // 1. Initialize Google Sign In
      // For web, you MUST provide a clientId. For Android/iOS, it's optional if configured in native files.
      const webClientId = '576075181196-ldt55dl4m7dh52ce27hmgpv5k0bids5s.apps.googleusercontent.com';
      
      final googleSignIn = GoogleSignIn(
        clientId: webClientId,
        scopes: [
          'email',
          'openid',
          'profile',
        ],
      );

      print('DEBUG: Starting Google Sign-In native flow...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('DEBUG: Google Sign-In cancelled by user');
        throw 'Google Sign-In was cancelled';
      }

      print('DEBUG: Google User retrieved: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        print('DEBUG: Error - No ID Token found');
        throw 'No ID Token found';
      }

      print('DEBUG: Attempting Supabase authentication with ID Token...');
      return await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      print('DEBUG ERROR: signInWithGoogle failed: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signInWithFacebook() async {
    try {
      print('DEBUG: Starting Facebook Login native flow...');
      // 1. Trigger the sign-in flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        print('DEBUG: Facebook Login successful, getting access token...');
        // 2. Get the access token
        final AccessToken accessToken = result.accessToken!;
        
        print('DEBUG: Attempting Supabase authentication with Facebook token...');
        // 3. Authenticate with Supabase
        return await client.auth.signInWithIdToken(
          provider: OAuthProvider.facebook,
          idToken: accessToken.tokenString, // For Facebook, we use the token string
        );
      } else {
        print('DEBUG: Facebook Login failed or cancelled: ${result.status}, ${result.message}');
        throw 'Facebook Sign-In failed: ${result.message}';
      }
    } catch (e) {
      print('DEBUG ERROR: signInWithFacebook failed: $e');
      rethrow;
    }
  }

  static Future<void> signInWithGoogleWeb() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://signin-callback/',
    );
  }

  static Future<void> signInWithFacebookWeb() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://signin-callback/',
    );
  }

  static User? get currentUser => client.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Database methods
  static Future<List<Map<String, dynamic>>> select({
    required String table,
    String? columns,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
  }) async {
    dynamic query = client.from(table).select(columns ?? '*');

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    final response = await query;
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final response = await client.from(table).insert(data).select();
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> update({
    required String table,
    required Map<String, dynamic> data,
    String? column,
    dynamic value,
  }) async {
    var query = client.from(table).update(data);

    if (column != null && value != null) {
      query = query.eq(column, value);
    }

    final response = await query.select();
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> delete({
    required String table,
    String? column,
    dynamic value,
  }) async {
    var query = client.from(table).delete();

    if (column != null && value != null) {
      query = query.eq(column, value);
    }

    final response = await query.select();
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Storage methods
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    final response = await client.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: contentType,
          ),
        );
    return response;
  }

  static Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  }) async {
    return await client.storage.from(bucket).download(path);
  }

  static Future<List<FileObject>> listFiles({
    required String bucket,
    String? path,
  }) async {
    return await client.storage.from(bucket).list(path: path);
  }

  static Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await client.storage.from(bucket).remove([path]);
  }

  static String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
