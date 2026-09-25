/// The categories screen library provides the CategoriesScreen widget for visual exploration of event categories and subcategories.
library categories_screen;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/presentation/views/customer/search_screen.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';

/// Represents a visual category item designed specifically for visual exploration
class VisualCategoryItem {
  final String title;
  final String shortName;
  final String description;
  final String emoji;
  final IconData icon;
  final Color accentColor;
  final String searchKeyword;
  final EventType eventType;

  const VisualCategoryItem({
    required this.title,
    required this.shortName,
    required this.description,
    required this.emoji,
    required this.icon,
    required this.accentColor,
    required this.searchKeyword,
    required this.eventType,
  });
}

class VisualThemeGroup {
  final String themeName;
  final String emoji;
  final String subtitle;
  final EventType eventType;
  final List<VisualCategoryItem> categories;

  const VisualThemeGroup({
    required this.themeName,
    required this.emoji,
    required this.subtitle,
    required this.eventType,
    required this.categories,
  });
}

class CategoriesScreen extends StatefulWidget {
  final EventType? initialEventType;
  const CategoriesScreen({super.key, this.initialEventType});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  EventType? _selectedEventType;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  // Visual Groups matching user specifications
  static const List<VisualThemeGroup> _themeGroups = [
    VisualThemeGroup(
      themeName: 'Wedding',
      emoji: '💍',
      subtitle: 'Everything needed to plan your dream wedding',
      eventType: EventType.wedding,
      categories: [
        VisualCategoryItem(
          title: 'Photography & Film',
          shortName: 'Photo',
          description: 'Candid shots, pre-wedding & cinematographers',
          emoji: '📸',
          icon: Icons.camera_alt_outlined,
          accentColor: Color(0xFF6B3FA0),
          searchKeyword: 'Photography',
          eventType: EventType.wedding,
        ),
        VisualCategoryItem(
          title: 'Floral & Decor',
          shortName: 'Decor',
          description: 'Stage setup, arches, walkway & centerpieces',
          emoji: '💐',
          icon: Icons.local_florist_outlined,
          accentColor: Color(0xFFE91E63),
          searchKeyword: 'Decoration',
          eventType: EventType.wedding,
        ),
        VisualCategoryItem(
          title: 'Catering & Dining',
          shortName: 'Catering',
          description: 'Banquet buffets, fine dining & dome sets',
          emoji: '🍽',
          icon: Icons.restaurant_outlined,
          accentColor: Color(0xFFFF9800),
          searchKeyword: 'Catering',
          eventType: EventType.wedding,
        ),
        VisualCategoryItem(
          title: 'Bridal Makeup',
          shortName: 'Makeup',
          description: 'Hair styling, bridal glam & henna artists',
          emoji: '💄',
          icon: Icons.brush_outlined,
          accentColor: Color(0xFF9C27B0),
          searchKeyword: 'Makeup',
          eventType: EventType.wedding,
        ),
        VisualCategoryItem(
          title: 'Wedding Venues',
          shortName: 'Venues',
          description: 'Glasshouses, hotel ballrooms & garden lawns',
          emoji: '📍',
          icon: Icons.location_on_outlined,
          accentColor: Color(0xFF2196F3),
          searchKeyword: 'Venue',
          eventType: EventType.wedding,
        ),
        VisualCategoryItem(
          title: 'Bridal Attire',
          shortName: 'Attire',
          description: 'Wedding gowns, tuxedos & traditional dresses',
          emoji: '👗',
          icon: Icons.checkroom_outlined,
          accentColor: Color(0xFF009688),
          searchKeyword: 'Attire',
          eventType: EventType.wedding,
        ),
      ],
    ),
    VisualThemeGroup(
      themeName: 'Birthday & Parties',
      emoji: '🎂',
      subtitle: 'Memorable celebrations for kids, teens & adults',
      eventType: EventType.birthday,
      categories: [
        VisualCategoryItem(
          title: 'Custom Cakes',
          shortName: 'Cakes',
          description: 'Designer cakes, cupcakes & dessert tables',
          emoji: '🎂',
          icon: Icons.cake_outlined,
          accentColor: Color(0xFFE91E63),
          searchKeyword: 'Cakes',
          eventType: EventType.birthday,
        ),
        VisualCategoryItem(
          title: 'Party & Balloon Decor',
          shortName: 'Decor',
          description: 'Balloon garlands, themed backdrops & arches',
          emoji: '🎈',
          icon: Icons.celebration_outlined,
          accentColor: Color(0xFFFF5722),
          searchKeyword: 'Decoration',
          eventType: EventType.birthday,
        ),
        VisualCategoryItem(
          title: 'Entertainment & Shows',
          shortName: 'Entertainment',
          description: 'Magicians, clowns, DJs & party games',
          emoji: '🎤',
          icon: Icons.mic_outlined,
          accentColor: Color(0xFF3F51B5),
          searchKeyword: 'Entertainment',
          eventType: EventType.birthday,
        ),
        VisualCategoryItem(
          title: 'Photobooths & 360',
          shortName: 'Photobooth',
          description: 'Instant prints, fun props & 360 spin booths',
          emoji: '📸',
          icon: Icons.photo_camera_outlined,
          accentColor: Color(0xFF673AB7),
          searchKeyword: 'Photobooth',
          eventType: EventType.birthday,
        ),
        VisualCategoryItem(
          title: 'Party Food & Bites',
          shortName: 'Party Food',
          description: 'Food trucks, finger snacks, burgers & BBQ',
          emoji: '🍔',
          icon: Icons.fastfood_outlined,
          accentColor: Color(0xFFFF9800),
          searchKeyword: 'Food',
          eventType: EventType.birthday,
        ),
        VisualCategoryItem(
          title: 'Door Gifts & Favors',
          shortName: 'Gifts',
          description: 'Custom souvenirs, gift bags & favors',
          emoji: '🎁',
          icon: Icons.card_giftcard_outlined,
          accentColor: Color(0xFF00BCD4),
          searchKeyword: 'Gifts',
          eventType: EventType.birthday,
        ),
      ],
    ),
    VisualThemeGroup(
      themeName: 'Corporate & Conferences',
      emoji: '🏢',
      subtitle: 'Professional solutions for summits, expos & galas',
      eventType: EventType.corporate,
      categories: [
        VisualCategoryItem(
          title: 'Conference Venues',
          shortName: 'Venues',
          description: 'Seminar rooms, convention halls & auditoriums',
          emoji: '🏢',
          icon: Icons.business_outlined,
          accentColor: Color(0xFF1976D2),
          searchKeyword: 'Venue',
          eventType: EventType.corporate,
        ),
        VisualCategoryItem(
          title: 'AV, Sound & Lighting',
          shortName: 'AV & Tech',
          description: 'LED video walls, PA systems & stage lighting',
          emoji: '🎧',
          icon: Icons.headset_mic_outlined,
          accentColor: Color(0xFF455A64),
          searchKeyword: 'Sound',
          eventType: EventType.corporate,
        ),
        VisualCategoryItem(
          title: 'Corporate Catering',
          shortName: 'Catering',
          description: 'Coffee breaks, executive bento & networking canapes',
          emoji: '☕',
          icon: Icons.coffee_outlined,
          accentColor: Color(0xFF795548),
          searchKeyword: 'Catering',
          eventType: EventType.corporate,
        ),
        VisualCategoryItem(
          title: 'Emcees & Moderators',
          shortName: 'Emcees',
          description: 'Bilingual hosts & professional facilitators',
          emoji: '🎙',
          icon: Icons.record_voice_over_outlined,
          accentColor: Color(0xFF5E35B1),
          searchKeyword: 'Emcee',
          eventType: EventType.corporate,
        ),
      ],
    ),
    VisualThemeGroup(
      themeName: 'Special Occasions & Rentals',
      emoji: '🎉',
      subtitle: 'Equipment, sound, canopies & music for all events',
      eventType: EventType.party,
      categories: [
        VisualCategoryItem(
          title: 'Tents & Canopies',
          shortName: 'Rentals',
          description: 'Marquee tents, tables, chairs & mist coolers',
          emoji: '⛺',
          icon: Icons.roofing_outlined,
          accentColor: Color(0xFF00796B),
          searchKeyword: 'Rental',
          eventType: EventType.party,
        ),
        VisualCategoryItem(
          title: 'Live Bands & Music',
          shortName: 'Live Music',
          description: 'Acoustic duos, jazz quartets & violinists',
          emoji: '🎸',
          icon: Icons.music_note_outlined,
          accentColor: Color(0xFFD81B60),
          searchKeyword: 'Music',
          eventType: EventType.party,
        ),
        VisualCategoryItem(
          title: 'Event Planners',
          shortName: 'Planners',
          description: 'Full-service planners & on-day coordinators',
          emoji: '📋',
          icon: Icons.assignment_outlined,
          accentColor: Color(0xFF2E7D32),
          searchKeyword: 'Planner',
          eventType: EventType.party,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedEventType = widget.initialEventType;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProviderCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderCategories() async {
    try {
      final provider = context.read<CategoryProvider>();
      if (provider.allCategories.isEmpty) {
        await provider.fetchCategories();
      }
    } catch (e) {
      debugPrint('CategoriesScreen: Note on category fetch: $e');
    }
  }

  List<VisualThemeGroup> get _filteredGroups {
    return _themeGroups.where((group) {
      if (_selectedEventType != null && group.eventType != _selectedEventType) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;

      // Check group name or items
      if (group.themeName.toLowerCase().contains(_searchQuery)) return true;
      return group.categories.any((c) =>
          c.title.toLowerCase().contains(_searchQuery) ||
          c.shortName.toLowerCase().contains(_searchQuery) ||
          c.description.toLowerCase().contains(_searchQuery) ||
          c.searchKeyword.toLowerCase().contains(_searchQuery));
    }).map((group) {
      if (_searchQuery.isEmpty) return group;
      final matchedCategories = group.categories.where((c) =>
          c.title.toLowerCase().contains(_searchQuery) ||
          c.shortName.toLowerCase().contains(_searchQuery) ||
          c.description.toLowerCase().contains(_searchQuery) ||
          c.searchKeyword.toLowerCase().contains(_searchQuery)).toList();
      return VisualThemeGroup(
        themeName: group.themeName,
        emoji: group.emoji,
        subtitle: group.subtitle,
        eventType: group.eventType,
        categories: matchedCategories,
      );
    }).where((group) => group.categories.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _filteredGroups;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Explore Categories',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimaryColor),
            tooltip: 'Search Services',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Visual Header & Filter Bar
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Input
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search categories, photo, decor, cakes...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF6B3FA0),
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildThemeFilterChip('✨ All Themes', null),
                          const SizedBox(width: 8),
                          _buildThemeFilterChip('💍 Wedding', EventType.wedding),
                          const SizedBox(width: 8),
                          _buildThemeFilterChip('🎂 Birthday', EventType.birthday),
                          const SizedBox(width: 8),
                          _buildThemeFilterChip('🏢 Corporate', EventType.corporate),
                          const SizedBox(width: 8),
                          _buildThemeFilterChip('🎉 Parties', EventType.party),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Empty state if search finds nothing
            if (filteredGroups.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No categories found matching "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedEventType = null;
                            });
                          },
                          child: const Text('Reset filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Visual Themed Category Sections
            for (final group in filteredGroups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B3FA0).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          group.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.themeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              group.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${group.categories.length} items',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Visual Grid for this group
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isDesktop ? 1.4 : 1.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = group.categories[index];
                      return _buildVisualCard(item);
                    },
                    childCount: group.categories.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],

            // Footer
            const SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 24),
                  AppFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeFilterChip(String label, EventType? type) {
    final isSelected = _selectedEventType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEventType = isSelected ? null : type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A1B6E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A1B6E) : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2A1B6E).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCard(VisualCategoryItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchScreen(
              initialCategory: item.searchKeyword,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Emoji Squircle + Action Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),

            // Bottom Content: Short Title + Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
