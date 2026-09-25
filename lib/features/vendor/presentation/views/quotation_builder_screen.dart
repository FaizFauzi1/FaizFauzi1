import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:intl/intl.dart';

class QuotationLineItem {
  String description;
  int quantity;
  double unitPrice;

  QuotationLineItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0.0,
  });

  double get total => quantity * unitPrice;
}

class QuotationBuilderScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String vendorId;
  final String? serviceId;

  const QuotationBuilderScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    this.serviceId,
  });

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  final List<QuotationLineItem> _items = [
    QuotationLineItem(description: 'Service Fee', quantity: 1, unitPrice: 0.0),
  ];

  double _taxRate = 6.0; // Default 6%
  double _serviceFee = 0.0;
  double _discount = 0.0;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  final TextEditingController _notesController = TextEditingController();

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _taxAmount => (_subtotal * _taxRate) / 100;
  double get _total => _subtotal + _taxAmount + _serviceFee - _discount;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(QuotationLineItem(description: 'New Item'));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  void _sendQuotation() {
    // Generate quotation metadata
    final metadata = {
      'customerId': widget.customerId,
      'vendorId': widget.vendorId,
      'serviceId': widget.serviceId,
      'items': _items.map((item) => {
        'description': item.description,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'total': item.total,
      }).toList(),
      'subtotal': _subtotal,
      'taxRate': _taxRate,
      'taxAmount': _taxAmount,
      'serviceFee': _serviceFee,
      'discount': _discount,
      'totalAmount': _total,
      'expiryDate': _expiryDate.toIso8601String(),
      'notes': _notesController.text,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Return the quotation data to the previous screen
    Navigator.pop(context, metadata);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Final Quotation'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfo(),
                  const SizedBox(height: 24),
                  _buildLineItemsSection(),
                  const SizedBox(height: 24),
                  _buildAdjustmentsSection(),
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Text(widget.customerName[0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quotation For:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(widget.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._items.asMap().entries.map((entry) => _buildLineItemRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildLineItemRow(int index, QuotationLineItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g. Venue Rental',
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => item.description = val),
                  controller: TextEditingController(text: item.description)..selection = TextSelection.collapsed(offset: item.description.length),
                ),
              ),
              const SizedBox(width: 8),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                  onChanged: (val) => setState(() => item.quantity = int.tryParse(val) ?? 0),
                  controller: TextEditingController(text: item.quantity.toString()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Unit Price (RM)', isDense: true),
                  onChanged: (val) => setState(() => item.unitPrice = double.tryParse(val) ?? 0.0),
                  controller: TextEditingController(text: item.unitPrice == 0 ? '' : item.unitPrice.toString()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('RM ${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildAdjustmentRow(
            'Tax (SST) %',
            TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(isDense: true, suffixText: '%'),
              onChanged: (val) => setState(() => _taxRate = double.tryParse(val) ?? 0.0),
              controller: TextEditingController(text: _taxRate.toString()),
            ),
          ),
          const Divider(),
          _buildAdjustmentRow(
            'Service Fee (RM)',
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(isDense: true, prefixText: 'RM '),
              onChanged: (val) => setState(() => _serviceFee = double.tryParse(val) ?? 0.0),
              controller: TextEditingController(text: _serviceFee == 0 ? '' : _serviceFee.toString()),
            ),
          ),
          const Divider(),
          _buildAdjustmentRow(
            'Discount (RM)',
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(isDense: true, prefixText: '-RM '),
              onChanged: (val) => setState(() => _discount = double.tryParse(val) ?? 0.0),
              controller: TextEditingController(text: _discount == 0 ? '' : _discount.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentRow(String label, Widget input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          SizedBox(width: 100, child: input),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Terms & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          title: const Text('Validity Period'),
          subtitle: Text('Valid until ${DateFormat('yyyy-MM-dd').format(_expiryDate)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: _selectExpiryDate,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Notes & Policy',
            hintText: 'e.g. 50% deposit required for booking.',
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('RM ${_total.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _sendQuotation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
