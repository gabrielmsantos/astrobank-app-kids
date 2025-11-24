import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/credit_card_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item_model.dart';

class CardService {
  static Future<List<CreditCard>> getCustomerCards(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.creditCards(customerId)),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle both direct array response and object with 'cards' key
        final cardsList = data is List 
            ? data 
            : (data['cards'] as List? ?? []);
        
        final cards = cardsList
            .map((item) => CreditCard.fromJson(item as Map<String, dynamic>))
            .toList();
        return cards;
      } else {
        throw Exception('Failed to load credit cards: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching credit cards: $e');
    }
  }

  static Future<Map<String, dynamic>> getCardInvoices(
    String cardId, {
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = AppConfig.defaultPageSize,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (fromDate != null) {
        queryParams['from_date'] = fromDate;
      }
      if (toDate != null) {
        queryParams['to_date'] = toDate;
      }
      if (cursor != null && cursor.isNotEmpty) {
        queryParams['cursor'] = cursor;
      }

      final uri = Uri.parse(AppConfig.cardInvoices(cardId))
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle both direct array response and object with 'invoices' key
        final invoicesList = data is List 
            ? data 
            : (data['invoices'] as List? ?? []);
        
        final invoices = invoicesList
            .map((item) => Invoice.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'invoices': invoices,
          'next_cursor': data is Map ? (data['next_cursor']) : null,
          'has_more': data is Map ? (data['has_more'] ?? false) : false,
        };
      } else {
        throw Exception('Failed to load invoices: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching invoices: $e');
    }
  }

  static Future<Map<String, dynamic>> getInvoiceItems(
    String invoiceId, {
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (cursor != null && cursor.isNotEmpty) {
        queryParams['cursor'] = cursor;
      }

      final uri = Uri.parse(AppConfig.invoiceItems(invoiceId))
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = (data['items'] as List? ?? [])
            .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'items': items,
          'next_cursor': data['next_cursor'],
          'has_more': data['has_more'] ?? false,
        };
      } else {
        throw Exception('Failed to load invoice items');
      }
    } catch (e) {
      throw Exception('Error fetching invoice items: $e');
    }
  }

  static Map<String, String> getMonthDateRange(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    return {
      'from_date': firstDay.toIso8601String().split('T')[0],
      'to_date': lastDay.toIso8601String().split('T')[0],
    };
  }

  static Future<Map<String, dynamic>> recordInvoicePayment(
    String invoiceId, {
    required double amount,
  }) async {
    try {
      // Simplified payload with only amount
      final payload = {
        'amount': amount,
      };

      final response = await http.post(
        Uri.parse(AppConfig.invoicePayment(invoiceId)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Payment recorded successfully',
          'payment': data['payment'],
          'invoice': data['invoice'] != null 
              ? Invoice.fromJson(data['invoice'] as Map<String, dynamic>)
              : null,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to record payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error recording payment: $e');
    }
  }
}
