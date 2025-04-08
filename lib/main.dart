import 'package:flutter/material.dart';
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
  final chatbot = GeminiChatbot(dotenv.env['GEMINI_API_KEY'] ?? "");
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  List<String> _eventTitles = [];
  String? _userId;
  bool _showEvents = false; // Track which view to show

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
      messages.add({"user": userMessage});
    });

    Map<String, dynamic> botResponse =
        await chatbot.structuredChat(userMessage);
    String tempChatbotResponse = await chatbot.chat(userMessage);
    String dateTimeInfo = Chrono.parseDate(tempChatbotResponse).toString();

    // Handle event creation if response contains event details
    if (botResponse.containsKey('event_title')) {
      try {
        final date = botResponse['date'] as String;
        final time = botResponse['time'] as String;
        final endTime = botResponse['end_time'] as String;

        // Parse date and time strings to DateTime
        final startDateTime = DateTime.parse('${date}T$time');
        final endDateTime = DateTime.parse('${date}T$endTime');

        await widget.calendarService.createEvent(
          botResponse['event_title'],
          startDateTime,
          endDateTime,
        );

        _fetchEvents(); // Refresh events after creating
      } catch (e) {
        print('Error creating event: $e');
      }
    }

    setState(() {
      messages.add({
        "bot": botResponse.isEmpty
            ? "$tempChatbotResponse\n$dateTimeInfo"
            : botResponse.toString()
      });
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
      itemCount: messages.length,
      padding: EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.containsKey('user');
        return ListTile(
          title: FormattedText(
            message.values.first,
            textAlign: TextAlign.left,
          ),
          leading: Icon(
            isUser ? Icons.person : Icons.android,
            color: isUser ? Colors.blue : Colors.green,
          ),
        );
      },
    );
  }
}
