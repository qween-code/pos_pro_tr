import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Firestore REST API Service for platforms without native Firestore SDK (Windows/Linux)
/// Provides cloud synchronization using Firestore REST API
class FirestoreRestService {
  final String projectId;
  final String? apiKey;
  
  FirestoreRestService({
    required this.projectId,
    this.apiKey,
  });

  String get baseUrl => 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  /// Create or update a document
  Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    try {
      final url = '$baseUrl/$collection/$documentId';
      final fields = _convertToFirestoreFields(data);
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null) 'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({'fields': fields}),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Firestore REST: Set document failed - ${response.statusCode}: ${response.body}');
        throw Exception('Failed to set document: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Firestore REST: Error setting document: $e');
      rethrow;
    }
  }

  /// Get a document
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      final url = '$baseUrl/$collection/$documentId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null) 'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _convertFromFirestoreFields(data['fields']);
      } else if (response.statusCode == 404) {
        return null; // Document doesn't exist
      } else {
        debugPrint('❌ Firestore REST: Get document failed - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Firestore REST: Error getting document: $e');
      return null;
    }
  }

  /// List documents in a collection
  Future<List<Map<String, dynamic>>> listDocuments(String collection, {int pageSize = 100}) async {
    try {
      final url = '$baseUrl/$collection?pageSize=$pageSize';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null) 'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List? ?? [];
        
        return documents.map<Map<String, dynamic>>((doc) {
          final fields = doc['fields'] as Map<String, dynamic>? ?? {};
          return _convertFromFirestoreFields(fields);
        }).toList();
      } else {
        debugPrint('❌ Firestore REST: List documents failed - ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Firestore REST: Error listing documents: $e');
      return [];
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      final url = '$baseUrl/$collection/$documentId';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (apiKey != null) 'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('❌ Firestore REST: Delete document failed - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Firestore REST: Error deleting document: $e');
    }
  }

  /// Convert Dart Map to Firestore field format
  Map<String, dynamic> _convertToFirestoreFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value == null) {
        fields[key] = {'nullValue': null};
      } else if (value is String) {
        fields[key] = {'stringValue': value};
      } else if (value is int) {
        fields[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        fields[key] = {'doubleValue': value};
      } else if (value is bool) {
        fields[key] = {'booleanValue': value};
      } else if (value is DateTime) {
        fields[key] = {'timestampValue': value.toUtc().toIso8601String()};
      } else if (value is List) {
        fields[key] = {
          'arrayValue': {
            'values': value.map((item) {
              if (item is Map<String, dynamic>) {
                return {'mapValue': {'fields': _convertToFirestoreFields(item)}};
              }
              return _convertToFirestoreFields({'value': item})['value'];
            }).toList()
          }
        };
      } else if (value is Map<String, dynamic>) {
        fields[key] = {'mapValue': {'fields': _convertToFirestoreFields(value)}};
      }
    });
    
    return fields;
  }

  /// Convert Firestore fields to Dart Map
  Map<String, dynamic> _convertFromFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    
    fields.forEach((key, value) {
      if (value is! Map) return;
      
      if (value.containsKey('stringValue')) {
        result[key] = value['stringValue'];
      } else if (value.containsKey('integerValue')) {
        result[key] = int.tryParse(value['integerValue'] ?? '0') ?? 0;
      } else if (value.containsKey('doubleValue')) {
        result[key] = value['doubleValue'];
      } else if (value.containsKey('booleanValue')) {
        result[key] = value['booleanValue'];
      } else if (value.containsKey('timestampValue')) {
        result[key] = DateTime.parse(value['timestampValue']);
      } else if (value.containsKey('nullValue')) {
        result[key] = null;
      } else if (value.containsKey('arrayValue')) {
        final arrayValue = value['arrayValue'];
        if (arrayValue is Map && arrayValue.containsKey('values')) {
          result[key] = (arrayValue['values'] as List).map((item) {
            if (item is Map && item.containsKey('mapValue')) {
              return _convertFromFirestoreFields(item['mapValue']['fields']);
            }
            return item;
          }).toList();
        }
      } else if (value.containsKey('mapValue')) {
        final mapValue = value['mapValue'];
        if (mapValue is Map && mapValue.containsKey('fields')) {
          result[key] = _convertFromFirestoreFields(mapValue['fields']);
        }
      }
    });
    
    return result;
  }
}

/// Platform-aware Sync Service
/// Uses native Firestore on mobile, REST API on desktop
class PlatformSyncService {
  static Future<void> syncOrderToCloud(String orderId, Map<String, dynamic> orderData) async {
    if (Platform.isWindows || Platform.isLinux) {
      // Desktop: Use REST API
      final restService = FirestoreRestService(
        projectId: 'pos-pro-tr-2025', // Your Firebase project ID
      );
      
      await restService.setDocument('orders', orderId, orderData);
      debugPrint('✅ Desktop: Order synced via REST API');
    } else {
      // Mobile: Use native Firestore SDK (handled by HybridOrderRepository)
      debugPrint('✅ Mobile: Order synced via native Firestore');
    }
  }

  static Future<void> syncProductToCloud(String productId, Map<String, dynamic> productData) async {
    if (Platform.isWindows || Platform.isLinux) {
      final restService = FirestoreRestService(projectId: 'pos-pro-tr-2025');
      await restService.setDocument('products', productId, productData);
    }
  }

  static Future<void> syncCustomerToCloud(String customerId, Map<String, dynamic> customerData) async {
    if (Platform.isWindows || Platform.isLinux) {
      final restService = FirestoreRestService(projectId: 'pos-pro-tr-2025');
      await restService.setDocument('customers', customerId, customerData);
    }
  }
}
