import 'package:flutter/material.dart';
import 'package:googleapis/chat/v1.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'googleauth.dart';
import 'signin.dart';
import 'chatbot.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'calendar.dart'; // Import the CalendarService
import 'package:formatted_text/formatted_text.dart';
import 'package:chrono_dart/chrono_dart.dart' show Chrono;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupabaseClient supabase = Supabase.instance.client;
  late GoogleAuthService _authService;
  late CalendarService _calendarService;

  @override
  void initState() {
    super.initState();
    _authService = GoogleAuthService(supabase);
    _calendarService =
        CalendarService(_authService); // Initialize CalendarService
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _authService.currentUser == null
          ? SignInScreen(
              _authService, _calendarService) // Show Sign-In Screen first
          : ChatbotApp(_authService, _calendarService), // Pass CalendarService
    );
  }
}

class ChatbotApp extends StatefulWidget {
  final GoogleAuthService authService;
  final CalendarService calendarService; // Add CalendarService

  const ChatbotApp(this.authService, this.calendarService, {super.key});

  @override
  _ChatbotAppState createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  final chatbot =
      GeminiChatbot(dotenv.env['GEMINI_API_KEY'] ?? "", "gemini-2.0-flash");
  final EventChatbot = GeminiChatbot(dotenv.env['GEMINI_API_KEY'] ?? "",
      'tunedModels/pocketsecretary-2-92sl5cmi8s2j');
  final TextEditingController _controller = TextEditingController();
  List<Map<String, Map<String, dynamic>>> messages = [];
  List<String> _eventTitles = [];
  String? _userId;
  bool _showEvents = false; // Track which view to show
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();

    widget.authService.supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _userId = data.session?.user.id;
      });
    });
  }

  void sendMessage() async {
    String userMessage = _controller.text;
    _controller.clear();

    setState(() {
      messages.add({
        "user": {"Content": userMessage}
      });
    });

    Map<String, dynamic> botResponse =
        await EventChatbot.structuredChat(userMessage);
    //basic text response
    String aiResponse = await chatbot.chat(
        "$userMessage add that to my calander. make sure the response is a short comment on the event less then 100words. this is the structured event info${botResponse.toString()}");

    // Handle event creation if response contains event details
    if (botResponse.containsKey('title')) {
      try {
        DateTime? startDateTime =
            Chrono.parseDate(botResponse['start_time_expression'] as String);
        //DateTime? endDateTime;
        DateTime? endDateTime =
            Chrono.parseDate(botResponse['end_time_expression'] as String) ??
                null;

        if (startDateTime != null) {
          if (botResponse.containsKey('end_time_expression') &&
              (botResponse['end_time_expression'] as String)
                  .trim()
                  .isNotEmpty) {
            endDateTime = Chrono.parseDate(botResponse['end_time_expression']);
          }

          // fallback to 1 hour after start time
          endDateTime ??= startDateTime.add(const Duration(hours: 1));

          // Update botResponse
          botResponse['start_time_expression'] = startDateTime;
          botResponse['end_time_expression'] = endDateTime;

          final currentEvent = await widget.calendarService.createEvent(
            botResponse['title'],
            startDateTime,
            endDateTime,
          );

          botResponse.addAll({"url": currentEvent?.htmlLink});
        }

        _fetchEvents(); // Refresh events after creating
      } catch (e) {
        print('Error creating event: $e');
      }
    }

    setState(() {
      messages.add({
        "bot": botResponse.isEmpty
            ? {
                "Content": "**No Response**",
                "eventData": null,
              }
            : {
                "Content": "$aiResponse}",
                "eventData": botResponse,
              }
      });
    });
    // Scroll to bottom after new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _signOut() async {
    await widget.authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SignInScreen(widget.authService, widget.calendarService)),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Always dispose controllers!
    super.dispose();
  }

  /// ✅ Fetch Calendar Events via `CalendarService`
  Future<void> _fetchEvents() async {
    final events = await widget.calendarService.fetchEvents();
    setState(() {
      _eventTitles =
          events.map((event) => event.summary ?? "No Title").toList();
    });
  }

  /// ✅ Create a Sample Event (for testing)
  Future<void> _createSampleEvent() async {
    await widget.calendarService.createEvent(
      "Test Meeting",
      DateTime.now().add(Duration(days: 1, hours: 9)), // Tomorrow at 9 AM
      DateTime.now().add(Duration(days: 1, hours: 10)), // Tomorrow at 10 AM
    );
    _fetchEvents(); // Refresh events after creating
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = widget.authService.getProfileImage();

    return Scaffold(
      appBar: AppBar(
        title: Text(_showEvents ? "Calendar Events" : "Pocket Secretary"),
        actions: [
          if (_showEvents)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _fetchEvents,
            ),
          // Toggle button
          IconButton(
            icon: Icon(_showEvents ? Icons.chat : Icons.calendar_today),
            onPressed: () {
              setState(() {
                _showEvents = !_showEvents;
              });
            },
          ),
          if (profileImageUrl != null)
            GestureDetector(
              onTap: _signOut,
              child: Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _showEvents ? _buildEventsView() : _buildChatView(),
          ),
          if (!_showEvents) // Only show message input in chat view
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          InputDecoration(hintText: "Type a message..."),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsView() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _createSampleEvent,
          child: Text("Create Sample Event"),
        ),
        Expanded(
          child: _eventTitles.isEmpty
              ? Center(child: Text("No events found"))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _eventTitles.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_eventTitles[index]),
                      leading: Icon(Icons.event),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      padding: EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.containsKey('user');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.android,
                  color: isUser ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FormattedText(
                    message.values.first["Content"]!,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
            (message.values.first["eventData"]?["title"] == null ||
                    message.values.first["eventData"]
                            ?["start_time_expression"] ==
                        null
                ? Text("")
                : ElevatedButton(
                    onPressed: () =>
                        {print(message.values.first["eventData"]["url"])},
                    child: FormattedText(
                        "${message.values.first["eventData"]?["title"] ?? ""}\n${message.values.first["eventData"]?["start_time_expression"] ?? ""}")))
          ]),
        );
      },
    );
  }

  // Widget _buildChatView() {
  //   return ListView.builder(
  //     itemCount: messages.length,
  //     padding: EdgeInsets.all(8.0),
  //     itemBuilder: (context, index) {
  //       final message = messages[index];
  //       final isUser = message.containsKey('user');
  //       return ListTile(
  //         title: FormattedText(
  //           message.values.first,
  //           textAlign: TextAlign.left,
  //         ),
  //         leading: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Icon(
  //               isUser ? Icons.person : Icons.android,
  //               color: isUser ? Colors.blue : Colors.green,
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
}
