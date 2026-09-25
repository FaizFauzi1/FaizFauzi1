import 'dart:convert';
import 'package:http/http.dart' as http;

enum ShippingProvider {
  posLaju,
  gdex,
  jnt,
  dhl,
  fedex,
  ups
}

enum ShippingType {
  standard,
  express,
  overnight,
  sameDay
}

class ShippingRate {
  final String provider;
  final ShippingType type;
  final double cost;
  final int estimatedDays;
  final String description;
  final bool isAvailable;

  ShippingRate({
    required this.provider,
    required this.type,
    required this.cost,
    required this.estimatedDays,
    required this.description,
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'type': type.toString(),
      'cost': cost,
      'estimatedDays': estimatedDays,
      'description': description,
      'isAvailable': isAvailable,
    };
  }

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      provider: json['provider'],
      type: ShippingType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ShippingType.standard,
      ),
      cost: json['cost'].toDouble(),
      estimatedDays: json['estimatedDays'],
      description: json['description'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}

class ShippingService {
  // API endpoints for different shipping providers
  static const String _posLajuApiUrl = 'https://api.poslaju.com.my/rates';
  static const String _gdexApiUrl = 'https://api.gdexpress.com/rates';
  static const String _jntApiUrl = 'https://api.jtexpress.my/rates';

  // API keys (replace with actual keys)
  static const String _posLajuApiKey = 'your_poslaju_api_key';
  static const String _gdexApiKey = 'your_gdex_api_key';
  static const String _jntApiKey = 'your_jnt_api_key';

  // Calculate shipping rates based on weight, dimensions, and destination
  static Future<List<ShippingRate>> calculateShippingRates({
    required double weightKg,
    required Map<String, double> dimensions, // width, height, length in cm
    required String originPostalCode,
    required String destinationPostalCode,
    required String country,
  }) async {
    List<ShippingRate> rates = [];

    try {
      // Get rates from multiple providers concurrently
      final results = await Future.wait([
        _getPosLajuRates(weightKg, dimensions, originPostalCode, destinationPostalCode),
        _getGdexRates(weightKg, dimensions, originPostalCode, destinationPostalCode),
        _getJNTRates(weightKg, dimensions, originPostalCode, destinationPostalCode),
        _getInternationalRates(weightKg, dimensions, country),
      ]);

      // Flatten results
      for (final providerRates in results) {
        rates.addAll(providerRates);
      }

      // Sort by cost
      rates.sort((a, b) => a.cost.compareTo(b.cost));

    } catch (e) {
      // Fallback to default rates if API calls fail
      rates = _getDefaultShippingRates(weightKg);
    }

    return rates;
  }

