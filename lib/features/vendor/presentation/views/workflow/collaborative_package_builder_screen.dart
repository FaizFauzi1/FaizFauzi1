import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';

class CollaborativePackageBuilderScreen extends StatefulWidget {
  final CollaborativePackage? existingPackage;

  const CollaborativePackageBuilderScreen({super.key, this.existingPackage});

  @override
  State<CollaborativePackageBuilderScreen> createState() => _CollaborativePackageBuilderScreenState();
}

class _CollaborativePackageBuilderScreenState extends State<CollaborativePackageBuilderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _basePriceController = TextEditingController(text: '25000');
  List<String> _selectedEventTypes = ['Wedding'];
  final List<PackageComponent> _components = [];

  final List<String> _eventOptions = ['Wedding', 'Corporate Gala', 'Birthday Celebration', 'Anniversary'];

  @override
  void initState() {
    super.initState();
    if (widget.existingPackage != null) {
      final p = widget.existingPackage!;
      _titleController.text = p.title;
      _descController.text = p.description;
      _basePriceController.text = p.basePrice.toStringAsFixed(0);
      _selectedEventTypes = List.from(p.eventTypes);
      _components.addAll(p.components);
    } else {
      _titleController.text = 'Premium Royal Wedding Package';
      _descController.text =
          'Curated luxury wedding package featuring Grand Hall Ballroom, authentic 10-course banquet catering, stage decor, and handpicked customer choices for photography, makeup, and wedding cake.';
      _initDefaultComponents();
    }
  }

  void _initDefaultComponents() {
    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    _components.addAll([
      PackageComponent(
        id: 'comp-1-venue',
        componentName: 'Grand Ballroom Venue',
        category: ServiceCategoryType.venue,
        description: 'Ballroom access for up to 500 guests with 4K LED Screen & AV.',
        isFixedVendor: true,
        selectionRule: ComponentSelectionRule.exactlyOne,
        appointmentRule: ComponentAppointmentRule.requiredBeforeBooking,
        packageAllowance: 6000.0,
        approvedCollaborators: [
          CollaboratorOption(
            vendorId: provider.currentVendorId,
            vendorName: provider.currentVendorName,
            serviceId: 'srv-venue-1',
            serviceName: 'The Grand Imperial Ballroom',
            partnerPrice: 6000.0,
            priceDelta: 0.0,
            appointmentOptions: [
              ServiceAppointmentType(
                id: 'apt-sv-1',
                serviceId: 'srv-venue-1',
                name: 'Venue Site Visit',
                description: 'Guided tour of ballroom, backstage, and AV equipment.',
                purpose: AppointmentPurpose.visit,
                durationMinutes: 60,
                location: 'Grand Hall Level 2',
              ),
            ],
          ),
        ],
        selectedCollaboratorId: provider.currentVendorId,
      ),
      PackageComponent(
        id: 'comp-2-catering',
        componentName: 'Banquet Catering (300 pax)',
        category: ServiceCategoryType.catering,
        description: '10-course authentic banquet buffet with servers and chafing dishes.',
        isFixedVendor: true,
        selectionRule: ComponentSelectionRule.exactlyOne,
        appointmentRule: ComponentAppointmentRule.recommendedAppointment,
        packageAllowance: 10000.0,
        approvedCollaborators: [
          CollaboratorOption(
            vendorId: provider.currentVendorId,
            vendorName: 'ABC Catering & Culinary Co.',
            serviceId: 'srv-catering-1',
            serviceName: 'Grand Royal Banquet Catering',
            partnerPrice: 10000.0,
            priceDelta: 0.0,
            appointmentOptions: [
              ServiceAppointmentType(
                id: 'apt-taste-1',
                serviceId: 'srv-catering-1',
                name: 'Food Tasting Session',
                description: 'Sample 6 signature dishes in Damansara studio.',
                purpose: AppointmentPurpose.tasting,
                durationMinutes: 60,
                fee: 100.0,
                isPaid: true,
                creditTowardBooking: true,
              ),
            ],
          ),
        ],
        selectedCollaboratorId: provider.currentVendorId,
      ),
      PackageComponent(
        id: 'comp-3-photo',
        componentName: 'Wedding Photography',
        category: ServiceCategoryType.photography,
        description: 'Full day photography coverage with edited high-res digital albums.',
        isFixedVendor: false, // Customer Choice!
        selectionRule: ComponentSelectionRule.exactlyOne,
        appointmentRule: ComponentAppointmentRule.optionalAppointment,
        packageAllowance: 3000.0,
        approvedCollaborators: [
          CollaboratorOption(
            vendorId: 'v-201',
            vendorName: 'Pixel & Lens Weddings',
            rating: 4.9,
            reviewsCount: 88,
            serviceId: 'srv-photo-1',
            serviceName: 'Essential Storyteller (8 hrs)',
            partnerPrice: 3000.0,
            priceDelta: 0.0,
          ),
          CollaboratorOption(
            vendorId: 'v-202',
            vendorName: 'Artisan Moments Co.',
            rating: 5.0,
            reviewsCount: 114,
            serviceId: 'srv-photo-artisan',
            serviceName: 'Dual Cinema Master (10 hrs)',
            partnerPrice: 3300.0,
            priceDelta: 300.0,
          ),
          CollaboratorOption(
            vendorId: 'v-203',
            vendorName: 'Lina Visuals',
            rating: 4.8,
            reviewsCount: 45,
            serviceId: 'srv-photo-lina',
            serviceName: 'Standard Wedding Coverage',
            partnerPrice: 2800.0,
            priceDelta: -200.0,
          ),
        ],
        selectedCollaboratorId: 'v-201',
      ),
      PackageComponent(
        id: 'comp-4-makeup',
        componentName: 'Bridal Makeup & Styling',
        category: ServiceCategoryType.makeupAndBeauty,
        description: 'Professional bridal makeup and hairstyling on wedding day.',
        isFixedVendor: false, // Customer Choice!
        selectionRule: ComponentSelectionRule.exactlyOne,
        appointmentRule: ComponentAppointmentRule.recommendedAppointment,
        packageAllowance: 800.0,
        approvedCollaborators: [
          CollaboratorOption(
            vendorId: 'v-401',
            vendorName: 'Glam Studio & Hair Artistry',
            rating: 4.9,
            serviceId: 'srv-makeup-1',
            serviceName: 'Bridal Makeup & Styling',
            partnerPrice: 800.0,
            priceDelta: 0.0,
            appointmentOptions: [
              ServiceAppointmentType(
                id: 'apt-trial-glam',
                serviceId: 'srv-makeup-1',
                name: 'Makeup Trial',
                description: 'Full airbrush & hair trial.',
                purpose: AppointmentPurpose.trial,
                durationMinutes: 90,
                fee: 150.0,
                isPaid: true,
                creditTowardBooking: true,
              ),
            ],
          ),
          CollaboratorOption(
            vendorId: 'v-402',
            vendorName: 'Beauty by Sarah',
            rating: 4.9,
            serviceId: 'srv-sarah-makeup',
            serviceName: 'Signature Airbrush Glam',
            partnerPrice: 850.0,
            priceDelta: 50.0,
            appointmentOptions: [
              ServiceAppointmentType(
                id: 'apt-sarah-trial',
                serviceId: 'srv-sarah-makeup',
                name: 'Airbrush Makeup Trial',
                description: 'Lash styling & airbrush session.',
                purpose: AppointmentPurpose.trial,
                durationMinutes: 90,
                fee: 150.0,
                isPaid: true,
                creditTowardBooking: true,
              ),
            ],
          ),
          CollaboratorOption(
            vendorId: 'v-403',
            vendorName: 'Makeup Pro Studio',
            rating: 5.0,
            serviceId: 'srv-pro-makeup',
            serviceName: 'Celebrity Bridal Glam',
            partnerPrice: 1000.0,
            priceDelta: 200.0,
          ),
          CollaboratorOption(
            vendorId: 'v-404',
            vendorName: 'Lina Beauty Studio',
            rating: 4.7,
            serviceId: 'srv-lina-makeup',
            serviceName: 'Natural Glow Look',
            partnerPrice: 750.0,
            priceDelta: -50.0,
          ),
        ],
        selectedCollaboratorId: 'v-401',
      ),
    ]);
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
    final basePrice = double.tryParse(_basePriceController.text) ?? 25000.0;

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
    final allowanceCtrl = TextEditingController(text: '1500');
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
                if (nameCtrl.text.isNotEmpty) {
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
                        packageAllowance: double.tryParse(allowanceCtrl.text) ?? 1000.0,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Component'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCollaboratorModal(PackageComponent comp) {
    final searchCtrl = TextEditingController();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final sampleVendors = [
            {
              'id': 'v-801',
              'name': 'Bloom Flora Artistry',
              'rating': 4.9,
              'category': comp.category.displayName,
              'location': 'Kuala Lumpur',
              'price': comp.packageAllowance,
            },
            {
              'id': 'v-802',
              'name': 'Elite Luxe Studio',
              'rating': 5.0,
              'category': comp.category.displayName,
              'location': 'Petaling Jaya',
              'price': comp.packageAllowance + 150,
            },
            {
              'id': 'v-803',
              'name': 'Urban Event Specialists',
              'rating': 4.8,
              'category': comp.category.displayName,
              'location': 'Shah Alam',
              'price': comp.packageAllowance - 100,
            },
          ];

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
                    itemCount: sampleVendors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final v = sampleVendors[index];
                      final price = v['price'] as double;
                      final delta = price - comp.packageAllowance;

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
                                  Text(v['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 12, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text('${v['rating']} · ${v['location']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  delta == 0
                                      ? 'RM ${price.toStringAsFixed(0)} (Included)'
                                      : delta > 0
                                          ? 'RM ${price.toStringAsFixed(0)} (+RM${delta.toStringAsFixed(0)})'
                                          : 'RM ${price.toStringAsFixed(0)} (-RM${delta.abs().toStringAsFixed(0)})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: delta > 0 ? Colors.amber.shade800 : Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                        targetVendorId: v['id'] as String,
                                        targetVendorName: v['name'] as String,
                                        roleCategory: comp.category,
                                        roleComponentName: comp.componentName,
                                        eventDate: 'Flexible 2026',
                                        location: 'Kuala Lumpur',
                                        packageAllowance: comp.packageAllowance,
                                        requestedAppointmentTypes: ['Consultation / Trial'],
                                      ),
                                    );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppTheme.successColor,
                                        content: Text('Collaboration invitation dispatched to ${v['name']}!'),
                                      ),
                                    );
                                  },
                                  child: const Text('Send Invitation'),
                                ),
                              ],
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
