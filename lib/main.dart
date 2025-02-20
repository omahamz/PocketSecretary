import 'package:flutter/material.dart';
import 'chatbot.dart';

void main() {
  runApp(ChatbotApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('Hello Flutter')),
        body: Center(child: Text('Welcome to Flutter!')),
      ),
    );
  }
}

class ChatbotApp extends StatefulWidget {
  @override
  _ChatbotAppState createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  final chatbot = GeminiChatbot("AIzaSyDjQ6cudgNpvmU0NvTNC3ytrBBFjlqgHzQ");
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  void sendMessage() async {
    String userMessage = _controller.text;
    _controller.clear();

    setState(() {
      messages.add({"user": userMessage});
    });

    String botResponse = await chatbot.chat(userMessage);

    setState(() {
      messages.add({"bot": botResponse});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Gemini Chatbot")),
        body: Column(
          children: [
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
      ),
    );
  }
}
