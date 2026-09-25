import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/auth/presentation/otp_verification_screen.dart';

class OrganizerLoginScreen extends StatefulWidget {
  const OrganizerLoginScreen({super.key});

  static const routeName = '/organizer/login';

  @override
  State<OrganizerLoginScreen> createState() => _OrganizerLoginScreenState();
}

class _OrganizerLoginScreenState extends State<OrganizerLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithEmailAndPassword(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      if (!auth.isOrganizer) {
        await auth.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied: Only authorized organizers can sign in to the Organizer Portal.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
      Navigator.pushReplacementNamed(context, '/organizer/expo-command-dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ResponsiveUtils.maxFormWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.festival, size: 56, color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Wedding Event Organizer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Expo · Bridal fair · AP Event',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Organizer email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/organizer/forgot-password'),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/organizer/activate'),
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: const Text('Activate with Invitation Code'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/organizer/staff-login'),
                    child: const Text('Staff login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrganizerStaffLoginScreen extends StatefulWidget {
  const OrganizerStaffLoginScreen({super.key});

  static const routeName = '/organizer/staff-login';

  @override
  State<OrganizerStaffLoginScreen> createState() => _OrganizerStaffLoginScreenState();
}

class _OrganizerStaffLoginScreenState extends State<OrganizerStaffLoginScreen> {
  String _role = 'registration';
  final _staffId = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _staffId.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Login'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ResponsiveUtils.maxFormWidth),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Role-based access for expo day operations'),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'registration', child: Text('Registration team')),
                  DropdownMenuItem(value: 'booth_support', child: Text('Booth support')),
                  DropdownMenuItem(value: 'crowd_control', child: Text('Crowd control')),
                  DropdownMenuItem(value: 'lead_capture', child: Text('Lead capture')),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _staffId,
                decoration: const InputDecoration(labelText: 'Staff ID', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pin,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'PIN', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationScreen(
                        phoneNumber: _staffId.text.isEmpty ? '+60123456789' : _staffId.text,
                        name: 'Staff',
                        role: _role,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Continue with OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrganizerForgotPasswordScreen extends StatefulWidget {
  const OrganizerForgotPasswordScreen({super.key});

  static const routeName = '/organizer/forgot-password';

  @override
  State<OrganizerForgotPasswordScreen> createState() => _OrganizerForgotPasswordScreenState();
}

class _OrganizerForgotPasswordScreenState extends State<OrganizerForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ResponsiveUtils.maxFormWidth),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter your organizer account email to receive a reset link.'),
                const SizedBox(height: 20),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset link sent (preview)')),
                    );
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Send reset link'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
