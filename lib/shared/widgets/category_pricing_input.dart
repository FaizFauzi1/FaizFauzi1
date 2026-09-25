import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventease/shared/models/services/service_category.dart';

/// Dynamic pricing input widget that adapts based on category pricing model
class CategoryPricingInput extends StatelessWidget {
  final ServiceCategory category;
  final double? basePrice;
  final Function(double?) onPriceChanged;
  final String? errorText;

  const CategoryPricingInput({
    Key? key,
    required this.category,
    this.basePrice,
    required this.onPriceChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pricing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildPricingModelInfo(context),
            const SizedBox(height: 16),
            _buildPriceInput(context),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildPricingExamples(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingModelInfo(BuildContext context) {
    IconData icon;
    String description;
    Color color;

    switch (category.pricingModel) {
      case PricingModel.perPax:
        icon = Icons.people;
        description = 'Price charged per person/guest';
        color = Colors.blue;
        break;
      case PricingModel.perDay:
        icon = Icons.calendar_today;
        description = 'Price charged per day';
        color = Colors.green;
        break;
      case PricingModel.perSession:
        icon = Icons.event;
        description = 'Price charged per session/event';
        color = Colors.orange;
        break;
      case PricingModel.perHour:
        icon = Icons.access_time;
        description = 'Price charged per hour';
        color = Colors.purple;
        break;
      case PricingModel.fixed:
        icon = Icons.attach_money;
        description = 'Fixed price for the service';
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.pricingModel.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInput(BuildContext context) {
    return TextFormField(
      initialValue: basePrice?.toString(),
      decoration: InputDecoration(
        labelText: _getPriceLabel(),
        hintText: _getPriceHint(),
        prefixText: 'RM ',
        suffixText: _getPriceSuffix(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a price';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Please enter a valid price';
        }
        return null;
      },
      onChanged: (value) {
        final price = double.tryParse(value);
        onPriceChanged(price);
      },
    );
  }

  String _getPriceLabel() {
    switch (category.pricingModel) {
      case PricingModel.perPax:
        return 'Price Per Person';
      case PricingModel.perDay:
        return 'Price Per Day';
      case PricingModel.perSession:
        return 'Price Per Session';
      case PricingModel.perHour:
        return 'Price Per Hour';
      case PricingModel.fixed:
        return 'Fixed Price';
    }
  }

  String _getPriceHint() {
    switch (category.pricingModel) {
      case PricingModel.perPax:
        return 'e.g., 50.00';
      case PricingModel.perDay:
        return 'e.g., 2000.00';
      case PricingModel.perSession:
        return 'e.g., 1500.00';
      case PricingModel.perHour:
        return 'e.g., 200.00';
      case PricingModel.fixed:
        return 'e.g., 5000.00';
    }
  }

  String _getPriceSuffix() {
    switch (category.pricingModel) {
      case PricingModel.perPax:
        return '/ person';
      case PricingModel.perDay:
        return '/ day';
      case PricingModel.perSession:
        return '/ session';
      case PricingModel.perHour:
        return '/ hour';
      case PricingModel.fixed:
        return '';
    }
  }

  Widget _buildPricingExamples(BuildContext context) {
    String example;
    
    switch (category.pricingModel) {
      case PricingModel.perPax:
        example = 'Example: RM 50/pax × 100 guests = RM 5,000';
        break;
      case PricingModel.perDay:
        example = 'Example: RM 2,000/day × 2 days = RM 4,000';
        break;
      case PricingModel.perSession:
        example = 'Example: RM 1,500 per event session';
        break;
      case PricingModel.perHour:
        example = 'Example: RM 200/hour × 4 hours = RM 800';
        break;
      case PricingModel.fixed:
        example = 'Example: RM 5,000 total (no multiplier)';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              example,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display pricing preview based on quantity
class PricingPreview extends StatelessWidget {
  final ServiceCategory category;
  final double basePrice;
  final int quantity;

  const PricingPreview({
    Key? key,
    required this.category,
    required this.basePrice,
    this.quantity = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = basePrice * quantity;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing Preview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base Price:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                category.pricingModel.formatPrice(basePrice),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (category.pricingModel != PricingModel.fixed && quantity > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantity:',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  '$quantity ${category.pricingModel.unit}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'RM ${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
