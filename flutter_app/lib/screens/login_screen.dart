import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _userIdController = TextEditingController();
  bool _isRegisterMode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade900,
                  Colors.purple.shade900,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo/Title
                    const Text(
                      '💸 ScholarSpend AI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Know how many days your money will last',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isRegisterMode) ...[
                            // Register: Name field
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Your Name',
                                prefixIcon: const Icon(Icons.person),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'Name required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Register: Initial Balance
                            TextFormField(
                              controller: _initialBalanceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Initial Balance (₹)',
                                prefixIcon: const Icon(Icons.currency_rupee),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'Balance required';
                                if (double.tryParse(v!) == null) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // Login: User ID field
                            TextFormField(
                              controller: _userIdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'User ID',
                                prefixIcon: const Icon(Icons.badge),
                                filled: true,
                                fillColor: Colors.white10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'User ID required' : null,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleSubmit(authProvider),
                        icon: authProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(_isRegisterMode ? Icons.app_registration : Icons.login),
                        label: Text(
                          _isRegisterMode ? 'Create Account' : 'Login',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    if (authProvider.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Error: ${authProvider.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Toggle mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegisterMode
                              ? 'Already have an account? '
                              : 'Don\'t have an account? ',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            _isRegisterMode ? 'Login' : 'Register',
                            style: TextStyle(
                              color: Colors.blue.shade200,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSubmit(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    bool success;
    if (_isRegisterMode) {
      final name = _nameController.text;
      final balance = double.parse(_initialBalanceController.text);
      success = await authProvider.register(name, balance);
    } else {
      final userId = int.parse(_userIdController.text);
      success = await authProvider.login(userId);
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
