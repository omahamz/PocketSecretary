import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page_model.dart';
import '/util/googleauth.dart';
export 'login_page_model.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  static String routeName = 'LoginPage';
  static String routePath = '/loginPage';

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  final SupabaseClient supabase = Supabase.instance.client;
  late LoginPageModel _model;
  late GoogleAuthService _googleAuthService;
  bool _isLoading = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginPageModel());
    _googleAuthService = GoogleAuthService(supabase);

    // Check current authentication state
    _checkAuthState();
  }

  void _checkAuthState() async {
    final session = supabase.auth.currentSession;
    print(
        'AUTH DEBUG: Current session: ${session != null ? 'ACTIVE' : 'NULL'}');

    if (session != null) {
      print('AUTH DEBUG: User ID: ${session.user.id}');
      print('AUTH DEBUG: User email: ${session.user.email}');
      print('AUTH DEBUG: Token expires: ${session.expiresAt}');

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        context.pushReplacementNamed(GeneratingResponsePageWidget.routeName);
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _googleAuthService.signInWithGoogle();
      if (result == null) {
        // null result means success
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          context.pushReplacementNamed(GeneratingResponsePageWidget.routeName);
        }
      } else {
        // Non-null result means there was an error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Logo
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Container(
                      width: 200.0,
                      height: 200.0,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/Poc_Sec_Logo_Final.png',
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),

                // Title
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'Pocket Secretary',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: Colors.black,
                            fontSize: 28.0,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ),

                // Subtitle 1
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Manage scheduling more easily and efficiently!',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Colors.black,
                          letterSpacing: 0.0,
                        ),
                  ),
                ),

                // Subtitle 2
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Sign in using Google to access the app',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Colors.black,
                          letterSpacing: 0.0,
                        ),
                  ),
                ),

                // Google Sign-In Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 16.0),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : FFButtonWidget(
                          onPressed: _handleGoogleSignIn,
                          text: 'Continue with Google',
                          icon: const FaIcon(
                            FontAwesomeIcons.google,
                            size: 20.0,
                          ),
                          options: FFButtonOptions(
                            width: 230.0,
                            height: 44.0,
                            padding: EdgeInsets.zero,
                            iconPadding: EdgeInsets.zero,
                            color: Colors.black,
                            textStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                ),
                            elevation: 0.0,
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(40.0),
                            hoverColor:
                                FlutterFlowTheme.of(context).primaryBackground,
                          ),
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
