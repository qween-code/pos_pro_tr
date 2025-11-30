import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';

class BranchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'branches';

  Future<List<Branch>> getBranches() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Branch.fromJson(data);
    }).toList();
  }

  Future<Branch?> getBranchById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Branch.fromJson(data);
  }

  Future<String> insertBranch(Branch branch) async {
    final docRef = await _firestore.collection(_collectionName).add(branch.toJson());
    return docRef.id;
  }

  Future<void> updateBranch(Branch branch) async {
    if (branch.id == null) throw Exception('Branch ID is required for update');
    await _firestore.collection(_collectionName).doc(branch.id).update(branch.toJson());
  }

  Future<void> deleteBranch(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Stream<List<Branch>> watchBranches() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Branch.fromJson(data);
      }).toList();
    });
  }
}
