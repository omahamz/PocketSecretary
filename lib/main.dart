import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'googleauth.dart';
import 'signin.dart';
import 'chatbot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'googleAuth.dart';

import 'calendar.dart'; // Import the CalendarService

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

  ChatbotApp(this.authService, this.calendarService);


  @override
  _ChatbotAppState createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  final chatbot = GeminiChatbot(dotenv.env['GEMINI_API_KEY'] ?? "");

  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  List<String> _eventTitles = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Fetch events on startup

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
      messages.add({"user": userMessage});
    });

    String botResponse = await GeminiChatbot("API_KEY").chat(userMessage);

    setState(() {
      messages.add({"bot": botResponse.isEmpty ? 'No response' : botResponse});
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
        title: Text("Gemini Chatbot"),
        actions: [
          if (profileImageUrl != null)
            GestureDetector(
              onTap: _signOut, // Tap to sign out
              child: Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchEvents, // Manually refresh events
          ),
        ],
      ),
      body: Column(
        children: [
          Text(_userId ?? 'Not signed in'),
          ElevatedButton(
            onPressed: _createSampleEvent,
            child: Text("Create Sample Event"),
          ),
          Expanded(
            child: _eventTitles.isEmpty
                ? Center(child: Text("No events found"))
                : ListView.builder(
                    itemCount: _eventTitles.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_eventTitles[index]),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
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
}