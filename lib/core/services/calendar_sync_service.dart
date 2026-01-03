import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/injection_record.dart';

/// Client HTTP autenticato con Google
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Google Calendar sync service
class CalendarSyncService {
  CalendarSyncService._();

  static final instance = CalendarSyncService._();

  static const _scopes = [gcal.CalendarApi.calendarScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);
  gcal.CalendarApi? _calendarApi;
  GoogleSignInAccount? _currentUser;

  /// Initialize the calendar API with Google Sign-In credentials
  Future<bool> initialize() async {
    try {
      // Try silent sign-in first, then full authentication if needed
      _currentUser = await _googleSignIn.signInSilently();
      _currentUser ??= await _googleSignIn.signIn();

      if (_currentUser == null) return false;

      // Get authorization headers for calendar scope
      final headers = await _currentUser!.authHeaders;

      if (headers['Authorization'] == null) {
        return false;
      }

      final client = _GoogleAuthClient(headers);
      _calendarApi = gcal.CalendarApi(client);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if calendar API is available
  bool get isAvailable => _calendarApi != null;

  /// Create a calendar event for an injection
  Future<String?> createInjectionEvent(InjectionRecord injection) async {
    if (_calendarApi == null) return null;

    try {
      final event = gcal.Event()
        ..summary = 'Iniezione - ${injection.pointLabel}'
        ..description = 'InjeCare Plan\n'
            'Punto: ${injection.pointCode}\n'
            '${injection.notes}'
        ..start = (gcal.EventDateTime()
          ..dateTime = injection.scheduledAt
          ..timeZone = 'Europe/Rome')
        ..end = (gcal.EventDateTime()
          ..dateTime = injection.scheduledAt.add(const Duration(minutes: 30))
          ..timeZone = 'Europe/Rome')
        ..reminders = (gcal.EventReminders()
          ..useDefault = false
          ..overrides = [
            gcal.EventReminder()
              ..method = 'popup'
              ..minutes = 30,
          ]);

      final createdEvent = await _calendarApi!.events.insert(
        event,
        'primary',
      );

      return createdEvent.id;
    } catch (e) {
      return null;
    }
  }

  /// Update a calendar event
  Future<bool> updateInjectionEvent(
    String eventId,
    InjectionRecord injection,
  ) async {
    if (_calendarApi == null) return false;

    try {
      final event = await _calendarApi!.events.get('primary', eventId);

      event.summary = 'Iniezione - ${injection.pointLabel}';
      event.description = 'InjeCare Plan\n'
          'Punto: ${injection.pointCode}\n'
          'Stato: ${_statusLabel(injection.status)}\n'
          '${injection.notes}';

      if (injection.status == InjectionStatus.completed) {
        event.colorId = '10'; // Green
      } else if (injection.status == InjectionStatus.skipped) {
        event.colorId = '11'; // Red
      }

      await _calendarApi!.events.update(event, 'primary', eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteInjectionEvent(String eventId) async {
    if (_calendarApi == null) return false;

    try {
      await _calendarApi!.events.delete('primary', eventId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get injection events from calendar
  Future<List<gcal.Event>> getInjectionEvents({
    DateTime? from,
    DateTime? to,
  }) async {
    if (_calendarApi == null) return [];

    try {
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: from?.toUtc(),
        timeMax: to?.toUtc(),
        q: 'InjeCare',
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      return [];
    }
  }

  String _statusLabel(InjectionStatus status) => switch (status) {
    InjectionStatus.completed => 'Completata',
    InjectionStatus.scheduled => 'Programmata',
    InjectionStatus.delayed => 'In ritardo',
    InjectionStatus.skipped => 'Saltata',
  };
}
