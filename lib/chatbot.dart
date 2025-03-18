import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'googleAuth.dart';
import 'util.dart';
import 'dart:core';

class GeminiChatbot {
  final GenerativeModel model;

  GeminiChatbot(String apiKey)
      : model = GenerativeModel(
          model: 'tunedModels/pocketsecretary-tkl0plqwx64f',
          apiKey: apiKey,
        );

  Future<Map<String, dynamic>> chat(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await model.generateContent(content);
      final jsonResponse = parseJson(trimJson(response.text ?? ''));

      return jsonResponse;
    } catch (e) {
      return {};
    }
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final String geminiApikey = dotenv.env['GEMINI_API_KEY'] ?? '';

  late final GeminiChatbot chatbot;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  @override
  void initState() {
    super.initState();
    chatbot = GeminiChatbot(geminiApikey);
  }

  void sendMessage() async {
    String userMessage = _controller.text;
    _controller.clear();

    setState(() {
      messages.add({"user": userMessage});
    });

    Map<String, dynamic> botResponse = await chatbot.chat(userMessage);

    // Convert the entire response map to a formatted string
    String responseText = botResponse.entries
        .map((entry) => "${entry.key}: ${entry.value}")
        .join('\n');

    setState(() {
      messages
          .add({"bot": responseText.isEmpty ? 'No response' : responseText});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gemini Chatbot"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Navigate back to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
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
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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
