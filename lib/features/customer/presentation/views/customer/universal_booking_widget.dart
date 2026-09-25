import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/shared/services/pricing_calculator.dart';
import 'package:eventease/core/utils/app_theme.dart';

class UniversalBookingWidget extends StatefulWidget {
  final VendorService service;
  final Function(double totalPrice, Map<String, dynamic> bookingDetails) onPriceCalculated;

  const UniversalBookingWidget({
    super.key,
    required this.service,
    required this.onPriceCalculated,
  });

  @override
  State<UniversalBookingWidget> createState() => _UniversalBookingWidgetState();
}

class _UniversalBookingWidgetState extends State<UniversalBookingWidget> {
  // Booking State
  List<String> _selectedEventTypes = [];
  int _pax = 100; // Default
  int _hours = 4;
  DateTime? _selectedDate;
  Map<String, int> _selectedAddOns = {}; // ID -> Quantity

  // Calculated State
  double _totalPrice = 0.0;
  Map<String, double> _breakdown = {};

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _calculatePrice();
  }

  void _initializeDefaults() {
    if (widget.service.pricingModel != null) {
      if (widget.service.pricingModel!.minPax != null) {
        _pax = widget.service.pricingModel!.minPax!;
      }
      
      // Select first event type by default if available
      // Ideally we ask user to select, but for now select first valid one
      if (widget.service.eventTypes.isNotEmpty) {
        _selectedEventTypes = [widget.service.eventTypes.first];
      }
    }
  }

  bool _shouldShowPaxInput(PricingModel pricingModel) {
    // Always show if per-pax pricing
    if (pricingModel.type == PricingModelType.perPax) return true;
    
    // Show if there are pax-based tiers
    if (pricingModel.paxTiers != null && pricingModel.paxTiers!.isNotEmpty) return true;
    
    // Show for categories that usually need guest count
    final category = widget.service.category.id.toLowerCase();
    if (['catering', 'venue', 'venues', 'all-in package'].contains(category)) return true;
    
    return false;
  }

  void _calculatePrice() {
    // Check if we have minimum requirements
    if (widget.service.pricingModel == null) return;
    
    // Simple validation before calculation
    if (_selectedEventTypes.isEmpty && widget.service.pricingModel?.type == PricingModelType.perEventType) {
      _totalPrice = 0.0;
      return;
    }

    final price = PricingCalculator.calculateServicePrice(
      service: widget.service,
      selectedEventTypes: _selectedEventTypes,
      paxCount: _pax,
      hours: _hours,
      days: 1, // Simplify for now
      selectedAddOns: _selectedAddOns,
    );

    final breakdown = PricingCalculator.getPriceBreakdown(
      service: widget.service,
      selectedEventTypes: _selectedEventTypes,
      paxCount: _pax,
      hours: _hours,
      days: 1,
      selectedAddOns: _selectedAddOns,
    );

    setState(() {
      _totalPrice = price;
      _breakdown = breakdown;
    });

    // Notify parent
    widget.onPriceCalculated(_totalPrice, {
      'eventTypes': _selectedEventTypes,
      'pax': _pax,
      'hours': _hours,
      'date': _selectedDate,
      'addOns': _selectedAddOns,
    });
  }

  @override
  Widget build(BuildContext context) {
    final pricingModel = widget.service.pricingModel;
    if (pricingModel == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Pricing model not available.'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero, // Remove margin to prevent nested spacing issues in wide layouts
      elevation: 0, // Let the parent container handle the elevation/border
      color: Colors.transparent, // Transparent to blend with parent container
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book This Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            
            // 1. Date Selection (Simplified)
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate == null ? 'Select Event Date' : DateFormat('dd MMM yyyy').format(_selectedDate!),
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            
            // 2. Event Type Selection (if multiple)
            if (widget.service.eventTypes.length > 1) ...[
              const SizedBox(height: 12),
              const Text('Event Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: widget.service.eventTypes.map((type) {
                    final isSelected = _selectedEventTypes.contains(type);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type.split('_').last.toUpperCase()),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                             _selectedEventTypes = [type];
                             _calculatePrice();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // 3. Pax Input (if needed)
            if (_shouldShowPaxInput(pricingModel)) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quantity / Guests:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                          onPressed: _pax > (pricingModel.minPax ?? 1) ? () {
                            setState(() {
                              _pax -= 10;
                               if (_pax < (pricingModel.minPax ?? 1)) _pax = pricingModel.minPax ?? 1;
                              _calculatePrice();
                            });
                          } : null,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            _editQuantityDialog('Enter Quantity', _pax, (val) {
                              setState(() {
                                _pax = val;
                                if (_pax < (pricingModel.minPax ?? 1)) _pax = pricingModel.minPax ?? 1;
                                _calculatePrice();
                              });
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Text('$_pax', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _pax += 10;
                              _calculatePrice();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // 4. Hours Input (if needed)
            if (pricingModel.type == PricingModelType.perHour) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Duration (Hours):'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _hours > 1 ? () => setState(() { _hours--; _calculatePrice(); }) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_hours h'),
                      IconButton(
                        onPressed: () => setState(() { _hours++; _calculatePrice(); }),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // 5. Add-Ons
            if (widget.service.addOns != null && widget.service.addOns!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Add-Ons', style: TextStyle(fontWeight: FontWeight.w600)),
              ...widget.service.addOns!.map((addon) {
                 final qty = _selectedAddOns[addon.id] ?? 0;
                 return CheckboxListTile(
                   title: Text(addon.name),
                   subtitle: Text(addon.formattedPrice),
                   value: qty > 0,
                   onChanged: (val) {
                     setState(() {
                       if (val == true) {
                         _selectedAddOns[addon.id] = 1;
                       } else {
                         _selectedAddOns.remove(addon.id);
                       }
                       _calculatePrice();
                     });
                   },
                   contentPadding: EdgeInsets.zero,
                 );
              }),
            ],

            const Divider(height: 32),
            
            // 6. Total Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Total Estimate',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RM ${_totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            
            TextButton(
              onPressed: _showBreakdownDetails,
              child: const Text('View Price Breakdown'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _calculatePrice(); // Ideally calculate day adjustments here
      });
    }
  }

  void _showBreakdownDetails() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Price Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (_breakdown.isEmpty) const Text('No details available.'),
            ..._breakdown.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(e.key)),
                  const SizedBox(width: 12),
                  Text('RM ${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('RM ${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _editQuantityDialog(String title, int currentValue, Function(int) onSaved) async {
    final controller = TextEditingController(text: currentValue.toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                onSaved(val);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
