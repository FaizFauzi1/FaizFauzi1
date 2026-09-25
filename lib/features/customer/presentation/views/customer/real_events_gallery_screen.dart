import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/customer/data/models/real_event_model.dart';
import 'package:eventease/features/customer/presentation/views/customer/real_event_detail_screen.dart';

class RealEventsGalleryScreen extends StatefulWidget {
  const RealEventsGalleryScreen({super.key});

  @override
  State<RealEventsGalleryScreen> createState() => _RealEventsGalleryScreenState();
}

class _RealEventsGalleryScreenState extends State<RealEventsGalleryScreen> {
  String _selectedCategory = 'All';
  String _selectedBudget = 'All Budgets';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<RealEvent> _events = [];

  final List<String> _categories = ['All', 'Weddings', 'Corporate Gala', 'Engagement', 'Birthday'];
  final List<String> _budgets = ['All Budgets', '< RM 30k', 'RM 30k - RM 70k', 'RM 70k - RM 150k', 'Luxury > RM 150k'];

  @override
  void initState() {
    super.initState();
    _loadEventsFromSupabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEventsFromSupabase() async {
    setState(() => _isLoading = true);

    try {
      final data = await SupabaseService.select(
        table: 'events',
        filters: {'is_public': true},
        orderBy: 'date',
        ascending: false,
      );

      if (data.isNotEmpty) {
        _events = data.map((json) => RealEvent.fromSupabase(json)).toList();
      } else {
        // If no public events in database yet, load from featured events
        _events = _getDefaultFeaturedEvents();
      }
    } catch (e) {
      debugPrint('Error loading events from Supabase: $e');
      _events = _getDefaultFeaturedEvents();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RealEvent> _getDefaultFeaturedEvents() {
    return [
      RealEvent(
        id: 'EV-001',
        title: 'Botanical Glasshouse Garden Wedding',
        coupleOrHost: 'Sarah & Danial',
        eventType: 'Weddings',
        location: 'Kuala Lumpur',
        venueName: 'Glasshouse Seputeh',
        budgetRange: 'RM 50k - RM 70k',
        estimatedTotalBudget: 65000,
        guestCount: 220,
        coverImage: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
        galleryImages: [
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
          'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=800',
          'https://images.unsplash.com/photo-1520854221256-17451cc331bf?w=800',
        ],
        storyDescription:
            'Sarah and Danial wanted an intimate botanical sanctuary in the heart of Kuala Lumpur. Filled with cascading eucalyptus, warm fairy lights, and live acoustic serenade, the wedding perfectly balanced modern elegance with lush natural greenery.',
        taggedVendors: const [
          TaggedVendor(id: 'v1', name: 'Glasshouse Seputeh', category: 'Venue', role: 'Event Venue', priceRange: 'RM 18,000 - RM 25,000'),
          TaggedVendor(id: 'v2', name: 'Petals & Bloom Floral', category: 'Florist', role: 'Botanical Styling', priceRange: 'RM 6,500 - RM 12,000'),
          TaggedVendor(id: 'v3', name: 'Lumiere Studios KL', category: 'Photography', role: 'Photo & Cinema', priceRange: 'RM 4,800 - RM 8,500'),
          TaggedVendor(id: 'v4', name: 'Seputeh Artisan Catering', category: 'Catering', role: 'Fusion Buffet', priceRange: 'RM 85 / pax'),
        ],
        eventDate: DateTime(2026, 7, 14),
      ),
      RealEvent(
        id: 'EV-002',
        title: 'Grand Hyatt Tech Innovation Gala Dinner',
        coupleOrHost: 'Petronas Tech Digital',
        eventType: 'Corporate Gala',
        location: 'Kuala Lumpur',
        venueName: 'Grand Hyatt Kuala Lumpur',
        budgetRange: 'RM 70k - RM 150k',
        estimatedTotalBudget: 120000,
        guestCount: 450,
        coverImage: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800',
        galleryImages: [
          'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800',
          'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=800',
        ],
        storyDescription:
            'An ultra-modern corporate gala celebrating digital transformation with 360-degree LED visual projection mapping, state-of-the-art stage lighting, and keynote live broadcasts across ASEAN.',
        taggedVendors: const [
          TaggedVendor(id: 'v5', name: 'Grand Hyatt Kuala Lumpur', category: 'Venue', role: 'Grand Ballroom', priceRange: 'RM 65,000+'),
          TaggedVendor(id: 'v6', name: 'AV Matrix Pro Lighting', category: 'AV & Tech', role: 'LED Wall & Sound', priceRange: 'RM 28,000'),
          TaggedVendor(id: 'v7', name: 'The Emcee Collective', category: 'Entertainment', role: 'Bilingual Host', priceRange: 'RM 4,000'),
        ],
        eventDate: DateTime(2026, 6, 20),
      ),
      RealEvent(
        id: 'EV-003',
        title: 'Colonial Glamour Heritage Reception',
        coupleOrHost: 'Farhan & Natasha',
        eventType: 'Weddings',
        location: 'Kuala Lumpur',
        venueName: 'The Majestic Hotel KL',
        budgetRange: 'Luxury > RM 150k',
        estimatedTotalBudget: 185000,
        guestCount: 500,
        coverImage: 'https://images.unsplash.com/photo-1544078751-58fee2d8a03b?w=800',
        galleryImages: [
          'https://images.unsplash.com/photo-1544078751-58fee2d8a03b?w=800',
          'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=800',
        ],
        storyDescription:
            'A royal Malaysian songket reception honoring classic heritage architecture with crystal chandeliers, orchid arches, and 8-course curated banquet cuisine.',
        taggedVendors: const [
          TaggedVendor(id: 'v8', name: 'The Majestic Hotel', category: 'Venue', role: 'Grand Ballroom', priceRange: 'RM 95,000+'),
          TaggedVendor(id: 'v9', name: 'Royal Songket Atelier', category: 'Attire', role: 'Custom Songket', priceRange: 'RM 14,000'),
          TaggedVendor(id: 'v10', name: 'Klang Valley Symphony Quartet', category: 'Music', role: 'Strings Ensemble', priceRange: 'RM 6,500'),
        ],
        eventDate: DateTime(2026, 5, 10),
      ),
      RealEvent(
        id: 'EV-004',
        title: 'Intimate Rainforest Sunset Engagement',
        coupleOrHost: 'Kevin & Melissa',
        eventType: 'Engagement',
        location: 'Ampang',
        venueName: 'Tamarind Springs',
        budgetRange: '< RM 30k',
        estimatedTotalBudget: 24000,
        guestCount: 60,
        coverImage: 'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800',
        galleryImages: [
          'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800',
        ],
        storyDescription:
            'A magical sunset engagement ceremony surrounded by lush tropical rainforest, wooden deck dining, and candlelit ambiance.',
        taggedVendors: const [
          TaggedVendor(id: 'v11', name: 'Tamarind Springs', category: 'Venue', role: 'Forest Deck', priceRange: 'RM 12,000'),
          TaggedVendor(id: 'v12', name: 'Wanderlust Moments', category: 'Photography', role: 'Intimate Storyteller', priceRange: 'RM 3,200'),
        ],
        eventDate: DateTime(2026, 8, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _events.where((e) {
      final matchesCategory = _selectedCategory == 'All' || e.eventType.toLowerCase().contains(_selectedCategory.toLowerCase());
      final matchesBudget = _selectedBudget == 'All Budgets' || e.budgetRange.contains(_selectedBudget.replaceAll('All Budgets', ''));
      final query = _searchController.text.toLowerCase();
      final matchesQuery = query.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.venueName.toLowerCase().contains(query) ||
          e.coupleOrHost.toLowerCase().contains(query);
      return matchesCategory && matchesBudget && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Real Events Inspiration',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadEventsFromSupabase,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search real weddings, venues, couples...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Budget Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _budgets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final b = _budgets[index];
                      final isSelected = _selectedBudget == b;
                      return ChoiceChip(
                        label: Text(b, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textSecondaryColor)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        onSelected: (val) => setState(() => _selectedBudget = b),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Events Grid/List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadEventsFromSupabase,
                    child: filtered.isEmpty
                        ? const Center(child: Text('No real events match your filter criteria.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildEventCard(filtered[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(RealEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RealEventDetailScreen(event: event)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    event.coverImage,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 190, color: Colors.grey.shade300),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.budgetRange,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.eventType,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(
                        event.coupleOrHost,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 2),
                      Text(
                        event.venueName,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            '${event.taggedVendors.length} Tagged Vendors',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'View Event Story',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryColor),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
