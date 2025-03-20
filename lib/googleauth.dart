import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

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
          clientId:
              '87171208864-1lnr6nt7o2cjcv5fa75r477c9hl1h99t.apps.googleusercontent.com',
          serverClientId:
              '87171208864-jpf59eh2tq90l697v86244otl8jspbl9.apps.googleusercontent.com',
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
