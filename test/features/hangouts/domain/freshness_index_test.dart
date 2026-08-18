import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18);
  final logged = DateTime.utc(2026, 8, 18, 9);

  Contact contact(String id, {Cadence cadence = Cadence.monthly}) => Contact(
    id: id,
    name: id,
    relationshipTypeId: 'rid-1',
    cadence: cadence,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Hangout hangout(String id, DateTime on, List<String> contactIds) => Hangout(
    id: id,
    occurredOn: on,
    contactIds: contactIds,
    attendeeIds: const ['uid-1'],
    createdBy: 'uid-1',
    createdAt: logged,
    updatedAt: logged,
  );

  FreshnessIndex indexOf(List<Hangout> hangouts) =>
      FreshnessIndex.from(hangouts: hangouts, now: now);

  group('lastSeenOn', () {
    test('is the latest day any hangout names the contact', () {
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8), ['cid-1']),
        hangout('hgid-2', DateTime.utc(2026, 8, 12), ['cid-1', 'cid-2']),
        hangout('hgid-3', DateTime.utc(2026, 7, 4), ['cid-1']),
      ]);

      expect(index.lastSeenOn('cid-1'), DateTime.utc(2026, 8, 12));
      expect(index.lastSeenOn('cid-2'), DateTime.utc(2026, 8, 12));
    });

    test('does not depend on the order the hangouts arrive in', () {
      final ascending = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 7), ['cid-1']),
        hangout('hgid-2', DateTime.utc(2026, 8, 12), ['cid-1']),
      ]);
      final descending = indexOf([
        hangout('hgid-2', DateTime.utc(2026, 8, 12), ['cid-1']),
        hangout('hgid-1', DateTime.utc(2026, 7), ['cid-1']),
      ]);

      expect(ascending.lastSeenOn('cid-1'), descending.lastSeenOn('cid-1'));
    });

    test('is null for a contact no hangout names', () {
      expect(indexOf(const []).lastSeenOn('cid-1'), isNull);
    });
  });

  group('of', () {
    test('measures a contact against their own cadence', () {
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8, 8), ['cid-1', 'cid-2']),
      ]);

      expect(
        index.of(contact('cid-1', cadence: Cadence.weekly)).state,
        FreshnessState.overdue,
      );
      expect(
        index.of(contact('cid-2', cadence: Cadence.quarterly)).state,
        FreshnessState.fresh,
      );
    });

    test('reads a contact with nothing logged as never', () {
      expect(
        indexOf(const []).of(contact('cid-1')).state,
        FreshnessState.never,
      );
    });
  });

  group('empty', () {
    test('reads every contact as never', () {
      expect(
        FreshnessIndex.empty.of(contact('cid-1')),
        const Freshness.never(),
      );
    });

    test('knows nobody', () {
      expect(FreshnessIndex.empty.lastSeenOn('cid-1'), isNull);
    });
  });

  group('compare', () {
    test('puts the more overdue contact first', () {
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-fresh']),
        hangout('hgid-2', DateTime.utc(2026, 5), ['cid-overdue']),
      ]);

      expect(
        index.compare(contact('cid-overdue'), contact('cid-fresh')),
        lessThan(0),
      );
      expect(
        index.compare(contact('cid-fresh'), contact('cid-overdue')),
        greaterThan(0),
      );
    });

    test('ranks on the ratio rather than on the raw days', () {
      // Seen 10 days ago on a weekly cadence is further past its mark than
      // seen 20 days ago on a quarterly one.
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8, 8), ['cid-weekly']),
        hangout('hgid-2', DateTime.utc(2026, 7, 29), ['cid-quarterly']),
      ]);

      expect(
        index.compare(
          contact('cid-weekly', cadence: Cadence.weekly),
          contact('cid-quarterly', cadence: Cadence.quarterly),
        ),
        lessThan(0),
      );
    });

    test('sinks contacts with nothing logged below every measured one', () {
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-fresh']),
      ]);

      expect(
        index.compare(contact('cid-never'), contact('cid-fresh')),
        greaterThan(0),
      );
      expect(
        index.compare(contact('cid-fresh'), contact('cid-never')),
        lessThan(0),
      );
    });

    test('leaves two unmeasured contacts for the caller to break', () {
      expect(
        indexOf(const []).compare(contact('cid-1'), contact('cid-2')),
        0,
      );
    });

    test('sorts a list most overdue first, unmeasured last', () {
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-fresh']),
        hangout('hgid-2', DateTime.utc(2026, 7, 20), ['cid-due']),
        hangout('hgid-3', DateTime.utc(2026, 4), ['cid-overdue']),
      ]);
      final contacts = [
        contact('cid-never'),
        contact('cid-fresh'),
        contact('cid-overdue'),
        contact('cid-due'),
      ]..sort(index.compare);

      expect(
        [for (final c in contacts) c.id],
        ['cid-overdue', 'cid-due', 'cid-fresh', 'cid-never'],
      );
    });
  });

  group('value semantics', () {
    test('two indexes over the same hangouts are equal', () {
      final hangouts = [
        hangout('hgid-1', DateTime.utc(2026, 8, 12), ['cid-1']),
      ];

      expect(indexOf(hangouts), indexOf(hangouts));
      expect(indexOf(hangouts).hashCode, indexOf(hangouts).hashCode);
    });

    test('an index at another instant is not equal', () {
      final hangouts = [
        hangout('hgid-1', DateTime.utc(2026, 8, 12), ['cid-1']),
      ];

      expect(
        indexOf(hangouts),
        isNot(FreshnessIndex.from(hangouts: hangouts, now: DateTime.utc(2027))),
      );
    });

    test('an index over different hangouts is not equal', () {
      expect(
        indexOf([
          hangout('hgid-1', DateTime.utc(2026, 8, 12), ['cid-1']),
        ]),
        isNot(
          indexOf([
            hangout('hgid-1', DateTime.utc(2026, 8), ['cid-1']),
          ]),
        ),
      );
    });

    test('toString says how many contacts it covers', () {
      final index = indexOf([
        hangout('hgid-1', DateTime.utc(2026, 8, 12), ['cid-1', 'cid-2']),
      ]);

      expect(index.toString(), contains('contacts: 2'));
    });
  });
}
