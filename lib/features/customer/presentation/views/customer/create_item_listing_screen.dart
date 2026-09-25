import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/models/item_listing.dart';
import 'package:eventease/features/customer/data/providers/marketplace_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateItemListingScreen extends StatefulWidget {
  const CreateItemListingScreen({super.key});

  @override
  State<CreateItemListingScreen> createState() => _CreateItemListingScreenState();
}

class _CreateItemListingScreenState extends State<CreateItemListingScreen> {
  // ⚡ TESTING: set to true to bypass Supabase and use local-only mode
  static const bool _testMode = true;

  final _formKey = GlobalKey<FormState>();

  final _itemNameController = TextEditingController();
  String _category = 'Bridal wear';
  ItemCondition _condition = ItemCondition.newCondition;
  final _quantityController = TextEditingController(text: '1');
  final _sizeController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String _deliveryOption = 'both';
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Bridal wear',
    'Groom suit',
    'Wedding shoes',
    'Accessories',
    'Doorgifts',
    'Wedding decorations',
    'Invitation cards',
    'Wedding props',
    'Other wedding items'
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _sizeController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'test-user-${DateTime.now().millisecondsSinceEpoch}';

    final listing = ItemListing(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      customerId: userId,
      category: _category,
      itemName: _itemNameController.text,
      description: _descriptionController.text,
      condition: _condition,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      size: _sizeController.text.isNotEmpty ? _sizeController.text : null,
      brand: _brandController.text.isNotEmpty ? _brandController.text : null,
      price: double.tryParse(_priceController.text) ?? 0,
      images: ['https://images.unsplash.com/photo-1594552072238-b8a33785b261?auto=format&fit=crop&w=800&q=80'],
      location: _locationController.text,
      deliveryOption: _deliveryOption,
      listingStatus: ItemListingStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<MarketplaceProvider>(context, listen: false);

    if (_testMode) {
      // ⚡ TEST MODE: skip Supabase, add locally immediately
      provider.addLocalItemListing(listing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ [Test Mode] Item listed locally!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    final success = await provider.createItemListing(listing);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item listed successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sell Wedding Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              const Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Silk Wedding Veil, Floral Table Centerpieces',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              // Condition & Price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<ItemCondition>(
                          value: _condition,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: ItemCondition.newCondition, child: Text('New')),
                            DropdownMenuItem(value: ItemCondition.likeNew, child: Text('Like New')),
                            DropdownMenuItem(value: ItemCondition.used, child: Text('Used')),
                          ],
                          onChanged: (val) => setState(() => _condition = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price (RM)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'RM 150',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity, Size & Brand
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Size (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _sizeController,
                          decoration: InputDecoration(
                            hintText: 'e.g. M / UK 8',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Brand (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _brandController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Vera Wang',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location & Delivery Options
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Kuala Lumpur',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivery Option', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _deliveryOption,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'delivery', child: Text('Delivery only')),
                            DropdownMenuItem(value: 'pickup', child: Text('Self-pickup')),
                            DropdownMenuItem(value: 'both', child: Text('Both options')),
                          ],
                          onChanged: (val) => setState(() => _deliveryOption = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your item. Condition details, shipping information, dimensions, defects...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter item description' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post Item Listing', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
