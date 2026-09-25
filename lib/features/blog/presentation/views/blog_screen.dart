import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/blog/data/providers/blog_provider.dart';
import 'package:eventease/features/blog/data/models/blog_post.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/seo_service.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  @override
  void initState() {
    super.initState();
    SeoService.setPage(
      title: 'EventEase Blog — Event Planning Tips & Inspiration for Malaysia',
      description:
          'Read expert tips on wedding planning, corporate events, and budgeting in Malaysia. Updated weekly by the EventEase team.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'EventEase Blog',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 48),
            _buildBlogGrid(context),
            const SizedBox(height: 80),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Insights & Inspiration',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your guide to planning perfect events in Malaysia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black.withOpacity(0.55),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogGrid(BuildContext context) {
    final posts = Provider.of<BlogProvider>(context).posts;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 600 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 32,
                  mainAxisSpacing: 48,
                  childAspectRatio: 0.75,
                ),
                itemCount: posts.length,
                itemBuilder: (ctx, i) => _buildBlogCard(ctx, posts[i]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBlogCard(BuildContext context, BlogPost post) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/blog-detail',
        arguments: post.slug,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Category badge
            Text(
              post.category.toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Excerpt
            Text(
              post.excerpt,
              style: TextStyle(
                color: Colors.black.withOpacity(0.5),
                fontSize: 14,
                height: 1.55,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Author + date
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  child: Text(
                    post.author[0],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.author,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  post.formattedDate,
                  style: TextStyle(
                      fontSize: 11, color: Colors.black.withOpacity(0.38)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
