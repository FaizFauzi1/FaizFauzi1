import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/customer/presentation/views/customer/search_screen.dart';
import 'package:eventease/shared/widgets/design_system/premium_widgets.dart';

/// Premium home hero with glass search overlay.
class HomeHeroWidget extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const HomeHeroWidget({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EEDesignTokens.radiusXl),
      child: Stack(
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: Image.asset(
              'assets/branding/eventease_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Positioned(
            left: EEDesignTokens.spaceLg,
            right: EEDesignTokens.spaceLg,
            bottom: EEDesignTokens.spaceLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Your Perfect Event',
                  style: EEDesignTokens.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: EEDesignTokens.spaceSm),
                Text(
                  'Discover premium vendors across Malaysia, Singapore & Indonesia',
                  style: EEDesignTokens.bodyMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: EEDesignTokens.spaceMd),
                GestureDetector(
                  onTap: onSearchTap ??
                      () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(EEDesignTokens.radiusPill),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(EEDesignTokens.radiusPill),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Search venues, caterers, photographers…',
                                style: EEDesignTokens.bodyMedium.copyWith(color: Colors.white70),
                              ),
                            ),
                            PillBadge(label: 'Search', color: Colors.white, textColor: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
