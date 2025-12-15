import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    
    String baseUrl = _getBaseUrl();
    
    apiService = ApiService(baseUrl: baseUrl);
    print('API Service configured with: $baseUrl');
  }

  String _getBaseUrl() {
    return 'http://localhost:5001';
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: LoginPage(
        toggleTheme: toggleTheme,
        apiService: apiService,
      ),
    );
  }
}