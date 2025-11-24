class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String apiVersion = 'v1';

  // Customer Configuration - Hardcoded for development
  static const String defaultCustomerId = '1';
  static const String defaultBankId = '1';

  // API Endpoints
  static String get authLogin => '$apiBaseUrl/api/$apiVersion/auth/login';
  
  static String customerProfile(String customerId) => 
    '$apiBaseUrl/api/$apiVersion/customers/$customerId';
  
  static String customerDetails(String customerId) =>
    '$apiBaseUrl/api/$apiVersion/customers/$customerId/details';
  
  static String get transactions => 
    '$apiBaseUrl/api/$apiVersion/transactions';
  
  static String creditCards(String customerId) => 
    '$apiBaseUrl/api/$apiVersion/customers/$customerId/credit-card';
  
  static String cardInvoices(String cardId) => 
    '$apiBaseUrl/api/$apiVersion/credit-cards/$cardId/invoices';
  
  static String invoiceItems(String invoiceId) => 
    '$apiBaseUrl/api/$apiVersion/invoices/$invoiceId/items';
  
  static String invoicePayment(String invoiceId) => 
    '$apiBaseUrl/api/$apiVersion/invoices/$invoiceId/payments';

  // Pagination
  static const int defaultPageSize = 15;
  static const int scrollThreshold = 300; // pixels from bottom

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Theme Colors
  static const String primaryPurple = '#7C3AED';
  static const String successGreen = '#00C950';
  static const String errorRed = '#FB2C36';
  static const String textDark = '#1A1A1A';
  static const String textGray = '#666666';
  static const String textLightGray = '#999999';
}
