class TaggedVendor {
  final String id;
  final String name;
  final String category;
  final String role;
  final String? avatarUrl;
  final String priceRange;
  final double rating;
  final bool isVerified;

  const TaggedVendor({
    required this.id,
    required this.name,
    required this.category,
    required this.role,
    this.avatarUrl,
    required this.priceRange,
    this.rating = 4.9,
    this.isVerified = true,
  });

  factory TaggedVendor.fromMap(Map<String, dynamic> map) {
    return TaggedVendor(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Vendor Partner',
      category: map['category']?.toString() ?? 'Service',
      role: map['role']?.toString() ?? map['category']?.toString() ?? 'Vendor',
      avatarUrl: map['avatar_url']?.toString(),
      priceRange: map['price_range']?.toString() ?? 'Custom Quote',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      isVerified: map['is_verified'] ?? true,
    );
  }
}

class RealEvent {
  final String id;
  final String title;
  final String coupleOrHost;
  final String eventType; // 'Weddings', 'Corporate Gala', 'Birthday', 'Engagement'
  final String location;
  final String venueName;
  final String budgetRange;
  final double estimatedTotalBudget;
  final int guestCount;
  final String coverImage;
  final List<String> galleryImages;
  final String storyDescription;
  final List<TaggedVendor> taggedVendors;
  final DateTime eventDate;

  const RealEvent({
    required this.id,
    required this.title,
    required this.coupleOrHost,
    required this.eventType,
    required this.location,
    required this.venueName,
    required this.budgetRange,
    required this.estimatedTotalBudget,
    required this.guestCount,
    required this.coverImage,
    required this.galleryImages,
    required this.storyDescription,
    required this.taggedVendors,
    required this.eventDate,
  });

  factory RealEvent.fromSupabase(Map<String, dynamic> json) {
    final budget = (json['budget'] as num?)?.toDouble() ?? 0.0;
    String budgetRange = '< RM 30k';
    if (budget >= 150000) {
      budgetRange = 'Luxury > RM 150k';
    } else if (budget >= 70000) {
      budgetRange = 'RM 70k - RM 150k';
    } else if (budget >= 30000) {
      budgetRange = 'RM 30k - RM 70k';
    }

    final rawGallery = json['gallery_images'] ?? json['additional_info']?['gallery'];
    List<String> gallery = [];
    if (rawGallery is List) {
      gallery = rawGallery.map((e) => e.toString()).toList();
    }

    return RealEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Celebration',
      coupleOrHost: json['host_name']?.toString() ?? 'Host',
      eventType: json['type']?.toString() ?? 'Weddings',
      location: json['venue']?['city']?.toString() ?? json['venue']?['name']?.toString() ?? 'Malaysia',
      venueName: json['venue']?['name']?.toString() ?? 'Featured Venue',
      budgetRange: budgetRange,
      estimatedTotalBudget: budget,
      guestCount: json['max_guests'] ?? 100,
      coverImage: json['cover_image']?.toString() ?? 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
      galleryImages: gallery.isNotEmpty ? gallery : [json['cover_image']?.toString() ?? 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800'],
      storyDescription: json['description']?.toString() ?? json['invitation_message']?.toString() ?? 'A beautiful celebration.',
      taggedVendors: const [],
      eventDate: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
