import 'package:flutter/material.dart';
import 'main_page.dart';
import '../api_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ApiService apiService;
  

  const LoginPage({
    Key? key,
    required this.toggleTheme,
    required this.apiService,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isRegistering = false;
  bool isLoading = false;

  Future<void> handleAuth() async {
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    
    print("=== Starting Auth ===");
    print("Name: $name");
    print("Password length: ${password.length}");
    print("Is registering: $isRegistering");

    if (name.isEmpty) {
      _showError("Please enter a username");
      return;
    }

    if (password.length < 8) {
      _showError("Password must be at least 8 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isRegistering) {
        print("Calling addUser API...");
        await widget.apiService.addUser(name, password);
        print("User added successfully!");
        _showSuccess("Account created!");
        navigateToMain(true, name);
      } else {
        print("Calling getBalance API...");
        final balance = await widget.apiService.getBalance(name, password);
        print("Balance received: $balance");
        if (balance != null) {
          navigateToMain(true, name);
        } else {
          _showError("User not found");
        }
      }
    } catch (e) {
      print("ERROR: $e");
      _showError(isRegistering ? "Registration failed: $e" : "Login failed: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void navigateToMain(bool loggedIn, String? userName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainPage(
          toggleTheme: widget.toggleTheme,
          isLoggedIn: loggedIn,
          apiService: widget.apiService,
          userName: userName,
          userPassword: passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegistering ? "Register" : "Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password (min 8 characters)"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleAuth,
                    child: Text(isRegistering ? "Register" : "Login"),
                  ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() => isRegistering = !isRegistering),
              child: Text(isRegistering
                  ? "Already have an account? Login"
                  : "Don't have an account? Register"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => navigateToMain(false, null),
              child: Text("Skip Login"),
            ),
          ],
        ),
      ),
    );
  }
}

bool isValidPassword(String password) {
  if (password.length < 8) return false;
  return true;
} 