import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/app_routes.dart';
import 'package:eventease/features/customer/presentation/views/account/account_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/search_screen.dart';
import 'package:eventease/core/services/analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommonNavbar extends StatelessWidget {
  final int currentIndex;

  const CommonNavbar({
    super.key,
    required this.currentIndex, 
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryColor,
      currentIndex: currentIndex,
      onTap: (index) {
        const tabNames = ['Home', 'Search', 'Messages', 'Favorites', 'Profile'];
        AnalyticsService().trackTabChanged(
          tabName: tabNames[index],
          tabIndex: index,
          screen: 'CustomerNavbar',
        );
        switch (index) {
          case 0:
            // Home - navigate back to home if not already there
            if (currentIndex != 0) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
            break;
          case 1:
            // Search
            if (currentIndex != 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            }
            break;
          case 2:
            // Messages
            if (currentIndex != 2) {
              AppNavigation.navigateToMessages(context);
            }
            break;
          case 3:
            // Favorites
            if (currentIndex != 3) {
              if (authProvider.isAuthenticated) {
                Navigator.pushNamed(context, '/favorites');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to view favorites')),
                );
              }
            }
            break;
          case 4:
            // Profile/Account
            if (currentIndex != 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
            }
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final totalUnread = chatProvider.conversations
                  .fold<int>(0, (int sum, conv) => sum + conv.unreadCount);

              return Stack(
                children: [
                  const Icon(Icons.message),
                  if (totalUnread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          totalUnread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.favorite),
              if (favoritesProvider.favoriteServiceIds.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      favoritesProvider.favoriteServiceIds.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Favorites',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
