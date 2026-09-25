
void main() {
  final testCases = [
    'https://eventease-web.netlify.app/vendor/123',
    'https://eventease-web.netlify.app/service/456',
    'https://eventease-web.netlify.app/vendor/123/',
    'https://eventease-web.netlify.app/service/456/',
    'eventease://vendor/123',
    'eventease://service/456',
    ' https://eventease-web.netlify.app/vendor/123 ',
    'https://eventease-web.netlify.app/vendors/789',
    'https://eventease-web.netlify.app/services/012',
    'eventease://vendor/abc-def',
    'eventease://service/ghi-jkl',
  ];

  for (final rawCode in testCases) {
    print('Testing: "$rawCode"');
    final result = processQRCode(rawCode);
    print('Result: VendorId=${result['vendorId']}, ServiceId=${result['serviceId']}');
    print('---');
  }
}

Map<String, String?> processQRCode(String rawCode) {
  final String code = rawCode.trim();
  String? vendorId;
  String? serviceId;

  try {
    if (code.startsWith('eventease://')) {
      final uri = Uri.parse(code);
      if (uri.host == 'vendor') {
        vendorId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (vendorId == null || vendorId.isEmpty) {
           vendorId = uri.path.replaceAll('/', '');
        }
      } else if (uri.host == 'service') {
        serviceId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (serviceId == null || serviceId.isEmpty) {
           serviceId = uri.path.replaceAll('/', '');
        }
      }
    } else {
      final uri = Uri.parse(code);
      final segments = uri.pathSegments;
      
      final vendorIndex = segments.indexWhere((s) => s == 'vendor' || s == 'vendors');
      if (vendorIndex != -1 && vendorIndex + 1 < segments.length) {
        vendorId = segments[vendorIndex + 1];
      } 
      
      final serviceIndex = segments.indexWhere((s) => s == 'service' || s == 'services');
      if (serviceIndex != -1 && serviceIndex + 1 < segments.length) {
        serviceId = segments[serviceIndex + 1];
      }
    }

    vendorId = vendorId?.replaceAll('/', '')?.trim();
    serviceId = serviceId?.replaceAll('/', '')?.trim();
  } catch (e) {
    print('Error: $e');
  }

  return {'vendorId': vendorId, 'serviceId': serviceId};
}
