import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:eventease/features/customer/presentation/views/home/home_screen.dart' ;
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/organizer/presentation/views/dashboard/expo_command_dashboard_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_onboarding_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/shared/views/maintenance_screen.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';
import 'package:eventease/core/services/deep_link_service.dart';
import 'package:eventease/core/constants/constant/image_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasHandledNavigation = false;
  AuthProvider? _authProvider;
  bool _authListenerAdded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Fast check: check auth and navigate as soon as brief entrance completes
    Future.delayed(const Duration(milliseconds: 650), () {
      _checkAuthAndNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider ??= Provider.of<AuthProvider>(context, listen: false);
    if (!_authListenerAdded && !_authProvider!.isInitialized) {
      _authProvider!.addListener(_onAuthChanged);
      _authListenerAdded = true;
    }
  }

  @override
  void dispose() {
    if (_authListenerAdded) {
      _authProvider?.removeListener(_onAuthChanged);
      _authListenerAdded = false;
    }
    _animationController.dispose();
    super.dispose();
  }
  
  void _onAuthChanged() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isInitialized) {
      _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_hasHandledNavigation) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // If auth not initialized yet, wait for listener
    if (!authProvider.isInitialized) {
      return;
    }

    // Check again after check
    if (_hasHandledNavigation) return;

    // Remove listener once we are checking navigation
    if (_authListenerAdded) {
      authProvider.removeListener(_onAuthChanged);
      _authListenerAdded = false;
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Check if maintenance mode is enabled for non-admin users
    if (adminProvider.isMaintenanceMode && !authProvider.isAdmin) {
      _hasHandledNavigation = true;
      _navigateToMaintenance();
      return;
    }

    // Check if there is a pending deep link being handled immediately
    if (DeepLinkService().hasPendingDeepLink) {
      debugPrint('SPLASH: Pending deep link detected, proceeding to content');
      _hasHandledNavigation = true;
      DeepLinkService().consumePendingUri();
      return; 
    }

    _hasHandledNavigation = true;
    if (authProvider.isAuthenticated) {
      // User is logged in, route based on role
      _navigateBasedOnRole(authProvider);
    } else {
      // User is not logged in, check maintenance mode for login screen
      if (adminProvider.isMaintenanceMode) {
        // Show maintenance screen even for unauthenticated users
        _navigateToMaintenance();
      } else {
        // --- ADD THIS BLOCK ---
        // Check for cached invitation code
        final prefs = await SharedPreferences.getInstance();
        final cachedCode = prefs.getString('last_joined_invitation_code');
        
        if (cachedCode != null) {
          // Attempt auto-join
          try {
            final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
            final eventProvider = Provider.of<EventProvider>(context, listen: false);
            
            final invitation = await invitationProvider.getInvitationByCode(cachedCode);
            if (invitation != null) {
              final event = await eventProvider.fetchEventById(invitation.eventId);
              if (event != null) {
                // Navigate to dashboard
                Navigator.pushReplacementNamed(
                  context,
                  '/guest-dashboard',
                  arguments: {'event': event, 'invitation': invitation},
                );
                return;
              }
            }
          } catch (e) {
            debugPrint('Error auto-joining event: $e');
          }
        }
        // --- END ADDED BLOCK ---

        // Allow guest access to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  void _navigateBasedOnRole(AuthProvider authProvider) async {
    Widget targetScreen;

    if (authProvider.isAdmin) {
      targetScreen = const AdminDashboardScreen();
    } else if (authProvider.isVendor) {
      // Check if vendor profile is complete before navigating to dashboard
      final vendorProfileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
      await vendorProfileProvider.loadVendorProfile();

      print('DEBUG: Vendor email: ${authProvider.userEmail}');
      print('DEBUG: Vendor profile exists: ${vendorProfileProvider.vendorProfile != null}');

      if (vendorProfileProvider.vendorProfile != null) {
        final profile = vendorProfileProvider.vendorProfile!;
        final completionPercentage = profile['profile_completion_percentage'] ?? 0;
        final status = profile['profile_completion_status'] ?? '';

        print('DEBUG: Profile completion percentage: $completionPercentage');
        print('DEBUG: Profile status: $status');
        print('DEBUG: Navigating to dashboard (Onboarding completed)');
        targetScreen = const VendorDashboardScreen();
      } else {
        // No profile found, redirect to onboarding
        print('DEBUG: Navigating to onboarding - no profile found');
        targetScreen = VendorOnboardingScreen(initialEmail: authProvider.userEmail);
      }
    } else if (authProvider.isOrganizer) {
      targetScreen = const ExpoCommandDashboardScreen();
    } else if (authProvider.isCustomer) {
      targetScreen = const HomeScreen();
    } else {
      // Fallback to login
      targetScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToMaintenance() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand logo (same asset as launcher / About)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Image.asset(
                        LogoImages.eventease,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tagline
                    const Text(
                      'Your Complete Event Planning Solution',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),

                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
