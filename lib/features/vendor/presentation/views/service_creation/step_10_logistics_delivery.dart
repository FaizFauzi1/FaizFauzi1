import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/views/service_creation/service_creation_state.dart';
import 'package:eventease/shared/models/services/service_logistics.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/app_theme.dart';

class Step10LogisticsDelivery extends StatefulWidget {
  const Step10LogisticsDelivery({super.key});

  @override
  State<Step10LogisticsDelivery> createState() => _Step10LogisticsDeliveryState();
}

class _Step10LogisticsDeliveryState extends State<Step10LogisticsDelivery> {
  late TextEditingController _deliveryFeeController;
  late TextEditingController _thresholdController;
  late TextEditingController _daysController;
  late TextEditingController _addressController;
  late TextEditingController _hoursController;
  late TextEditingController _depositController;
  late TextEditingController _waiverPctController;
  late TextEditingController _returnConditionController;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<ServiceCreationState>(context, listen: false);
    final l = state.productLogistics;
    
    _deliveryFeeController = TextEditingController(text: l.deliveryFee.toString());
    _thresholdController = TextEditingController(text: l.freeDeliveryThreshold.toString());
    _daysController = TextEditingController(text: l.estimatedDays.toString());
    _addressController = TextEditingController(text: l.pickupAddress ?? '');
    _hoursController = TextEditingController(text: l.pickupHours ?? 'Mon–Fri, 9am–5pm');
    
    _depositController = TextEditingController(text: l.rentalDeposit?.toString() ?? '0.0');
    _waiverPctController = TextEditingController(text: l.damageWaiverPct?.toString() ?? '5.0');
    _returnConditionController = TextEditingController(text: l.returnCondition ?? '');
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _thresholdController.dispose();
    _daysController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    _depositController.dispose();
    _waiverPctController.dispose();
    _returnConditionController.dispose();
    super.dispose();
  }

  void _updateLogistics(ServiceCreationState state, {
    bool? hasDelivery,
    bool? hasSelfPickup,
    String? feeType,
    double? fee,
    double? threshold,
    int? days,
    String? address,
    String? hours,
    double? deposit,
    bool? hasWaiver,
    double? waiverPct,
    String? condition,
  }) {
    final current = state.productLogistics;
    state.updateProductLogistics(ProductLogistics(
      hasDelivery: hasDelivery ?? current.hasDelivery,
      hasSelfPickup: hasSelfPickup ?? current.hasSelfPickup,
      deliveryFeeType: feeType ?? current.deliveryFeeType,
      deliveryFee: fee ?? current.deliveryFee,
      freeDeliveryThreshold: threshold ?? current.freeDeliveryThreshold,
      estimatedDays: days ?? current.estimatedDays,
      pickupAddress: address ?? current.pickupAddress,
      pickupHours: hours ?? current.pickupHours,
      rentalDeposit: deposit ?? current.rentalDeposit,
      hasDamageWaiver: hasWaiver ?? current.hasDamageWaiver,
      damageWaiverPct: waiverPct ?? current.damageWaiverPct,
      returnCondition: condition ?? current.returnCondition,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);
    final l = state.productLogistics;
    final isRental = state.serviceType == ServiceType.rental;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRental ? 'Logistics & Rental Terms' : 'Logistics & Delivery',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isRental 
              ? 'Define how items are delivered/returned and set security measures.'
              : 'Configure how your product reaches the customer.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // --- Delivery Section ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Delivery Available'),
                    subtitle: const Text('Vendor will deliver items to the event location.'),
                    value: l.hasDelivery,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => _updateLogistics(state, hasDelivery: val),
                  ),
                  if (l.hasDelivery) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: l.deliveryFeeType,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Fee Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'free', child: Text('Free Delivery')),
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Fee')),
                        DropdownMenuItem(value: 'per_km', child: Text('Per KM Rate')),
                      ],
                      onChanged: (val) => _updateLogistics(state, feeType: val),
                    ),
                    if (l.deliveryFeeType != 'free') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _deliveryFeeController,
                        decoration: InputDecoration(
                          labelText: l.deliveryFeeType == 'fixed' ? 'Fixed delivery Fee' : 'Fee per KM (distance from your base)',
                          prefixText: 'RM ',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _updateLogistics(state, fee: double.tryParse(val) ?? 0.0),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _thresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Free Delivery Threshold (Min Spend)',
                        prefixText: 'RM ',
                        hintText: '0.00 for no threshold',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _updateLogistics(state, threshold: double.tryParse(val) ?? 0.0),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _daysController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Dispatch/Delivery Time (Days)',
                        suffixText: 'days',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _updateLogistics(state, days: int.tryParse(val) ?? 3),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // --- Pickup Section ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Self-Pickup Available'),
                    subtitle: const Text('Customers can pick up items from your location.'),
                    value: l.hasSelfPickup,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) => _updateLogistics(state, hasSelfPickup: val),
                  ),
                  if (l.hasSelfPickup) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (val) => _updateLogistics(state, address: val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _hoursController,
                      decoration: const InputDecoration(
                        labelText: 'Operating Hours (for pickup)',
                        hintText: 'e.g., Mon–Fri, 9am–5pm',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _updateLogistics(state, hours: val),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isRental) ...[
            const SizedBox(height: 24),
            const Text(
              'Security & Protection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _depositController,
                      decoration: const InputDecoration(
                        labelText: 'Security Deposit (Refundable)',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => _updateLogistics(state, deposit: double.tryParse(val) ?? 0.0),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Offer Damage Waiver'),
                      subtitle: const Text('Optional non-refundable fee for protection.'),
                      value: l.hasDamageWaiver,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => _updateLogistics(state, hasWaiver: val),
                    ),
                    if (l.hasDamageWaiver) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _waiverPctController,
                        decoration: const InputDecoration(
                          labelText: 'Damage Waiver Fee (%)',
                          suffixText: '% of total price',
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _updateLogistics(state, waiverPct: double.tryParse(val) ?? 5.0),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _returnConditionController,
                      decoration: const InputDecoration(
                        labelText: 'Required Return Condition',
                        hintText: 'e.g., Must be dry-cleaned or in original packaging',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      maxLines: 2,
                      onChanged: (val) => _updateLogistics(state, condition: val),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
