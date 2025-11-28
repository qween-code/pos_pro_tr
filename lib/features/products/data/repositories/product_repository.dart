import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'products';

  Future<String> insertProduct(Product product) async {
    final docRef = await _firestore.collection(_collectionName).add(product.toJson());
    return docRef.id;
  }

  Future<List<Product>> getProducts({int limit = 100}) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .limit(limit)
      .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Firestore document ID'sini ekliyoruz
      return Product.fromJson(data);
    }).toList();
  }

  // Pagination ile ürünleri getir
  Future<List<Product>> getProductsPaginated({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection(_collectionName).limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null) throw Exception('Ürün ID bulunamadı');
    await _firestore.collection(_collectionName).doc(product.id.toString()).update(product.toJson());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Future<Product?> getProductById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Product.fromJson(data);
    }
    return null;
  }

  Future<List<Product>> searchProducts(String query, {int limit = 50}) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThanOrEqualTo: '$query\uf8ff')
      .limit(limit)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('category', isEqualTo: category)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }

  Future<List<Product>> getLowStockProducts(int threshold) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('stock', isLessThanOrEqualTo: threshold)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Product.fromJson(data);
    }).toList();
  }
}