import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../../../../core/services/firebase_service.dart';

class CustomerRepository {
  final FirebaseFirestore? _firestore = FirebaseService.instance.firestore;
  final String _collectionName = 'customers';

  Future<String> insertCustomer(Customer customer) async {
    if (_firestore == null) return 'offline_customer_${DateTime.now().millisecondsSinceEpoch}';
    final docRef = await _firestore!.collection(_collectionName).add(customer.toJson());
    return docRef.id;
  }

  Future<List<Customer>> getCustomers({int limit = 100}) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_collectionName)
      .limit(limit)
      .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Firestore document ID'sini ekliyoruz
      return Customer.fromJson(data);
    }).toList();
  }

  // Pagination ile müşterileri getir
  Future<List<Customer>> getCustomersPaginated({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    if (_firestore == null) return [];
    Query query = _firestore!.collection(_collectionName).limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Customer.fromJson(data);
    }).toList();
  }

  Future<void> updateCustomer(Customer customer) async {
    if (_firestore == null) return;
    if (customer.id == null) throw Exception('Müşteri ID bulunamadı');
    await _firestore!.collection(_collectionName).doc(customer.id.toString()).update(customer.toJson());
  }

  Future<void> deleteCustomer(String id) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collectionName).doc(id).delete();
  }

  Future<Customer?> getCustomerById(String id) async {
    if (_firestore == null) return null;
    final doc = await _firestore!.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Customer.fromJson(data);
    }
    return null;
  }

  Future<List<Customer>> searchCustomers(String query, {int limit = 50}) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_collectionName)
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThanOrEqualTo: '$query\uf8ff')
      .limit(limit)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Customer.fromJson(data);
    }).toList();
  }

  Future<List<Customer>> getCustomersByName(String name) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_collectionName)
      .where('name', isEqualTo: name)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Customer.fromJson(data);
    }).toList();
  }
  Future<void> updateBalance(String customerId, double amount) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collectionName).doc(customerId).update({
      'balance': FieldValue.increment(amount),
    });
  }
}