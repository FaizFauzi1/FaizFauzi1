import 'package:flutter/material.dart';
import 'package:eventease/shared/models/ad_models.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:provider/provider.dart';

// Import the AdProvider after it's created
import 'package:eventease/core/providers/ad_provider.dart';

class BannerAdWidget extends StatefulWidget {
  final String placementId;
  final double height;

  const BannerAdWidget({
    super.key,
    required this.placementId,
    this.height = 50.0,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  AdConfiguration? _currentAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adProvider = context.read<AdProvider>();
    _currentAd = adProvider.getBestAdForPlacement(widget.placementId);

    if (_currentAd != null) {
      // Record impression
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adProvider.recordImpression(_currentAd!.id);
      });
    }
  }

  void _onAdTap() {
    if (_currentAd != null) {
      final adProvider = context.read<AdProvider>();
      adProvider.recordClick(_currentAd!.id);

      // Handle ad click (open URL, navigate, etc.)
      if (_currentAd!.targetUrl != null) {
        // For now, just show a snackbar. In real app, open URL or navigate
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad clicked: ${_currentAd!.title ?? 'Ad'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAd == null) {
      return SizedBox(height: widget.height);
    }

    return GestureDetector(
      onTap: _onAdTap,
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _currentAd!.imageUrl != null
              ? Image.network(
                  _currentAd!.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildTextAd();
                  },
                )
              : _buildTextAd(),
        ),
      ),
    );
  }

  Widget _buildTextAd() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.ad_units, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentAd!.title ?? 'Advertisement',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_currentAd!.subtitle != null)
                  Text(
                    _currentAd!.subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_currentAd!.callToAction != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentAd!.callToAction!,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NativeAdWidget extends StatefulWidget {
  final String placementId;

  const NativeAdWidget({
    super.key,
    required this.placementId,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  AdConfiguration? _currentAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adProvider = context.read<AdProvider>();
    _currentAd = adProvider.getBestAdForPlacement(widget.placementId);

    if (_currentAd != null) {
      // Record impression
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adProvider.recordImpression(_currentAd!.id);
      });
    }
  }

  void _onAdTap() {
    if (_currentAd != null) {
      final adProvider = context.read<AdProvider>();
      adProvider.recordClick(_currentAd!.id);

      // Handle ad click
      if (_currentAd!.targetUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ad clicked: ${_currentAd!.title ?? 'Ad'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAd == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _onAdTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ad indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.ad_units,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Ad content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sponsored',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentAd!.title ?? 'Advertisement',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (_currentAd!.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _currentAd!.subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_currentAd!.callToAction != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _currentAd!.callToAction!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Ad image (if available)
            if (_currentAd!.imageUrl != null)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_currentAd!.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InterstitialAdManager {
  static DateTime? _lastShown;
  static const Duration _minInterval = Duration(minutes: 3);

  static bool shouldShowInterstitial(String placementId, BuildContext context) {
    final adProvider = context.read<AdProvider>();
    final ad = adProvider.getBestAdForPlacement(placementId);

    if (ad == null || ad.type != AdType.interstitial) {
      return false;
    }

    // Check if enough time has passed since last interstitial
    if (_lastShown != null) {
      final timeSinceLast = DateTime.now().difference(_lastShown!);
      if (timeSinceLast < _minInterval) {
        return false;
      }
    }

    return true;
  }

  static Future<void> showInterstitial(String placementId, BuildContext context) async {
    final adProvider = context.read<AdProvider>();
    final ad = adProvider.getBestAdForPlacement(placementId);

    if (ad == null || ad.type != AdType.interstitial) {
      return;
    }

    // Record impression
    adProvider.recordImpression(ad.id);

    // Show interstitial dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InterstitialAdDialog(ad: ad, adProvider: adProvider),
    );

    _lastShown = DateTime.now();
  }
}

class InterstitialAdDialog extends StatefulWidget {
  final AdConfiguration ad;
  final AdProvider adProvider;

  const InterstitialAdDialog({
    super.key,
    required this.ad,
    required this.adProvider,
  });

  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog> {
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _secondsRemaining--;
        });
        if (_secondsRemaining > 0) {
          _startCountdown();
        }
      }
    });
  }

  void _onAdTap() {
    widget.adProvider.recordClick(widget.ad.id);

    if (widget.ad.targetUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ad clicked: ${widget.ad.title ?? 'Ad'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: _secondsRemaining > 0 ? null : () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: _secondsRemaining > 0 ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),

            // Ad content
            Expanded(
              child: GestureDetector(
                onTap: _onAdTap,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ad image
                      if (widget.ad.imageUrl != null)
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(widget.ad.imageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Ad text content
                      Text(
                        widget.ad.title ?? 'Advertisement',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (widget.ad.subtitle != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.ad.subtitle!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Call to action button
                      if (widget.ad.callToAction != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            widget.ad.callToAction!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Countdown or close text
                      Text(
                        _secondsRemaining > 0
                            ? 'You can close this ad in $_secondsRemaining seconds'
                            : 'Tap anywhere to interact or close',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}