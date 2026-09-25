import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin screen for managing service categories
class AdminCategoryManagementScreen extends StatefulWidget {
  const AdminCategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminCategoryManagementScreen> createState() =>
      _AdminCategoryManagementScreenState();
}

class _AdminCategoryManagementScreenState
    extends State<AdminCategoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load categories on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Categories'),
            Tab(icon: Icon(Icons.event), text: 'Event Types'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoriesTab(),
          _EventTypesTab(),
          _AnalyticsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            )
          : null,
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(),
    );
  }
}

/// Tab for managing categories
class _CategoriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchCategories(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final categories = provider.allCategories;

        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories found. Add one to get started!'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryListTile(category: category);
          },
        );
      },
    );
  }
}

/// Category list tile with actions
class _CategoryListTile extends StatelessWidget {
  final ServiceCategory category;

  const _CategoryListTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.2),
          child: Icon(category.icon, color: category.color),
        ),
        title: Row(
          children: [
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (category.isAdvanced) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, size: 16, color: Colors.blue),
            ],
            if (!category.isActive) ...[
              const SizedBox(width: 8),
              const Icon(Icons.visibility_off, size: 16, color: Colors.grey),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(category.description),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(category.categoryType.displayName),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(category.pricingModel.displayName),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(category.minVendorTier.displayName),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Toggle Active'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mappings',
              child: Row(
                children: [
                  Icon(Icons.link),
                  SizedBox(width: 8),
                  Text('Event Type Mappings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleAction(context, value.toString()),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => _CategoryFormDialog(category: category),
        );
        break;
      case 'toggle':
        _toggleActive(context);
        break;
      case 'mappings':
        showDialog(
          context: context,
          builder: (context) => _EventTypeMappingDialog(category: category),
        );
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  Future<void> _toggleActive(BuildContext context) async {
    try {
      await Supabase.instance.client
          .from('service_categories')
          .update({'is_active': !category.isActive})
          .eq('id', category.id);

      if (context.mounted) {
        Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              category.isActive
                  ? 'Category deactivated'
                  : 'Category activated',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategory(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(BuildContext context) async {
    try {
      await Supabase.instance.client
          .from('service_categories')
          .delete()
          .eq('id', category.id);

      if (context.mounted) {
        Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Dialog for adding/editing categories
class _CategoryFormDialog extends StatefulWidget {
  final ServiceCategory? category;

  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  
  CategoryType _categoryType = CategoryType.service;
  PricingModel _pricingModel = PricingModel.fixed;
  VendorTier _minVendorTier = VendorTier.basic;
  bool _isAdvanced = false;
  bool _requiresVerification = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _slugController = TextEditingController(text: widget.category?.slug);
    _descriptionController = TextEditingController(text: widget.category?.description);
    
    if (widget.category != null) {
      _categoryType = widget.category!.categoryType;
      _pricingModel = widget.category!.pricingModel;
      _minVendorTier = widget.category!.minVendorTier;
      _isAdvanced = widget.category!.isAdvanced;
      _requiresVerification = widget.category!.requiresVerification;
      _isActive = widget.category!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                onChanged: (value) {
                  // Auto-generate slug
                  if (widget.category == null) {
                    _slugController.text = value
                        .toLowerCase()
                        .replaceAll(' ', '-')
                        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
                  }
                },
              ),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(labelText: 'Slug'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CategoryType>(
                value: _categoryType,
                decoration: const InputDecoration(labelText: 'Category Type'),
                items: CategoryType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _categoryType = value!),
              ),
              DropdownButtonFormField<PricingModel>(
                value: _pricingModel,
                decoration: const InputDecoration(labelText: 'Pricing Model'),
                items: PricingModel.values.map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Text(model.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _pricingModel = value!),
              ),
              DropdownButtonFormField<VendorTier>(
                value: _minVendorTier,
                decoration: const InputDecoration(labelText: 'Min Vendor Tier'),
                items: VendorTier.values.map((tier) {
                  return DropdownMenuItem(
                    value: tier,
                    child: Text(tier.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _minVendorTier = value!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Advanced Category'),
                subtitle: const Text('Requires vendor verification'),
                value: _isAdvanced,
                onChanged: (value) => setState(() => _isAdvanced = value),
              ),
              SwitchListTile(
                title: const Text('Requires Verification'),
                value: _requiresVerification,
                onChanged: (value) => setState(() => _requiresVerification = value),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text,
      'slug': _slugController.text,
      'description': _descriptionController.text,
      'category_type': _categoryType.value,
      'pricing_model': _pricingModel.value,
      'min_vendor_tier': _minVendorTier.value,
      'is_advanced': _isAdvanced,
      'requires_verification': _requiresVerification,
      'is_active': _isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.category == null) {
        // Insert new
        await Supabase.instance.client.from('service_categories').insert(data);
      } else {
        // Update existing
        await Supabase.instance.client
            .from('service_categories')
            .update(data)
            .eq('id', widget.category!.id);
      }

      if (mounted) {
        Navigator.pop(context);
        Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Dialog for managing event type mappings
class _EventTypeMappingDialog extends StatefulWidget {
  final ServiceCategory category;

  const _EventTypeMappingDialog({required this.category});

  @override
  State<_EventTypeMappingDialog> createState() =>
      _EventTypeMappingDialogState();
}

class _EventTypeMappingDialogState extends State<_EventTypeMappingDialog> {
  final _supabase = Supabase.instance.client;
  Map<String, bool> _mappings = {}; // Key is EventType Enum ID (slug)
  Map<String, bool> _primaryFlags = {}; // Key is EventType Enum ID (slug)
  Map<String, String> _slugToUuid = {}; // Map slug -> UUID
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMappings();
  }

  Future<void> _loadMappings() async {
    try {
      // 1. Get all event types to build UUID map
      final eventTypesResponse = await _supabase
          .from('event_types')
          .select('id, category');

      final slugToUuid = <String, String>{};
      final uuidToSlug = <String, String>{};

      for (final et in eventTypesResponse as List) {
        final id = et['id'] as String;
        final categorySlug = et['category'] as String?;
        if (categorySlug != null) {
          slugToUuid[categorySlug] = id;
          uuidToSlug[id] = categorySlug;
        }
      }

      // 2. Get existing mappings for this category
      final mappingsResponse = await _supabase
          .from('event_type_categories')
          .select('event_type_id, is_primary')
          .eq('category_id', widget.category.id);

      final mappedFlags = <String, bool>{};
      final primaryFlags = <String, bool>{};

      for (final mapping in mappingsResponse as List) {
        final uuid = mapping['event_type_id'] as String;
        final slug = uuidToSlug[uuid];
        if (slug != null) {
          mappedFlags[slug] = true;
          primaryFlags[slug] = mapping['is_primary'] ?? false;
        }
      }

      if (mounted) {
        setState(() {
          _slugToUuid = slugToUuid;
          _mappings = mappedFlags;
          _primaryFlags = primaryFlags;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading mappings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text('Event Type Mappings for ${widget.category.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: EventType.values.map((eventType) {
            // Only show if we found a matching UUID in DB
            if (!_slugToUuid.containsKey(eventType.id)) {
              return const SizedBox.shrink(); 
            }

            final isMapped = _mappings[eventType.id] ?? false;
            final isPrimary = _primaryFlags[eventType.id] ?? false;

            return CheckboxListTile(
              title: Row(
                children: [
                  Icon(eventType.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(eventType.displayName),
                ],
              ),
              subtitle: isMapped
                  ? Row(
                      children: [
                        const Text('Primary:'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isPrimary,
                          onChanged: (value) {
                            setState(() => _primaryFlags[eventType.id] = value);
                          },
                        ),
                      ],
                    )
                  : null,
              value: isMapped,
              onChanged: (value) {
                setState(() {
                  _mappings[eventType.id] = value ?? false;
                  if (value == false) {
                    _primaryFlags.remove(eventType.id);
                  }
                });
              },
            );
          }).where((w) => w is! SizedBox).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveMappings,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveMappings() async {
    try {
      // Delete all existing mappings
      await _supabase
          .from('event_type_categories')
          .delete()
          .eq('category_id', widget.category.id);

      // Prepare new mappings
      final newMappings = <Map<String, dynamic>>[];
      
      _mappings.forEach((slug, isMapped) {
        if (isMapped) {
          final uuid = _slugToUuid[slug];
          if (uuid != null) {
             newMappings.add({
                'category_id': widget.category.id,
                'event_type_id': uuid, // Use UUID key
                'is_primary': _primaryFlags[slug] ?? false,
             });
          }
        }
      });

      if (newMappings.isNotEmpty) {
        await _supabase.from('event_type_categories').insert(newMappings);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mappings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Tab for managing event types
class _EventTypesTab extends StatefulWidget {
  @override
  State<_EventTypesTab> createState() => _EventTypesTabState();
}

class _EventTypesTabState extends State<_EventTypesTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _eventTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventTypes();
  }

  Future<void> _loadEventTypes() async {
    try {
      final response = await _supabase
          .from('event_types')
          .select()
          .order('display_order', ascending: true);
      
      if (mounted) {
        setState(() {
          _eventTypes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading event types: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEnabled(String id, bool currentValue) async {
      try {
        await _supabase.from('event_types').update({'is_enabled': !currentValue}).eq('id', id);
        await _loadEventTypes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventTypes.length,
      itemBuilder: (context, index) {
        final et = _eventTypes[index];
        final name = et['name'] ?? 'Unknown';
        final description = et['description'] ?? '';
        final isEnabled = et['is_enabled'] ?? false;
        
        // Try to match with local Enum for icon
        final enumMatch = EventType.values.firstWhere(
          (e) => e.displayName == name || e.id == et['category'], // Try name or slug match
          orElse: () => EventType.other,
        );

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: enumMatch.color.withOpacity(0.2),
              child: Icon(enumMatch.icon, color: enumMatch.color),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isEnabled,
                  onChanged: (v) => _toggleEnabled(et['id'], isEnabled),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(Icons.category),
                          SizedBox(width: 8),
                          Text('Manage Categories'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'manage') {
                      showDialog(
                        context: context,
                        builder: (context) => _CategoryMappingDialog(
                          eventTypeId: et['id'],
                          eventTypeName: name,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialog for managing categories for a specific event type
class _CategoryMappingDialog extends StatefulWidget {
  final String eventTypeId;
  final String eventTypeName;

  const _CategoryMappingDialog({
    required this.eventTypeId,
    required this.eventTypeName,
  });

  @override
  State<_CategoryMappingDialog> createState() => _CategoryMappingDialogState();
}

class _CategoryMappingDialogState extends State<_CategoryMappingDialog> {
  final _supabase = Supabase.instance.client;
  List<ServiceCategory> _allCategories = [];
  Set<String> _mappedCategoryIds = {};
  Set<String> _primaryCategoryIds = {};
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Get all categories
      final categoriesResponse = await _supabase
          .from('service_categories')
          .select()
          .order('name', ascending: true);
      
      final allCategories = (categoriesResponse as List)
          .map((json) => ServiceCategory.fromMap(json))
          .toList();

      // 2. Get existing mappings for this event type
      final mappingsResponse = await _supabase
          .from('event_type_categories')
          .select('category_id, is_primary')
          .eq('event_type_id', widget.eventTypeId);

      final mappedIds = <String>{};
      final primaryIds = <String>{};

      for (final mapping in mappingsResponse as List) {
        final catId = mapping['category_id'] as String;
        mappedIds.add(catId);
        if (mapping['is_primary'] == true) {
          primaryIds.add(catId);
        }
      }

      if (mounted) {
        setState(() {
          _allCategories = allCategories;
          _mappedCategoryIds = mappedIds;
          _primaryCategoryIds = primaryIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading category mappings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ServiceCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _allCategories;
    return _allCategories.where((c) => 
      c.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text('Categories for ${widget.eventTypeName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = _filteredCategories[index];
                  final isMapped = _mappedCategoryIds.contains(category.id);
                  final isPrimary = _primaryCategoryIds.contains(category.id);

                  return CheckboxListTile(
                    title: Text(category.name),
                    subtitle: isMapped
                        ? Row(
                            children: [
                              const Text('Primary:'),
                              const SizedBox(width: 8),
                              Switch(
                                value: isPrimary,
                                onChanged: (value) {
                                  setState(() {
                                    if (value) {
                                      _primaryCategoryIds.add(category.id);
                                    } else {
                                      _primaryCategoryIds.remove(category.id);
                                    }
                                  });
                                },
                              ),
                            ],
                          )
                        : null,
                    value: isMapped,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _mappedCategoryIds.add(category.id);
                        } else {
                          _mappedCategoryIds.remove(category.id);
                          _primaryCategoryIds.remove(category.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveMappings,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveMappings() async {
    try {
      // Delete all existing mappings
      await _supabase
          .from('event_type_categories')
          .delete()
          .eq('event_type_id', widget.eventTypeId);

      // Prepare new mappings
      final newMappings = _mappedCategoryIds.map((catId) {
        return {
          'event_type_id': widget.eventTypeId,
          'category_id': catId,
          'is_primary': _primaryCategoryIds.contains(catId),
        };
      }).toList();

      if (newMappings.isNotEmpty) {
        await _supabase.from('event_type_categories').insert(newMappings);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mappings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

/// Tab for analytics
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Category Analytics Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text('View popular categories and conversion rates'),
        ],
      ),
    );
  }
}

