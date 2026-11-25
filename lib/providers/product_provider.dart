import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/mock_data_service.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

enum ProductSortOption {
  featured,
  priceAsc,
  priceDesc,
  ratingDesc,
  discountDesc,
}

extension ProductSortOptionExtension on ProductSortOption {
  String get label {
    switch (this) {
      case ProductSortOption.featured:
        return 'Nổi bật nhất';
      case ProductSortOption.priceAsc:
        return 'Giá: Thấp → Cao';
      case ProductSortOption.priceDesc:
        return 'Giá: Cao → Thấp';
      case ProductSortOption.ratingDesc:
        return 'Đánh giá cao';
      case ProductSortOption.discountDesc:
        return 'Ưu đãi sâu';
    }
  }
}

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  String _selectedCategory = 'Tất cả';
  String _selectedCertification = 'Tất cả';
  String? _selectedFarmId;
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.featured;
  bool _isLoading = false;

  List<ProductModel> get products => _products;
  String get selectedCategory => _selectedCategory;
  String get selectedCertification => _selectedCertification;
  String? get selectedFarmId => _selectedFarmId;
  String get searchQuery => _searchQuery;
  ProductSortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;

  bool get hasActiveFilters =>
      _selectedCategory != 'Tất cả' ||
      _selectedCertification != 'Tất cả' ||
      _selectedFarmId != null ||
      _searchQuery.isNotEmpty ||
      _sortOption != ProductSortOption.featured;

  ProductProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    // 1. Try loading from Firestore if connected
    final firestoreProducts = await FirebaseService.getProductsFromFirestore();
    if (firestoreProducts != null && firestoreProducts.isNotEmpty) {
      _products = firestoreProducts;
    } else {
      // 2. Try loading from Local Storage
      final cached = await StorageService.getProducts();
      if (cached != null && cached.isNotEmpty) {
        _products = cached;
      } else {
        // 3. Fallback to rich Mock Data
        _products = MockDataService.getMockProducts();
        await StorageService.saveProducts(_products);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  List<String> get categories {
    final Set<String> cats = {'Tất cả'};
    for (var p in _products) {
      cats.add(p.category);
    }
    return cats.toList();
  }

  List<String> get certifications {
    return ['Tất cả', 'VietGAP', 'GlobalGAP', 'Organic USDA', 'OCOP 4 Sao'];
  }

  List<ProductModel> get filteredProducts {
    final list = _products.where((p) {
      final matchCategory =
          _selectedCategory == 'Tất cả' || p.category == _selectedCategory;
      final matchCert =
          _selectedCertification == 'Tất cả' ||
          p.certification == _selectedCertification;
      final matchFarm =
          _selectedFarmId == null || p.farmId == _selectedFarmId;
      final q = _searchQuery.trim().toLowerCase();
      final matchQuery =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.region.toLowerCase().contains(q) ||
          p.farmName.toLowerCase().contains(q) ||
          p.certification.toLowerCase().contains(q);
      return matchCategory && matchCert && matchFarm && matchQuery;
    }).toList();

    switch (_sortOption) {
      case ProductSortOption.featured:
        list.sort((a, b) {
          if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
          return b.reviewCount.compareTo(a.reviewCount);
        });
        break;
      case ProductSortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.ratingDesc:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSortOption.discountDesc:
        double discountRate(ProductModel p) {
          if (p.originalPrice == null || p.originalPrice! <= p.price) return 0;
          return (p.originalPrice! - p.price) / p.originalPrice!;
        }
        list.sort((a, b) => discountRate(b).compareTo(discountRate(a)));
        break;
    }
    return list;
  }

  List<ProductModel> get featuredProducts {
    return _products.where((p) => p.isFeatured).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setCertification(String cert) {
    _selectedCertification = cert;
    notifyListeners();
  }

  void setFarmFilter(String? farmId) {
    _selectedFarmId = _selectedFarmId == farmId ? null : farmId;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = 'Tất cả';
    _selectedCertification = 'Tất cả';
    _selectedFarmId = null;
    _searchQuery = '';
    _sortOption = ProductSortOption.featured;
    notifyListeners();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProduct(ProductModel product) async {
    _products.insert(0, product);
    await StorageService.saveProducts(_products);
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      await StorageService.saveProducts(_products);
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    await StorageService.saveProducts(_products);
    notifyListeners();
  }

  void deductStock(String productId, int quantity) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final newQty = (current.stockQuantity - quantity).clamp(0, 99999);
      _products[index] = current.copyWith(stockQuantity: newQty);
      StorageService.saveProducts(_products);
      notifyListeners();
    }
  }
}

