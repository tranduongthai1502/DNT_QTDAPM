import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/batch_model.dart';
import '../firebase_options.dart';
import 'mock_data_service.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      // The demo has no sign-in screen yet. An anonymous Firebase session
      // gives Storage a verified identity without exposing public write access.
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (e) {
          // Firestore can still be used if Anonymous Auth is not enabled yet.
          if (kDebugMode) print('Anonymous Firebase Auth unavailable: $e');
        }
      }
      if (kDebugMode) {
        print('Firebase successfully initialized for project: dnt-q-90cae');
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('Firebase running in local offline mode: $e');
      }
    }
  }

  // --- Firestore Integration with Safe Fallback ---

  static Future<List<ProductModel>?> getProductsFromFirestore() async {
    if (!_isInitialized) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Firestore read products error: $e');
      return null;
    }
  }

  static Future<void> syncOrderToFirestore(OrderModel order) async {
    if (!_isInitialized) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .set(order.toMap(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('Firestore write order error: $e');
    }
  }

  static Future<void> syncBatchToFirestore(BatchModel batch) async {
    if (!_isInitialized) return;
    try {
      await FirebaseFirestore.instance
          .collection('batches')
          .doc(batch.id)
          .set(batch.toMap(), SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('Firestore write batch error: $e');
    }
  }

  /// Uploads a product image from a local asset or external URL to Firebase Storage.
  /// Returns the permanent Firebase download URL, or null if the upload fails.
  static Future<String?> uploadProductImage({
    required String productId,
    required String imageUrl,
  }) async {
    if (!_isInitialized || imageUrl.isEmpty) return null;
    if (imageUrl.contains('firebasestorage.googleapis.com')) return imageUrl;

    try {
      Uint8List bytes;
      String contentType;
      String extension;

      if (imageUrl.startsWith('assets/')) {
        final data = await rootBundle.load(imageUrl);
        bytes = data.buffer.asUint8List();
        final isPng = imageUrl.toLowerCase().endsWith('.png');
        extension = isPng ? 'png' : 'jpg';
        contentType = isPng ? 'image/png' : 'image/jpeg';
      } else {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        bytes = response.bodyBytes;
        extension = imageUrl.toLowerCase().contains('.png') ? 'png' : 'jpg';
        contentType = response.headers['content-type'] ?? 'image/jpeg';
      }

      final reference = FirebaseStorage.instance.ref(
        'products/$productId.$extension',
      );
      await reference.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public,max-age=86400',
        ),
      );
      return await reference.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print('Firebase Storage image upload error: $e');
      return null;
    }
  }

  static Future<String?> uploadImageBytes({
    required String storagePath,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    if (!_isInitialized || bytes.isEmpty) return null;
    try {
      final reference = FirebaseStorage.instance.ref(storagePath);
      await reference.putData(
        bytes,
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public,max-age=86400',
        ),
      );
      return await reference.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print('Firebase Storage local image upload error: $e');
      return null;
    }
  }

  static Future<BatchModel?> getBatchByCode(String code) async {
    if (!_isInitialized) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('batches')
          .doc(code)
          .get();
      if (doc.exists && doc.data() != null) {
        return BatchModel.fromMap(doc.data()!);
      }
    } catch (e) {
      if (kDebugMode) print('Firestore fetch batch error: $e');
    }
    return null;
  }

  /// Pushes all agricultural products, traceability batches, farms, and orders into Cloud Firestore
  static Future<bool> seedAllDataToFirestore() async {
    if (!_isInitialized) return false;
    try {
      final firestore = FirebaseFirestore.instance;

      for (final p in MockDataService.getMockProducts()) {
        final imageUrl = await uploadProductImage(
          productId: p.id,
          imageUrl: p.imageUrl,
        );
        final productData = p.toMap();
        if (imageUrl != null) productData['imageUrl'] = imageUrl;
        productData['imageStoragePath'] = 'products/${p.id}';
        productData['updatedAt'] = FieldValue.serverTimestamp();
        await firestore
            .collection('products')
            .doc(p.id)
            .set(productData, SetOptions(merge: true));
      }
      for (final b in MockDataService.getMockBatches()) {
        await firestore
            .collection('batches')
            .doc(b.id)
            .set(b.toMap(), SetOptions(merge: true));
      }
      for (final f in MockDataService.getMockFarms()) {
        await firestore
            .collection('farms')
            .doc(f.id)
            .set(f.toMap(), SetOptions(merge: true));
      }
      for (final o in MockDataService.getMockOrders()) {
        await firestore
            .collection('orders')
            .doc(o.id)
            .set(o.toMap(), SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error seeding data to Firestore: $e');
      return false;
    }
  }

  static Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    if (!_isInitialized) return null;
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (kDebugMode) print('Firebase Auth sign in error: $e');
      rethrow;
    }
  }
}
