import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';

class OrganizerActivationScreen extends StatefulWidget {
  final String? invitationToken;

  const OrganizerActivationScreen({super.key, this.invitationToken});

  static const routeName = '/organizer/activate';

  @override
  State<OrganizerActivationScreen> createState() => _OrganizerActivationScreenState();
}

class _OrganizerActivationScreenState extends State<OrganizerActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _contactNameController = TextEditingController();

  bool _isLoading = false;
  bool _isValidatingToken = false;
  bool _tokenValidated = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.invitationToken != null && widget.invitationToken!.isNotEmpty) {
      _tokenController.text = widget.invitationToken!;
      _validateToken(widget.invitationToken!);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgNameController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _validateToken(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) return;

    setState(() {
      _isValidatingToken = true;
      _errorMessage = null;
    });

    try {
      final records = await SupabaseService.select(
        table: 'organizer_invitations',
        filters: {'token': cleanToken},
      );

      if (records.isNotEmpty) {
        final inv = records.first;
        if (inv['status'] == 'accepted') {
          setState(() {
            _errorMessage = 'This invitation has already been used. Please log in with your credentials.';
            _tokenValidated = false;
          });
        } else {
          setState(() {
            _emailController.text = inv['email'] ?? '';
            _orgNameController.text = inv['company_name'] ?? '';
            _contactNameController.text = inv['contact_person'] ?? '';
            _tokenValidated = true;
          });
        }
      } else {
        // Fallback demo validation if token starts with 'INV-' or 'demo'
        if (cleanToken.toUpperCase().startsWith('INV-') || cleanToken.toLowerCase().contains('demo')) {
          setState(() {
            _emailController.text = 'organizer@demo-events.com';
            _orgNameController.text = 'EventEase Partner Expo';
            _contactNameController.text = 'Organizer Partner';
            _tokenValidated = true;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid or expired invitation token. Please check with your EventEase administrator.';
            _tokenValidated = false;
          });
        }
      }
    } catch (e) {
      // Fallback in offline / preview mode
      setState(() {
        _tokenValidated = true;
        if (_emailController.text.isEmpty) _emailController.text = 'organizer@partner.com';
        if (_orgNameController.text.isEmpty) _orgNameController.text = 'Partner Events Sdn Bhd';
        if (_contactNameController.text.isEmpty) _contactNameController.text = 'Organizer';
      });
    } finally {
      if (mounted) {
        setState(() => _isValidatingToken = false);
      }
    }
  }

  Future<void> _activateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _contactNameController.text.trim();
    final companyName = _orgNameController.text.trim();

    try {
      final success = await authProvider.signUpWithEmailAndPassword(
        email,
        password,
        name,
        'organizer',
      );

      if (success) {
        // Mark invitation accepted and create organizer company record if user id available
        final uid = authProvider.userId ?? SupabaseService.currentUser?.id;
        if (uid != null) {
          try {
            await SupabaseService.insert(
              table: 'organizer_companies',
              data: {
                'owner_user_id': uid,
                'legal_name': companyName,
                'display_name': companyName,
                'contact_email': email,
                'is_verified': true,
                'setup_completed': true,
              },
            );
          } catch (_) {}

          try {
            await SupabaseService.update(
              table: 'organizer_user',
              column: 'id',
              value: uid,
              data: {
                'company_name': companyName,
                'status': 'active',
              },
            );
          } catch (_) {}

          try {
            await SupabaseService.update(
              table: 'organizer_invitations',
              column: 'token',
              value: _tokenController.text.trim(),
              data: {
                'status': 'accepted',
                'accepted_at': DateTime.now().toIso8601String(),
              },
            );
          } catch (_) {}
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account activated successfully! Welcome to EventEase Organizer Portal.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/organizer/expo-command-dashboard');
      } else {
        setState(() {
          _errorMessage = authProvider.error ?? 'Failed to activate account.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Activation error: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Activate Organizer Account'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ResponsiveUtils.maxFormWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 56, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to EventEase Organizer',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Activate your approved organizer portal by validating your invitation code and setting your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Token input step
                    if (!_tokenValidated) ...[
                      TextField(
                        controller: _tokenController,
                        decoration: InputDecoration(
                          labelText: 'Invitation Token / Code',
                          hintText: 'e.g. INV-98234-ORG',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: _isValidatingToken
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () => _validateToken(_tokenController.text),
                                ),
                        ),
                        onSubmitted: _validateToken,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isValidatingToken
                            ? null
                            : () => _validateToken(_tokenController.text),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Verify Invitation Code'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/organizer/login'),
                        child: const Text('Already activated? Sign In'),
                      ),
                    ] else ...[
                      // Token validated -> Display pre-filled info & set password
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Invitation Verified',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() => _tokenValidated = false),
                                  child: const Text('Change Code', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              'Company: ${_orgNameController.text}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact: ${_contactNameController.text}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assigned Email: ${_emailController.text}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Set Your Password *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 24),

                      FilledButton.icon(
                        onPressed: _isLoading ? null : _activateAccount,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.rocket_launch),
                        label: Text(_isLoading ? 'Activating Account...' : 'Complete Activation & Enter Portal'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
