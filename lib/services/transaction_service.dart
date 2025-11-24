import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static Future<Map<String, dynamic>> getTransactionsPaginated({
    required String customerId,
    String? cursor,
    int limit = AppConfig.defaultPageSize,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      if (customerId.isEmpty) {
        throw Exception('Customer ID cannot be empty');
      }

      final queryParams = <String, String>{
        'customer_id': customerId,
        'limit': limit.toString(),
      };

      if (cursor != null && cursor.isNotEmpty) {
        queryParams['cursor'] = cursor;
      }
      if (fromDate != null) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate;
      }

      final uri = Uri.parse(AppConfig.transactions)
          .replace(queryParameters: queryParams);

      print('Fetching transactions from: $uri'); // Debug log

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactions = (data['transactions'] as List)
            .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'transactions': transactions,
          'next_cursor': data['next_cursor'],
          'has_more': data['has_more'] ?? false,
        };
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  static Future<Map<String, dynamic>> getTransactionById(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.transactions}/$transactionId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transaction': Transaction.fromJson(data),
        };
      } else {
        throw Exception('Failed to load transaction');
      }
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }
}
