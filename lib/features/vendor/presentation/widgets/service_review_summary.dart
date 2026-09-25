import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendor_service_enhanced.dart';
import '../../../../shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/currency_formatter.dart';

class ServiceReviewSummary extends StatelessWidget {
  final VendorServiceEnhanced service;

  const ServiceReviewSummary({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Basic Information'),
          _buildDetailRow('Name', service.name),
          _buildDetailRow('Type', service.serviceType.name.toUpperCase()),
          _buildDetailRow('Category', service.productCategory.displayName),
          if (service.subcategory != null)
            _buildDetailRow('Subcategory', service.subcategory!),
          _buildDetailRow('Description', service.description),

          const Divider(),
          _buildSectionTitle('Pricing & Inventory'),
          _buildDetailRow('Base Price', '${CurrencyFormatter.symbol} ${service.price.toStringAsFixed(2)}'),
          if (service.originalPrice != null)
            _buildDetailRow('Original Price', '${CurrencyFormatter.symbol} ${service.originalPrice!.toStringAsFixed(2)}'),
          if (service.promoExpiry != null)
            _buildDetailRow('Promotion Ends', DateFormat('dd MMM yyyy').format(service.promoExpiry!)),
          
          if (service.multiLayerPricing.isNotEmpty) ...[
            _buildDetailRow('Multi-tier Pricing', ''),
            Wrap(
              spacing: 8,
              children: service.multiLayerPricing.entries.map((e) => Chip(
                label: Text('${e.key} Pax: ${CurrencyFormatter.symbol} ${e.value.toStringAsFixed(0)}'),
                backgroundColor: Colors.teal.withOpacity(0.1),
              )).toList(),
            ),
          ],

          if (service.pricingTiers.isNotEmpty) ...[
            const Divider(),
            _buildSectionTitle('Rates / Packages'),
            ...service.pricingTiers.map((tier) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tier.name ?? 'Unnamed Rate', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (tier.originalPrice != null && tier.originalPrice! > tier.price)
                              Text('${CurrencyFormatter.symbol} ${tier.originalPrice!.toStringAsFixed(2)}', 
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough, 
                                  color: Colors.grey, 
                                  fontSize: 11
                                )),
                            Text('${CurrencyFormatter.symbol} ${tier.price.toStringAsFixed(2)}', 
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: Colors.teal,
                                fontSize: 15
                              )),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tier.minPax > 0 || (tier.maxPax ?? 0) > 0)
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Pax: ${tier.minPax} - ${tier.maxPax ?? "Unlimited"}', 
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    if (tier.promoExpiry != null)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('Ends: ${DateFormat('dd MMM yyyy').format(tier.promoExpiry!)}', 
                            style: const TextStyle(fontSize: 12, color: Colors.orange)),
                        ],
                      ),
                    if (tier.description != null && tier.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(tier.description!, 
                        style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            )),
          ],

          if (service.components.isNotEmpty) ...[
            const Divider(),
            _buildSectionTitle('What\'s Included'),
            ...service.components.map((comp) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(comp.name.toUpperCase(), 
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.teal.shade700,
                      letterSpacing: 1.1
                    )),
                ),
                ...comp.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${item.quantity}x ', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Expanded(
                                  child: Text(item.name, 
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                                if (item.unitPrice > 0)
                                  Text('${CurrencyFormatter.symbol} ${item.unitPrice.toStringAsFixed(2)}', 
                                    style: const TextStyle(fontSize: 12, color: Colors.teal)),
                              ],
                            ),
                            if (item.description != null && item.description!.isNotEmpty)
                              Text(item.description!, 
                                style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            if (item.galleryUrls.isNotEmpty || item.newGalleryFiles != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('📸 ${(item.galleryUrls.length + (item.newGalleryFiles?.length ?? 0))} photos included',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                              ),
                            if (item.pdfUrl != null || item.newPdfFile != null)
                              const Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('📄 Document attached',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 8),
              ],
            )),
          ],

          if (service.serviceType == ServiceType.product)
            _buildDetailRow('Stock Quantity', service.inventory.toString()),

          const Divider(),
          _buildSectionTitle('Location & Logistics'),
          if (service.venueAddress != null && service.venueAddress!.isNotEmpty)
            _buildDetailRow('Venue Address', service.venueAddress!),
          if (service.coverageArea != null && service.coverageArea!.isNotEmpty)
            _buildDetailRow('Coverage Area', service.coverageArea!),
          if (service.supportsRentals)
            _buildDetailRow('Rental Supported', 'Yes'),
          
          const Divider(),
          _buildSectionTitle('Policies'),
          _buildDetailRow('Cancellation', 
             service.cancellationPolicyType == 'platform' 
               ? 'Platform Default Policy' 
               : (service.cancellationPolicy ?? 'Not specified')),
          
          if (service.options.containsKey('attributes')) ...[
            const Divider(),
            _buildSectionTitle('Category Specific Details'),
            ...(service.options['attributes'] as Map<String, dynamic>).entries.map((e) => 
              _buildDetailRow(e.key, e.value.toString())
            ),
          ],

          if (service.options.containsKey('variations')) ...[
            const Divider(),
            _buildSectionTitle('Variations'),
            ...(service.options['variations'] as Map<String, dynamic>).entries.map((e) {
              final data = e.value as Map<String, dynamic>;
              final options = (data['options'] as List).join(', ');
              return _buildDetailRow(e.key, options);
            }),
          ],

          if (service.options.containsKey('addOns')) ...[
            const Divider(),
            _buildSectionTitle('Add-Ons'),
            ...(service.options['addOns'] as Map<String, dynamic>).entries.map((e) {
              final data = e.value as Map<String, dynamic>;
              return _buildDetailRow(e.key, '${CurrencyFormatter.symbol} ${data['price']} - ${data['description']}');
            }),
          ],

          if (service.serviceType == ServiceType.package) ...[
            const Divider(),
            _buildSectionTitle('Package Details'),
            if (service.options.containsKey('includedServices'))
              _buildDetailRow('Included Services', (service.options['includedServices'] as List).join(', ')),
            if (service.options.containsKey('selectedExistingServices'))
              _buildDetailRow('Existing Services', (service.options['selectedExistingServices'] as List).join(', ')),
          ],

          const Divider(),
          _buildSectionTitle('Availability'),
          _buildAvailabilitySummary(),
          
          if (service.images.isNotEmpty) ...[
            const Divider(),
            _buildSectionTitle('Media'),
            Text('${service.images.length} images uploaded', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: service.images.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(service.images[index], width: 100, height: 100, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySummary() {
    final availableDays = <String>[];
    service.availability.forEach((day, data) {
      if (data['available'] == true) {
        availableDays.add(day[0].toUpperCase() + day.substring(1, 3));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Days', availableDays.isEmpty ? 'None' : availableDays.join(', ')),
        if (service.options.containsKey('timeSlots')) ...[
          _buildDetailRow('Time Slots', ''),
          ...(service.options['timeSlots'] as List).map((slot) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text('${slot['name']}: ${slot['start']} - ${slot['end']} (${CurrencyFormatter.symbol} ${slot['price']})',
              style: const TextStyle(fontSize: 12)),
          )),
        ],
      ],
    );
  }
}
