class VendorServiceItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String subcategory;
  final double price;
  final String imageUrl;
  final List<String> features;
  final bool isPopular;
  final double rating;
  final int reviewCount;
  final Map<String, double>? pricingTiers;

  const VendorServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.imageUrl,
    required this.features,
    required this.isPopular,
    required this.rating,
    required this.reviewCount,
    this.pricingTiers,
  });
}
