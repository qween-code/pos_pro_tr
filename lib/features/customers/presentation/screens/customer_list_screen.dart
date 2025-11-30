import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/customer_controller.dart';
import '../../data/models/customer_model.dart';
import 'customer_detail_screen.dart';
import 'customer_add_edit_screen.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/constants/theme_constants.dart';

class CustomerListScreen extends StatelessWidget {
  final CustomerController _customerController = Get.put(CustomerController());

  CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Müşteriler'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomerSearchDelegate(_customerController),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_customerController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_customerController.customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Henüz müşteri eklenmemiş',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _customerController.customers.length,
          itemBuilder: (context, index) {
            final customer = _customerController.customers[index];
            return _buildCustomerCard(context, customer);
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => CustomerAddEditScreen()),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.background),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => CustomerDetailScreen(customer: customer)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Text(
                      customer.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (customer.phone != null)
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              customer.phone!,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: customer.balance > 0 
                              ? Colors.red.withOpacity(0.1) 
                              : (customer.balance < 0 ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Bakiye: ₺${customer.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: customer.balance > 0 
                                ? Colors.red 
                                : (customer.balance < 0 ? Colors.green : Colors.grey),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (customer.loyaltyPoints > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${customer.loyaltyPoints} Puan',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      color: AppTheme.secondary,
                      onTap: () => Get.to(() => CustomerAddEditScreen(customer: customer)),
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: AppTheme.error,
                      onTap: () => _showDeleteConfirmationDialog(customer),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Customer customer) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Müşteriyi Sil',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${customer.name} müşterisini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _customerController.deleteCustomer(customer.id.toString());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sil', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerSearchDelegate extends SearchDelegate {
  final CustomerController _customerController;

  CustomerSearchDelegate(this._customerController);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return AppTheme.darkTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.surface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Arama yapmak için müşteri adı girin',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return FutureBuilder<List<Customer>>(
      future: _customerController.searchCustomers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Müşteri bulunamadı',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final Customer customer = snapshot.data![index];
            return ListTile(
              title: Text(customer.name, style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: customer.phone != null
                  ? Text(customer.phone!, style: TextStyle(color: AppTheme.textSecondary))
                  : null,
              onTap: () {
                close(context, customer);
                Get.to(() => CustomerAddEditScreen(customer: customer));
              },
            );
          },
        );
      },
    );
  }
}