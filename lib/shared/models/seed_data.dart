class SeedData {
  // All user data and credentials now come exclusively from Supabase.
  static const Map<String, Map<String, String>> adminUsers = {};
  static const Map<String, Map<String, String>> vendorUsers = {};
  static const Map<String, Map<String, String>> organizerUsers = {};
  static const Map<String, Map<String, String>> customerUsers = {};

  static Map<String, Map<String, String>> getAllUsers() => {};

  static Map<String, Map<String, String>> getUsersByRole(String role) => {};

  static Map<String, Map<String, String>> getVendorsByCategory(String category) => {};

  static String getPassword(String email) => '';

  static String getUserRole(String email) => '';

  static String getUserName(String email) => '';
}
