import '/flutter_flow/flutter_flow_theme.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/util/calendar.dart';
import '/util/googleauth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class CalendarEventsPageWidget extends StatefulWidget {
  const CalendarEventsPageWidget({super.key});

  static String routeName = 'CalendarEventsPage';
  static String routePath = '/calendarEventsPage';

  @override
  State<CalendarEventsPageWidget> createState() =>
      _CalendarEventsPageWidgetState();
}

class _CalendarEventsPageWidgetState extends State<CalendarEventsPageWidget> {
  List<calendar.Event> _events = [];
  bool _isLoading = true;
  String? _error;
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final googleAuthService =
          Provider.of<GoogleAuthService>(context, listen: false);
      // Ensure we're authenticated before fetching events
      final reAuthResult = await googleAuthService.reAuthenticatClient();
      if (reAuthResult != null) {
        _fetchEvents();
      }
    });
  }

  Future<void> _fetchEvents() async {
    print("Starting to fetch events in CalendarEventsPageWidget");
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final googleAuthService =
          Provider.of<GoogleAuthService>(context, listen: false);
      print("Got GoogleAuthService");
      // Ensure we're authenticated
      final reAuthResult = await googleAuthService.reAuthenticatClient();
      if (reAuthResult == null) {
        throw Exception('Failed to authenticate for calendar access');
      }

      final calendarService = CalendarService(googleAuthService);
      print("Created CalendarService");
      final events = await calendarService.fetchEvents();
      print("Fetched ${events.length} events");
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in _fetchEvents: $e");
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFBEBEBE),
        iconTheme: IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        leading: InkWell(
          onTap: () =>
              context.pushNamed(GeneratingResponsePageWidget.routeName),
          child: Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Events',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
                color: Colors.black,
                fontSize: 28.0,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchEvents,
          ),
        ],
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _events.isEmpty
                    ? Center(child: Text('No events found'))
                    : ListView.builder(
                        reverse: true,
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          _events.sort((a, b) {
                            final aTime = a.start?.dateTime ?? a.start?.date;
                            final bTime = b.start?.dateTime ?? b.start?.date;
                            if (aTime == null || bTime == null) return 0;
                            return bTime.compareTo(aTime);
                          });

                          final event = _events[index];
                          final startTime =
                              event.start?.dateTime ?? event.start?.date;
                          return ListTile(
                            title: Text(event.summary ?? 'Untitled Event'),
                            subtitle: Text(
                              startTime != null
                                  ? _dateFormat.format(startTime)
                                  : 'No start time',
                            ),
                            onTap: () {
                              // You can add navigation or details here
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
