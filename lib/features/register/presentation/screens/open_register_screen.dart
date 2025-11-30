import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/theme_constants.dart';
import '../controllers/register_controller.dart';

class OpenRegisterScreen extends StatefulWidget {
  const OpenRegisterScreen({super.key});

  @override
  State<OpenRegisterScreen> createState() => _OpenRegisterScreenState();
}

class _OpenRegisterScreenState extends State<OpenRegisterScreen> {
  final RegisterController controller = Get.put(RegisterController());
  final TextEditingController amountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedCashier;
  String? selectedCashierName;
  String? selectedBranch;
  List<Map<String, String>> cashiers = [];
  List<String> branches = ['Ana Şube', 'İstanbul', 'İzmir', 'Ankara'];
  bool isLoadingCashiers = true;

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cashier')
          .get();

      setState(() {
        cashiers = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc.data()['name'] as String? ?? 'Bilinmeyen',
          };
        }).toList();
        isLoadingCashiers = false;
      });
    } catch (e) {
      debugPrint('❌ Kasiyer yükleme hatası: $e');
      setState(() => isLoadingCashiers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kasa Açılışı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gün Başı İşlemleri',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Kasiyer Seçimi
              if (isLoadingCashiers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: selectedCashier,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Kasiyer Seçin',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person, color: AppTheme.primary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                  items: cashiers.map((cashier) {
                    return DropdownMenuItem<String>(
                      value: cashier['id'],
                      child: Text(cashier['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCashier = value;
                      selectedCashierName = cashiers.firstWhere(
                        (c) => c['id'] == value,
                        orElse: () => {'name': 'Bilinmeyen'},
                      )['name'];
                    });
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Şube Seçimi
              DropdownButtonFormField<String>(
                value: selectedBranch,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Şube Seçin',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.store, color: AppTheme.primary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
                items: branches.map((branch) {
                  return DropdownMenuItem<String>(
                    value: branch,
                    child: Text(branch),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedBranch = value);
                },
              ),
              
              const SizedBox(height: 16),
              
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Açılış Bakiyesi (Nakit)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primary),
                  suffixText: '₺',
                  suffixStyle: const TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (amountController.text.isEmpty || 
                              selectedCashier == null || 
                              selectedBranch == null) {
                            Get.snackbar('Hata', 'Lütfen tüm alanları doldurun');
                            return;
                          }
                          final amount = double.tryParse(amountController.text) ?? 0.0;
                          final success = await controller.openRegister(
                            amount,
                            selectedCashierName ?? 'Bilinmeyen',
                          );
                          if (success) {
                            Get.back();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'KASAYI AÇ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
