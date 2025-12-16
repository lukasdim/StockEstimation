import 'package:flutter/material.dart';
import 'package:prediction_app/pages/login_page.dart';
import '../api_service.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isLoggedIn;
  final ApiService apiService;
  final String? userName;
  final String? userPassword;

  SettingsPage({
    required this.toggleTheme,
    required this.isLoggedIn,
    required this.apiService,
    this.userName,
    this.userPassword,
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  
  bool isLoading = false;
  bool isOwner = false;
  List<Map<String, dynamic>> allUsers = [];
  double? currentBalance;

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
  }

  Future<void> _checkOwnerStatus() async {
    if (!widget.isLoggedIn || widget.userName == null) return;
    
    try {
      final users = await widget.apiService.getAllUsers(
        widget.userName!,
        widget.userPassword ?? '',
      );
      
      if (users != null) {
        // Find current user's balance
        final currentUser = users.firstWhere(
          (user) => user['name'] == widget.userName,
          orElse: () => {'balance': 0.0},
        );
        
        setState(() {
          isOwner = true;
          allUsers = users;
          currentBalance = currentUser['balance']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      // Not an owner or error occurred
      setState(() => isOwner = false);
      // Try to get current user balance even if not owner
      _loadCurrentUserBalance();
    }
  }

  Future<void> _loadCurrentUserBalance() async {
    if (!widget.isLoggedIn || widget.userName == null) return;
    
    try {
      final users = await widget.apiService.getAllUsers(
        widget.userName!,
        widget.userPassword ?? '',
      );
      
      if (users != null) {
        final currentUser = users.firstWhere(
          (user) => user['name'] == widget.userName,
          orElse: () => {'balance': 0.0},
        );
        
        setState(() {
          currentBalance = currentUser['balance']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      // Could not load balance
      print('Could not load current balance: $e');
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      _showError('Please enter your current password');
      return;
    }

    if (newPassword.isEmpty) {
      _showError('Please enter a new password');
      return;
    }

    if (newPassword.length < 8) {
      _showError('New password must be at least 8 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);

    try {
      await widget.apiService.updateUser(
        widget.userName!,
        currentPassword,
        newPassword: newPassword,
      );
      
      _showSuccess('Password updated successfully. Please log in again.');
      
      Future.delayed(Duration(seconds: 1), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(
              toggleTheme: widget.toggleTheme,
              apiService: widget.apiService,
            ),
          ),
          (route) => false,
        );
      });
    } catch (e) {
      _showError('Failed to update password: $e');
      setState(() => isLoading = false);
    }
  }


  Future<void> _deleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: Text('Confirm Account Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please enter your password to confirm account deletion.'),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Final Confirmation'),
        content: Text(
          'This will permanently delete your account and all associated data. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      await widget.apiService.deleteUser(
        widget.userName!,
        password,
      );
      
      _showSuccess('Account deleted successfully');
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(
            toggleTheme: widget.toggleTheme,
            apiService: widget.apiService,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError('Failed to delete account: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _promoteToOwner() async {
    if (widget.userName == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Promote to Owner'),
        content: Text(
          'This will promote your account to owner status, giving you admin privileges. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Promote'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      await widget.apiService.promoteToOwner(
        widget.userName!,
        widget.userPassword ?? '',
      );
      
      _showSuccess('Promoted to owner! Please restart the app.');
      await _checkOwnerStatus();
    } catch (e) {
      _showError('Failed to promote: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _adminCreateUser() async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password (min 8 characters)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'password': passwordController.text,
            }),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result['password']!.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => isLoading = true);

    try {
      await widget.apiService.addUser(result['name']!, result['password']!);
      _showSuccess('User created successfully');
      await _checkOwnerStatus();
    } catch (e) {
      _showError('Failed to create user: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _adminDeleteUser(String username) async {
    final passwordController = TextEditingController();
    
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User: $username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the user\'s password to confirm deletion:'),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'User Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await widget.apiService.deleteUser(username, password);
      _showSuccess('User deleted successfully');
      await _checkOwnerStatus();
    } catch (e) {
      _showError('Failed to delete user: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _adminEditUser(Map<String, dynamic> user) async {
    final passwordController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User: ${user['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password (min 8 characters)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'current_password': passwordController.text,
              'new_password': newPasswordController.text,
            }),
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result['new_password']!.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => isLoading = true);

    try {
      await widget.apiService.updateUser(
        user['name'],
        result['current_password']!,
        newPassword: result['new_password'],
      );
      _showSuccess('User updated successfully');
      await _checkOwnerStatus();
    } catch (e) {
      _showError('Failed to update user: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: widget.isLoggedIn
          ? _buildLoggedInSettings()
          : _buildLoggedOutSettings(),
    );
  }

  Widget _buildLoggedInSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // admin section only visible for owners
          if (isOwner) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _adminCreateUser,
                      icon: Icon(Icons.person_add),
                      label: Text('Create New User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'All Users (${allUsers.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...allUsers.map((user) => Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          user['is_owner'] 
                            ? Icons.admin_panel_settings 
                            : Icons.person,
                          color: user['is_owner'] ? Colors.blue : Colors.grey,
                        ),
                        title: Text(
                          user['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Balance: \$${user['balance'].toStringAsFixed(2)}'),
                            Text('Email: ${user['email'] ?? 'N/A'}'),
                            if (user['is_owner']) 
                              Text('Role: Owner', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: isLoading 
                                ? null 
                                : () => _adminEditUser(user),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: isLoading || user['name'] == widget.userName
                                ? null 
                                : () => _adminDeleteUser(user['name']),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    )).toList(),
                    SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: isLoading ? null : _checkOwnerStatus,
                      icon: Icon(Icons.refresh),
                      label: Text('Refresh User List'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],

          // promote to owner only visible for non-owners
          if (!isOwner) ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upgrade, color: Colors.amber.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Become an Owner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Gain admin privileges to manage all users'),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _promoteToOwner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                      ),
                      child: Text('Promote to Owner'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],

          //change Password Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Note: You will need to log in again after changing your password.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 8 characters)',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _changePassword,
                    child: Text('Update Password'),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          

          SizedBox(height: 20),

          //theme toggle
          Card(
            child: ListTile(
              title: Text('Toggle Dark Mode'),
              trailing: Icon(Icons.brightness_6),
              onTap: widget.toggleTheme,
            ),
          ),
          SizedBox(height: 20),
          //delete account
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Once you delete your account, there is no going back. Please be certain.',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Delete Account'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Please log in to access settings',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginPage(
                    toggleTheme: widget.toggleTheme,
                    apiService: widget.apiService,
                  ),
                ),
              );
            },
            child: Text("Login/Register"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.toggleTheme,
            child: Text("Toggle Dark Mode"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    balanceController.dispose();
    super.dispose();
  }
}