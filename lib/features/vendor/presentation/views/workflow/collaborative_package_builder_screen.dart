import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollaborativePackageBuilderScreen extends StatefulWidget {
  final CollaborativePackage? existingPackage;

  const CollaborativePackageBuilderScreen({super.key, this.existingPackage});

  @override
  State<CollaborativePackageBuilderScreen> createState() => _CollaborativePackageBuilderScreenState();
}

class _CollaborativePackageBuilderScreenState extends State<CollaborativePackageBuilderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _basePriceController = TextEditingController();
  List<String> _selectedEventTypes = [];
  final List<PackageComponent> _components = [];
  List<String> _eventOptions = [];

  @override
  void initState() {
    super.initState();
    _loadEventTypes();
    if (widget.existingPackage != null) {
      final p = widget.existingPackage!;
      _titleController.text = p.title;
      _descController.text = p.description;
      _basePriceController.text = p.basePrice.toStringAsFixed(0);
      _selectedEventTypes = List.from(p.eventTypes);
      _components.addAll(p.components);
    }
  }

  Future<void> _loadEventTypes() async {
    try {
      final response = await Supabase.instance.client
          .from('event_types')
          .select()
          .order('display_order');
      final eventTypes = (response as List)
          .where((row) => (row['is_enabled'] ?? row['is_active'] ?? true) == true)
          .map((row) => (row['display_name'] ?? row['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();
      if (mounted) setState(() => _eventOptions = eventTypes);
    } catch (e) {
      debugPrint('Failed to load package event types: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  void _savePackage() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a package title')),
      );
      return;
    }

    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    final packageId = widget.existingPackage?.id ?? 'pkg-collab-${DateTime.now().millisecondsSinceEpoch}';
    final basePrice = double.tryParse(_basePriceController.text.trim());
    if (basePrice == null || basePrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid package price.')),
      );
      return;
    }

    final pkg = CollaborativePackage(
      id: packageId,
      ownerVendorId: provider.currentVendorId,
      ownerVendorName: provider.currentVendorName,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      eventTypes: _selectedEventTypes,
      basePrice: basePrice,
      components: _components,
      isPublished: true,
    );

    provider.savePackage(pkg);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.successColor,
        content: Text('Package "${pkg.title}" saved successfully!'),
      ),
    );

    Navigator.pop(context);
  }

  int get _readyCount => _components.where((c) => c.isReady).length;

  void _showAddComponentDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final allowanceCtrl = TextEditingController();
    ServiceCategoryType selectedCategory = ServiceCategoryType.decoration;
    bool isFixed = false;
    ComponentSelectionRule selRule = ComponentSelectionRule.exactlyOne;
    ComponentAppointmentRule apptRule = ComponentAppointmentRule.optionalAppointment;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Package Component', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Component Name *', hintText: 'e.g. Wedding Cake, Stage Decor'),
                ),
                const SizedBox(height: 10),
                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<ServiceCategoryType>(
                  value: selectedCategory,
                  items: ServiceCategoryType.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: allowanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Package Allowance (RM) *', hintText: 'Budget portion allocated'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Component Description'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Fixed Vendor Component', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Customer cannot change the vendor for this component.', style: TextStyle(fontSize: 11)),
                  value: isFixed,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isFixed = val),
                ),
                const SizedBox(height: 10),
                const Text('Selection Rule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<ComponentSelectionRule>(
                  value: selRule,
                  items: ComponentSelectionRule.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selRule = val);
                  },
                ),
                const SizedBox(height: 10),
                const Text('Appointment Requirement Rule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<ComponentAppointmentRule>(
                  value: apptRule,
                  items: ComponentAppointmentRule.values
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => apptRule = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final allowance = double.tryParse(allowanceCtrl.text.trim());
                if (nameCtrl.text.trim().isNotEmpty &&
                    allowance != null &&
                    allowance >= 0) {
                  setState(() {
                    _components.add(
                      PackageComponent(
                        id: 'comp-${DateTime.now().millisecondsSinceEpoch}',
                        componentName: nameCtrl.text.trim(),
                        category: selectedCategory,
                        description: descCtrl.text.trim(),
                        isFixedVendor: isFixed,
                        selectionRule: selRule,
                        appointmentRule: apptRule,
                        packageAllowance: allowance,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a component name and valid allowance.'),
                    ),
                  );
                }
              },
              child: const Text('Add Component'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCollaboratorModal(PackageComponent comp) async {
    final networkingProvider =
        Provider.of<VendorNetworkingProvider>(context, listen: false);
    if (networkingProvider.allVendors.isEmpty) {
      await networkingProvider.loadDiscoveryVendors();
    }
    if (!mounted) return;

    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final workflowProvider =
              Provider.of<VendorWorkflowProvider>(ctx, listen: false);
          final vendors = networkingProvider
              .searchVendors(query)
              .where((vendor) => vendor.id != workflowProvider.currentVendorId)
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite Collaborator: ${comp.componentName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Role: ${comp.category.displayName} · Allowance: RM ${comp.packageAllowance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchCtrl,
                  onChanged: (v) => setModalState(() => query = v),
                  decoration: InputDecoration(
                    hintText: 'Search vendors by name or location...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Recommended Vendors in Network:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: vendors.isEmpty ? 1 : vendors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (vendors.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No other vendors found.')),
                        );
                      }
                      final vendor = vendors[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: comp.category.brandColor.withOpacity(0.1),
                              child: Icon(comp.category.iconData, color: comp.category.brandColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 12, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text('${vendor.rating.toStringAsFixed(1)} · ${vendor.location}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () {
                                    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
                                    provider.sendCollaboratorInvitation(
                                      CollaboratorInvitation(
                                        id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
                                        packageId: widget.existingPackage?.id ?? 'pkg-new',
                                        packageName: _titleController.text.trim(),
                                        ownerVendorId: provider.currentVendorId,
                                        ownerVendorName: provider.currentVendorName,
                                        targetVendorId: vendor.id,
                                        targetVendorName: vendor.name,
                                        roleCategory: comp.category,
                                        roleComponentName: comp.componentName,
                                        eventDate: '',
                                        location: '',
                                        packageAllowance: comp.packageAllowance,
                                        requestedAppointmentTypes: const [],
                                      ),
                                    );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.successColor,
                                        content: Text('Invitation created for ${vendor.name}.'),
                                      ),
                                    );
                                  },
                                  child: const Text('Send Invitation'),
                                ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Collaborative Package Builder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton.icon(
            onPressed: _savePackage,
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
            label: const Text('Publish Package', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Readiness Tracker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Package Readiness Status',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '$_readyCount of ${_components.length} components ready',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _components.isEmpty ? 0 : _readyCount / _components.length,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Collaborators must accept invitations and submit their services before the component becomes active.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Package Details Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Package Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Package Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _basePriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Base Package Price (RM) *', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Package Overview & Customer Value Proposition', border: OutlineInputBorder()),
                  ),
                  if (_eventOptions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Event Types', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _eventOptions.map((eventType) {
                        return FilterChip(
                          label: Text(eventType),
                          selected: _selectedEventTypes.contains(eventType),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedEventTypes.add(eventType);
                              } else {
                                _selectedEventTypes.remove(eventType);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Components List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Package Components', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'Fixed vendors, customer choices, allowances and appointment requirements',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showAddComponentDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Component'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Components Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _components.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final comp = _components[index];
                return _buildComponentCard(comp, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentCard(PackageComponent comp, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comp.isReady ? AppTheme.borderColor : Colors.amber.shade300,
          width: comp.isReady ? 1.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: comp.category.brandColor.withOpacity(0.12),
                    child: Icon(comp.category.iconData, color: comp.category.brandColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comp.componentName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: comp.isFixedVendor ? Colors.blue.shade50 : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  comp.isFixedVendor ? 'Fixed Vendor' : 'Customer Choice',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: comp.isFixedVendor ? Colors.blue.shade700 : Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comp.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 10),

          // Metadata Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text('Allowance: RM ${comp.packageAllowance.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: comp.appointmentRule.badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 11, color: comp.appointmentRule.badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      comp.appointmentRule.displayName,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: comp.appointmentRule.badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Collaborators List for this component
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Approved Options (${comp.approvedCollaborators.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (!comp.isFixedVendor)
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _showAddCollaboratorModal(comp),
                  icon: const Icon(Icons.person_add_alt_1, size: 14),
                  label: const Text('+ Add Collaborator', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 6),

          ...comp.approvedCollaborators.map((collab) {
            final deltaText = collab.priceDelta == 0
                ? 'Included'
                : collab.priceDelta > 0
                    ? '+RM ${collab.priceDelta.toStringAsFixed(0)}'
                    : '-RM ${collab.priceDelta.abs().toStringAsFixed(0)}';

            final deltaColor = collab.priceDelta > 0
                ? Colors.amber.shade900
                : collab.priceDelta < 0
                    ? Colors.green.shade800
                    : AppTheme.primaryColor;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Text(collab.vendorName[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(collab.vendorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('${collab.serviceName} · RM ${collab.partnerPrice.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (collab.appointmentOptions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        '${collab.appointmentOptions.length} appts',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      deltaText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deltaColor),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _components.removeAt(index));
                },
                child: const Text('Remove Component', style: TextStyle(color: AppTheme.errorColor, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
