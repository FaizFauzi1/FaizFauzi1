import 'package:intl/intl.dart';

class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String excerpt;
  final String author;
  final String imageUrl;
  final DateTime publishedAt;
  final List<String> tags;
  final String category;

  BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.excerpt,
    required this.author,
    required this.imageUrl,
    required this.publishedAt,
    required this.tags,
    required this.category,
  });

  String get formattedDate => DateFormat('MMM d, yyyy').format(publishedAt);

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      excerpt: json['excerpt'],
      author: json['author'],
      imageUrl: json['image_url'],
      publishedAt: DateTime.parse(json['published_at']),
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'excerpt': excerpt,
      'author': author,
      'image_url': imageUrl,
      'published_at': publishedAt.toIso8601String(),
      'tags': tags,
      'category': category,
    };
  }
}
