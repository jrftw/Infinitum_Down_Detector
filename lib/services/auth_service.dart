// Filename: auth_service.dart
// Purpose: Firebase authentication service for user authentication
// Author: Kevin Doyle Jr. / Infinitum Imagery LLC
// Last Modified: 2025-01-27
// Dependencies: firebase_auth, logger.dart
// Platform Compatibility: Web, iOS, Android

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/logger.dart';

// MARK: - Authentication Service
// Handles Firebase authentication and user session management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // MARK: - Streams
  // Stream of authentication state changes
  Stream<bool> get authStateChanges {
    return _auth.authStateChanges().map((user) => user != null);
  }
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  // MARK: - Authentication Methods
  /// Signs in with email and password
  /// [email] - User email address
  /// [password] - User password
  /// Returns User if successful, throws exception on failure
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      Logger.logInfo('Attempting sign in for: $email', 'auth_service.dart', 'signInWithEmailAndPassword');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      Logger.logInfo('Sign in successful for: $email', 'auth_service.dart', 'signInWithEmailAndPassword');
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      Logger.logError('Firebase auth error during sign in', 'auth_service.dart', 'signInWithEmailAndPassword', e);
      rethrow;
    } catch (e) {
      Logger.logError('Unexpected error during sign in', 'auth_service.dart', 'signInWithEmailAndPassword', e);
      rethrow;
    }
  }
  
  /// Signs out the current user
  /// Returns void
  Future<void> signOut() async {
    try {
      Logger.logInfo('Signing out user: ${currentUser?.email}', 'auth_service.dart', 'signOut');
      await _auth.signOut();
      Logger.logInfo('Sign out successful', 'auth_service.dart', 'signOut');
    } catch (e) {
      Logger.logError('Error during sign out', 'auth_service.dart', 'signOut', e);
      rethrow;
    }
  }
  
  /// Registers a new user with email and password
  /// [email] - User email address
  /// [password] - User password
  /// Returns User if successful, throws exception on failure
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      Logger.logInfo('Attempting registration for: $email', 'auth_service.dart', 'registerWithEmailAndPassword');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      Logger.logInfo('Registration successful for: $email', 'auth_service.dart', 'registerWithEmailAndPassword');
      return userCredential.user;
      
    } on FirebaseAuthException catch (e) {
      Logger.logError('Firebase auth error during registration', 'auth_service.dart', 'registerWithEmailAndPassword', e);
      rethrow;
    } catch (e) {
      Logger.logError('Unexpected error during registration', 'auth_service.dart', 'registerWithEmailAndPassword', e);
      rethrow;
    }
  }
  
  /// Sends a password reset email
  /// [email] - User email address
  /// Returns void
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      Logger.logInfo('Sending password reset email to: $email', 'auth_service.dart', 'sendPasswordResetEmail');
      await _auth.sendPasswordResetEmail(email: email);
      Logger.logInfo('Password reset email sent successfully', 'auth_service.dart', 'sendPasswordResetEmail');
    } catch (e) {
      Logger.logError('Error sending password reset email', 'auth_service.dart', 'sendPasswordResetEmail', e);
      rethrow;
    }
  }
}

// Suggestions For Features and Additions Later:
// - Add Google Sign-In integration
// - Add Apple Sign-In integration
// - Implement email verification
// - Add user profile management
// - Create role-based access control
// - Add session management and token refresh
// - Implement biometric authentication
// - Add two-factor authentication support

