import '/util/googleauth.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '/util/chatbot.dart';
import '/util/textscanner.dart';
import '/util/calendar.dart';
import '/util/message_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:chrono_dart/chrono_dart.dart';
import 'generating_response_page_model.dart';
export 'generating_response_page_model.dart';

class GeneratingResponsePageWidget extends StatefulWidget {
  const GeneratingResponsePageWidget({super.key});

  static String routeName = 'GeneratingResponsePage';
  static String routePath = '/generatingResponsePage';

  @override
  State<GeneratingResponsePageWidget> createState() =>
      _GeneratingResponsePageWidgetState();
}

class _GeneratingResponsePageWidgetState
    extends State<GeneratingResponsePageWidget> {
  late GeneratingResponsePageModel _model;
  late GeminiChatbot chatbot;
  late GeminiChatbot eventChatbot;
  late TextScannerService scannerService;
  late CalendarService calendarService;
  bool _isProcessing = false;
  final _timeFormat = DateFormat('hh:mm a');
  final _scrollController = ScrollController();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GeneratingResponsePageModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    // Initialize services
    final googleAuthService =
        Provider.of<GoogleAuthService>(context, listen: false);
    calendarService = CalendarService(googleAuthService);
    scannerService = TextScannerService();

    // Initialize chatbots
    chatbot = GeminiChatbot(dotenv.env['GEMINI_API_KEY'] ?? "",
        "gemini-2.0-flash" // Restored original model name
        );
    eventChatbot = GeminiChatbot(dotenv.env['GEMINI_API_KEY'] ?? "",
        'tunedModels/pocketsecretary-2-92sl5cmi8s2j' // Restored original model name
        );

    // Listen for auth state changes
    googleAuthService.supabase.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    if (_isProcessing ||
        _model.textController == null ||
        _model.textController!.text.isEmpty) {
      return;
    }

    final userMessage = _model.textController!.text;
    _model.textController?.clear();

    final messageProvider =
        Provider.of<MessageProvider>(context, listen: false);
    messageProvider.addMessage({
      "user": {"Content": userMessage}
    });

    // Scroll to bottom after adding user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    setState(() {
      _isProcessing = true;
    });

    try {
      Map<String, dynamic> botResponse =
          await eventChatbot.structuredChat(userMessage);
      String aiResponse = await chatbot.chat(
          "$userMessage add that to my calendar. make sure the response is a short comment on the event less than 100words. this is the structured event info${botResponse.toString()}");

      if (botResponse.containsKey('title')) {
        try {
          DateTime? startDateTime =
              Chrono.parseDate(botResponse['start_time_expression']);
          if (startDateTime == null) {
            throw Exception('Invalid start date/time');
          }

          DateTime? endDateTime;
          if (botResponse['end_time_expression'] != null) {
            endDateTime = Chrono.parseDate(botResponse['end_time_expression']);
          }

          // If endDateTime is null or before startDateTime, set it to 1 hour after start
          if (endDateTime == null || !endDateTime.isAfter(startDateTime)) {
            endDateTime = startDateTime.add(const Duration(hours: 1));
          }

          List<String>? recurrenceRule;
          if (botResponse['recurrence'] != null) {
            String rule =
                'RRULE:FREQ=${botResponse['recurrence']?.toUpperCase()}';

            if (botResponse['interval'] != null) {
              rule += ';INTERVAL=${botResponse['interval']}';
            }

            final days = botResponse['days'];
            if (days != null && days.trim().isNotEmpty) {
              rule += ';BYDAY=${days.replaceAll(" ", "")}';
            }

            recurrenceRule = [rule];
          }

          // Re-authenticate before creating event
          final reAuthResult =
              await calendarService.authService.reAuthenticatClient();
          if (reAuthResult == null) {
            throw Exception('Failed to re-authenticate for calendar access');
          }

          final currentEvent = await calendarService.createEvent(
            botResponse['title'],
            startDateTime,
            endDateTime,
            recurrenceRule,
          );

          if (currentEvent?.htmlLink != null) {
            botResponse.addAll({"url": currentEvent?.htmlLink});
          }
        } catch (e) {
          print('Error creating calendar event: $e');
          messageProvider.addMessage({
            "bot": {
              "Content":
                  "I'm sorry, I encountered an error creating the calendar event: ${e.toString()}"
            }
          });
        }
      }

      messageProvider.addMessage({
        "bot": botResponse.isEmpty
            ? {"Content": aiResponse}
            : {"Content": aiResponse, "eventData": botResponse}
      });

      // Scroll to bottom after adding bot response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      print('Error processing message: $e');
      messageProvider.addMessage({
        "bot": {
          "Content":
              "I'm sorry, I encountered an error processing your request."
        }
      });
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Widget _buildMessageBubble(bool isUser, String content,
      Map<String, dynamic>? eventData, String time) {
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      decoration: BoxDecoration(
        color: isUser ? Color(0xFFE0E0E0) : Color(0xFF4B4B4B),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 4.0),
              child: Text(
                content,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      color: isUser ? Colors.black : Colors.white,
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            if (eventData != null && eventData['title'] != null) ...[
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 12.0, 4.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF0F91CB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📅 ${eventData['title']}',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                              color: Colors.white,
                              letterSpacing: 0.0,
                            ),
                      ),
                      if (eventData['start_time_expression'] != null)
                        Text(
                          '🕒 ${eventData['start_time_expression']}',
                          style:
                              FlutterFlowTheme.of(context).bodySmall.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w400),
                                    color: Colors.white70,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (eventData['url'] != null)
                            TextButton(
                              onPressed: () async {
                                final url = Uri.parse(eventData['url']);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                'View in Calendar',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500),
                                      color: Color(0xFF0F91CB),
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                          TextButton(
                            onPressed: () {
                              context.pushNamed(
                                  CalendarEventsPageWidget.routeName);
                            },
                            child: Text(
                              'View All Events',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500),
                                    color: Color(0xFF0F91CB),
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 8.0),
              child: Text(
                time,
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      color: isUser ? Color(0xFF757575) : Color(0xFFCCCCCC),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final googleAuthService =
        Provider.of<GoogleAuthService>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context);

    // Ensure calendar service is properly initialized
    calendarService ??= CalendarService(googleAuthService);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF545459),
        automaticallyImplyLeading: false,
        title: Text(
          'Pocket Secretary',
          style: FlutterFlowTheme.of(context).titleLarge.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                color: Colors.white,
                letterSpacing: 0.0,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () async {
              context.pushNamed(CalendarEventsPageWidget.routeName);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await googleAuthService.signOut();
              context.pushNamed(LoginPageWidget.routeName);
            },
          ),
        ],
        centerTitle: true,
        elevation: 2.0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.vertical,
                  itemCount: messageProvider.messages.isEmpty
                      ? 1
                      : messageProvider.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Welcome message
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMessageBubble(
                            false,
                            "Hello! I'm your Pocket Secretary. How can I assist you today?",
                            null,
                            "10:30 AM",
                          ),
                        ],
                      );
                    }

                    final message = messageProvider.messages[index - 1];
                    final isUser = message.containsKey('user');
                    final content = message.values.first['Content'] as String;
                    final eventData =
                        isUser ? null : message.values.first['eventData'];

                    return Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
                      child: _buildMessageBubble(
                        isUser,
                        content,
                        eventData,
                        _timeFormat.format(DateTime.now()),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Camera button
                    FlutterFlowIconButton(
                      borderRadius: 25.0,
                      buttonSize: 50.0,
                      fillColor: Color(0xFF0F91CB),
                      icon: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: () async {
                        final result =
                            await scannerService.scanTextFromCamera();
                        if (result != null) {
                          setState(() {
                            _model.textController.text = result;
                          });
                          sendMessage();
                        }
                      },
                    ),
                    // Gallery button
                    FlutterFlowIconButton(
                      borderRadius: 25.0,
                      buttonSize: 50.0,
                      fillColor: Color(0xFF0F91CB),
                      icon: Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: () async {
                        final result =
                            await scannerService.scanTextFromGallery();
                        if (result != null) {
                          setState(() {
                            _model.textController.text = result;
                          });
                          sendMessage();
                        }
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _model.textController,
                        focusNode: _model.textFieldFocusNode,
                        textCapitalization: TextCapitalization.sentences,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: 'Type your message here...',
                          hintStyle:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w400),
                                    color: Color(0xFF757575),
                                    letterSpacing: 0.0,
                                  ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF0F91CB),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 12.0, 16.0, 12.0),
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w400),
                              color: Colors.black87,
                              letterSpacing: 0.0,
                            ),
                        maxLines: 5,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        cursorColor: Color(0xFF0F91CB),
                        cursorWidth: 2.0,
                        validator:
                            _model.textControllerValidator.asValidator(context),
                      ),
                    ),
                    FlutterFlowIconButton(
                      borderRadius: 25.0,
                      buttonSize: 50.0,
                      fillColor: Color(0xFF0F91CB),
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: _isProcessing ? null : sendMessage,
                    ),
                  ].divide(SizedBox(width: 8.0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
