import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/customer_model.dart';

class CustomerService {
  static Future<Customer> getCustomerDetails(String customerId, String bankId) async {
    try {
      final uri = Uri.parse(AppConfig.customerDetails(customerId))
          .replace(queryParameters: {
            'customer_id': customerId,
            'bank_id': bankId,
          });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Customer.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Customer not found or no account for this bank');
      } else {
        throw Exception('Failed to load customer details');
      }
    } catch (e) {
      throw Exception('Error fetching customer details: $e');
    }
  }

  static Future<void> updateCustomerProfile(
    String customerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(AppConfig.customerProfile(customerId)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updates),
      ).timeout(AppConfig.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to update customer profile');
      }
    } catch (e) {
      throw Exception('Error updating customer profile: $e');
    }
  }
}
