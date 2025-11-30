/// API Configuration
class ApiConfig {
  // Environment
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  
  // Base URLs for different environments
  static const Map<String, String> _baseUrls = {
    'dev': 'http://localhost:3000/api',
    'staging': 'https://staging-api.pospro.com/api',
    'production': 'https://api.pospro.com/api',
  };
  
  // Get base URL for current environment
  static String get baseUrl => _baseUrls[environment] ?? _baseUrls['dev']!;
  
  // API Endpoints
  static const String products = '/products';
  static const String orders = '/orders';
  static const String customers = '/customers';
  static const String users = '/users';
  static const String auth = '/auth';
  static const String reports = '/reports';
  static const String sync = '/sync';
  
  // ERP Integration (if needed)
  static const String erpBaseUrl = 'https://erp.company.com/api';
  static const String erpProducts = '/products';
  static const String erpOrders = '/orders';
  
  // Third-party APIs
  static const String smsApiUrl = 'https://sms-provider.com/api';
  static const String emailApiUrl = 'https://email-provider.com/api';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // Cache configuration
  static const Duration cacheExpiry = Duration(hours: 1);
  static const bool enableCache = true;
  
  // Debug mode
  static bool get isDebugMode => environment == 'dev';
}
