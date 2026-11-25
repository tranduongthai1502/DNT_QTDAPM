import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Renders product or banner images from local bundled assets, Firebase Storage,
/// or external URLs, while remapping legacy mismatched Unsplash seed URLs to
/// verified local agricultural photography.
class FreshFarmImage extends StatelessWidget {
  final String imageUrl;
  final String? productId;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double fallbackIconSize;

  const FreshFarmImage({
    super.key,
    required this.imageUrl,
    this.productId,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIconSize = 40,
  });

  static const Map<String, String> _productAssetById = {
    'PROD-001': 'assets/images/products/prod_001.jpg',
    'PROD-002': 'assets/images/products/prod_002.jpg',
    'PROD-003': 'assets/images/products/prod_003.jpg',
    'PROD-004': 'assets/images/products/prod_004.jpg',
    'PROD-005': 'assets/images/products/prod_005.jpg',
    'PROD-006': 'assets/images/products/prod_006.jpg',
    'PROD-007': 'assets/images/products/prod_007.jpg',
    'PROD-008': 'assets/images/products/prod_008.jpg',
  };

  static const Map<String, String> _legacyUrlToAsset = {
    'photo-1592924357228-91a4daadcfea': 'assets/images/products/prod_001.jpg',
    'photo-1598170845058-32b9d6a5da37': 'assets/images/products/prod_002.jpg',
    'photo-1587334274328-64186a80aeee': 'assets/images/products/prod_003.jpg',
    'photo-1523049673857-eb18f1d7b578': 'assets/images/products/prod_004.jpg',
    'photo-1540420773420-3366772f4999': 'assets/images/products/prod_005.jpg',
    'photo-1557800636-894a64c1696f': 'assets/images/products/prod_006.jpg',
    'photo-1524179091875-bf99a9a6fa57': 'assets/images/products/prod_007.jpg',
    'photo-1553279768-865429fa0078': 'assets/images/products/prod_008.jpg',
    'photo-1542838132-92c53300491e': 'assets/images/hero_freshfarm.jpg',
  };

  /// Resolves an image reference to a local asset path when applicable.
  static String? resolveLocalAsset(String url, {String? productId}) {
    if (url.startsWith('assets/')) return url;
    for (final entry in _legacyUrlToAsset.entries) {
      if (url.contains(entry.key)) return entry.value;
    }
    if (url.isEmpty && productId != null) {
      return _productAssetById[productId];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localAsset = resolveLocalAsset(imageUrl, productId: productId);
    if (localAsset != null) {
      return Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (imageUrl.isEmpty) return _fallback();

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppColors.surfaceVariant.withOpacity(0.6),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        final idAsset = productId != null ? _productAssetById[productId] : null;
        if (idAsset != null) {
          return Image.asset(
            idAsset,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallback(),
          );
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() => Container(
    width: width,
    height: height,
    color: AppColors.surfaceVariant,
    child: Center(
      child: Icon(
        Icons.eco_rounded,
        color: AppColors.primary,
        size: fallbackIconSize,
      ),
    ),
  );
}
