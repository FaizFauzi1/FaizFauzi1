import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_onboarding_screen.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/customer/presentation/views/home/home_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:eventease/features/auth/presentation/otp_verification_screen.dart';
import 'package:eventease/core/providers/country_provider.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/shared/widgets/design_system/shimmer_widgets.dart';


class SignUpScreen extends StatefulWidget {
  final String? returnUrl;
  final String? referralCode;
  final String? initialRole;

  const SignUpScreen({super.key, this.returnUrl, this.referralCode, this.initialRole});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'customer'; // Default role
  bool _agreeToTerms = false;
  PhoneNumber? _phoneNumber; // Store phone number with country code
  String _signUpMethod = 'password'; // 'password', 'phone_otp', 'email_otp'
  bool get _isPhoneOtp => _signUpMethod == 'phone_otp';
  bool get _isEmailOtp => _signUpMethod == 'email_otp';
  bool get _isPassword => _signUpMethod == 'password';
  bool get _phoneOnly => _isPhoneOtp;
  String _selectedCountry = 'MY';

  String _normalizeFromPhoneNumber(PhoneNumber phone) {
    // Build E.164: +<countryCode><nationalNumber>
    final rawCountry = phone.countryCode.replaceAll('+', '');
    var national = phone.number.replaceAll(RegExp(r'[^0-9]'), '');
    // If the national part already contains the country code (user typed full +60...), remove duplication
    if (rawCountry.isNotEmpty && national.startsWith(rawCountry)) {
      national = national.substring(rawCountry.length);
    }

    // Remove leading zero from national number if present
    if (national.startsWith('0')) {
      national = national.substring(1);
    }

    if (rawCountry.isEmpty || national.isEmpty) return '';

    final result = '+$rawCountry$national';
    // Debug print to help trace issues
    print('normalizeFromPhoneNumber -> country: $rawCountry, national: $national, result: $result');
    return result;
  }

  // Return country and national parts as digits only
  Map<String, String> _phoneComponents(PhoneNumber phone) {
    final rawCountry = phone.countryCode.replaceAll('+', '');
    var national = phone.number.replaceAll(RegExp(r'[^0-9]'), '');

    // If national part contains country prefix, remove it
    if (rawCountry.isNotEmpty && national.startsWith(rawCountry)) {
      national = national.substring(rawCountry.length);
    }

    // Remove leading zero
    if (national.startsWith('0')) national = national.substring(1);

    return {'country': rawCountry, 'national': national};
  }

