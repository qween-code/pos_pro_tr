import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/discount_model.dart';
import '../controllers/discount_controller.dart';

class DiscountAddEditScreen extends StatelessWidget {
  final Discount? discount;
  final DiscountController _discountController = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final RxString _discountType = 'percentage'.obs;
  final RxBool _isActive = true.obs;

  DiscountAddEditScreen({super.key, this.discount}) {
    if (discount != null) {
      _nameController.text = discount!.name;
      _valueController.text = discount!.discountType == 'percentage'
          ? (discount!.discountValue * 100).toStringAsFixed(0)
          : discount!.discountValue.toStringAsFixed(2);
      _startDateController.text = DateFormat('yyyy-MM-dd').format(discount!.startDate);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(discount!.endDate);
      _discountType.value = discount!.discountType;
      _isActive.value = discount!.isActive;
    } else {
      // Varsayılan tarihler (bugünden itibaren 1 ay)
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, now.day);
      _startDateController.text = DateFormat('yyyy-MM-dd').format(now);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(nextMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(discount == null ? 'İndirim Ekle' : 'İndirim Düzenle'),
        actions: [
          if (discount != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmationDialog(),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'İndirim Adı*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen indirim adını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(() => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Yüzde İndirim'),
                          value: 'percentage',
                          groupValue: _discountType.value,
                          onChanged: (value) {
                            _discountType.value = value!;
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Sabit İndirim'),
                          value: 'fixed',
                          groupValue: _discountType.value,
                          onChanged: (value) {
                            _discountType.value = value!;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: _discountType.value == 'percentage'
                          ? 'İndirim Yüzdesi (%)*'
                          : 'İndirim Miktarı (₺)*',
                      border: const OutlineInputBorder(),
                      prefixText: _discountType.value == 'percentage' ? '%' : '₺ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen indirim değerini girin';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Geçerli bir değer girin';
                      }
                      if (_discountType.value == 'percentage' && double.parse(value) > 100) {
                        return 'Yüzde 100\'den büyük olamaz';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Değer sıfırdan büyük olmalı';
                      }
                      return null;
                    },
                  ),
                ],
              )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Başlangıç Tarihi*',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _startDateController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen başlangıç tarihini seçin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'Bitiş Tarihi*',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _endDateController),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen bitiş tarihini seçin';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() => SwitchListTile(
                title: const Text('Aktif'),
                value: _isActive.value,
                onChanged: (value) {
                  _isActive.value = value;
                },
              )),
              const SizedBox(height: 24),
              const Text(
                '* Zorunlu alanlar',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _discountController.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              final double value = double.parse(_valueController.text);
                              final double finalValue = _discountType.value == 'percentage'
                                  ? value / 100
                                  : value;

                              final Discount newDiscount = Discount(
                                id: discount?.id,
                                name: _nameController.text,
                                discountType: _discountType.value,
                                discountValue: finalValue,
                                startDate: DateFormat('yyyy-MM-dd').parse(_startDateController.text),
                                endDate: DateFormat('yyyy-MM-dd').parse(_endDateController.text),
                                isActive: _isActive.value,
                              );

                              if (discount == null) {
                                _discountController.addDiscount(newDiscount);
                              } else {
                                _discountController.updateDiscount(newDiscount);
                              }
                            }
                          },
                    child: _discountController.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            discount == null ? 'İNDİRİM EKLE' : 'İNDİRİMİ GÜNCELLE',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isEmpty
          ? DateTime.now()
          : DateFormat('yyyy-MM-dd').parse(controller.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _showDeleteConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('İndirimi Sil'),
        content: Text('${discount!.name} indirimini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _discountController.deleteDiscount(discount!.id!);
              Get.back(); // Ekrandan çık
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}