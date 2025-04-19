import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'util.dart';

/// Handles communication with the Gemini API
class GeminiChatbot {
  final GenerativeModel model;

  GeminiChatbot(String apiKey, String model)
      : model = GenerativeModel(
          model: model,
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
      return eventParseing(response.text ?? '');
    } catch (e) {
      debugPrint('Chatbot error: $e');
      return {"content": message};
    }
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
