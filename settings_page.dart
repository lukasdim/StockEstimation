import 'package:flutter/material.dart';
import 'package:prediction_app/pages/login_page.dart';
import '../api_service.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isLoggedIn;
  final ApiService apiService;

  SettingsPage({required this.toggleTheme, required this.isLoggedIn, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: isLoggedIn
          ? ListView(
              children: [
                ListTile(
                  title: Text("Change Password/Email"),
                  onTap: () {
                    // TODO: implement change email/password
                  },
                ),
                ListTile(
                  title: Text("Toggle Dark Mode"),
                  onTap: toggleTheme,
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                               builder: (_) => LoginPage(
                              toggleTheme: this.toggleTheme,
                              apiService: this.apiService,
                          )));
                      },
                      child: Text("Login/Register to access settings"),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: toggleTheme,
                    child: Text("Toggle Dark Mode"),
                  ),
                ],
              ),
            ),
    );
    
  }
}
