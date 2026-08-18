import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/services/calendar_sink.dart';

void main() {
  CalendarEvent eventOn(DateTime day) =>
      CalendarEvent(id: 'evt_1', title: 'Marcus', day: day);

  group('CalendarEvent', () {
    test('reduces whatever instant it is handed to a calendar day', () {
      expect(
        eventOn(DateTime(2026, 8, 18, 23, 30)).day,
        DateTime.utc(2026, 8, 18),
      );
    });

    test('leaves a day it is handed alone', () {
      final day = DateTime.utc(2026, 8, 18);

      expect(eventOn(day).day, day);
    });

    test('equals another event describing the same entry', () {
      final event = CalendarEvent(
        id: 'evt_1',
        title: 'Marcus',
        day: DateTime.utc(2026, 8, 18),
        note: 'coffee',
      );
      final same = CalendarEvent(
        id: 'evt_1',
        title: 'Marcus',
        // The same day, spelled as the instant it was read from.
        day: DateTime(2026, 8, 18, 9),
        note: 'coffee',
      );

      expect(event, same);
      expect(event.hashCode, same.hashCode);
    });

    test('differs on every field that identifies the entry', () {
      final event = CalendarEvent(
        id: 'evt_1',
        title: 'Marcus',
        day: DateTime.utc(2026, 8, 18),
        note: 'coffee',
      );

      expect(event, isNot(equals(eventOn(DateTime.utc(2026, 8, 18)))));
      expect(
        event,
        isNot(
          equals(
            CalendarEvent(
              id: 'evt_2',
              title: 'Marcus',
              day: DateTime.utc(2026, 8, 18),
              note: 'coffee',
            ),
          ),
        ),
      );
      expect(
        event,
        isNot(
          equals(
            CalendarEvent(
              id: 'evt_1',
              title: 'Ana',
              day: DateTime.utc(2026, 8, 18),
              note: 'coffee',
            ),
          ),
        ),
      );
      expect(
        event,
        isNot(
          equals(
            CalendarEvent(
              id: 'evt_1',
              title: 'Marcus',
              day: DateTime.utc(2026, 8, 19),
              note: 'coffee',
            ),
          ),
        ),
      );
    });

    test('names itself and its day in toString', () {
      expect(
        eventOn(DateTime.utc(2026, 8, 18)).toString(),
        'CalendarEvent(id: evt_1, title: Marcus, '
        'day: 2026-08-18 00:00:00.000Z, note: null)',
      );
    });
  });
}
