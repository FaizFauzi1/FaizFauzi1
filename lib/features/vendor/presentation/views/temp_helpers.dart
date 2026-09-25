
  // --- Service Template Helpers ---

  Widget _buildPricingTiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tiered Pricing Structure",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_pricingTiers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No pricing tiers added. Add tiers to define pricing for different guest counts (e.g. 500 pax vs 1000 pax).", style: TextStyle(color: Colors.grey)),
          ),
        ..._pricingTiers.mapIndexed((index, tier) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(tier.name ?? "${tier.minPax} - ${tier.maxPax ?? 'Up'} Pax"),
              subtitle: Text("Price: RM ${tier.price.toStringAsFixed(2)}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _pricingTiers.removeAt(index)),
              ),
            ),
          );
        }).toList(),
        OutlinedButton.icon(
          onPressed: _addPricingTierDialog,
          icon: const Icon(Icons.add),
          label: const Text("Add Pricing Tier"),
        ),
      ],
    );
  }

  Future<void> _addPricingTierDialog() async {
    final minPaxCtrl = TextEditingController();
    final maxPaxCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final nameCtrl = TextEditingController(); // Optional name

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Pricing Tier"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tier Name (Optional, e.g. Silver Package)")),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: minPaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Min Pax"))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: maxPaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Max Pax (Empty for ∞)"))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Price (RM)", prefixText: "RM ")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (minPaxCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                setState(() {
                  _pricingTiers.add(ServicePricingTier(
                    name: nameCtrl.text.isEmpty ? null : nameCtrl.text,
                    minPax: int.tryParse(minPaxCtrl.text) ?? 0,
                    maxPax: int.tryParse(maxPaxCtrl.text),
                    price: double.tryParse(priceCtrl.text) ?? 0.0,
                    description: "Tier for ${minPaxCtrl.text} pax",
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Package Components",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text("Define what is included in this package (Decoration, Catering, etc.)", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        
        ..._components.mapIndexed((index, component) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text("${component.componentType.toUpperCase()}: ${component.name}"),
              subtitle: Text("${component.items.length} items included"),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ...component.items.mapIndexed((itemIndex, item) => ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text("Qty: ${item.quantity}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              component.items.removeAt(itemIndex);
                            });
                          },
                        ),
                      )).toList(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _addItemDialog(component),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Add Item"),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _components.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                            label: const Text("Remove Component"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        OutlinedButton.icon(
          onPressed: _addComponentDialog,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Add Component Category"),
        ),
      ],
    );
  }
  
  Future<void> _addComponentDialog() async {
    final nameCtrl = TextEditingController();
    String selectedType = 'decoration'; 
    final types = ['decoration', 'catering', 'hall', 'photography', 'makeup', 'apparel', 'sound', 'emcee', 'gift', 'invitation', 'other'];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Component"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "Component Type"),
                  items: types.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Component Name (e.g. Main Hall Decor)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _components.add(ServiceComponent(
                      componentType: selectedType,
                      name: nameCtrl.text,
                      items: [],
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItemDialog(ServiceComponent component) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Item to ${component.name}"),
        content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
                const SizedBox(height: 8),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantity")),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description (Optional)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    component.items.add(ServiceItem(
                      name: nameCtrl.text,
                      quantity: int.tryParse(qtyCtrl.text) ?? 1,
                      description: descCtrl.text,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
    );
  }
