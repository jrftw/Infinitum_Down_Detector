// Filename: auth_screen.dart
// Purpose: Authentication screen for user login and registration
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: flutter, services/auth_service.dart, core/logger.dart
// Platform Compatibility: Web, iOS, Android

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../core/logger.dart';

// MARK: - Authentication Screen
// Provides login and registration functionality
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // MARK: - Authentication Methods
  /// Handles form submission for login or registration
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isLogin) {
        await authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        Logger.logInfo('User signed in successfully', 'auth_screen.dart', '_handleSubmit');
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Passwords do not match';
            _isLoading = false;
          });
          return;
        }

        await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        Logger.logInfo('User registered successfully', 'auth_screen.dart', '_handleSubmit');
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
      Logger.logError('Authentication error', 'auth_screen.dart', '_handleSubmit', e);
    }
  }

  /// Gets user-friendly error message from exception
  String _getErrorMessage(Exception e) {
    final errorString = e.toString().toLowerCase();
    if (errorString.contains('user-not-found') || errorString.contains('wrong-password')) {
      return 'Invalid email or password';
    } else if (errorString.contains('email-already-in-use')) {
      return 'An account with this email already exists';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your connection';
    }
    return 'An error occurred. Please try again';
  }

  // MARK: - UI Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title
                    Icon(
                      Icons.monitor_heart,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Infinitum Down Detector',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Sign in to monitor services' : 'Create an account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (!_isLogin && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm password field (registration only)
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Submit button
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Sign In' : 'Register'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Toggle login/register
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _errorMessage = null;
                              });
                            },
                      child: Text(
                        _isLogin
                            ? 'Don\'t have an account? Register'
                            : 'Already have an account? Sign In',
                      ),
                    ),
                    
                    // Forgot password
                    if (_isLogin)
                      TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Password Reset
  /// Handles forgot password functionality
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendPasswordResetEmail(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Please check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_getErrorMessage(e as Exception)}'),
          ),
        );
      }
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add Google Sign-In button
// - Add Apple Sign-In button
// - Implement biometric authentication
// - Add "Remember me" functionality
// - Create email verification flow
// - Add social login options
// - Implement account recovery options
// - Add terms of service and privacy policy links

