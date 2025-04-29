import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'googleauth.dart';

class CalendarService {
  final GoogleAuthService authService;

  CalendarService(this.authService);

  // Fetch User's Calendar Events
  Future<List<calendar.Event>> fetchEvents() async {
    print("Fetching events...");
    final auth.AuthClient? client = authService.getAuthClient();
    if (client == null) {
      print("User is not authenticated, skipping fetch.");
      return [];
    }

    print("Auth client obtained, fetching events...");
    final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);
    try {
      final events = await calendarApi.events.list("primary");
      print("Fetched ${events.items?.length ?? 0} events.");
      return events.items ?? [];
    } catch (e) {
      print("Error fetching events: $e");
      rethrow;
    }
  }

  // Create a Google Calendar Event
  Future<calendar.Event?> createEvent(String title, DateTime start,
      DateTime? end, List<String>? recurrence) async {
    print("Creating event...");
    final reAuthResult = await authService.reAuthenticatClient();
    if (reAuthResult == null) {
      print("Re-authentication failed, cannot create event");
      return null;
    }

    final auth.AuthClient? client = authService.getAuthClient();
    if (client == null) {
      print("User is not authenticated, skipping event creation.");
      return null;
    }

    final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);

    final event = calendar.Event()
      ..summary = title
      ..start = (calendar.EventDateTime()
        ..dateTime = start.toUtc()
        ..timeZone = "UTC")
      ..end = (calendar.EventDateTime()
        ..dateTime = end?.toUtc()
        ..timeZone = "UTC")
      ..recurrence = recurrence;

    print("Start: $start\n End: $end\n Recurrence: $recurrence");
    try {
      final createdEvent = await calendarApi.events.insert(event, "primary");
      print("Event created: ${createdEvent.htmlLink}");
      return createdEvent;
    } catch (e) {
      print("Error creating event: $e");
      return null;
    }
  }

  /// ✅ Update an Existing Event
  Future<void> updateEvent(String eventId, String newTitle) async {
    final auth.AuthClient? client = authService.getAuthClient();
    if (client == null) {
      print("User is not authenticated, skipping event update.");
      return;
    }

    final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);
    final event = await calendarApi.events.get("primary", eventId);

    event.summary = newTitle; // Modify the event title
    await calendarApi.events.update(event, "primary", eventId);
    print("Event updated successfully.");
  }

  /// ✅ Delete a Calendar Event
  Future<void> deleteEvent(String eventId) async {
    final auth.AuthClient? client = authService.getAuthClient();
    if (client == null) {
      print("User is not authenticated, skipping event deletion.");
      return;
    }

    final calendar.CalendarApi calendarApi = calendar.CalendarApi(client);
    await calendarApi.events.delete("primary", eventId);
    print("Event deleted successfully.");
  }
}
