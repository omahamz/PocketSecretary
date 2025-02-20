import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiChatbot {
  final String apiKey;
  final String baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";

  GeminiChatbot(this.apiKey);

  Future<String> chat(String userMessage) async {
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
