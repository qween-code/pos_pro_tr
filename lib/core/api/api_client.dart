import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Base API client for REST API communication
class ApiClient {
  final Dio _dio;
  final String baseUrl;
  
  ApiClient({
    required this.baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      request: kDebugMode,
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseHeader: kDebugMode,
      responseBody: kDebugMode,
      error: true,
      logPrint: (log) => debugPrint('[API] $log'),
    ));
    
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }
  
  /// GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// DELETE request
  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// PATCH request
  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Handle Dio errors and convert to app-specific exceptions
  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
          type: ApiExceptionType.timeout,
        );
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?['message'] ?? 
                        error.response?.statusMessage ?? 
                        'Server error occurred';
        
        if (statusCode == 401) {
          return ApiException(
            message: 'Unauthorized. Please login again.',
            statusCode: 401,
            type: ApiExceptionType.unauthorized,
          );
        } else if (statusCode == 403) {
          return ApiException(
            message: 'Access forbidden.',
            statusCode: 403,
            type: ApiExceptionType.forbidden,
          );
        } else if (statusCode == 404) {
          return ApiException(
            message: 'Resource not found.',
            statusCode: 404,
            type: ApiExceptionType.notFound,
          );
        } else if (statusCode >= 500) {
          return ApiException(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
            type: ApiExceptionType.serverError,
          );
        }
        
        return ApiException(
          message: message,
          statusCode: statusCode,
          type: ApiExceptionType.badResponse,
        );
        
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          statusCode: 0,
          type: ApiExceptionType.cancelled,
        );
        
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: 'Network error. Please check your connection.',
          statusCode: 0,
          type: ApiExceptionType.network,
        );
    }
  }
}

/// Auth interceptor to add JWT token to requests
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Get token from auth service (you can implement this)
    // For now, we'll skip adding token
    // TODO: Implement token retrieval from auth service
    
    // Example:
    // final token = Get.find<AuthController>().token;
    // if (token != null) {
    //   options.headers['Authorization'] = 'Bearer $token';
    // }
    
    handler.next(options);
  }
}

/// Retry interceptor for failed requests
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on network errors or timeout
    if (err.type != DioExceptionType.connectionTimeout &&
        err.type != DioExceptionType.sendTimeout &&
        err.type != DioExceptionType.receiveTimeout &&
        err.type != DioExceptionType.connectionError) {
      return handler.next(err);
    }
    
    final extra = err.requestOptions.extra;
    final retries = extra['retries'] ?? 0;
    
    if (retries >= maxRetries) {
      return handler.next(err);
    }
    
    debugPrint('[API] Retry ${retries + 1}/$maxRetries for ${err.requestOptions.path}');
    
    // Wait before retry
    await Future.delayed(retryDelay * (retries + 1));
    
    // Increment retry count
    err.requestOptions.extra['retries'] = retries + 1;
    
    try {
      // Retry the request
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final ApiExceptionType type;
  final dynamic data;
  
  ApiException({
    required this.message,
    required this.statusCode,
    required this.type,
    this.data,
  });
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode, Type: $type)';
}

/// API Exception Types
enum ApiExceptionType {
  timeout,
  network,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  badResponse,
  cancelled,
  unknown,
}
