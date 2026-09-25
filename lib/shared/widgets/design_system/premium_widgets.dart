import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:eventease/core/utils/ee_design_tokens.dart';

/// Glassmorphism card for auth and hero overlays.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? maxWidth;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EEDesignTokens.spaceLg),
    this.width,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EEDesignTokens.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
          padding: padding,
          decoration: EEDesignTokens.glassDecoration(),
          child: child,
        ),
      ),
    );
  }
}

/// Premium pill badge for verified/pro/premium status.
class PillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(EEDesignTokens.radiusPill),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? bg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: EEDesignTokens.labelMedium.copyWith(
              color: textColor ?? bg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip for search/discovery.
class FilterChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: EEDesignTokens.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(EEDesignTokens.radiusPill),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
          ),
          boxShadow: selected ? EEDesignTokens.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : theme.colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pressable card with subtle scale animation.
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: EEDesignTokens.animFast,
        child: AnimatedContainer(
          duration: EEDesignTokens.animFast,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EEDesignTokens.radiusLg),
            boxShadow: _pressed ? [] : EEDesignTokens.cardShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
