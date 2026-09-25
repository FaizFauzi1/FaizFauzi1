import 'package:flutter/material.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';

class ClaimBusinessScreen extends StatefulWidget {
  const ClaimBusinessScreen({super.key});

  @override
  State<ClaimBusinessScreen> createState() => _ClaimBusinessScreenState();
}

class _ClaimBusinessScreenState extends State<ClaimBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final code = _codeController.text.trim();
    debugPrint('DEBUG: Attempting to claim business with code: $code');

    try {
      final success = await context.read<VendorProfileProvider>().claimVendor(code);
      debugPrint('DEBUG: Claim result success: $success');

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text(
                'Business claimed successfully. You can now manage your vendor profile.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const VendorDashboardScreen(),
                    ),
                  );
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        final error = context.read<VendorProfileProvider>().error;
        debugPrint('DEBUG: Claim failed. Provider error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to claim business. Please check your code.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('DEBUG: Exception during claim: $e');
      debugPrint('DEBUG: StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Your Business'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.business_center,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Claim Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'If an administrator has already created a profile for your business, enter the 8-character claim code they provided to link it to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _codeController,
                label: 'Claim Code',
                keyboardType: TextInputType.text,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Code is required';
                  if (v.length != 8) return 'Code must be 8 characters long';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Claim Business',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
