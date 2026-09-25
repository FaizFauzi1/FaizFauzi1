class Photo {
  final String id;
  final String albumId;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final String uploadedBy;
  final DateTime uploadedAt;
  final List<String> tags;
  final bool isApproved;

  const Photo({
    required this.id,
    required this.albumId,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.tags,
    required this.isApproved,
  });

  Photo copyWith({
    String? id,
    String? albumId,
    String? url,
    String? thumbnailUrl,
    String? caption,
    String? uploadedBy,
    DateTime? uploadedAt,
    List<String>? tags,
    bool? isApproved,
  }) {
    return Photo(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      tags: tags ?? this.tags,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'uploadedBy': uploadedBy,
      'uploadedAt': uploadedAt.toIso8601String(),
      'tags': tags,
      'isApproved': isApproved,
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      albumId: json['albumId'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
      caption: json['caption'],
      uploadedBy: json['uploadedBy'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      isApproved: json['isApproved'] ?? true,
    );
  }

  // Supabase for Photo
  factory Photo.fromSupabase(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      albumId: json['album_id'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      caption: json['caption'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
      tags: List<String>.from(json['tags'] ?? []),
      isApproved: json['is_approved'] ?? true,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'album_id': albumId,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'caption': caption,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
      'tags': tags,
      'is_approved': isApproved,
    };
  }
}

class PhotoAlbum {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final List<Photo> photos;
  final bool allowGuestUploads;
  final bool requireApproval;
  final int? maxPhotosPerGuest;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PhotoAlbum({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.photos,
    required this.allowGuestUploads,
    required this.requireApproval,
    this.maxPhotosPerGuest,
    required this.createdAt,
    required this.updatedAt,
  });

  PhotoAlbum copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    List<Photo>? photos,
    bool? allowGuestUploads,
    bool? requireApproval,
    int? maxPhotosPerGuest,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PhotoAlbum(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      allowGuestUploads: allowGuestUploads ?? this.allowGuestUploads,
      requireApproval: requireApproval ?? this.requireApproval,
      maxPhotosPerGuest: maxPhotosPerGuest ?? this.maxPhotosPerGuest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'allowGuestUploads': allowGuestUploads,
      'requireApproval': requireApproval,
      'maxPhotosPerGuest': maxPhotosPerGuest,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PhotoAlbum.fromJson(Map<String, dynamic> json) {
    return PhotoAlbum(
      id: json['id'],
      eventId: json['eventId'],
      title: json['title'],
      description: json['description'],
      photos: (json['photos'] as List<dynamic>?)
          ?.map((photo) => Photo.fromJson(photo))
          .toList() ?? [],
      allowGuestUploads: json['allowGuestUploads'] ?? true,
      requireApproval: json['requireApproval'] ?? false,
      maxPhotosPerGuest: json['maxPhotosPerGuest'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Supabase for PhotoAlbum
  factory PhotoAlbum.fromSupabase(Map<String, dynamic> json) {
    var photosList = json['event_photos'] as List?;
    return PhotoAlbum(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'],
      description: json['description'] ?? '',
      photos: photosList?.map((p) => Photo.fromSupabase(p)).toList() ?? [],
      allowGuestUploads: json['allow_guest_uploads'] ?? true,
      requireApproval: json['require_approval'] ?? false,
      maxPhotosPerGuest: json['max_photos_per_guest'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'description': description,
      'allow_guest_uploads': allowGuestUploads,
      'require_approval': requireApproval,
      'max_photos_per_guest': maxPhotosPerGuest,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters for computed properties
  int get photoCount => photos.length;

  String? get coverImageUrl => photos.isNotEmpty
      ? photos.first.thumbnailUrl ?? photos.first.url
      : null;

  factory PhotoAlbum.sample() {
    return PhotoAlbum(
      id: 'album_1',
      eventId: 'event_1',
      title: 'Sarah & John\'s Wedding Photos',
      description: 'Capture the memories of our special day!',
      photos: [
        Photo(
          id: 'photo_1',
          albumId: 'album_1',
          url: 'https://via.placeholder.com/800x600?text=Wedding+Photo+1',
          thumbnailUrl: 'https://via.placeholder.com/200x150?text=Wedding+Photo+1',
          caption: 'First dance',
          uploadedBy: 'Sarah Johnson',
          uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
          tags: ['dance', 'first dance'],
          isApproved: true,
        ),
        Photo(
          id: 'photo_2',
          albumId: 'album_1',
          url: 'https://via.placeholder.com/800x600?text=Wedding+Photo+2',
          thumbnailUrl: 'https://via.placeholder.com/200x150?text=Wedding+Photo+2',
          caption: 'Cake cutting ceremony',
          uploadedBy: 'John Smith',
          uploadedAt: DateTime.now().subtract(const Duration(hours: 1)),
          tags: ['cake', 'ceremony'],
          isApproved: true,
        ),
      ],
      allowGuestUploads: true,
      requireApproval: false,
      maxPhotosPerGuest: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }
}
