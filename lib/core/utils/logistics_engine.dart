import 'dart:math';
import '../../shared/models/services/service_logistics.dart';

class LogisticsEngine {
  /// Calculates distance between two points in KM.
  /// Note: In a real app, this would use Google Maps Distance Matrix API.
  /// For this implementation, we'll use a mock calculation or Haversine formula
  /// if coordinates were available, but here we'll mock the distance fetch.
  static Future<double> getDistanceKm(String origin, String destination) async {
    // Mocking API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Deterministic mock distance for testing based on string lengths
    // In production, replace with: 
    // final response = await http.get('google_maps_url?origins=$origin&destinations=$destination');
    return (origin.length + destination.length).toDouble() % 100 + 5.0;
  }

  /// Calculates travel fee based on ServiceLogistics rules.
  static double calculateTravelFee({
    required double distanceKm,
    required ServiceLogistics logistics,
  }) {
    if (distanceKm <= logistics.freeRadiusKm) {
      return 0.0;
    }
    
    final billableDistance = distanceKm - logistics.freeRadiusKm;
    return billableDistance * logistics.perKmRate;
  }

  /// Estimates logistics for "Location Not Yet Known" (TBC).
  /// Uses a default distance estimate from city center.
  static double estimateTbcDistance(String? primaryState) {
    // If state is known, we can be more accurate. 
    // Otherwise, assume a mid-range distance (35km).
    return 35.0;
  }

  /// Checks if a night surcharge applies based on start/end times.
  static bool isNightWork(String timeStr) {
    try {
      final hour = int.parse(timeStr.split(':')[0]);
      // Surcharge usually applies between 11 PM and 6 AM
      return hour >= 23 || hour <= 6;
    } catch (_) {
      return false;
    }
  }
}
