import 'package:flutter/material.dart';
import 'package:eventease/shared/models/ad_models.dart';
import 'package:eventease/core/services/supabase_service.dart';

class AdProvider extends ChangeNotifier {
  List<AdConfiguration> _ads = [];
  List<AdPlacement> _placements = [];
  bool _isLoading = false;

  AdProvider() {
    _init();
  }

  Future<void> _init() async {
    await refreshData();
  }

  List<AdConfiguration> get ads => List.unmodifiable(_ads);
  List<AdPlacement> get placements => List.unmodifiable(_placements);
  bool get isLoading => _isLoading;

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchAds(),
        fetchPlacements(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing ad data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAds() async {
    try {
      final res = await SupabaseService.select(table: 'admin_ads_v2', orderBy: 'created_at', ascending: false);
      _ads = res.map((m) => AdConfiguration.fromMap(_mapToCamelCase(m))).toList();
    } catch (e) {
      debugPrint('Error fetching ads: $e');
      rethrow;
    }
  }

  Future<void> fetchPlacements() async {
    try {
      final res = await SupabaseService.select(table: 'admin_ad_placements', orderBy: 'id');
      _placements = res.map((m) => AdPlacement.fromMap(_mapToCamelCase(m))).toList();
    } catch (e) {
      debugPrint('Error fetching placements: $e');
      rethrow;
    }
  }

  AdConfiguration? getBestAdForPlacement(String placementId) {
    if (_placements.isEmpty) return null;
    
    final placement = _placements.firstWhere(
      (p) => p.id == placementId && p.isEnabled,
      orElse: () => AdPlacement(
        id: '',
        name: '',
        description: '',
        adType: AdType.banner,
        screen: '',
        position: '',
        adIds: [],
      ),
    );

    if (placement.id.isEmpty || placement.adIds.isEmpty) {
      return null;
    }

    // Get active ads for this placement
    final availableAds = _ads.where((ad) =>
      placement.adIds.contains(ad.id) &&
      ad.isActive
    ).toList();

    if (availableAds.isEmpty) {
      return null;
    }

    // Sort by priority (higher priority first)
    availableAds.sort((a, b) => b.priority.compareTo(a.priority));

    // Return the highest priority ad
    return availableAds.first;
  }

  Map<String, dynamic> getAdAnalytics(String adId) {
    try {
        final ad = _ads.firstWhere((a) => a.id == adId);
        final ctr = ad.currentImpressions > 0
            ? (ad.currentClicks / ad.currentImpressions) * 100
            : 0.0;

        return {
        'impressions': ad.currentImpressions,
        'clicks': ad.currentClicks,
        'ctr': ctr,
        };
    } catch (e) {
        return {'impressions': 0, 'clicks': 0, 'ctr': 0.0};
    }
  }

  Future<void> recordImpression(String adId) async {
    final index = _ads.indexWhere((ad) => ad.id == adId);
    if (index != -1) {
      final ad = _ads[index];
      final newCount = ad.currentImpressions + 1;
      
      try {
        await SupabaseService.update(
          table: 'admin_ads_v2',
          data: {'current_impressions': newCount, 'updated_at': DateTime.now().toIso8601String()},
          column: 'id',
          value: adId,
        );
        _ads[index] = ad.copyWith(currentImpressions: newCount, updatedAt: DateTime.now());
        notifyListeners();
      } catch (e) {
        debugPrint('Error recording impression: $e');
      }
    }
  }

  Future<void> recordClick(String adId) async {
    final index = _ads.indexWhere((ad) => ad.id == adId);
    if (index != -1) {
      final ad = _ads[index];
      final newCount = ad.currentClicks + 1;

      try {
        await SupabaseService.update(
          table: 'admin_ads_v2',
          data: {'current_clicks': newCount, 'updated_at': DateTime.now().toIso8601String()},
          column: 'id',
          value: adId,
        );
        _ads[index] = ad.copyWith(currentClicks: newCount, updatedAt: DateTime.now());
        notifyListeners();
      } catch (e) {
        debugPrint('Error recording click: $e');
      }
    }
  }

  Future<void> addAd(AdConfiguration ad) async {
    try {
      final res = await SupabaseService.insert(
        table: 'admin_ads_v2',
        data: _mapToSnakeCase(ad.toMap()..remove('id')),
      );
      if (res.isNotEmpty) {
        _ads.insert(0, AdConfiguration.fromMap(_mapToCamelCase(res.first)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding ad: $e');
      rethrow;
    }
  }

  Future<void> updateAd(AdConfiguration updatedAd) async {
    try {
      final res = await SupabaseService.update(
        table: 'admin_ads_v2',
        data: _mapToSnakeCase(updatedAd.toMap()),
        column: 'id',
        value: updatedAd.id,
      );
      if (res.isNotEmpty) {
        final index = _ads.indexWhere((ad) => ad.id == updatedAd.id);
        if (index != -1) {
          _ads[index] = AdConfiguration.fromMap(_mapToCamelCase(res.first));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating ad: $e');
      rethrow;
    }
  }

  Future<void> deleteAd(String adId) async {
    try {
      await SupabaseService.delete(table: 'admin_ads_v2', column: 'id', value: adId);
      _ads.removeWhere((ad) => ad.id == adId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting ad: $e');
      rethrow;
    }
  }

  Future<void> updatePlacement(AdPlacement updatedPlacement) async {
    try {
      final res = await SupabaseService.update(
        table: 'admin_ad_placements',
        data: _mapToSnakeCase(updatedPlacement.toMap()),
        column: 'id',
        value: updatedPlacement.id,
      );
      if (res.isNotEmpty) {
        final index = _placements.indexWhere((p) => p.id == updatedPlacement.id);
        if (index != -1) {
          _placements[index] = AdPlacement.fromMap(_mapToCamelCase(res.first));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating placement: $e');
      rethrow;
    }
  }

  // Get active ads count
  int get activeAdsCount => _ads.where((ad) => ad.status == AdStatus.active).length;

  // Get total impressions across all ads
  int get totalImpressions => _ads.fold(0, (sum, ad) => sum + ad.currentImpressions);

  // Get total clicks across all ads
  int get totalClicks => _ads.fold(0, (sum, ad) => sum + ad.currentClicks);

  // Get overall CTR
  double get overallCTR {
    final totalImp = totalImpressions;
    return totalImp > 0 ? (totalClicks / totalImp) * 100 : 0.0;
  }

  // Helpers for mapping snake_case <-> camelCase
  Map<String, dynamic> _mapToCamelCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      final camelKey = _toCamelCase(key);
      result[camelKey] = value;
    });
    return result;
  }

  Map<String, dynamic> _mapToSnakeCase(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      final snakeKey = _toSnakeCase(key);
      result[snakeKey] = value;
    });
    return result;
  }

  String _toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length <= 1) return snakeCase;
    return parts[0] + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  String _toSnakeCase(String camelCase) {
    return camelCase.replaceAllMapped(RegExp('([A-Z])'), (match) => '_${match.group(1)!.toLowerCase()}');
  }
}