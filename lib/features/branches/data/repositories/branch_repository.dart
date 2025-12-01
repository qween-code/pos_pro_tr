import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/branch_model.dart';
import '../../../../core/services/firebase_service.dart';

import 'dart:io';

class BranchRepository {
  FirebaseFirestore? _firestore;
  final String _collectionName = 'branches';

  BranchRepository() {
    _firestore = FirebaseService.instance.firestore;
  }

  Future<List<Branch>> getBranches() async {
    if (_firestore == null) return [];
    final snapshot = await _firestore!.collection(_collectionName).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Branch.fromJson(data);
    }).toList();
  }

  Future<Branch?> getBranchById(String id) async {
    if (_firestore == null) return null;
    final doc = await _firestore!.collection(_collectionName).doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Branch.fromJson(data);
  }

  Future<String> insertBranch(Branch branch) async {
    if (_firestore == null) return 'offline_branch_${DateTime.now().millisecondsSinceEpoch}';
    final docRef = await _firestore!.collection(_collectionName).add(branch.toJson());
    return docRef.id;
  }

  Future<void> updateBranch(Branch branch) async {
    if (_firestore == null) return;
    if (branch.id == null) throw Exception('Branch ID is required for update');
    await _firestore!.collection(_collectionName).doc(branch.id).update(branch.toJson());
  }

  Future<void> deleteBranch(String id) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collectionName).doc(id).delete();
  }

  Stream<List<Branch>> watchBranches() {
    if (_firestore == null) return Stream.value([]);
    return _firestore!.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Branch.fromJson(data);
      }).toList();
    });
  }
}
