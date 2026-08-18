import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';
import 'package:kith/features/suggestions/engine/suggestion_engine.dart';

void main() {
  // Pinned: every expectation below is hand-computed against this instant, as
  // `docs/PLAN.md`'s M4 gate asks.
  final now = DateTime.utc(2026, 8, 18, 10, 15);

  Contact person(
    String id, {
    String? name,
    Cadence cadence = Cadence.monthly,
    ContactPriority priority = ContactPriority.normal,
    DateTime? createdAt,
    bool isArchived = false,
  }) => Contact(
    id: id,
    name: name ?? id.toUpperCase(),
    relationshipTypeId: 'rid-1',
    cadence: cadence,
    priority: priority,
    createdAt: createdAt ?? DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    isArchived: isArchived,
  );

  /// A freshness index in which each contact was last seen that many days ago.
  FreshnessIndex seen(Map<String, int> daysAgo) => FreshnessIndex.from(
    hangouts: [
      for (final (index, entry) in daysAgo.entries.indexed)
        Hangout(
          id: 'hgid-$index',
          occurredOn: now.subtract(Duration(days: entry.value)),
          contactIds: [entry.key],
          attendeeIds: const [],
          createdBy: 'uid-1',
          createdAt: now,
          updatedAt: now,
        ),
    ],
    now: now,
  );

  PlannedHangout plan(
    String id, {
    required List<String> contactIds,
    required int inDays,
    PlannedHangoutStatus status = PlannedHangoutStatus.proposed,
  }) => PlannedHangout(
    id: id,
    plannedFor: now.add(Duration(days: inDays)),
    contactIds: contactIds,
    status: status,
    createdBy: 'uid-1',
    createdAt: now,
    updatedAt: now,
  );

  group('who is put forward', () {
    test('leaves out contacts seen well inside their cadence', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 10}),
        plans: const [],
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('puts forward contacts who are due and contacts who are overdue', () {
      final suggestions = SuggestionEngine.rank(
        // 23 of 30 days is 0.77, the first day of due; 60 is twice over.
        contacts: [person('cid-1'), person('cid-2')],
        freshness: seen({'cid-1': 23, 'cid-2': 60}),
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => s.freshness.state),
        containsAll(<FreshnessState>[
          FreshnessState.due,
          FreshnessState.overdue,
        ]),
      );
    });

    test('puts forward a contact with nothing logged, unscored', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: FreshnessIndex.empty,
        plans: const [],
        now: now,
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.score, isNull);
      expect(suggestions.single.isMeasured, isFalse);
    });

    test('leaves out archived contacts however overdue they are', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1', isArchived: true)],
        freshness: seen({'cid-1': 400}),
        plans: const [],
        now: now,
      );

      expect(suggestions, isEmpty);
    });
  });

  group('the score', () {
    test('is ratio times priority weight, hand-computed', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          // 60 of 30 days is a ratio of 2, at 1.5 for high: 3.
          person('cid-1', priority: ContactPriority.high),
          // 7 of 7 days is a ratio of 1, at 1.0 for normal: 1.
          person('cid-2', cadence: Cadence.weekly),
          // 30 of 30 days is a ratio of 1, at 0.5 for low: 0.5.
          person('cid-3', priority: ContactPriority.low),
        ],
        freshness: seen({'cid-1': 60, 'cid-2': 7, 'cid-3': 30}),
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => (s.contact.id, s.score)),
        orderedEquals(<(String, double)>[
          ('cid-1', 3),
          ('cid-2', 1),
          ('cid-3', 0.5),
        ]),
      );
    });

    test('stops counting lateness past three times the cadence', () {
      final suggestions = SuggestionEngine.rank(
        // 40 and 400 of 7 days are ratios of 5.7 and 57; both clamp to 3.
        contacts: [
          person('cid-1', cadence: Cadence.weekly),
          person('cid-2', cadence: Cadence.weekly),
        ],
        freshness: seen({'cid-1': 40, 'cid-2': 400}),
        plans: const [],
        now: now,
      );

      expect(suggestions.map((s) => s.score), everyElement(3.0));
    });

    test('lets priority outrank lateness once both are clamped', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          // Clamped to 3, at 0.5 for low: 1.5.
          person(
            'cid-late',
            cadence: Cadence.weekly,
            priority: ContactPriority.low,
          ),
          // A ratio of 2, at 1.5: 3. The clamp is what lets this win.
          person('cid-cared', priority: ContactPriority.high),
        ],
        freshness: seen({'cid-late': 400, 'cid-cared': 60}),
        plans: const [],
        now: now,
      );

      expect(suggestions.first.contact.id, 'cid-cared');
    });

    test('is damped to a quarter by an arrangement already standing', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1', priority: ContactPriority.high)],
        freshness: seen({'cid-1': 60}),
        plans: [plan('pid-1', contactIds: const ['cid-1'], inDays: 3)],
        now: now,
      );

      expect(suggestions.single.score, 3 * SuggestionEngine.plannedDamping);
      expect(suggestions.single.isPlanned, isTrue);
      expect(suggestions.single.plan?.id, 'pid-1');
    });
  });

  group('plans already standing', () {
    test('a snooze that has not run out removes the contact', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [
          plan(
            'pid-1',
            contactIds: const ['cid-1'],
            inDays: 5,
            status: PlannedHangoutStatus.snoozed,
          ),
        ],
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('a snooze that has run out no longer hides anyone', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [
          plan(
            'pid-1',
            contactIds: const ['cid-1'],
            inDays: -1,
            status: PlannedHangoutStatus.snoozed,
          ),
        ],
        now: now,
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.plan, isNull);
    });

    test('a snooze taken on the last day still holds', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [
          plan(
            'pid-1',
            contactIds: const ['cid-1'],
            inDays: 0,
            status: PlannedHangoutStatus.snoozed,
          ),
        ],
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('an arrangement whose day has gone by stops damping', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [plan('pid-1', contactIds: const ['cid-1'], inDays: -2)],
        now: now,
      );

      expect(suggestions.single.score, 2);
      expect(suggestions.single.plan, isNull);
    });

    test('a confirmed arrangement damps like a proposed one', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [
          plan(
            'pid-1',
            contactIds: const ['cid-1'],
            inDays: 3,
            status: PlannedHangoutStatus.confirmed,
          ),
        ],
        now: now,
      );

      expect(suggestions.single.score, 2 * SuggestionEngine.plannedDamping);
    });

    test('the soonest of two arrangements is the one reported', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [
          plan('pid-far', contactIds: const ['cid-1'], inDays: 20),
          plan('pid-near', contactIds: const ['cid-1'], inDays: 2),
        ],
        now: now,
      );

      expect(suggestions.single.plan?.id, 'pid-near');
    });

    test('a snooze wins over an arrangement, so "not now" is honoured', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: [
          plan('pid-arranged', contactIds: const ['cid-1'], inDays: 2),
          plan(
            'pid-snooze',
            contactIds: const ['cid-1'],
            inDays: 20,
            status: PlannedHangoutStatus.snoozed,
          ),
        ],
        now: now,
      );

      expect(suggestions, isEmpty);
    });

    test('a plan naming several contacts speaks for all of them', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [person('cid-1'), person('cid-2')],
        freshness: seen({'cid-1': 60, 'cid-2': 60}),
        plans: [
          plan('pid-1', contactIds: const ['cid-1', 'cid-2'], inDays: 4),
        ],
        now: now,
      );

      expect(suggestions.map((s) => s.plan?.id), everyElement('pid-1'));
    });
  });

  group('the order', () {
    test('is most pressing first', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          person('cid-mild', priority: ContactPriority.low),
          person('cid-worst', priority: ContactPriority.high),
          person('cid-middling'),
        ],
        freshness: seen({'cid-mild': 40, 'cid-worst': 80, 'cid-middling': 45}),
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-worst', 'cid-middling', 'cid-mild']),
      );
    });

    test('breaks a tied score by the longest absolute absence', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          // Both score 2: 60 of 30 days, and 14 of 7 days.
          person('cid-recent', cadence: Cadence.weekly),
          person('cid-ancient'),
        ],
        freshness: seen({'cid-recent': 14, 'cid-ancient': 60}),
        plans: const [],
        now: now,
      );

      expect(suggestions.map((s) => s.score), everyElement(2.0));
      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-ancient', 'cid-recent']),
      );
    });

    test('breaks a full tie by name, then by id', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          person('cid-3', name: 'Bo'),
          person('cid-2', name: 'ana'),
          person('cid-1', name: 'ana'),
        ],
        freshness: seen({'cid-1': 60, 'cid-2': 60, 'cid-3': 60}),
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-1', 'cid-2', 'cid-3']),
      );
    });

    test('puts every unmeasured contact below every measured one', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          person('cid-never', priority: ContactPriority.high),
          // Barely due, and still ahead of somebody with no reading at all.
          person('cid-due'),
        ],
        freshness: seen({'cid-due': 23}),
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-due', 'cid-never']),
      );
    });

    test('breaks a full tie between unmeasured contacts by name', () {
      final added = DateTime.utc(2026, 3);
      final suggestions = SuggestionEngine.rank(
        contacts: [
          person('cid-2', name: 'Bo', createdAt: added),
          person('cid-1', name: 'Ana', createdAt: added),
        ],
        freshness: FreshnessIndex.empty,
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-1', 'cid-2']),
      );
    });

    test('orders unmeasured contacts by priority, then by how long they '
        'have been on the list', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          person('cid-new', createdAt: DateTime.utc(2026, 8)),
          person('cid-old', createdAt: DateTime.utc(2025)),
          person(
            'cid-cared',
            priority: ContactPriority.high,
            createdAt: DateTime.utc(2026, 8, 17),
          ),
        ],
        freshness: FreshnessIndex.empty,
        plans: const [],
        now: now,
      );

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-cared', 'cid-old', 'cid-new']),
      );
    });
  });

  group('the list itself', () {
    test('stops at the limit, keeping the most pressing', () {
      final suggestions = SuggestionEngine.rank(
        contacts: [
          for (var index = 0; index < 8; index++) person('cid-$index'),
        ],
        freshness: seen({
          for (var index = 0; index < 8; index++) 'cid-$index': 30 + index,
        }),
        plans: const [],
        now: now,
        limit: 3,
      );

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-7', 'cid-6', 'cid-5']),
      );
    });

    test('asks for five by default, as the plan says', () {
      expect(SuggestionEngine.defaultLimit, 5);

      final suggestions = SuggestionEngine.rank(
        contacts: [
          for (var index = 0; index < 9; index++) person('cid-$index'),
        ],
        freshness: seen({
          for (var index = 0; index < 9; index++) 'cid-$index': 30 + index,
        }),
        plans: const [],
        now: now,
      );

      expect(suggestions, hasLength(5));
    });

    test('comes back unmodifiable, short list or long', () {
      final short = SuggestionEngine.rank(
        contacts: [person('cid-1')],
        freshness: seen({'cid-1': 60}),
        plans: const [],
        now: now,
      );
      final long = SuggestionEngine.rank(
        contacts: [
          for (var index = 0; index < 9; index++) person('cid-$index'),
        ],
        freshness: seen({
          for (var index = 0; index < 9; index++) 'cid-$index': 60,
        }),
        plans: const [],
        now: now,
      );

      expect(short.clear, throwsUnsupportedError);
      expect(long.clear, throwsUnsupportedError);
    });

    test('is deterministic: the same inputs give the same list', () {
      List<String> run() => SuggestionEngine.rank(
        contacts: [
          person('cid-1', priority: ContactPriority.high),
          person('cid-2'),
          person('cid-3', priority: ContactPriority.low),
          person('cid-4'),
        ],
        freshness: seen({'cid-1': 60, 'cid-2': 60, 'cid-3': 60}),
        plans: [plan('pid-1', contactIds: const ['cid-2'], inDays: 5)],
        now: now,
      ).map((s) => '${s.contact.id}:${s.score}').toList();

      expect(run(), orderedEquals(run()));
    });

    test('has nothing to say about a household with no contacts', () {
      expect(
        SuggestionEngine.rank(
          contacts: const [],
          freshness: FreshnessIndex.empty,
          plans: const [],
          now: now,
        ),
        isEmpty,
      );
    });
  });
}
