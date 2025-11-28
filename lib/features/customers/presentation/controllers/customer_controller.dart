import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerController extends GetxController {
  final CustomerRepository _customerRepository = CustomerRepository();
  final RxList<Customer> customers = <Customer>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    isLoading.value = true;
    try {
      final List<Customer> customerList = await _customerRepository.getCustomers();
      customers.assignAll(customerList);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Müşteriler yüklenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    isLoading.value = true;
    try {
      await _customerRepository.insertCustomer(customer);
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
}