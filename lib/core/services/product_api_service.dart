import '../api/api_client.dart';
import '../api/api_config.dart';
import '../../features/products/data/models/product_model.dart';

/// REST API Service for Product operations
/// This is optional and can be used alongside Firebase
class ProductApiService {
  final ApiClient _client;
  
  ProductApiService({ApiClient? client}) 
      : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  
  /// Get all products from REST API
  Future<List<Product>> getProducts({
    int? page,
    int? limit,
    String? category,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    
    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    
    final response = await _client.get<Map<String, dynamic>>(
      ApiConfig.products,
      queryParameters: queryParams,
    );
    
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Product.fromJson(json)).toList();
  }
  
  /// Get single product by ID
  Future<Product> getProductById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.products}/$id',
    );
    
    return Product.fromJson(response['data']);
  }
  
  /// Get product by barcode
  Future<Product?> getProductByBarcode(String barcode) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.products}/barcode/$barcode',
    );
    
    if (response['data'] == null) return null;
    return Product.fromJson(response['data']);
  }
  
  /// Create new product
  Future<Product> createProduct(Product product) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConfig.products,
      data: product.toJson(),
    );
    
    return Product.fromJson(response['data']);
  }
  
  /// Update existing product
  Future<Product> updateProduct(String id, Product product) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConfig.products}/$id',
      data: product.toJson(),
    );
    
    return Product.fromJson(response['data']);
  }
  
  /// Update product stock
  Future<void> updateStock(String id, int quantity) async {
    await _client.patch<Map<String, dynamic>>(
      '${ApiConfig.products}/$id/stock',
      data: {'quantity': quantity},
    );
  }
  
  /// Get low stock products
  Future<List<Product>> getLowStockProducts({int? threshold}) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConfig.products}/low-stock',
      queryParameters: threshold != null ? {'threshold': threshold} : null,
    );
    
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Product.fromJson(json)).toList();
  }
  
  /// Delete product
  Future<void> deleteProduct(String id) async {
    await _client.delete('${ApiConfig.products}/$id');
  }
  
  /// Batch update prices (e.g., from ERP)
  Future<void> batchUpdatePrices(Map<String, double> prices) async {
    await _client.post<Map<String, dynamic>>(
      '${ApiConfig.products}/batch/prices',
      data: prices,
    );
  }
  
  /// Sync products from external system (ERP)
  Future<List<Product>> syncFromERP() async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConfig.products}/sync/erp',
    );
    
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
