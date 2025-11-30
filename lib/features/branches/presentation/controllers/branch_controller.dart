import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/branch_model.dart';
import '../../data/repositories/branch_repository.dart';

class BranchController extends GetxController {
  final BranchRepository _branchRepository = BranchRepository();
  
  final RxList<Branch> branches = <Branch>[].obs;
  final Rx<Branch?> selectedBranch = Rx<Branch?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    fetchBranches();
    loadSelectedBranch();
  }

  Future<void> fetchBranches() async {
    isLoading.value = true;
    try {
      final branchList = await _branchRepository.getBranches();
      branches.assignAll(branchList);
      
      // Eğer hiç şube yoksa varsayılanı oluştur
      if (branches.isEmpty) {
        await _createDefaultBranch();
      }
    } catch (e) {
      debugPrint('Şubeler yüklenemedi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createDefaultBranch() async {
    final defaultBranch = Branch(
      name: 'Ana Şube',
      address: 'Varsayılan Adres',
      phone: '',
      email: '',
      isActive: true,
    );
    
    final id = await _branchRepository.insertBranch(defaultBranch);
    final createdBranch = defaultBranch.copyWith(id: id);
    branches.add(createdBranch);
    
    // Varsayılan şubeyi seç
    await selectBranch(createdBranch);
  }

  Future<void> loadSelectedBranch() async {
    final prefs = await SharedPreferences.getInstance();
    final branchId = prefs.getString('selectedBranchId');
    
    if (branchId != null) {
      final branch = await _branchRepository.getBranchById(branchId);
      selectedBranch.value = branch;
    } else if (branches.isNotEmpty) {
      // Hiç seçili şube yoksa ilkini seç
      await selectBranch(branches.first);
    }
  }

  Future<void> selectBranch(Branch branch) async {
    selectedBranch.value = branch;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBranchId', branch.id!);
    
    ErrorHandler.showSuccessMessage('${branch.name} şubesine geçildi');
  }

  Future<void> addBranch(Branch branch) async {
    isLoading.value = true;
    try {
      final id = await _branchRepository.insertBranch(branch);
      final createdBranch = branch.copyWith(id: id);
      branches.add(createdBranch);
      
      Get.back();
      ErrorHandler.showSuccessMessage('Şube başarıyla eklendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Şube eklenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateBranch(Branch branch) async {
    isLoading.value = true;
    try {
      await _branchRepository.updateBranch(branch);
      
      final index = branches.indexWhere((b) => b.id == branch.id);
      if (index != -1) {
        branches[index] = branch;
      }
      
      // Eğer güncellenen şube seçili şube ise, onu da güncelle
      if (selectedBranch.value?.id == branch.id) {
        selectedBranch.value = branch;
      }
      
      Get.back();
      ErrorHandler.showSuccessMessage('Şube başarıyla güncellendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Şube güncellenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBranch(String id) async {
    isLoading.value = true;
    try {
      await _branchRepository.deleteBranch(id);
      branches.removeWhere((b) => b.id == id);
      
      // Eğer silinen şube seçili şube ise, başka bir şubeyi seç
      if (selectedBranch.value?.id == id && branches.isNotEmpty) {
        await selectBranch(branches.first);
      }
      
      ErrorHandler.showSuccessMessage('Şube başarıyla silindi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Şube silinemedi');
    } finally {
      isLoading.value = false;
    }
  }
}
