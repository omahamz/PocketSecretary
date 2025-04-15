import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
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
        return "User canceled sign-in.";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Auth tokens are null';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      _user = googleUser;

      // Initialize the AuthClient for making API requests
      _authClient = auth.authenticatedClient(
        http.Client(),
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            googleAuth.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)),
          ),
          null,
          ['https://www.googleapis.com/auth/calendar.events'],
        ),
      );

      print("User Signed In: ${googleUser.displayName} (${googleUser.email})");
      return null;
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