  @override
  void initState() {
    super.initState();
    // Pre-select role if provided
    if (widget.initialRole != null) {
      _selectedRole = widget.initialRole!;
    }
    final code = widget.referralCode ?? _extractReferralCode(widget.returnUrl);
    if (code != null && code.isNotEmpty) {
      _referralCodeController.text = code;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ReferralProvider>().setPendingReferralCode(code);
        }
      });
    }
  }

  String? _extractReferralCode(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url.contains('://') ? url : 'https://eventease.my$url');
    return uri?.queryParameters['ref'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the Terms of Service and Privacy Policy to register.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If phone OTP sign up is selected
    if (_isPhoneOtp) {
      if (_phoneNumber == null || _phoneNumber!.completeNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number'),
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

        // Validate phone components
        final comps = _phoneComponents(_phoneNumber!);
        final rawCountry = comps['country']!;
        final national = comps['national']!;

        // Country-specific validation: Malaysia expects country(2) + national digits = 11
        if (rawCountry == '60') {
          final totalDigits = rawCountry.length + national.length;
          if (totalDigits != 11) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid Malaysian number. Enter local number like 01423456789'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else {
          if (national.length < 6 || national.length > 12) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid phone number length'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        final normalized = _normalizeFromPhoneNumber(_phoneNumber!);

        final sent = await authProvider.signInWithPhone(normalized);

        setState(() {
          _isLoading = false;
        });

        if (sent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: normalized,
                name: _nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim(),
                role: _selectedRole,
                isLogin: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // If email OTP sign up is selected
    if (_isEmailOtp) {
      final email = _emailController.text.trim();
      if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
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
        final sent = await authProvider.signInWithEmailOtp(email);

        setState(() {
          _isLoading = false;
        });

        if (sent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: email,
                name: _nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim(),
                role: _selectedRole,
                isLogin: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Additional phone number validation
    if (_phoneNumber == null || _phoneNumber!.number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
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

      // Validate phone before email signup
      final comps = _phoneComponents(_phoneNumber!);
      final rawCountry = comps['country']!;
      final national = comps['national']!;

      if (rawCountry == '60') {
        final totalDigits = rawCountry.length + national.length;
        if (totalDigits != 11) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Malaysian number. Enter local number like 01423456789'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        if (national.length < 6 || national.length > 12) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid phone number length'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Email sign up with phone number
      final normalizedPhone = _normalizeFromPhoneNumber(_phoneNumber!);
      // Debug
      print('Signing up email user with phone: $normalizedPhone');

      bool success = await authProvider.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
        phone: normalizedPhone,
        countryCode: _selectedCountry,
      );

      if (success) {
        if (!mounted) return;
        final countryProvider = Provider.of<CountryProvider>(context, listen: false);
        await countryProvider.setCountry(_selectedCountry);
        if (authProvider.userId != null) {
          await countryProvider.syncToProfile(
            userId: authProvider.userId!,
            role: _selectedRole,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Navigate based on role
        if (_selectedRole == 'vendor') {
          // Navigate to vendor onboarding to complete profile setup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor account created successfully! Please complete your profile setup.'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VendorOnboardingScreen(
                initialEmail: _emailController.text.trim(),
                initialPhone: _normalizeFromPhoneNumber(_phoneNumber!),
                initialBusinessName: _nameController.text.trim(),
              ),
            ),
          );
        } else {
          // For customers, navigate to home screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to returnUrl if provided, otherwise go to home
          if (widget.returnUrl != null && widget.returnUrl!.isNotEmpty) {
            Navigator.pushReplacementNamed(context, widget.returnUrl!);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else {
        // Show error from auth provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 1024;
            final formContent = _buildFormContent(context);

            if (isWideScreen) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Image.asset('assets/branding/eventease_logo.png'),
                            ),
                            const SizedBox(height: 40),
                            const Text(
                              "Join EventEase",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Create your account and start planning.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: formContent,
                      ),
                    ),
                  ),
                ],
              );
            }
            return formContent;
          },
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Welcome Text
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join EventEase and start planning your perfect event',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CountrySelector(
                  value: _selectedCountry,
                  onChanged: (code) => setState(() => _selectedCountry = code),
                ),

                const SizedBox(height: 16),

                // Verification Method Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Method',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            avatar: const Icon(Icons.lock_outline, size: 16),
                            label: const Text('Password'),
                            selected: _signUpMethod == 'password',
                            onSelected: (selected) {
                              if (selected) setState(() => _signUpMethod = 'password');
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: _signUpMethod == 'password' ? AppTheme.primaryColor : Colors.black87,
                              fontWeight: _signUpMethod == 'password' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            avatar: const Icon(Icons.phone_android, size: 16),
                            label: const Text('Phone OTP'),
                            selected: _signUpMethod == 'phone_otp',
                            onSelected: (selected) {
                              if (selected) setState(() => _signUpMethod = 'phone_otp');
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: _signUpMethod == 'phone_otp' ? AppTheme.primaryColor : Colors.black87,
                              fontWeight: _signUpMethod == 'phone_otp' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            avatar: const Icon(Icons.email_outlined, size: 16),
                            label: const Text('Email OTP'),
                            selected: _signUpMethod == 'email_otp',
                            onSelected: (selected) {
                              if (selected) setState(() => _signUpMethod = 'email_otp');
                            },
                            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: _signUpMethod == 'email_otp' ? AppTheme.primaryColor : Colors.black87,
                              fontWeight: _signUpMethod == 'email_otp' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Email Field (hidden when using phone-only)
                if (!_isPhoneOtp)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                if (!_isPhoneOtp && !_isEmailOtp)
                  const SizedBox(height: 16),

                // Phone Field (hidden when using email-only OTP)
                if (!_isEmailOtp)
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    initialCountryCode: 'MY', // Default to Malaysia
                    autovalidateMode: AutovalidateMode.disabled,
                    onChanged: (phone) {
                      setState(() {
                        _phoneNumber = phone;
                      });
                    },
                  ),

                if (_isPassword) ...[
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          if (_passwordController.text.isNotEmpty)
                            _buildPasswordStrengthIndicator(),
                        ],
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 16),

                TextFormField(
                  controller: _referralCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Referral Code (optional)',
                    prefixIcon: Icon(Icons.card_giftcard_outlined),
                    hintText: 'Enter a friend\'s code',
                  ),
                  onChanged: (value) {
                    context
                        .read<ReferralProvider>()
                        .setPendingReferralCode(value);
                  },
                ),

                const SizedBox(height: 24),

                // Role Selection
                const Text(
                  'I am a:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Customer'),
                        subtitle: const Text('Planning an event'),
                        value: 'customer',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Vendor'),
                        subtitle: const Text('Providing services'),
                        value: 'vendor',
                        groupValue: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Organizer Callout Card (Controlled Access)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.festival_outlined, color: AppTheme.primaryColor, size: 22),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Want to organize an event with EventEase?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Contact our team to become an Event Organizer. Organizer accounts are approved and onboarded directly by EventEase.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _showOrganizerInquiryModal,
                          icon: const Icon(Icons.mail_outline, size: 16),
                          label: const Text('Contact EventEase'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Terms and Conditions Checkbox
                CheckboxListTile(
                  value: _agreeToTerms,
                  onChanged: (val) {
                    setState(() {
                      _agreeToTerms = val ?? false;
                    });
                  },
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('I agree to the ', style: TextStyle(fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/terms-of-service'),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Text(' and ', style: TextStyle(fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryColor,
                ),

                const SizedBox(height: 24),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agreeToTerms ? AppTheme.primaryColor : Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isPhoneOtp
                              ? 'Send Phone OTP'
                              : (_isEmailOtp
                                  ? 'Send Email OTP'
                                  : 'Sign Up'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color color;
    String text;
    double width;

    switch (strength) {
      case 1:
        color = Colors.red;
        text = 'Weak';
        width = 0.2;
        break;
      case 2:
        color = Colors.orange;
        text = 'Fair';
        width = 0.4;
        break;
      case 3:
        color = Colors.yellow[700]!;
        text = 'Good';
        width = 0.6;
        break;
      case 4:
        color = Colors.lightGreen;
        text = 'Strong';
        width = 0.8;
        break;
      case 5:
        color = Colors.green;
        text = 'Very Strong';
        width = 1.0;
        break;
      default:
        color = Colors.grey;
        text = '';
        width = 0.0;
    }

    return Container(
      width: 100,
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 2,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: width,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrganizerInquiryModal() {
    final companyCtrl = TextEditingController();
    final contactCtrl = TextEditingController(text: _nameController.text.trim());
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final phoneCtrl = TextEditingController(
      text: _phoneNumber != null ? _normalizeFromPhoneNumber(_phoneNumber!) : '',
    );
    final notesCtrl = TextEditingController();
    String eventType = 'Wedding Expo';
    int booths = 30;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.festival, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Request Organizer Access',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              'Host expos, bridal fairs & vendor markets',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Organizer accounts are vetted by EventEase to maintain event excellence. Once approved, you will receive an activation invitation.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company / Organization Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: contactCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Contact Person *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Business Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: eventType,
                          decoration: const InputDecoration(
                            labelText: 'Event Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Wedding Expo', child: Text('Wedding Expo')),
                            DropdownMenuItem(value: 'Bridal Fair', child: Text('Bridal Fair')),
                            DropdownMenuItem(value: 'Festival / Marketplace', child: Text('Festival / Marketplace')),
                            DropdownMenuItem(value: 'Corporate / Other', child: Text('Corporate / Other')),
                          ],
                          onChanged: (v) => setModalState(() => eventType = v ?? 'Wedding Expo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: booths.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Est. Booths',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => booths = int.tryParse(v) ?? 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Event Details / Target Venue / Dates',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (companyCtrl.text.trim().isEmpty ||
                                contactCtrl.text.trim().isEmpty ||
                                emailCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            try {
                              await SupabaseService.insert(
                                table: 'organizer_inquiries',
                                data: {
                                  'company_name': companyCtrl.text.trim(),
                                  'contact_person': contactCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'event_type': eventType,
                                  'estimated_booths': booths,
                                  'notes': notesCtrl.text.trim(),
                                  'status': 'pending',
                                },
                              );
                            } catch (e) {
                              debugPrint('Submitting inquiry to Supabase fallback: $e');
                            }

                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Inquiry submitted! Our partnership team will contact you with your activation invitation.',
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(isSubmitting ? 'Submitting...' : 'Submit Organizer Request'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
