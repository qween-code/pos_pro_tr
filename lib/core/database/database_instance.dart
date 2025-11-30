import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/app_database.dart';

/// Global Database Instance Service
/// 
/// Uygulama boyunca tek bir AppDatabase instance'ı paylaşır
class DatabaseInstance extends GetxService {
  late final AppDatabase database;

  Future<DatabaseInstance> init() async {
    database = AppDatabase();
    return this;
  }

  @override
  void onClose() {
    database.close();
    super.onClose();
  }
}

/// Kolay erişim için helper
AppDatabase get db => Get.find<DatabaseInstance>().database;
FirebaseFirestore get firestore => FirebaseFirestore.instance;
