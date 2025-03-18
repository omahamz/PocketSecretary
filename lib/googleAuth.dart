import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'dart:math' show min;

// Google Auth Service
class GoogleAuthService {
  final supabase = Supabase.instance.client;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
    serverClientId:
        '278206926357-8r4h92uec0aj4lr57dn0ps7jv3d4j06n.apps.googleusercontent.com',
  );

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Sign out first to ensure a fresh sign-in
      await _googleSignIn.signOut();

      // Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In was cancelled by user');
        return null;
      }

      // Verify we have a valid user before proceeding
      if (!googleUser.email.isNotEmpty) {
        print('Error: Invalid Google user data');
        return null;
      }

      print('Google Sign In successful: ${googleUser.email}');
      print('Display Name: ${googleUser.displayName ?? "No name"}');
      print('Photo URL: ${googleUser.photoUrl ?? "No photo"}');

      // Get auth details from Google with null safety
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth == null) {
        print('Error: Failed to get Google authentication');
        return null;
      }

      // Safely print token information
      if (googleAuth.idToken != null) {
        print(
            'ID Token: ${googleAuth.idToken!.substring(0, min(10, googleAuth.idToken!.length))}...');
      } else {
        print('ID Token is null');
      }

      if (googleAuth.accessToken != null) {
        print(
            'Access Token: ${googleAuth.accessToken!.substring(0, min(10, googleAuth.accessToken!.length))}...');
      } else {
        print('Access Token is null');
      }

      // Check for null tokens
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        print('Error: Google auth tokens are null');
        return null;
      }

      // Create credentials for Supabase
      final authResponse = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      print('Supabase auth successful');
      return authResponse;
    } catch (error) {
      print('Error signing in with Google: $error');
      if (error is PlatformException) {
        print('Error code: ${error.code}');
        print('Error message: ${error.message}');
        print('Error details: ${error.details}');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await supabase.auth.signOut();
  }
}

// Login Screen Widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authService.signInWithGoogle();
      if (response != null && mounted) {
        // Get the current signed-in user
        final googleUser = await _authService._googleSignIn.signInSilently();
        if (googleUser != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(user: googleUser),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome Text
                const Text(
                  'Welcome to\nPocket Secretary',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Your AI-powered personal assistant',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),

                // Google Sign In Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '🔍',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                // Version Text
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
