import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../../booking/data/providers/cart_provider.dart';
import '../../../../booking/data/providers/order_provider.dart';
import '../../../../booking/data/providers/payment_provider.dart';
import '../../../../booking/data/models/cart_item.dart';
import 'package:eventease/core/services/payment_service.dart';
import 'package:eventease/core/services/shipping_service.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart' as booking_payment;
import 'package:eventease/shared/models/payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/vendor/data/models/vendor_installment_settings.dart';
import 'package:eventease/features/referral/data/referral_service.dart';
import 'package:eventease/core/services/payment_gateway_service.dart';
import 'package:eventease/core/constants/country_config.dart';
import 'package:eventease/core/providers/country_provider.dart';
import 'package:eventease/core/utils/currency_formatter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isProcessing = false;
  String _selectedPaymentMethod = 'online_banking';
  
  // Installment related state
  Map<String, VendorInstallmentSettings> _vendorSettings = {};
  Map<String, bool> _useInstallments = {}; // vendorId -> bool
  bool _isLoadingSettings = true;
  double _serviceFee = 0;
  bool _hasReferralDiscount = false;

  @override
  void initState() {
    super.initState();
    _loadVendorSettings();
    _prefillFromAuth();
  }

  void _prefillFromAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    _nameController.text = user.userMetadata?['name'] ?? '';
    _emailController.text = user.email ?? '';
    _phoneController.text = user.userMetadata?['phone'] ?? '';
  }

  Future<void> _loadVendorSettings() async {
    setState(() {
      _isLoadingSettings = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final vendorIds = cartProvider.selectedItems
          .map((item) => item.vendorId)
          .whereType<String>()
          .toSet();

      if (vendorIds.isEmpty) return;

      final response = await Supabase.instance.client
          .from('vendor_installment_settings')
          .select()
          .filter('vendor_id', 'in', vendorIds.toList());

      final settingsList = (response as List)
          .map((json) => VendorInstallmentSettings.fromSupabase(json))
          .toList();

      setState(() {
        _vendorSettings = {
          for (var settings in settingsList) settings.vendorId: settings
        };
        for (var vendorId in vendorIds) {
          _useInstallments[vendorId] = false;
        }
        _isLoadingSettings = false;
      });
      await _recalculateServiceFee();
    } catch (e) {
      debugPrint('Error loading vendor installment settings: $e');
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _recalculateServiceFee() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final customerId = Supabase.instance.client.auth.currentUser?.id;
    if (customerId == null || cartProvider.selectedItems.isEmpty) {
      if (mounted) {
        setState(() {
          _serviceFee = 0;
          _hasReferralDiscount = false;
        });
      }
      return;
    }

    final groupedItems = <String, List<CartItem>>{};
    for (var item in cartProvider.selectedItems) {
      final vendorId = item.vendorId ?? 'unknown';
      groupedItems.putIfAbsent(vendorId, () => []).add(item);
    }

    final upfrontByVendor = <String, double>{};
    for (var entry in groupedItems.entries) {
      final vendorSubtotal =
          entry.value.fold(0.0, (sum, item) => sum + item.totalPrice);
      if (_useInstallments[entry.key] == true &&
          _vendorSettings.containsKey(entry.key)) {
        final settings = _vendorSettings[entry.key]!;
        upfrontByVendor[entry.key] =
            vendorSubtotal * (settings.depositPercentage / 100);
      } else {
        upfrontByVendor[entry.key] = vendorSubtotal;
      }
    }

    final fee = await ReferralService.calculateCartServiceFee(
      customerId: customerId,
      upfrontByVendorId: upfrontByVendor,
    );

    var hasDiscount = false;
    for (final vendorId in upfrontByVendor.keys) {
      if (vendorId == 'unknown') continue;
      final rate = await ReferralService.getServiceFeeRate(
        customerId: customerId,
        vendorId: vendorId,
      );
      if (rate < 0.02) {
        hasDiscount = true;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _serviceFee = fee;
        _hasReferralDiscount = hasDiscount;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.selectedItems.isEmpty) {
            return _buildEmptyCart();
          }
          return _buildCheckoutContent(cartProvider);
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your checkout is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Back to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Summary
          _buildOrderSummary(cartProvider),

          const SizedBox(height: 24),

          // Customer Information
          _buildCustomerInformation(),

          const SizedBox(height: 24),

          // Shipping Method Summary
          _buildShippingSummary(cartProvider),

          const SizedBox(height: 24),

          // Payment Method
          _buildPaymentMethod(),

          const SizedBox(height: 24),

          // Order Total
          _buildOrderTotal(cartProvider),

          const SizedBox(height: 24),

          // Place Order Button
          _buildPlaceOrderButton(cartProvider),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    // Group items by vendor
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in cartProvider.selectedItems) {
      final vendorId = item.vendorId ?? 'unknown';
      if (!groupedItems.containsKey(vendorId)) {
        groupedItems[vendorId] = [];
      }
      groupedItems[vendorId]!.add(item);
    }

    return Column(
      children: groupedItems.entries.map((entry) {
        final vendorId = entry.key;
        final items = entry.value;
        final vendorName = items.first.vendor;
        final settings = _vendorSettings[vendorId];
        
        final vendorSubtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
        final canUseInstallments = settings != null && 
                                 settings.isEnabled && 
                                 vendorSubtotal >= settings.minOrderAmount;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vendorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (canUseInstallments)
                    const Chip(
                      label: Text('Installments Available', style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _buildOrderItem(item)),
              
              if (canUseInstallments) ...[
                const Divider(),
                SwitchListTile(
                  title: const Text('Pay with Installments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Initial deposit: RM ${(vendorSubtotal * (settings.depositPercentage / 100)).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _useInstallments[vendorId] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _useInstallments[vendorId] = value;
                    });
                    _recalculateServiceFee();
                  },
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image,
                    color: AppTheme.textSecondaryColor,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.vendor} • Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'RM ${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter delivery address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingSummary(CartProvider cartProvider) {
    final selectedVendors = cartProvider.selectedItems.map((item) => item.vendor).toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...selectedVendors.map((vendor) {
            final rate = cartProvider.getSelectedShippingRate(vendor);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          rate != null ? '${rate.provider} (${rate.type.toString().split('.').last})' : 'Not selected',
                          style: TextStyle(color: rate == null ? Colors.red : AppTheme.textSecondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rate != null ? 'RM ${rate.cost.toStringAsFixed(2)}' : 'RM 0.00',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentOption('Online Banking', 'online_banking', Icons.account_balance),
          const SizedBox(height: 8),
          _buildPaymentOption('Credit/Debit Card', 'card', Icons.credit_card),
          const SizedBox(height: 8),
          _buildPaymentOption('E-Wallet', 'ewallet', Icons.account_balance_wallet),
          const SizedBox(height: 8),
          _buildPaymentOption('Cash on Delivery', 'cod', Icons.money),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, String value, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? AppTheme.primaryColor
                : Colors.grey[300]!,
            width: _selectedPaymentMethod == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedPaymentMethod == value
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedPaymentMethod == value
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: _selectedPaymentMethod == value
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimaryColor,
                fontWeight: _selectedPaymentMethod == value
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (_selectedPaymentMethod == value)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotal(CartProvider cartProvider) {
    // Group items by vendor to calculate installments
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in cartProvider.selectedItems) {
      final vendorId = item.vendorId ?? 'unknown';
      if (!groupedItems.containsKey(vendorId)) {
        groupedItems[vendorId] = [];
      }
      groupedItems[vendorId]!.add(item);
    }

    double totalToPayUpfront = 0;
    double totalRemainingBalance = 0;
    
    for (var entry in groupedItems.entries) {
      final vendorId = entry.key;
      final items = entry.value;
      final vendorSubtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      if (_useInstallments[vendorId] == true && _vendorSettings.containsKey(vendorId)) {
        final settings = _vendorSettings[vendorId]!;
        final deposit = vendorSubtotal * (settings.depositPercentage / 100);
        totalToPayUpfront += deposit;
        totalRemainingBalance += (vendorSubtotal - deposit);
      } else {
        totalToPayUpfront += vendorSubtotal;
      }
    }

    final shippingTotal = cartProvider.shippingCost;
    final serviceFee = _serviceFee;
    final countryCode = context.read<CountryProvider>().selectedCountryCode;
    final breakdown = PaymentGatewayService.buildBreakdown(
      subtotal: totalToPayUpfront + shippingTotal,
      platformFee: serviceFee,
      countryCode: countryCode,
    );
    final finalTotal = breakdown.total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal (Selected Items):',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
              ),
              Text(
                'RM ${cartProvider.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
              ),
            ],
          ),
          if (totalRemainingBalance > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Deferred Balance:',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
                Text(
                  '- RM ${totalRemainingBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payable Now:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              Text(
                'RM ${totalToPayUpfront.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping Total:',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
              ),
              Text(
                'RM ${shippingTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _hasReferralDiscount
                    ? 'Service Fee (1% referral rate):'
                    : 'Service Fee (2%):',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                'RM ${serviceFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  color: _hasReferralDiscount
                      ? Colors.green
                      : AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          if (_hasReferralDiscount)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Referral discount applied — thank you for booking via your vendor!',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (${(CountryConfig.taxRateForCountry(countryCode) * 100).toStringAsFixed(0)}%):',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
              ),
              Text(
                CurrencyFormatter.format(breakdown.tax),
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Payment via ${breakdown.gateway.toUpperCase()} · ${breakdown.currency}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              Text(
                'RM ${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),
          if (totalRemainingBalance > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '* RM ${totalRemainingBalance.toStringAsFixed(2)} will be paid in installments',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(CartProvider cartProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : () => _placeOrder(cartProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _placeOrder(CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if all selected vendors have shipping rates
    final selectedVendors = cartProvider.selectedItems.map((item) => item.vendor).toSet();
    for (var vendor in selectedVendors) {
      if (cartProvider.getSelectedShippingRate(vendor) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a shipping method for $vendor in the cart'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final paymentProvider = Provider.of<booking_payment.PaymentProvider>(context, listen: false);

      // Create order from cart (now handles payment and installments)
      final order = await orderProvider.createOrderFromCart(
        customerId: 'customer_demo_id', // Should use real user ID
        customerName: _nameController.text,
        customerEmail: _emailController.text,
        cartItems: cartProvider.selectedItems,
        paymentProvider: paymentProvider,
        installmentSelections: _useInstallments,
        vendorSettings: _vendorSettings,
        shippingAddress: _addressController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (order.paymentStatus != PaymentStatus.failed) {
        // Clear only selected items after successful order
        for (var item in List.from(cartProvider.selectedItems)) {
          await cartProvider.removeItem(item.serviceId);
        }

        // Navigate to order confirmation
        Navigator.pushReplacementNamed(
          context,
          '/order-confirmation',
          arguments: order,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  PaymentMethod _getPaymentMethodFromString(String method) {
    switch (method) {
      case 'online_banking':
        return PaymentMethod.onlineBanking;
      case 'card':
        return PaymentMethod.creditCard;
      case 'ewallet':
        return PaymentMethod.eWallet;
      case 'cod':
        return PaymentMethod.cashOnDelivery;
      default:
        return PaymentMethod.onlineBanking;
    }
  }
}
