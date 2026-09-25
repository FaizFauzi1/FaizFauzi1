import 'package:flutter/material.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/blog_post.dart';

class BlogProvider with ChangeNotifier {
  final List<BlogPost> _posts = [];
  bool _isLoading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  List<BlogPost> get posts => [..._posts];
  bool get isLoading => _isLoading;

  BlogProvider() {
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('admin_articles')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false);

      _posts.clear();
      for (var item in response) {
        _posts.add(BlogPost(
          id: item['id'].toString(),
          title: item['title'] ?? 'Untitled',
          slug: item['id'].toString(),
          excerpt: _getExcerpt(item['content']),
          content: item['content'] ?? '',
          author: item['author_name'] ?? 'Admin',
          imageUrl: item['featured_image'] ?? 'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=2070&auto=format&fit=crop',
          publishedAt: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
          category: item['category'] ?? 'General',
          tags: [],
        ));
      }
    } catch (e) {
      debugPrint('Error fetching articles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getExcerpt(String? contentJson) {
    if (contentJson == null || contentJson.isEmpty) return '';
    try {
      final List<dynamic> delta = jsonDecode(contentJson);
      String text = '';
      for (var op in delta) {
        if (op['insert'] is String) {
          text += op['insert'];
        }
      }
      text = text.replaceAll('\n', ' ').trim();
      return text.length > 150 ? '${text.substring(0, 150)}...' : text;
    } catch (e) {
      return '';
    }
  }

  BlogPost? getBySlug(String slug) {
    try {
      return _posts.firstWhere((post) => post.slug == slug);
    } catch (e) {
      return null;
    }
  }

  List<BlogPost> getByCategory(String category) {
    return _posts.where((post) => post.category == category).toList();
  }
}
