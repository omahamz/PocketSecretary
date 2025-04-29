import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calendar_page_model.dart';
import 'package:provider/provider.dart';
import '/util/calendar.dart';
import '/util/googleauth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '/util/message_provider.dart';

class CalendarPageWidget extends StatefulWidget {
  const CalendarPageWidget({super.key});

  static String routeName = 'CalendarPage';
  static String routePath = '/calendarPage';

  @override
  State<CalendarPageWidget> createState() => _CalendarPageWidgetState();
}

class _CalendarPageWidgetState extends State<CalendarPageWidget> {
  late CalendarPageModel _model;
  List<calendar.Event> _events = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('MMM d, yyyy h:mm a');
  late CalendarService _calendarService;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CalendarPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  void _initializeServices() {
    final googleAuthService =
        Provider.of<GoogleAuthService>(context, listen: false);
    _calendarService = CalendarService(googleAuthService);
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _calendarService.fetchEvents();
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<calendar.Event> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = event.start?.dateTime ?? event.start?.date;
      if (eventDate == null) return false;
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 40.0,
            fillColor: FlutterFlowTheme.of(context).primary,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).info,
              size: 24.0,
            ),
            onPressed: () async {
              context.pushNamed(CalendarEventsPageWidget.routeName);
            },
          ),
          title: Text(
            'Calendar',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchEvents,
            ),
          ],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FlutterFlowCalendar(
                      color: FlutterFlowTheme.of(context).primary,
                      iconColor: FlutterFlowTheme.of(context).secondaryText,
                      weekFormat: false,
                      weekStartsMonday: false,
                      rowHeight: 48.0,
                      onChange: (DateTimeRange? newSelectedDate) {
                        safeSetState(
                            () => _model.calendarSelectedDay = newSelectedDate);
                      },
                      titleStyle:
                          FlutterFlowTheme.of(context).titleLarge.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .fontStyle,
                              ),
                      dayOfWeekStyle:
                          FlutterFlowTheme.of(context).bodyLarge.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyLarge
                                    .fontStyle,
                              ),
                      dateStyle:
                          FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                      selectedDateStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                      inactiveDateStyle:
                          FlutterFlowTheme.of(context).labelMedium.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                    ),
                    if (_model.calendarSelectedDay != null) ...[
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Events for ${DateFormat('MMMM d, yyyy').format(_model.calendarSelectedDay!.start)}',
                          style: FlutterFlowTheme.of(context).titleMedium,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _getEventsForDate(
                                  _model.calendarSelectedDay!.start)
                              .length,
                          itemBuilder: (context, index) {
                            final event = _getEventsForDate(
                                _model.calendarSelectedDay!.start)[index];
                            final startTime =
                                event.start?.dateTime ?? event.start?.date;
                            final endTime =
                                event.end?.dateTime ?? event.end?.date;

                            return Card(
                              margin: EdgeInsets.only(bottom: 8.0),
                              child: ListTile(
                                title: Text(event.summary ?? "Untitled Event"),
                                subtitle: Text(
                                  startTime != null
                                      ? _dateFormat.format(startTime)
                                      : "No start time",
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.open_in_new),
                                  onPressed: () async {
                                    if (event.htmlLink != null) {
                                      final url = Uri.parse(event.htmlLink!);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
