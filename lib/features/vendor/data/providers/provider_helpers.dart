
  Future<void> _saveStructuredServiceData(String serviceId, VendorServiceEnhanced service) async {
    final client = Supabase.instance.client;

    // 1. Save Pricing Tiers
    await client.from('service_pricing_tiers').delete().eq('service_id', serviceId);
    if (service.pricingTiers.isNotEmpty) {
      await client.from('service_pricing_tiers').insert(
        service.pricingTiers.map((t) => {
          'service_id': serviceId,
          'name': t.name,
          'min_pax': t.minPax,
          'max_pax': t.maxPax,
          'price': t.price,
          'description': t.description ?? '',
        }).toList()
      );
    }

    // 2. Save Components & Items
    await client.from('service_components').delete().eq('service_id', serviceId);

    for (final component in service.components) {
      final compResponse = await client.from('service_components').insert({
        'service_id': serviceId,
        'name': component.name,
        'component_type': component.componentType,
      }).select().single();
      
      final componentId = compResponse['id'];

      if (component.items.isNotEmpty) {
        await client.from('service_items').insert(
          component.items.map((item) => {
            'component_id': componentId,
            'name': item.name,
            'quantity': item.quantity,
            'description': item.description ?? '',
            'unit_price': item.unitPrice,
          }).toList()
        );
      }
    }
  }

  Future<VendorServiceEnhanced> _loadStructuredServiceData(VendorServiceEnhanced service) async {
    final client = Supabase.instance.client;

    // Load tiers
    final tiersData = await client.from('service_pricing_tiers').select().eq('service_id', service.id);
    final tiers = (tiersData as List).map((t) => ServicePricingTier(
      id: t['id'],
      name: t['name'],
      minPax: t['min_pax'],
      maxPax: t['max_pax'],
      price: (t['price'] as num).toDouble(),
      description: t['description'],
    )).toList();

    // Load components
    final componentsData = await client.from('service_components').select('*, service_items(*)').eq('service_id', service.id);
    final components = (componentsData as List).map((c) {
      final itemsData = c['service_items'] as List;
      final items = itemsData.map((i) => ServiceItem(
        id: i['id'],
        name: i['name'],
        quantity: i['quantity'],
        unitPrice: (i['unit_price'] as num?)?.toDouble() ?? 0.0,
        description: i['description'],
      )).toList();

      return ServiceComponent(
        id: c['id'],
        name: c['name'],
        componentType: c['component_type'],
        items: items,
      );
    }).toList();

    return service.copyWith(
      pricingTiers: tiers,
      components: components,
    );
  }
