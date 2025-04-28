import 'package:flutter/material.dart';
import 'package:pocket_secretary/textscanner.dart';
import 'calendar.dart';
import 'googleauth.dart'; // Import GoogleAuthService
import 'main.dart'; // Import ChatbotApp to navigate after login

class SignInScreen extends StatefulWidget {
  final GoogleAuthService authService;
  final CalendarService calendarService;
  final TextScannerService scannerService;

  const SignInScreen(
      this.authService, this.calendarService, this.scannerService,
      {super.key}); // Accept authService

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
        MaterialPageRoute(
            builder: (context) => ChatbotApp(widget.authService,
                widget.calendarService, widget.scannerService)),
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text('Sign in with Google'),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
