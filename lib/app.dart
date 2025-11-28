import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/constants/theme_constants.dart';
import 'core/widgets/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/products/presentation/screens/product_list_screen.dart';
import 'features/products/presentation/screens/product_add_edit_screen.dart';
import 'features/customers/presentation/screens/customer_list_screen.dart';
import 'features/customers/presentation/screens/customer_add_edit_screen.dart';
import 'features/orders/presentation/screens/order_list_screen.dart';
import 'features/orders/presentation/screens/order_create_screen.dart';
import 'features/orders/presentation/screens/order_detail_screen.dart';
import 'features/payments/presentation/screens/payment_list_screen.dart';
import 'features/payments/presentation/screens/payment_detail_screen.dart';
import 'features/discounts/presentation/screens/discount_list_screen.dart';
import 'features/discounts/presentation/screens/discount_add_edit_screen.dart';
import 'features/reports/presentation/screens/report_screen.dart';

class PosProApp extends StatelessWidget {
  const PosProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'POS Pro TR',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.noTransition,
      builder: (context, child) {
        return child!;
      },
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/products', page: () => ProductListScreen()),
        GetPage(name: '/products/add', page: () => ProductAddEditScreen()),
        GetPage(name: '/products/edit', page: () => ProductAddEditScreen(product: Get.arguments)),
        GetPage(name: '/customers', page: () => CustomerListScreen()),
        GetPage(name: '/customers/add', page: () => CustomerAddEditScreen()),
        GetPage(name: '/customers/edit', page: () => CustomerAddEditScreen(customer: Get.arguments)),
        GetPage(name: '/orders', page: () => OrderListScreen()),
        GetPage(name: '/orders/create', page: () => OrderCreateScreen()),
        GetPage(name: '/orders/detail', page: () => OrderDetailScreen(order: Get.arguments)),
        GetPage(name: '/payments', page: () => PaymentListScreen()),
        GetPage(name: '/payments/detail', page: () => PaymentDetailScreen(payment: Get.arguments)),
        GetPage(name: '/discounts', page: () => DiscountListScreen()),
        GetPage(name: '/discounts/add', page: () => DiscountAddEditScreen()),
        GetPage(name: '/discounts/edit', page: () => DiscountAddEditScreen(discount: Get.arguments)),
        GetPage(name: '/reports', page: () => ReportScreen()),
      ],
      unknownRoute: GetPage(name: '/login', page: () => const LoginScreen()),
    );
  }
}