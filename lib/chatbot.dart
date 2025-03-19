import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'googleAuth.dart';
import 'util.dart';
import 'dart:core';

class GeminiChatbot {
  late String apiKey =
      const String.fromEnvironment("GEMINI_API_KEY", defaultValue: "");
  final String baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  GeminiChatbot(this.apiKey);

  Future<String> chat(String userMessage) async {
    // Error Fetch
    if (apiKey.isEmpty) {
      return "Error: API key is missing.";
    }

    final uri = Uri.parse("$baseUrl?key=$apiKey");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": userMessage}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      return "Error: ${response.reasonPhrase}";
    }
  }
}
