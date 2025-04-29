import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService extends ChangeNotifier {
  final SupabaseClient supabase;

  final GoogleSignIn _googleSignIn;

  GoogleAuthService(this.supabase)
      : _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/calendar.events', // Google Calendar scope
          ],
          // For Android, we don't need to specify clientId here
          serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '',
        );

  GoogleSignInAccount? _user;
  auth.AuthClient? _authClient;

  GoogleSignInAccount? get currentUser => _user;

  Future<String?> signInWithGoogle() async {
    try {
      print("signing in...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return "Sign-in was cancelled";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return 'Authentication failed: missing tokens';
      }

      // First sign out to ensure clean state
      await supabase.auth.signOut();

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user == null) {
        return 'Failed to authenticate with Supabase';
      }

      _user = googleUser;

      // Initialize the AuthClient for making API requests
      _authClient = auth.authenticatedClient(
        http.Client(),
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            googleAuth.accessToken!,
            DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
          null,
          ['https://www.googleapis.com/auth/calendar.events'],
        ),
      );

      print("User Signed In: ${googleUser.displayName} (${googleUser.email})");
      notifyListeners();
      return null; // Success
    } catch (error) {
      print("Google Sign-In Error: $error");
      return error.toString();
    }
  }

  Future<int?> reAuthenticatClient() async {
    final googleUser = await GoogleSignIn(
      scopes: ['https://www.googleapis.com/auth/calendar.events'],
    ).signInSilently();

    final googleAuth = await googleUser!.authentication;

    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          googleAuth.accessToken!,
          DateTime.now().toUtc().add(Duration(
              seconds: 3600)), // Fake expiry is fine for short-lived clients
        ),
        null,
        ['https://www.googleapis.com/auth/calendar.events'],
      ),
    );
    return 0;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await supabase.auth.signOut();
    _user = null;
    _authClient = null;
    print("User Signed Out");
  }

  auth.AuthClient? getAuthClient() => _authClient;

  String? getProfileImage() {
    return _user?.photoUrl;
  }
}
