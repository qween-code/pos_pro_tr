import 'package:get/get.dart';
import '../../data/models/discount_model.dart';
import '../../data/repositories/discount_repository.dart';

class DiscountController extends GetxController {
  final DiscountRepository _discountRepository = DiscountRepository();
  final RxList<Discount> discounts = <Discount>[].obs;
  final RxList<Discount> activeDiscounts = <Discount>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDiscounts();
    fetchActiveDiscounts();
  }

  Future<void> fetchDiscounts() async {
    isLoading.value = true;
    try {
      final List<Discount> discountList = await _discountRepository.getDiscounts();
      discounts.assignAll(discountList);
    } catch (e) {
      Get.snackbar('Hata', 'İndirimler yüklenemedi: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchActiveDiscounts() async {
    try {
      final List<Discount> discountList = await _discountRepository.getActiveDiscounts();
      activeDiscounts.assignAll(discountList);
    } catch (e) {
      Get.snackbar('Hata', 'Aktif indirimler yüklenemedi: ${e.toString()}');
    }
  }

  Future<void> addDiscount(Discount discount) async {
    isLoading.value = true;
    try {
      await _discountRepository.insertDiscount(discount);
      await fetchDiscounts();
      await fetchActiveDiscounts();
      Get.back();
      Get.snackbar('Başarılı', 'İndirim başarıyla eklendi');
    } catch (e) {
      Get.snackbar('Hata', 'İndirim eklenemedi: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDiscount(Discount discount) async {
    isLoading.value = true;
    try {
      await _discountRepository.updateDiscount(discount);
      await fetchDiscounts();
      await fetchActiveDiscounts();
      Get.back();
      Get.snackbar('Başarılı', 'İndirim başarıyla güncellendi');
    } catch (e) {
      Get.snackbar('Hata', 'İndirim güncellenemedi: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDiscount(String id) async {
    isLoading.value = true;
    try {
      await _discountRepository.deleteDiscount(id);
      await fetchDiscounts();
      await fetchActiveDiscounts();
      Get.snackbar('Başarılı', 'İndirim başarıyla silindi');
    } catch (e) {
      Get.snackbar('Hata', 'İndirim silinemedi: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Discount>> searchDiscounts(String query) async {
    try {
      return discounts.where((discount) =>
        discount.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      Get.snackbar('Hata', 'İndirim araması yapılamadı: ${e.toString()}');
      return [];
    }
  }
}