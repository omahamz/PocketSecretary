import 'package:flutter/foundation.dart';

class MessageProvider extends ChangeNotifier {
  List<Map<String, Map<String, dynamic>>> _messages = [];

  List<Map<String, Map<String, dynamic>>> get messages => _messages;

  void addMessage(Map<String, Map<String, dynamic>> message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void setMessages(List<Map<String, Map<String, dynamic>>> messages) {
    _messages = messages;
    notifyListeners();
  }
}
