import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:eventease/features/blog/data/providers/blog_provider.dart';
import 'package:eventease/features/blog/data/models/blog_post.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/seo_service.dart';
import 'dart:convert';

class BlogDetailScreen extends StatelessWidget {
  final String slug;
  const BlogDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    final post = Provider.of<BlogProvider>(context).getBySlug(slug);

    if (post == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: Text('Post not found')),
      );
    }

    // Update page title & description for SEO
    SeoService.setPage(
      title: '${post.title} | EventEase Blog',
      description: post.excerpt,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildArticle(context, post),
            const SizedBox(height: 80),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildArticle(BuildContext context, BlogPost post) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Category
              Text(
                post.category.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Title (h1)
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1.22,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 24),

              // Author + date row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      post.author.isNotEmpty ? post.author[0] : 'A',
                      style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Published on ${post.formattedDate}',
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.45),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Hero image
              if (post.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    post.imageUrl,
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 64, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 48),

              // Body content (Quill)
              _QuillBody(jsonContent: post.content),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 24),

              // Tags
              if (post.tags.isNotEmpty) ...[
                const Text(
                  'Tags',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: post.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey[100],
                          elevation: 0,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuillBody extends StatefulWidget {
  final String jsonContent;
  const _QuillBody({required this.jsonContent});

  @override
  State<_QuillBody> createState() => _QuillBodyState();
}

class _QuillBodyState extends State<_QuillBody> {
  late quill.QuillController _controller;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    try {
      final doc = quill.Document.fromJson(jsonDecode(widget.jsonContent));
      _controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
      _isValid = true;
    } catch (e) {
      debugPrint('Error parsing Quill JSON: $e');
      _isValid = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValid) {
      // Fallback for plain text or legacy HTML
      return Text(widget.jsonContent);
    }

    return quill.QuillEditor.basic(
      controller: _controller,
      config: const quill.QuillEditorConfig(),
    );
  }
}
