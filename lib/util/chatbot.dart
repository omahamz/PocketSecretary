import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'util.dart';

/// Handles communication with the Gemini API
class GeminiChatbot {
  final GenerativeModel model;

  GeminiChatbot(String apiKey, String modelName)
      : model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

  Future<String> chat(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        debugPrint('Empty response from Gemini API');
        return "I'm sorry, I couldn't generate a response at this time.";
      }

      return text;
    } catch (e) {
      debugPrint('Chatbot error: $e');
      if (e is GenerativeAIException) {
        return "API Error: ${e.message}";
      }
      return "I encountered an error while processing your request. Please try again.";
    }
  }

  Future<Map<String, dynamic>> structuredChat(String message) async {
    try {
      final content = [Content.text(message)];
      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        debugPrint('Empty response from Gemini API');
        return {"error": "No response from AI"};
      }

      return eventParseing(text);
    } catch (e) {
      debugPrint('Structured chat error: $e');
      if (e is GenerativeAIException) {
        return {"error": "API Error: ${e.message}"};
      }
      return {"error": "Failed to process the message"};
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
