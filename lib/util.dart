import 'dart:convert';

Map<String, dynamic> parseJson(String jsonString) {
  try {
    final jsonData = jsonDecode(jsonString);
    print(jsonData);
    return jsonData;
  } catch (e) {
    print('Error parsing JSON: $e');
  }
  return {};
}

String trimJson(String jsonString) {
  // Find the index of the first '{'
  int startIndex = jsonString.indexOf('{');
  // If '{' is found, return the substring starting from it
  if (startIndex != -1) {
    return jsonString.substring(startIndex);
  }
  // If '{' is not found, return the original string
  return jsonString;
}
