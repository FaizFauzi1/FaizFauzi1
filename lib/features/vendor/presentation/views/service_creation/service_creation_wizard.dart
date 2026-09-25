import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'service_creation_state.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'step_1_basic_info.dart';
import 'step_2_event_types.dart';
import 'step_3_pricing_model.dart';
import 'step_4_event_combinations.dart';
import 'step_5_duration_days.dart';
import 'step_6_addons.dart';
import 'step_7_capacity.dart';
import 'step_8_prep_timeline.dart';
import 'step_9_guarantee.dart';
import 'step_10_logistics_delivery.dart';
import 'step_11_bulk_pricing.dart';
import 'step_12_variations.dart';

class ServiceCreationWizard extends StatelessWidget {
  static const String routeName = '/service-creation-wizard';

  final String vendorId;
  final VendorService? existingService;

  const ServiceCreationWizard({
    super.key, 
    required this.vendorId, 
    this.existingService
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceCreationState(
        vendorId: vendorId,
        existingService: existingService,
      ),
      child: const _ServiceCreationWizardContent(),
    );
  }
}

class _ServiceCreationWizardContent extends StatelessWidget {
  const _ServiceCreationWizardContent();

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Service (${state.currentStep + 1}/${state.totalSteps})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (state.currentStep + 1) / state.totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildStepContent(state.currentStep),
            ),
            _buildBottomBar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return const Step2EventTypes();
      case 1:
        return const Step1BasicInfo();
      case 2:
        return const Step3PricingModel();
      case 3:
        return const Step4EventCombinations();
      case 4:
        return const Step5DurationDays();
      case 5:
        return const Step6AddOns();
      case 6:
        return const Step7Capacity();
      case 7:
        return const Step8PrepTimeline();
      case 8:
        return const Step9Guarantee();
      case 9:
        return const Step10LogisticsDelivery();
      case 10:
        return const Step11BulkPricing();
      case 11:
        return const Step12Variations();
      default:
        return const Center(child: Text('Unknown Step'));
    }
  }

  Widget _buildBottomBar(BuildContext context, ServiceCreationState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.currentStep > 0)
            OutlinedButton(
              onPressed: state.previousStep,
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(), // Placeholder for layout
          
          ElevatedButton(
            onPressed: state.isLoading 
              ? null 
              : () async {
                  if (state.currentStep < state.totalSteps - 1) {
                    state.nextStep();
                  } else {
                    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                    final success = await state.submit(context, vendorProvider);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service published successfully!')),
                      );
                    }
                  }
                },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: state.isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(state.currentStep < state.totalSteps - 1 ? 'Next' : 'Publish Service'),
          ),
        ],
      ),
    );
  }
}
