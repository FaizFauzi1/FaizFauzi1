import 'dart:convert';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/providers/review_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/shared/models/services/service_review.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/vendor_responsive_scaffold.dart';

class VendorReviewsScreen extends StatefulWidget {
  const VendorReviewsScreen({super.key});

  @override
  State<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends State<VendorReviewsScreen> {
  String _filter = "All";
  String _sort = "Newest";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  void _loadReviews() {
    final vendor = Provider.of<VendorProvider>(context, listen: false).currentVendor;
    if (vendor != null) {
      Provider.of<ReviewProvider>(context, listen: false).loadReviewsForVendor(vendor.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = Provider.of<VendorProvider>(context).currentVendor;
    
    return VendorResponsiveScaffold(
      title: 'All Reviews',
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) => setState(() => _filter = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'All', child: Text('All')),
            PopupMenuItem(value: 'Positive', child: Text('Positive')),
            PopupMenuItem(value: 'Neutral', child: Text('Neutral')),
            PopupMenuItem(value: 'Negative', child: Text('Negative')),
          ],
          icon: const Icon(Icons.filter_alt, color: AppTheme.primaryColor),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'Newest', child: Text('Newest')),
            PopupMenuItem(value: 'Oldest', child: Text('Oldest')),
            PopupMenuItem(value: 'Highest', child: Text('Highest Rated')),
            PopupMenuItem(value: 'Lowest', child: Text('Lowest Rated')),
          ],
          icon: const Icon(Icons.sort, color: AppTheme.primaryColor),
        ),
      ],
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, child) {
          if (reviewProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vendor == null) {
            return const Center(child: Text("Vendor profile not loaded."));
          }

          final reviews = reviewProvider.getReviewsForVendor(vendor.id);
          
          if (reviews.isEmpty) {
            return const Center(child: Text("No reviews found yet."));
          }

          List<ServiceReview> filtered = reviews.where((r) {
            if (_filter == "All") return true;
            if (_filter == "Positive") return r.rating >= 4;
            if (_filter == "Neutral") return r.rating == 3;
            if (_filter == "Negative") return r.rating <= 2;
            return true;
          }).toList();

          filtered.sort((a, b) {
            switch (_sort) {
              case "Newest":
                return b.createdAt.compareTo(a.createdAt);
              case "Oldest":
                return a.createdAt.compareTo(b.createdAt);
              case "Highest":
                return b.rating.compareTo(a.rating);
              case "Lowest":
                return a.rating.compareTo(b.rating);
            }
            return 0;
          });

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;

              if (isWideScreen) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Sidebar: Analytics
                    Container(
                      width: 350,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: ListView(
                        children: [
                          _buildAnalytics(reviews),
                        ],
                      ),
                    ),
                    // Right Content: Reviews
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: filtered.isEmpty
                            ? [const Center(child: Text("No reviews found for this filter."))]
                            : filtered.map(_buildReviewCard).toList(),
                      ),
                    ),
                  ],
                );
              }

              // Mobile View
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAnalytics(reviews),
                  const Divider(height: 32),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("No reviews found.")),
                    ),
                  ...filtered.map(_buildReviewCard).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAnalytics(List<ServiceReview> reviews) {
    double avg = reviews.isEmpty
        ? 0
        : reviews.map((e) => e.rating).reduce((a, b) => a + b) / reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rating Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(avg.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 48)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) => Icon(
                    index < avg.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                ),
                Text("${reviews.length} reviews", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...List.generate(5, (i) {
          int star = 5 - i;
          int count = reviews.where((r) => r.rating == star).length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text("$star ⭐")),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: reviews.isEmpty ? 0 : count / reviews.length,
                      color: AppTheme.primaryColor,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 30, child: Text("$count", textAlign: TextAlign.end)),
              ],
            ),
          );
        })
      ],
    );
  }

  Widget _buildReviewCard(ServiceReview r) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    (r.customerName ?? "A")[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.customerName ?? "Anonymous",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(DateFormat("yMMMd").format(r.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text("${r.rating}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              r.comment ?? "No comment provided.",
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showReplyEditor(r),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text("Reply"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showReplyEditor(ServiceReview r) {
    final _replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reply to Review"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Your reply will be visible to everyone on the service page."),
            const SizedBox(height: 16),
            TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                hintText: "Type your reply...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Reply functionality coming soon!")));
              },
              child: const Text("Send Reply")),
        ],
      ),
    );
  }
}
