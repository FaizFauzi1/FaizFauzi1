import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:eventease/core/constants/country_config.dart';
import 'package:eventease/core/providers/country_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';

/// Country picker used in signup, onboarding, and settings.
class CountrySelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool showCurrency;

  const CountrySelector({
    super.key,
    this.value,
    this.onChanged,
    this.showCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CountryProvider>();
    final selected = value ?? provider.selectedCountryCode;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Country',
        prefixIcon: const Icon(Icons.public_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EEDesignTokens.radiusMd),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: CountryConfig.supported.containsKey(selected)
              ? selected
              : CountryConfig.defaultCountryCode,
          items: CountryConfig.supported.entries.map((entry) {
            final info = entry.value;
            return DropdownMenuItem(
              value: info.code,
              child: Row(
                children: [
                  Text(_flagEmoji(info.code)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(info.name)),
                  if (showCurrency)
                    Text(
                      info.currencyCode,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (code) {
            if (code == null) return;
            onChanged?.call(code);
            provider.setCountry(code);
          },
        ),
      ),
    );
  }

  String _flagEmoji(String code) {
    return code.toUpperCase().split('').map((c) {
      return String.fromCharCode(c.codeUnitAt(0) + 127397);
    }).join();
  }
}

/// Shimmer placeholder for vendor cards.
class ShimmerVendorCard extends StatelessWidget {
  const ShimmerVendorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: EEDesignTokens.spaceMd),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EEDesignTokens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(EEDesignTokens.radiusLg),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 180, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer list for generic list loading.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(EEDesignTokens.radiusMd),
          ),
        ),
      ),
    );
  }
}
