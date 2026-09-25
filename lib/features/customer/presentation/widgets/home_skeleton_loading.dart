import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';

/// A rich, modern skeleton loading placeholder for the Home Screen.
/// Displayed immediately when the app launches so the user never sits
/// waiting on a blank or stuck screen.
class HomeSkeletonLoading extends StatelessWidget {
  const HomeSkeletonLoading({super.key});

  Widget _buildBox({
    required double width,
    required double height,
    double borderRadius = 8,
    Color color = Colors.white,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      period: const Duration(milliseconds: 1400),
      child: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Greeting & Search Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBox(width: 140, height: 18, borderRadius: 6),
                      const SizedBox(height: 8),
                      _buildBox(width: 220, height: 26, borderRadius: 8),
                    ],
                  ),
                  _buildBox(width: 44, height: 44, borderRadius: 22),
                ],
              ),

              const SizedBox(height: 24),

              // "My Event" / Active Planning Card Skeleton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBox(width: 100, height: 14, borderRadius: 4),
                        _buildBox(width: 60, height: 22, borderRadius: 12),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildBox(width: 200, height: 24, borderRadius: 6),
                    const SizedBox(height: 8),
                    _buildBox(width: 130, height: 14, borderRadius: 4),
                    const SizedBox(height: 20),
                    // Progress Bar Skeleton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBox(width: 120, height: 12, borderRadius: 4),
                        _buildBox(width: 40, height: 12, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildBox(width: double.infinity, height: 10, borderRadius: 5),
                    const SizedBox(height: 20),
                    // Action Buttons Skeleton
                    Row(
                      children: [
                        Expanded(child: _buildBox(width: double.infinity, height: 44, borderRadius: 12)),
                        const SizedBox(width: 12),
                        _buildBox(width: 44, height: 44, borderRadius: 12),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // How it works small link skeleton
              Row(
                children: [
                  _buildBox(width: 16, height: 16, borderRadius: 8),
                  const SizedBox(width: 8),
                  _buildBox(width: 240, height: 14, borderRadius: 4),
                ],
              ),

              const SizedBox(height: 28),

              // Categories Header Skeleton
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBox(width: 130, height: 20, borderRadius: 6),
                  _buildBox(width: 100, height: 14, borderRadius: 4),
                ],
              ),
              const SizedBox(height: 16),

              // Categories Horizontal Shortcuts Skeleton
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBox(width: 40, height: 40, borderRadius: 20),
                          const SizedBox(height: 8),
                          _buildBox(width: 50, height: 10, borderRadius: 4),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Featured Section Header Skeleton
              _buildBox(width: 180, height: 20, borderRadius: 6),
              const SizedBox(height: 16),

              // Horizontal Cards Skeleton
              SizedBox(
                height: isMobile ? 260 : 300,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Container(
                      width: isMobile ? 260 : 320,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBox(
                            width: double.infinity,
                            height: 130,
                            borderRadius: 16,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBox(width: 160, height: 16, borderRadius: 4),
                                const SizedBox(height: 8),
                                _buildBox(width: 200, height: 12, borderRadius: 4),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildBox(width: 60, height: 14, borderRadius: 4),
                                    _buildBox(width: 80, height: 14, borderRadius: 4),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
