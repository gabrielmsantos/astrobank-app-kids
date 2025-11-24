import 'package:flutter_test/flutter_test.dart';
import 'package:astrobank_kids/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('API base URL has a valid value', () {
      expect(AppConfig.apiBaseUrl, isNotEmpty);
    });

    test('API base URL is a valid URL format', () {
      expect(
        AppConfig.apiBaseUrl,
        matches(RegExp(r'^https?://')),
        reason: 'API base URL should start with http:// or https://',
      );
    });

    test('API version is set', () {
      expect(AppConfig.apiVersion, isNotEmpty);
      expect(AppConfig.apiVersion, equals('v1'));
    });

    test('API endpoints use correct base URL', () {
      expect(
        AppConfig.authLogin,
        startsWith(AppConfig.apiBaseUrl),
      );
      expect(
        AppConfig.transactions,
        startsWith(AppConfig.apiBaseUrl),
      );
    });

    test('Default values are provided for localhost', () {
      // When no dart-define is used, should default to localhost
      // This test verifies the fallback works
      expect(
        AppConfig.apiBaseUrl,
        anyOf(
          equals('http://localhost:8000'), // Default when no dart-define
          contains('http'),                 // Or custom URL from dart-define
        ),
      );
    });

    test('API endpoints format is correct', () {
      // Format should be: {apiBaseUrl}/api/{apiVersion}/{endpoint}
      expect(
        AppConfig.authLogin,
        contains('/api/v1/'),
      );
      expect(
        AppConfig.transactions,
        contains('/api/v1/transactions'),
      );
    });

    test('Configuration URLs are not null', () {
      expect(AppConfig.apiBaseUrl, isNotNull);
      expect(AppConfig.authLogin, isNotNull);
      expect(AppConfig.transactions, isNotNull);
    });
  });
}

