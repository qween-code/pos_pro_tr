import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

/// 🚀 PosPro API Service
/// Handles all HTTP communication with FastAPI backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuration
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const Duration timeout = Duration(seconds: 30);
  
  // Dio instance
  late final Dio _dio;
  
  // Secure storage for tokens
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Token management
  String? _accessToken;
  String? _refreshToken;
  
  /// Initialize the API service
  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
    
    // Load saved tokens
    await _loadTokens();
    
    developer.log('✅ ApiService initialized', name: 'API');
  }
  
  /// Load tokens from secure storage
  Future<void> _loadTokens() async {
    try {
      _accessToken = await _storage.read(key: 'access_token');
      _refreshToken = await _storage.read(key: 'refresh_token');
      
      if (_accessToken != null) {
        developer.log('Token loaded from storage', name: 'API');
      }
    } catch (e) {
      developer.log('Error loading tokens: $e', name: 'API', error: e);
    }
  }
  
  /// Save tokens to secure storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    try {
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      developer.log('Tokens saved', name: 'API');
    } catch (e) {
      developer.log('Error saving tokens: $e', name: 'API', error: e);
    }
  }
  
  /// Clear tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    _accessToken = null;
    _refreshToken = null;
    developer.log('Tokens cleared', name: 'API');
  }
  
  /// Request interceptor
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add auth token to headers
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    developer.log(
      '➡️ ${options.method} ${options.path}',
      name: 'API',
    );
    
    return handler.next(options);
  }
  
  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    developer.log(
      '✅ ${response.statusCode} ${response.requestOptions.path}',
      name: 'API',
    );
    
    return handler.next(response);
  }
  
  /// Error interceptor
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    developer.log(
      '❌ ${err.response?.statusCode} ${err.requestOptions.path}',
      name: 'API',
      error: err.message,
    );
    
    // Handle 401 - Unauthorized (token expired)
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh logic
      developer.log('Token expired, clearing auth', name: 'API');
      await clearTokens();
    }
    
    return handler.next(err);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // AUTH API
  // ═══════════════════════════════════════════════════════════════
  
  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final data = response.data as Map<String, dynamic>;
      
      // Save tokens
      await _saveTokens(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
      
      return data;
    } catch (e) {
      developer.log('Login error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get user error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Logout
  Future<void> logout() async {
    await clearTokens();
    developer.log('User logged out', name: 'API');
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PRODUCTS API
  // ═══════════════════════════════════════════════════════════════
  
  /// Get products list
  Future<Map<String, dynamic>> getProducts({
    int skip = 0,
    int limit = 50,
    String? search,
    String? categoryId,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        if (search != null) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        if (isActive != null) 'is_active': isActive,
      };
      
      final response = await _dio.get('/products', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get products error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Get single product
  Future<Map<String, dynamic>> getProduct(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get product error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Create product
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/products', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Create product error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Update product
  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/products/$id', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Update product error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // ORDERS API
  // ═══════════════════════════════════════════════════════════════
  
  /// Create order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/orders', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Create order error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Get orders list
  Future<Map<String, dynamic>> getOrders({
    int skip = 0,
    int limit = 50,
    String? status,
    String? customerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        if (status != null) 'status': status,
        if (customerId != null) 'customer_id': customerId,
      };
      
      final response = await _dio.get('/orders', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get orders error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Get single order
  Future<Map<String, dynamic>> getOrder(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get order error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // CUSTOMERS API
  // ═══════════════════════════════════════════════════════════════
  
  /// Get customers list
  Future<Map<String, dynamic>> getCustomers({
    int skip = 0,
    int limit = 50,
    String? search,
    String? segment,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
        if (search != null) 'search': search,
        if (segment != null) 'segment': segment,
      };
      
      final response = await _dio.get('/customers', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get customers error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Create customer
  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/customers', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Create customer error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Get customer analytics
  Future<Map<String, dynamic>> getCustomerAnalytics(String id) async {
    try {
      final response = await _dio.get('/customers/$id/analytics');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get customer analytics error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // POS API
  // ═══════════════════════════════════════════════════════════════
  
  /// Scan barcode
  Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    try {
      final response = await _dio.get('/pos/scan/$barcode');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Scan barcode error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Search products (POS)
  Future<List<dynamic>> searchProducts(String query, {int limit = 20}) async {
    try {
      final response = await _dio.get('/pos/products/search', queryParameters: {
        'q': query,
        'limit': limit,
      });
      return response.data as List<dynamic>;
    } catch (e) {
      developer.log('Search products error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Quick checkout
  Future<Map<String, dynamic>> quickCheckout(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/pos/checkout', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Quick checkout error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  /// Low stock alert
  Future<Map<String, dynamic>> getLowStock({int limit = 50}) async {
    try {
      final response = await _dio.get('/pos/stock/low', queryParameters: {
        'limit': limit,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      developer.log('Get low stock error: $e', name: 'API', error: e);
      rethrow;
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // HEALTH CHECK
  // ═══════════════════════════════════════════════════════════════
  
  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/ping');
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Health check failed: $e', name: 'API', error: e);
      return false;
    }
  }
}