  // Get Pos Laju shipping rates
  static Future<List<ShippingRate>> _getPosLajuRates(
    double weightKg,
    Map<String, double> dimensions,
    String originPostalCode,
    String destinationPostalCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_posLajuApiUrl),
        headers: {
          'Authorization': 'Bearer $_posLajuApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'weight': weightKg,
          'dimensions': dimensions,
          'origin_postal_code': originPostalCode,
          'destination_postal_code': destinationPostalCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePosLajuResponse(data);
      } else {
        return _getDefaultPosLajuRates(weightKg);
      }
    } catch (e) {
      return _getDefaultPosLajuRates(weightKg);
    }
  }

  // Get GDEX shipping rates
  static Future<List<ShippingRate>> _getGdexRates(
    double weightKg,
    Map<String, double> dimensions,
    String originPostalCode,
    String destinationPostalCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_gdexApiUrl),
        headers: {
          'Authorization': 'Bearer $_gdexApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'weight': weightKg,
          'dimensions': dimensions,
          'origin_postal_code': originPostalCode,
          'destination_postal_code': destinationPostalCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGdexResponse(data);
      } else {
        return _getDefaultGdexRates(weightKg);
      }
    } catch (e) {
      return _getDefaultGdexRates(weightKg);
    }
  }

  // Get JNT shipping rates
  static Future<List<ShippingRate>> _getJNTRates(
    double weightKg,
    Map<String, double> dimensions,
    String originPostalCode,
    String destinationPostalCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_jntApiUrl),
        headers: {
          'Authorization': 'Bearer $_jntApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'weight': weightKg,
          'dimensions': dimensions,
          'origin_postal_code': originPostalCode,
          'destination_postal_code': destinationPostalCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseJNTResponse(data);
      } else {
        return _getDefaultJNTRates(weightKg);
      }
    } catch (e) {
      return _getDefaultJNTRates(weightKg);
    }
  }

  // Get international shipping rates
  static Future<List<ShippingRate>> _getInternationalRates(
    double weightKg,
    Map<String, double> dimensions,
    String country,
  ) async {
    // For international shipping, use DHL/FedEx rates
    List<ShippingRate> rates = [];

    // DHL rates
    rates.addAll(_getDefaultDHLRates(weightKg, country));

    // FedEx rates
    rates.addAll(_getDefaultFedExRates(weightKg, country));

    return rates;
  }

  // Parse responses from different providers
  static List<ShippingRate> _parsePosLajuResponse(Map<String, dynamic> data) {
    List<ShippingRate> rates = [];
    if (data['rates'] != null) {
      for (final rate in data['rates']) {
        rates.add(ShippingRate(
          provider: 'Pos Laju',
          type: _parseShippingType(rate['service_type']),
          cost: rate['price'].toDouble(),
          estimatedDays: rate['estimated_days'],
          description: rate['description'] ?? 'Pos Laju delivery',
        ));
      }
    }
    return rates.isNotEmpty ? rates : _getDefaultPosLajuRates(1.0);
  }

  static List<ShippingRate> _parseGdexResponse(Map<String, dynamic> data) {
    List<ShippingRate> rates = [];
    if (data['rates'] != null) {
      for (final rate in data['rates']) {
        rates.add(ShippingRate(
          provider: 'GDEX',
          type: _parseShippingType(rate['service_type']),
          cost: rate['price'].toDouble(),
          estimatedDays: rate['estimated_days'],
          description: rate['description'] ?? 'GDEX delivery',
        ));
      }
    }
    return rates.isNotEmpty ? rates : _getDefaultGdexRates(1.0);
  }

  static List<ShippingRate> _parseJNTResponse(Map<String, dynamic> data) {
    List<ShippingRate> rates = [];
    if (data['rates'] != null) {
      for (final rate in data['rates']) {
        rates.add(ShippingRate(
          provider: 'J&T Express',
          type: _parseShippingType(rate['service_type']),
          cost: rate['price'].toDouble(),
          estimatedDays: rate['estimated_days'],
          description: rate['description'] ?? 'J&T Express delivery',
        ));
      }
    }
    return rates.isNotEmpty ? rates : _getDefaultJNTRates(1.0);
  }

  static ShippingType _parseShippingType(String type) {
    switch (type.toLowerCase()) {
      case 'express':
      case 'next_day':
        return ShippingType.express;
      case 'overnight':
        return ShippingType.overnight;
      case 'same_day':
        return ShippingType.sameDay;
      default:
        return ShippingType.standard;
    }
  }

  // Default fallback rates (public method for external access)
  static List<ShippingRate> getDefaultShippingRates(double weightKg) {
    return _getDefaultShippingRates(weightKg);
  }

  // Default fallback rates
  static List<ShippingRate> _getDefaultShippingRates(double weightKg) {
    return [
      ShippingRate(
        provider: 'Standard Delivery',
        type: ShippingType.standard,
        cost: 8.50 + (weightKg * 2.0),
        estimatedDays: 3,
        description: '3-5 business days delivery',
      ),
      ShippingRate(
        provider: 'Express Delivery',
        type: ShippingType.express,
        cost: 15.00 + (weightKg * 3.0),
        estimatedDays: 1,
        description: 'Next business day delivery',
      ),
    ];
  }

  static List<ShippingRate> _getDefaultPosLajuRates(double weightKg) {
    return [
      ShippingRate(
        provider: 'Pos Laju',
        type: ShippingType.standard,
        cost: 6.00 + (weightKg * 1.5),
        estimatedDays: 2,
        description: 'Pos Laju standard delivery',
      ),
      ShippingRate(
        provider: 'Pos Laju',
        type: ShippingType.express,
        cost: 12.00 + (weightKg * 2.5),
        estimatedDays: 1,
        description: 'Pos Laju express delivery',
      ),
    ];
  }

  static List<ShippingRate> _getDefaultGdexRates(double weightKg) {
    return [
      ShippingRate(
        provider: 'GDEX',
        type: ShippingType.standard,
        cost: 7.50 + (weightKg * 1.8),
        estimatedDays: 2,
        description: 'GDEX standard delivery',
      ),
      ShippingRate(
        provider: 'GDEX',
        type: ShippingType.express,
        cost: 14.00 + (weightKg * 2.8),
        estimatedDays: 1,
        description: 'GDEX express delivery',
      ),
    ];
  }

  static List<ShippingRate> _getDefaultJNTRates(double weightKg) {
    return [
      ShippingRate(
        provider: 'J&T Express',
        type: ShippingType.standard,
        cost: 5.50 + (weightKg * 1.2),
        estimatedDays: 2,
        description: 'J&T Express standard delivery',
      ),
      ShippingRate(
        provider: 'J&T Express',
        type: ShippingType.express,
        cost: 11.00 + (weightKg * 2.2),
        estimatedDays: 1,
        description: 'J&T Express express delivery',
      ),
    ];
  }

  static List<ShippingRate> _getDefaultDHLRates(double weightKg, String country) {
    return [
      ShippingRate(
        provider: 'DHL',
        type: ShippingType.express,
        cost: 25.00 + (weightKg * 5.0),
        estimatedDays: 3,
        description: 'DHL international express to $country',
      ),
    ];
  }

  static List<ShippingRate> _getDefaultFedExRates(double weightKg, String country) {
    return [
      ShippingRate(
        provider: 'FedEx',
        type: ShippingType.express,
        cost: 28.00 + (weightKg * 5.5),
        estimatedDays: 3,
        description: 'FedEx international express to $country',
      ),
    ];
  }

  // Track shipment
  static Future<Map<String, dynamic>> trackShipment({
    required String trackingNumber,
    required String provider,
  }) async {
    // Implementation for tracking shipments
    // This would integrate with each provider's tracking API
    return {
      'tracking_number': trackingNumber,
      'status': 'In Transit',
      'estimated_delivery': DateTime.now().add(const Duration(days: 2)),
      'updates': [
        {
          'date': DateTime.now().subtract(const Duration(hours: 5)),
          'status': 'Picked up',
          'location': 'Origin Facility',
        },
        {
          'date': DateTime.now().subtract(const Duration(hours: 2)),
          'status': 'In Transit',
          'location': 'Sorting Facility',
        },
      ],
    };
  }
}