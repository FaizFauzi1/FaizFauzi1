import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/coupon_provider.dart';
import '../../../../core/utils/app_theme.dart';
import '../../models/service_coupon.dart';
import '../../models/vendor_service.dart';
import '../../data/providers/vendor_provider_updated.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      final couponProvider = Provider.of<CouponProvider>(context, listen: false);
      final profileId = vendorProvider.currentVendor?.id;
      if (profileId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          couponProvider.fetchVendorCoupons(profileId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promotions & Coupons"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCouponDialog(),
          ),
        ],
      ),
      body: Consumer2<CouponProvider, VendorProvider>(
        builder: (context, couponProvider, vendorProvider, child) {
          if (couponProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (couponProvider.vendorCoupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.confirmation_num_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("No coupons created yet", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCouponDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text("Create First Coupon"),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: couponProvider.vendorCoupons.length,
            itemBuilder: (context, index) {
              final coupon = couponProvider.vendorCoupons[index];
              return _buildCouponCard(coupon);
            },
          );
        },
      ),
    );
  }

  Widget _buildCouponCard(ServiceCoupon coupon) {
    final bool isExpired = coupon.expiryDate != null && coupon.expiryDate!.isBefore(DateTime.now());
    final bool isLimitReached = coupon.usageLimit != null && coupon.currentUsage >= coupon.usageLimit!;
    final bool isActive = coupon.isActive && !isExpired && !isLimitReached;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCouponDialog(coupon: coupon),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(
                       color: AppTheme.primaryColor.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(4),
                       border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                     ),
                     child: Text(
                       coupon.code,
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor, letterSpacing: 1.2),
                     ),
                   ),
                   Switch.adaptive(
                     value: coupon.isActive,
                     onChanged: (val) {
                       context.read<CouponProvider>().saveCoupon(coupon.copyWith(isActive: val));
                     },
                     activeColor: AppTheme.primaryColor,
                   )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    coupon.discountType == 'percentage' ? "${coupon.discountValue.toStringAsFixed(0)}% OFF" : "RM ${coupon.discountValue.toStringAsFixed(0)} OFF",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        isExpired ? "EXPIRED" : (isLimitReached ? "LIMIT REACHED" : "INACTIVE"),
                        style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Min Spend: RM ${coupon.minSpend.toStringAsFixed(0)}",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (coupon.usageLimit != null) ...[
                const SizedBox(height: 4),
                Text(
                  "Usage: ${coupon.currentUsage} / ${coupon.usageLimit}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              if (coupon.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  "Expires: ${DateFormat('dd MMM yyyy').format(coupon.expiryDate!)}",
                  style: TextStyle(color: isExpired ? Colors.red : Colors.grey[600], fontSize: 13),
                ),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.settings_input_component, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                       coupon.serviceId == null ? "All Services" : "Specific Service Only",
                       style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _deleteConfirm(coupon.id!),
                    child: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCouponDialog({ServiceCoupon? coupon}) async {
    final isEditing = coupon != null;
    final codeCtrl = TextEditingController(text: coupon?.code);
    final valueCtrl = TextEditingController(text: coupon?.discountValue.toStringAsFixed(0) ?? "");
    final minSpendCtrl = TextEditingController(text: coupon?.minSpend.toStringAsFixed(0) ?? "0");
    final limitCtrl = TextEditingController(text: coupon?.usageLimit?.toString() ?? "");
    String discountType = coupon?.discountType ?? 'percentage';
    String? selectedServiceId = coupon?.serviceId;
    DateTime? selectedExpiry = coupon?.expiryDate;

    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final services = vendorProvider.getCurrentVendorServices(); // Assuming these are pre-loaded

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? "Edit Coupon" : "Create Coupon"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: "Promo Code", hintText: "e.g. SAVE50"),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: discountType == 'percentage' ? "Discount %" : "Discount RM",
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: discountType,
                        items: const [
                          DropdownMenuItem(value: 'percentage', child: Text("Percentage")),
                          DropdownMenuItem(value: 'flat', child: Text("Flat RM")),
                        ],
                        onChanged: (val) => setDialogState(() => discountType = val!),
                        decoration: const InputDecoration(labelText: "Type"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minSpendCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Min. Spend (RM)", hintText: "0"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Usage Limit (Optional)", hintText: "e.g. 100"),
                ),
                const SizedBox(height: 12),
                
                // Expiry Picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedExpiry ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (date != null) setDialogState(() => selectedExpiry = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: "Expiry Date (Optional)"),
                    child: Text(selectedExpiry == null ? "No Expiry" : DateFormat('dd MMM yyyy').format(selectedExpiry!)),
                  ),
                ),
                const SizedBox(height: 12),

                // Service Picker
                DropdownButtonFormField<String?>(
                  value: selectedServiceId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All My Services")),
                    ...services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name ?? "Unnamed Service", overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedServiceId = val),
                  decoration: const InputDecoration(labelText: "Applicable To"),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty || valueCtrl.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in code and value")));
                   return;
                }

                final newCoupon = ServiceCoupon(
                  id: coupon?.id,
                  vendorId: vendorProvider.currentVendor!.id,
                  serviceId: selectedServiceId,
                  code: codeCtrl.text.toUpperCase(),
                  discountType: discountType,
                  discountValue: double.tryParse(valueCtrl.text) ?? 0.0,
                  minSpend: double.tryParse(minSpendCtrl.text) ?? 0.0,
                  usageLimit: int.tryParse(limitCtrl.text),
                  expiryDate: selectedExpiry,
                  isActive: coupon?.isActive ?? true,
                  currentUsage: coupon?.currentUsage ?? 0,
                );

                final success = await context.read<CouponProvider>().saveCoupon(newCoupon);
                if (success) {
                  Navigator.pop(context);
                  context.read<CouponProvider>().fetchVendorCoupons(vendorProvider.currentVendor!.id);
                }
              },
              child: Text(isEditing ? "Update" : "Create"),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteConfirm(String id) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text("Delete Coupon?"),
         content: const Text("This action cannot be undone."),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
           TextButton(
             onPressed: () async {
               await context.read<CouponProvider>().deleteCoupon(id);
               Navigator.pop(context);
             },
             child: const Text("Delete", style: TextStyle(color: Colors.red)),
           ),
         ],
       ),
     );
  }
}
