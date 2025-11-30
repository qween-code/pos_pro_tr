import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/database/database_instance.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/hybrid_customer_repository.dart';

class CustomerController extends GetxController {
  late final HybridCustomerRepository _customerRepository;
  final RxList<Customer> customers = <Customer>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _customerRepository = HybridCustomerRepository(
      localDb: db,
      firestore: firestore,
    );
  }

  @override
  void onClose() {
    _customerRepository.dispose();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    isLoading.value = true;
    try {
      final List<Customer> customerList = await _customerRepository.getCustomers();
      customers.assignAll(customerList);
    } catch (e) {
      debugPrint('Müşteriler yüklenemedi: $e');
      customers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    isLoading.value = true;
    try {
      await _customerRepository.addCustomer(customer);
      await fetchCustomers();
      Get.back();
      ErrorHandler.showSuccessMessage('Müşteri başarıyla eklendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Müşteri eklenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    isLoading.value = true;
    try {
      await _customerRepository.updateCustomer(customer);
      await fetchCustomers();
      Get.back();
      ErrorHandler.showSuccessMessage('Müşteri başarıyla güncellendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Müşteri güncellenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCustomer(String id) async {
    isLoading.value = true;
    try {
      await _customerRepository.deleteCustomer(id);
      await fetchCustomers();
      ErrorHandler.showSuccessMessage('Müşteri başarıyla silindi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Müşteri silinemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Customer>> searchCustomers(String query) async {
    try {
      return await _customerRepository.searchCustomers(query);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Arama yapılamadı');
      return [];
    }
  }

  Future<void> updateBalance(String customerId, double amount) async {
    try {
      await _customerRepository.updateBalance(customerId, amount);
      // Listeyi güncellemek yerine sadece ilgili müşteriyi güncellemek daha performanslı olurdu ama şimdilik fetchCustomers yeterli.
      // Ancak detay ekranında anlık güncelleme için fetchCustomers çağırmak yerine UI tarafında state güncelledik.
      // Yine de liste ekranına dönüldüğünde güncel olması için fetchCustomers çağırabiliriz veya listedeki öğeyi güncelleyebiliriz.
      final index = customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        customers[index] = customers[index].copyWith(
          balance: customers[index].balance + amount
        );
      }
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Bakiye güncellenemedi');
    }
  }
}