import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  /// Determines the current position of the device.
  static Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return null;
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return null;
    }
  }

  /// Gets the placemark for the current location.
  static Future<Placemark?> getCurrentPlacemark() async {
    try {
      final position = await _determinePosition();
      if (position != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          return placemarks.first;
        }
      }
    } catch (e) {
      print('Error getting placemark: $e');
    }
    return null;
  }

  /// Detects the ISO country code (e.g., 'US', 'MY'). Returns null if unable to detect.
  static Future<String?> detectCountryCode() async {
    final placemark = await getCurrentPlacemark();
    return placemark?.isoCountryCode;
  }
  
  /// Detects the full country name.
  static Future<String?> detectCountryName() async {
    final placemark = await getCurrentPlacemark();
    return placemark?.country;
  }

  /// Detects the city/state combined string for service areas (e.g., 'Kuala Lumpur, MY').
  static Future<String?> detectServiceArea() async {
    final placemark = await getCurrentPlacemark();
    if (placemark != null) {
      List<String> parts = [];
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        parts.add(placemark.locality!);
      } else if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
        parts.add(placemark.subAdministrativeArea!);
      }
      
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
        parts.add(placemark.administrativeArea!);
      }
      
      if (parts.isNotEmpty) {
        return parts.join(', ');
      } else {
        return placemark.country;
      }
    }
    return null;
  }
}
