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

Map<String, dynamic> eventParseing(String data) {
  /*
    example input
      title: Soccer
      description: 
      location: Sage Park
      start_time_expression: 5:00 PM
      end_time_expression: 7:00 PM
      is_recurring: false
      recurrence_frequency: 
      recurrence_interval: 
      recurrence_days:
     */

  final dataSections = data.split("\n");
  Map<String, dynamic> parsData = {};

  for (var i = 0; i < dataSections.length; i++) {
    final itter = dataSections[i].split(":");
    final key = itter[0].trim();
    String item = itter[1].trim();
    for (var i = 2; i < itter.length; i++) {
      item += ":${itter[i].trim()}";
    }
    parsData.addAll({key: item});
  }

  return parsData;
}
