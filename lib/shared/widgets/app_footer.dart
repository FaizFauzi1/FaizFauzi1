import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // Enable for web and larger tablets, or if explicitly requested. 
    // For mobile apps, we usually use a simpler footer or none, 
    // but we'll make a compact version here.
    bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Premium Slate-900 background
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 40 : 64,
      ),
      child: Column(
        children: [
          if (!isMobile)
            Wrap(
              spacing: 40,
              runSpacing: 40,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildBrandSection(),
                _buildLinkSection(context, 'Company', ['About Us', 'Contact', 'Careers', 'Blog']),
                _buildLinkSection(context, 'Services', ['Venues', 'Catering', 'Photography', 'Decoration']),
                _buildLinkSection(context, 'Support', ['Help Center', 'Safety', 'Terms of Service', 'Privacy Policy']),
                _buildNewsletterSection(),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandSection(),
                const SizedBox(height: 32),
                _buildMobileLinkGrid(context),
                const SizedBox(height: 48),
                _buildNewsletterSection(),
              ],
            ),
          const SizedBox(height: 64),
          const Divider(color: Colors.white10),
          const SizedBox(height: 32),
          if (!isMobile)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2026 EventEase Malaysia. All rights reserved.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
                _buildSocialIconsRow(),
              ],
            )
          else
            Column(
              children: [
                _buildSocialIconsRow(),
                const SizedBox(height: 24),
                Text(
                  '© 2026 EventEase Malaysia. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'EventEase',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'The #1 platform for event planning in Malaysia. From dreamy weddings to corporate galas, we make it happen.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context, String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _navigateTo(context, link),
                  child: Text(
                    link,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildMobileLinkGrid(BuildContext context) {
    return Wrap(
      spacing: 40,
      runSpacing: 32,
      children: [
        _buildCompactLinkSection(context, 'Company', ['About Us', 'Blog', 'Contact']),
        _buildCompactLinkSection(context, 'Legal', ['Terms', 'Privacy']),
        _buildCompactLinkSection(context, 'Services', ['Venues', 'Catering']),
      ],
    );
  }

  Widget _buildCompactLinkSection(BuildContext context, String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ...links.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _navigateTo(context, l),
            child: Text(l, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          ),
        )),
      ],
    );
  }

  void _navigateTo(BuildContext context, String link) {
    switch (link) {
      case 'About Us':
        Navigator.pushNamed(context, '/about');
        break;
      case 'Blog':
        Navigator.pushNamed(context, '/blog');
        break;
      case 'Privacy Policy':
      case 'Privacy':
        Navigator.pushNamed(context, '/privacy-policy');
        break;
      case 'Terms of Service':
      case 'Terms':
        Navigator.pushNamed(context, '/terms-of-service');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$link is coming soon!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget _buildNewsletterSection() {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JOIN OUR COMMUNITY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Email address',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                  onPressed: () {},
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get low-price alerts and planning tips.',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIconsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSocialIcon(Icons.facebook, 'Facebook'),
        const SizedBox(width: 20),
        _buildSocialIcon(Icons.camera_alt, 'Instagram'),
        const SizedBox(width: 20),
        _buildSocialIcon(Icons.alternate_email, 'Twitter'),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
