import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/features/calendar/application/calendar_link_state.dart';

void main() {
  const failure = NetworkFailure('offline');
  const family = CalendarListing(id: 'cal-1', name: 'Family');

  group('CalendarLinkState', () {
    test('starts unauthorised, with nothing listed and nothing to report', () {
      const state = CalendarLinkState();

      expect(state.isBusy, isFalse);
      expect(state.isAuthorised, isFalse);
      expect(state.calendars, isEmpty);
      expect(state.failure, isNull);
    });

    test('copyWith covers every field', () {
      const state = CalendarLinkState();

      expect(state.copyWith(), state);
      expect(state.copyWith(isBusy: true).isBusy, isTrue);
      expect(state.copyWith(isAuthorised: true).isAuthorised, isTrue);
      expect(state.copyWith(calendars: const [family]).calendars, [family]);
      expect(state.copyWith(failure: failure).failure, failure);
    });

    test('clearing the failure is distinct from omitting it', () {
      const state = CalendarLinkState(failure: failure);

      expect(state.copyWith().failure, failure);
      expect(state.copyWith(clearFailure: true).failure, isNull);
    });

    test('has value semantics, including over the list', () {
      const state = CalendarLinkState(
        isBusy: true,
        isAuthorised: true,
        calendars: [family],
        failure: failure,
      );

      expect(state.copyWith(), state);
      expect(state.copyWith().hashCode, state.hashCode);
      expect(
        state.copyWith(calendars: const [CalendarListing(id: 'x', name: 'X')]),
        isNot(state),
      );
      expect(state.copyWith(isAuthorised: false), isNot(state));
      expect(state.copyWith(clearFailure: true), isNot(state));
    });

    test('toString says how much it holds rather than listing it', () {
      const state = CalendarLinkState(
        isAuthorised: true,
        calendars: [family],
        failure: failure,
      );

      expect(state.toString(), contains('isAuthorised: true'));
      expect(state.toString(), contains('calendars: 1'));
      expect(state.toString(), contains('offline'));
    });
  });

  group('CalendarListing', () {
    test('has value semantics', () {
      const listing = CalendarListing(id: 'cal-1', name: 'Family');

      expect(listing, family);
      expect(listing.hashCode, family.hashCode);
      expect(listing, isNot(const CalendarListing(id: 'cal-2', name: 'F')));
      expect(
        listing,
        isNot(
          const CalendarListing(id: 'cal-1', name: 'Family', isPrimary: true),
        ),
      );
    });

    test('is not the account default unless it says so', () {
      expect(family.isPrimary, isFalse);
    });

    test('toString names every field', () {
      expect(family.toString(), contains('cal-1'));
      expect(family.toString(), contains('Family'));
      expect(family.toString(), contains('isPrimary: false'));
    });
  });
}
