import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // GET estimations
  Future<Map<String, dynamic>> getEstimations() async {
    final response = await http.get(Uri.parse('$baseUrl/estimations'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      
      // Process the nested structure from the API
      // Expected format: {ticker: {date: {predicted_price: x, yhat: y, ...}}}
      Map<String, dynamic> processedData = {};
      
      if (data is Map) {
        data.forEach((key, value) {
          if (value is Map) {
            processedData[key] = value;
          }
        });
      }
      
      return processedData;
    } else {
      throw Exception('Failed to fetch estimations: ${response.body}');
    }
  }

  // POST add user
  Future<Map<String, dynamic>> addUser(String name, String password, {String? email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add user: ${response.body}');
    }
  }

  // GET user balance
  Future<double?> getBalance(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/user/balance?name=$name'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['balance'] as num).toDouble();
    } else if (response.statusCode == 404) {
      return null; // User not found
    } else {
      throw Exception('Failed to get balance: ${response.body}');
    }
  }

  // POST add ticker
  Future<Map<String, dynamic>> addTicker(String ticker) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ticker/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticker': ticker}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add ticker: ${response.body}');
    }
  }

  // POST update estimations
  Future<Map<String, dynamic>> updateEstimations() async {
    final response = await http.post(
      Uri.parse('$baseUrl/estimations/update'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update estimations: ${response.body}');
    }
  }
}