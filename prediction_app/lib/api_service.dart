import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});


Future<void> updateBalance(String username, String password, double newBalance) async {
  final response = await http.put(
    Uri.parse('$baseUrl/users/$username/balance'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'password': password,
      'balance': newBalance,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to update balance: ${response.body}');
  }
}

Future<double?> setBalance(String name, String password, double newBalance) async {
  final response = await http.put(
    Uri.parse('$baseUrl/user/balance/set'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'password': password,
      'new_balance': newBalance,
    }),
  );

  if (response.statusCode == 200) {
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    return (data['new_balance'] as num).toDouble();
  } else if (response.statusCode == 404) {
    return null; // User not found
  } else {
    throw Exception('Failed to set balance: ${response.body}');
  }
}

//admin update user balance
Future<Map<String, dynamic>> adminUpdateBalance(
  String ownerName,
  String ownerPassword,
  String targetUsername,
  double newBalance,
) async {
  final response = await http.put(
    Uri.parse('$baseUrl/admin/user/balance'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'owner_name': ownerName,
      'owner_password': ownerPassword,
      'target_username': targetUsername,
      'new_balance': newBalance,
    }),
  );

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update balance: ${response.body}');
  }
}

  //admin delete user owner uses their own password
Future<Map<String, dynamic>> adminDeleteUser(
  String ownerName,
  String ownerPassword,
  String targetUsername,
) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/admin/user/delete'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'owner_name': ownerName,
      'owner_password': ownerPassword,
      'target_username': targetUsername,
    }),
  );

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to delete user: ${response.body}');
  }
}

//admin update user (owner uses their own password)
Future<Map<String, dynamic>> adminUpdateUser(
  String ownerName,
  String ownerPassword,
  String targetUsername,
  String newPassword,
) async {
  final response = await http.put(
    Uri.parse('$baseUrl/admin/user/update'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'owner_name': ownerName,
      'owner_password': ownerPassword,
      'target_username': targetUsername,
      'new_password': newPassword,
    }),
  );

  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update user: ${response.body}');
  }
}

  //estimations
  Future<Map<String, dynamic>> getEstimations() async {
  final response = await http.get(Uri.parse('$baseUrl/estimations'));
  if (response.statusCode == 200) {
    var rawData = jsonDecode(response.body);
    
    // Helper function to recursively convert LinkedHashMaps
    dynamic deepConvert(dynamic item) {
      if (item is Map) {
        return Map<String, dynamic>.from(
          item.map((key, value) => MapEntry(key.toString(), deepConvert(value)))
        );
      } else if (item is List) {
        return item.map((e) => deepConvert(e)).toList();
      }
      return item;
    }
    
    // Apply deep conversion to the entire data structure
    Map<String, dynamic> processedData = deepConvert(rawData);
    
    return processedData;
  } else {
    throw Exception('Failed to fetch estimations: ${response.body}');
  }
}

  // add user
  Future<Map<String, dynamic>> addUser(String name, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add user: ${response.body}');
    }
  }

  // GET user balance
  Future<double?> getBalance(String name, String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/balance?name=$name&password=$password')
    );
    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(response.body));
      return (data['balance'] as num).toDouble();
    } else if (response.statusCode == 404) {
      return null; // user not found
    } else {
      throw Exception('Failed to get balance: ${response.body}');
    }
  }

  //user positions
  Future<Map<String, dynamic>?> getPositions(String name, String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/positions?name=$name&password=$password')
    );
    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(response.body));
      return Map<String, dynamic>.from(data['positions']);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get positions: ${response.body}');
    }
  }

  //add ticker
  Future<Map<String, dynamic>> addTicker(String ticker) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ticker/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticker': ticker}),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add ticker: ${response.body}');
    }
  }

  //update estimations
  Future<Map<String, dynamic>> updateEstimations() async {
    final response = await http.post(
      Uri.parse('$baseUrl/estimations/update'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update estimations: ${response.body}');
    }
  }

  //buy order
  Future<Map<String, dynamic>> buyOrder(
    String name, 
    String password, 
    String ticker, 
    double numShares
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order/buy'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
        'ticker': ticker,
        'num_shares': numShares,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute buy order: ${response.body}');
    }
  }

  //sell order
  Future<Map<String, dynamic>> sellOrder(
    String name, 
    String password, 
    String ticker, 
    double numShares
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/order/sell'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
        'ticker': ticker,
        'num_shares': numShares,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to execute sell order: ${response.body}');
    }
  }

  //update user (only password, no email or username changes)
  Future<Map<String, dynamic>> updateUser(
    String name,
    String password,
    {String? newPassword}
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
        if (newPassword != null) 'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  //delete user
  Future<Map<String, dynamic>> deleteUser(String name, String password) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  //promote user to owner
  Future<Map<String, dynamic>> promoteToOwner(String name, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/promote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to promote user: ${response.body}');
    }
  }

  //get all users (admin only)
  Future<List<Map<String, dynamic>>?> getAllUsers(String adminName, String adminPassword) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/list?name=$adminName&password=$adminPassword')
    );
    
    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(response.body));
      return List<Map<String, dynamic>>.from(data['users']);
    } else if (response.statusCode == 403) {
      return null; // Unauthorized
    } else {
      throw Exception('Failed to get users: ${response.body}');
    }
  }
}

