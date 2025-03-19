import 'package:flutter/material.dart';
import 'googleauth.dart'; // Import GoogleAuthService
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'main.dart'; // Import ChatbotApp to navigate after login

class SignInScreen extends StatefulWidget {
  final GoogleAuthService authService;

  SignInScreen(this.authService); // Accept authService

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });

    String? error = await widget.authService.signInWithGoogle();

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChatbotApp(widget.authService)),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to PocketSecretary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : GestureDetector(
                    onTap: () {
                      print("Button tapped");
                      _signIn();
                    },
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(color: Colors.grey, blurRadius: 4)
                          ],
                        ),
                        child: SignInButton(
                          Buttons.Google,
                          onPressed: () {
                            print("Button tapped");
                            _signIn();
                          },
                        )),
                  ),
          ],
        ),
      ),
    );
  }
}
