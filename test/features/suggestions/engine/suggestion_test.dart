import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  final now = DateTime.utc(2026, 8, 18);

  Contact person({
    String name = 'Marcus Bell',
    Cadence cadence = Cadence.monthly,
  }) => Contact(
    id: 'cid-1',
    name: name,
    relationshipTypeId: 'rid-1',
    cadence: cadence,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Freshness after(int days, {Cadence cadence = Cadence.monthly}) =>
      Freshness.of(
        cadence: cadence,
        lastSeenOn: now.subtract(Duration(days: days)),
        now: now,
      );

  Suggestion sample() => Suggestion(
    contact: person(),
    freshness: after(60),
    score: 2,
  );

  group('the reason', () {
    test('is the sentence the plan writes', () {
      final suggestion = Suggestion(
        contact: person(),
        freshness: after(42),
        score: 1.4,
      );

      expect(
        suggestion.reason(l10n),
        "It's been 6 weeks — you usually see Marcus Bell monthly.",
      );
    });

    test('reads the cadence mid-sentence, preset or custom', () {
      expect(
        Suggestion(
          contact: person(cadence: Cadence.biweekly),
          freshness: after(21, cadence: Cadence.biweekly),
          score: 1.5,
        ).reason(l10n),
        "It's been 3 weeks — you usually see Marcus Bell every 2 weeks.",
      );
      expect(
        Suggestion(
          contact: person(cadence: const Cadence.custom(45)),
          freshness: after(50, cadence: const Cadence.custom(45)),
          score: 1.1,
        ).reason(l10n),
        "It's been 7 weeks — you usually see Marcus Bell every 45 days.",
      );
    });

    test('says nothing has been logged when nothing has', () {
      final suggestion = Suggestion(
        contact: person(),
        freshness: const Freshness.never(),
        score: null,
      );

      expect(suggestion.reason(l10n), 'Nothing logged with Marcus Bell yet.');
    });

    test('carries the name, so it stands on its own away from the card', () {
      expect(sample().reason(l10n), contains('Marcus Bell'));
    });
  });

  group('what it reports about itself', () {
    test('is planned only when an arrangement came with it', () {
      expect(sample().isPlanned, isFalse);
      expect(
        sample()
            .copyWithPlanForTest(
              PlannedHangout(
                id: 'pid-1',
                plannedFor: now.add(const Duration(days: 3)),
                contactIds: const ['cid-1'],
                status: PlannedHangoutStatus.proposed,
                createdBy: 'uid-1',
                createdAt: now,
                updatedAt: now,
              ),
            )
            .isPlanned,
        isTrue,
      );
    });

    test('is measured only when a hangout is behind it', () {
      expect(sample().isMeasured, isTrue);
      expect(
        Suggestion(
          contact: person(),
          freshness: const Freshness.never(),
          score: null,
        ).isMeasured,
        isFalse,
      );
    });
  });

  test('is equal by value and differs on every field', () {
    final plan = PlannedHangout(
      id: 'pid-1',
      plannedFor: now,
      contactIds: const ['cid-1'],
      status: PlannedHangoutStatus.proposed,
      createdBy: 'uid-1',
      createdAt: now,
      updatedAt: now,
    );

    expect(sample(), sample());
    expect(sample().hashCode, sample().hashCode);
    expect(
      sample(),
      isNot(
        Suggestion(
          contact: person(name: 'Someone else'),
          freshness: after(60),
          score: 2,
        ),
      ),
    );
    expect(
      sample(),
      isNot(Suggestion(contact: person(), freshness: after(40), score: 2)),
    );
    expect(
      sample(),
      isNot(Suggestion(contact: person(), freshness: after(60), score: 1)),
    );
    expect(sample(), isNot(sample().copyWithPlanForTest(plan)));
  });

  test('names the contact, the reading and the score in toString', () {
    final text = sample().toString();

    expect(text, contains('Marcus Bell'));
    expect(text, contains('overdue'));
    expect(text, contains('2'));
  });
}

/// Rebuilds a suggestion with a plan attached.
///
/// [Suggestion] has no `copyWith` — the engine is the only thing that builds
/// one, and it builds them whole — so the tests that need the planned variant
/// spell it out here rather than widening the model for their benefit.
extension on Suggestion {
  Suggestion copyWithPlanForTest(PlannedHangout plan) => Suggestion(
    contact: contact,
    freshness: freshness,
    score: score,
    plan: plan,
  );
}
