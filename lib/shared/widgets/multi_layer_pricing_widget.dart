import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultiLayerPricingWidget extends StatefulWidget {
  final Map<String, dynamic> initialPricing;
  final Function(Map<String, dynamic>) onPricingChanged;
  final bool showTierDescriptions;

  const MultiLayerPricingWidget({
    super.key,
    required this.initialPricing,
    required this.onPricingChanged,
    this.showTierDescriptions = true,
  });

  @override
  State<MultiLayerPricingWidget> createState() => _MultiLayerPricingWidgetState();
}

class _MultiLayerPricingWidgetState extends State<MultiLayerPricingWidget> {
  late Map<String, dynamic> _pricing;
  late Map<PricingTier, double> _tierPrices;
  late Map<PricingTier, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _initializePricing();
  }

  void _initializePricing() {
    _pricing = Map.from(widget.initialPricing);

    // Initialize tier prices
    _tierPrices = {
      PricingTier.basic: _pricing['basic']?.toDouble() ?? 0.0,
      PricingTier.standard: _pricing['standard']?.toDouble() ?? 0.0,
      PricingTier.premium: _pricing['premium']?.toDouble() ?? 0.0,
      PricingTier.enterprise: _pricing['enterprise']?.toDouble() ?? 0.0,
    };

    // Initialize controllers
    _controllers = {
      PricingTier.basic: TextEditingController(
        text: _tierPrices[PricingTier.basic]?.toStringAsFixed(2) ?? '0.00',
      ),
      PricingTier.standard: TextEditingController(
        text: _tierPrices[PricingTier.standard]?.toStringAsFixed(2) ?? '0.00',
      ),
      PricingTier.premium: TextEditingController(
        text: _tierPrices[PricingTier.premium]?.toStringAsFixed(2) ?? '0.00',
      ),
      PricingTier.enterprise: TextEditingController(
        text: _tierPrices[PricingTier.enterprise]?.toStringAsFixed(2) ?? '0.00',
      ),
    };

    // Add listeners
    _controllers.forEach((tier, controller) {
      controller.addListener(() => _updatePrice(tier, controller.text));
    });
  }

  void _updatePrice(PricingTier tier, String value) {
    final price = double.tryParse(value) ?? 0.0;
    setState(() {
      _tierPrices[tier] = price;
      _pricing[tier.toString().split('.').last] = price;
    });
    widget.onPricingChanged(_pricing);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing Tiers',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...PricingTier.values.map((tier) => _buildPricingTierCard(tier)),
        const SizedBox(height: 16),
        _buildPricingSummary(),
      ],
    );
  }

  Widget _buildPricingTierCard(PricingTier tier) {
    final controller = _controllers[tier]!;
    final price = _tierPrices[tier]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTierColor(tier).withOpacity(0.05),
        border: Border.all(
          color: _getTierColor(tier).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTierColor(tier),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tier.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'RM ${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getTierColor(tier),
                ),
              ),
            ],
          ),
          if (widget.showTierDescriptions) ...[
            const SizedBox(height: 8),
            Text(
              tier.description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Price (RM)',
              prefixText: 'RM ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _getTierColor(tier),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary() {
    final prices = _tierPrices.values.where((price) => price > 0).toList();
    if (prices.isEmpty) return const SizedBox.shrink();

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Range:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                'RM ${minPrice.toStringAsFixed(2)} - RM ${maxPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                'RM ${avgPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTierColor(PricingTier tier) {
    switch (tier) {
      case PricingTier.basic:
        return Colors.green;
      case PricingTier.standard:
        return Colors.blue;
      case PricingTier.premium:
        return Colors.purple;
      case PricingTier.enterprise:
        return Colors.orange;
    }
  }
}

class QuickPricingTemplateWidget extends StatelessWidget {
  final Function(Map<PricingTier, double>) onTemplateApplied;

  const QuickPricingTemplateWidget({
    super.key,
    required this.onTemplateApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Pricing Templates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTemplateButton(
                'Budget Friendly',
                'Lower prices for cost-conscious customers',
                () => _applyBudgetTemplate(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTemplateButton(
                'Premium Focus',
                'Higher prices for luxury market',
                () => _applyPremiumTemplate(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTemplateButton(
                'Tiered Value',
                'Clear value progression across tiers',
                () => _applyTieredTemplate(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTemplateButton(
                'Reset to Zero',
                'Clear all pricing',
                () => _applyResetTemplate(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateButton(String title, String description, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _applyBudgetTemplate() {
    final template = {
      PricingTier.basic: 99.0,
      PricingTier.standard: 199.0,
      PricingTier.premium: 299.0,
      PricingTier.enterprise: 499.0,
    };
    onTemplateApplied(template);
  }

  void _applyPremiumTemplate() {
    final template = {
      PricingTier.basic: 299.0,
      PricingTier.standard: 599.0,
      PricingTier.premium: 999.0,
      PricingTier.enterprise: 1999.0,
    };
    onTemplateApplied(template);
  }

  void _applyTieredTemplate() {
    final template = {
      PricingTier.basic: 149.0,
      PricingTier.standard: 299.0,
      PricingTier.premium: 599.0,
      PricingTier.enterprise: 999.0,
    };
    onTemplateApplied(template);
  }

  void _applyResetTemplate() {
    final template = {
      PricingTier.basic: 0.0,
      PricingTier.standard: 0.0,
      PricingTier.premium: 0.0,
      PricingTier.enterprise: 0.0,
    };
    onTemplateApplied(template);
  }
}

class PricingComparisonWidget extends StatelessWidget {
  final Map<PricingTier, double> currentPrices;
  final Map<PricingTier, double> competitorPrices;

  const PricingComparisonWidget({
    super.key,
    required this.currentPrices,
    required this.competitorPrices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...PricingTier.values.map((tier) => _buildComparisonRow(tier)),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(PricingTier tier) {
    final currentPrice = currentPrices[tier] ?? 0.0;
    final competitorPrice = competitorPrices[tier] ?? 0.0;
    final difference = currentPrice - competitorPrice;
    final isLower = difference < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              tier.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'RM ${currentPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'RM ${competitorPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              isLower ? '-RM ${difference.abs().toStringAsFixed(2)}' : '+RM ${difference.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLower ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
