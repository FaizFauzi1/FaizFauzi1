import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VendorScreensGalleryScreen extends StatelessWidget {
  const VendorScreensGalleryScreen({super.key});

  static const routeName = '/__debug/vendor-screens';

  static const List<_VendorRouteEntry> _routes = [
    _VendorRouteEntry('Vendor Dashboard', '/vendor-dashboard'),
    _VendorRouteEntry('Vendor Services', '/vendor-services'),
    _VendorRouteEntry('Vendor Booking Management', '/vendor-booking-management'),
    _VendorRouteEntry('Vendor Booking Status', '/vendor-booking-status'),
    _VendorRouteEntry('Vendor Finance', '/vendor-finance'),
    _VendorRouteEntry('Vendor Shop Performance', '/vendor-shop-performance'),
    _VendorRouteEntry('Vendor Marketing', '/vendor-marketing'),
    _VendorRouteEntry('Vendor Promotions', '/vendor-promotions'),
    _VendorRouteEntry('Vendor Analytics', '/vendor-analytics'),
    _VendorRouteEntry('Vendor Inventory', '/vendor-inventory'),
    _VendorRouteEntry('Vendor Customers', '/vendor-customers'),
    _VendorRouteEntry('Vendor Loyalty Programs', '/vendor-loyalty'),
    _VendorRouteEntry('Vendor Subscriptions', '/vendor-subscriptions'),
    _VendorRouteEntry('Vendor Support Tickets', '/vendor-support'),
    _VendorRouteEntry('Vendor Help Center', '/vendor-help'),
    _VendorRouteEntry('Vendor Settings', '/vendor-settings'),
    _VendorRouteEntry('Vendor Payment & Payout', '/vendor-payment-payout'),
    _VendorRouteEntry('Vendor Social Media Manager', '/vendor-social-media'),
    _VendorRouteEntry('Vendor QR Codes', '/vendor-qr-codes'),
    _VendorRouteEntry('Vendor Availability Management', '/vendor-availability-management'),
    _VendorRouteEntry('CRM Dashboard', '/crm-dashboard'),
    _VendorRouteEntry('Product/Service Demo', '/product-service-demo'),
    _VendorRouteEntry('Networking', '/networking'),
    _VendorRouteEntry('Find Partners', '/find-partners'),
    _VendorRouteEntry('Collaboration Requests', '/collaboration-requests'),
    _VendorRouteEntry('Package Builder', '/package-builder'),
    _VendorRouteEntry('Vendor Groups', '/vendor-groups'),
    _VendorRouteEntry('Marketplace', '/marketplace'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Screens (Debug)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                kDebugMode
                    ? 'Tap to open a route. Used by integration screenshot tests.'
                    : 'Debug-only screen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: _routes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _routes[index];
          return ListTile(
            title: Text(entry.title),
            subtitle: Text(entry.route),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed(entry.route),
          );
        },
      ),
    );
  }
}

class _VendorRouteEntry {
  final String title;
  final String route;
  const _VendorRouteEntry(this.title, this.route);
}

