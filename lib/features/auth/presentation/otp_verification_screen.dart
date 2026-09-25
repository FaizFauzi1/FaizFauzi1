import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_onboarding_screen.dart';
import 'package:eventease/features/customer/presentation/views/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? email;
  final String name;
  final String role;
  final bool isLogin;
  final String? returnUrl;

  const OtpVerificationScreen({
    super.key,
    this.phoneNumber,
    this.email,
    this.name = 'User',
    this.role = 'customer',
    this.isLogin = false,
    this.returnUrl,
  }) : assert(phoneNumber != null || email != null, 'Either phoneNumber or email must be provided');

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 30;
  Timer? _timer;
  StreamSubscription<AuthState>? _authSubscription;

  bool get _isEmail => widget.email != null && widget.email!.isNotEmpty;
  String get _targetValue => _isEmail ? widget.email! : (widget.phoneNumber ?? '');

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _listenToAuthState();
  }

  void _listenToAuthState() {
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (widget.isLogin) {
          final targetRoute = authProvider.getRouteForUser();
          Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
        } else {
          if (widget.role == 'vendor' || authProvider.isVendor) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VendorOnboardingScreen(
                  initialBusinessName: widget.name,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendTimer > 1) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _resendTimer = 0;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = false;
      if (_isEmail) {
        success = await authProvider.verifyEmailOtp(
          email: widget.email!,
          token: code,
          name: widget.name,
          role: widget.role,
        );
      } else {
        success = await authProvider.verifyPhoneOtp(
          phone: widget.phoneNumber!,
          token: code,
          name: widget.name,
          role: widget.role,
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isEmail ? 'Email' : 'Phone'} verification successful!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.isLogin) {
          // Route based on authenticated role
          final targetRoute = authProvider.getRouteForUser();
          Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
        } else {
          // Registration flow
          if (widget.role == 'vendor' || authProvider.isVendor) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VendorOnboardingScreen(
                  initialBusinessName: widget.name,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isEmail) {
        await authProvider.signInWithEmailOtp(widget.email!);
      } else {
        await authProvider.signInWithPhone(widget.phoneNumber!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP resent to $_targetValue'),
          backgroundColor: Colors.green,
        ),
      );

      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon with adaptive visual
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEmail ? Icons.mark_email_read_outlined : Icons.phone_android,
                  size: 54,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Text(
                _isEmail ? 'Verify Your Email' : 'Verify Your Phone',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'We\'ve sent a 6-digit verification code to\n$_targetValue',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              // Test mode badge if running in debug
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.developer_mode, size: 16, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Text(
                        'Test Mode: Use code 123456',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // OTP Input using Pinput
              Pinput(
                controller: _otpController,
                length: 6,
                autofocus: true,
                defaultPinTheme: PinTheme(
                  width: 48,
                  height: 52,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 48,
                  height: 52,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                submittedPinTheme: PinTheme(
                  width: 48,
                  height: 52,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.primaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onCompleted: (pin) => _verifyOtp(),
              ),

              const SizedBox(height: 32),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Resend OTP Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Didn\'t receive the code? ',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _canResend ? _resendOtp : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Text(
                      _canResend ? 'Resend' : 'Resend in ${_resendTimer}s',
                      style: TextStyle(
                        color: _canResend ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}