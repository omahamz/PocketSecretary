import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'util.dart';

/// Handles communication with the Gemini API
class GeminiChatbot {
  final GenerativeModel model;

  GeminiChatbot(String apiKey)
      : model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        );

  Future<String> chat(String message) async {
    final content = [Content.text(message)];
    final response = await model.generateContent(content);
    try {
      final text = response.text ?? "no response"; // fallback if null
      print(text);
      return text;
    } catch (e) {
      debugPrint('Chatbot error: $e');
      return "no responcse";
    }
  }

  Future<Map<String, dynamic>> structuredChat(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await model.generateContent(content);
      print(response.text);
      return parseJson(trimJson(response.text ?? ''));
    } catch (e) {
      debugPrint('Chatbot error: $e');
      return {"content": message};
    }
  }
}

/// Main chat interface screen
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  late final GeminiChatbot _chatbot;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _chatbot = GeminiChatbot(_geminiApiKey);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
      ));
    });

    String botResponse = await _chatbot.chat(userMessage);
    Map<String, dynamic> strResponse =
        await _chatbot.structuredChat(userMessage);

    final formattedResponse = _formatBotResponse(strResponse);

    setState(() {
      _messages.add(ChatMessage(
        text: botResponse,
        isUser: false,
      ));
    });
  }

  String _formatBotResponse(Map<String, dynamic> response) {
    if (response.isEmpty) return "No response";
    return response.entries
        .map((entry) => "${entry.key}: ${entry.value}")
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pocket Secretary'),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a single chat message
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

/// Custom widget for displaying chat messages
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                child: Icon(Icons.android),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          if (message.isUser)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
        ],
      ),
    );
  }
}
