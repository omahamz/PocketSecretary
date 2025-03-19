import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'googleauth.dart';
import 'signin.dart';
import 'chatbot.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis/calendar/v3.dart' as calendar;

void main() async {
  await Supabase.initialize(
    url: 'https://qthipgkobnvhwsmxiuyn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0aGlwZ2tvYm52aHdzbXhpdXluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2MDQ2ODAsImV4cCI6MjA1NjE4MDY4MH0.DJkQAhPO3aSus1NyWmImErutMd3781a2BY3f7IUc9zM',
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

  @override
  void initState() {
    super.initState();
    _authService = GoogleAuthService(supabase);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _authService.currentUser == null
          ? SignInScreen(_authService) // Show Sign-In Screen first
          : ChatbotApp(_authService), // If signed in, go to chatbot
    );
  }
}

class ChatbotApp extends StatefulWidget {
  final GoogleAuthService authService;
  ChatbotApp(this.authService);

  @override
  _ChatbotAppState createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  String? _userId;

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

    String botResponse = await GeminiChatbot("API_KEY").chat(userMessage);

    setState(() {
      messages.add({"bot": botResponse});
    });
  }

  void _signOut() async {
    await widget.authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen(widget.authService)),
    );
  }

  Future<void> _fetchEvents() async {
    final auth.AuthClient? client = widget.authService.getAuthClient();
    if (client == null) {
      print("User is not authenticated");
      return;
    }

    final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);
    final events = await calendarApi.events.list("primary");

    for (var event in events.items ?? []) {
      print("Event: ${event.summary} at ${event.start?.dateTime}");
    }
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
        ],
      ),
      body: Column(
        children: [
          Text(_userId ?? 'Not signed in'),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(
                    message.keys.first == "user"
                        ? "You: ${message["user"]}"
                        : "Bot: ${message["bot"]}",
                    textAlign: message.keys.first == "user"
                        ? TextAlign.right
                        : TextAlign.left,
                  ),
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
