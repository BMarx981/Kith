import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';

/// Ranks who the household should see next.
///
/// Pure, with no I/O and no clock of its own: everything it needs arrives as an
/// argument, so the same inputs always give the same list and the whole
/// ranking is table-testable. That is the point of keeping it here rather than
/// in a provider.
///
/// The score is the one `docs/PLAN.md` specifies:
///
/// ```text
/// score = overdueRatio * priorityWeight * recencyDamping
/// ```
///
/// with `overdueRatio` the freshness ratio clamped at [maxOverdueRatio],
/// `priorityWeight` the contact's own weight, and `recencyDamping`
/// [plannedDamping] when something is already arranged and 1 otherwise.
abstract final class SuggestionEngine {
  /// Ratio past which more lateness stops counting.
  ///
  /// Three times the cadence is already "you have let this slide"; past that,
  /// the number keeps climbing but says nothing new, and an uncapped ratio
  /// would let one forgotten contact from years ago sit at the top of the list
  /// forever while priority stopped mattering at all.
  static const maxOverdueRatio = 3.0;

  /// What an arrangement already standing does to a score.
  ///
  /// A quarter rather than zero: somebody you have arranged to see is not a
  /// person to prompt about, but hiding them would mean the list quietly
  /// forgets the most overdue person in the household the moment a plan is
  /// made, and the plan is worth seeing on the card.
  static const plannedDamping = 0.25;

  /// How many suggestions the Reconnect section asks for.
  ///
  /// The top of `docs/PLAN.md`'s 3–5 band: five is as many cards as fit above
  /// the fold, and a list long enough to scroll is a contact list, not a
  /// prompt.
  static const defaultLimit = 5;

  /// The top [limit] contacts to reconnect with, most pressing first.
  ///
  /// [freshness] and [now] are expected to come from the same clock read;
  /// [now] is passed separately rather than taken from the index because the
  /// empty index carries no meaningful instant, and a plan's dates have to be
  /// judged against a real day even before the first hangout is logged.
  ///
  /// Who is left out, and why:
  ///
  /// * **Archived contacts.** Archiving is Kith's removal; a removed person is
  ///   not someone to be prompted about.
  /// * **Fresh contacts.** The section answers "who is overdue", so somebody
  ///   seen well inside their cadence has nothing to answer. This is what
  ///   keeps a household that is on top of everything from being told to
  ///   reconnect with the friend they saw yesterday.
  /// * **Snoozed contacts**, while the snooze runs. Saying "not now" and being
  ///   asked again the next morning would make the button pointless.
  ///
  /// A contact with no hangout behind them is *not* left out. They have no
  /// ratio, so they cannot be scored against anyone, and they sort below every
  /// measured contact rather than being ranked on an invented number — the
  /// same rule the freshness sort follows. But somebody deliberately added and
  /// never seen is exactly who this section exists for.
  static List<Suggestion> rank({
    required Iterable<Contact> contacts,
    required FreshnessIndex freshness,
    required Iterable<PlannedHangout> plans,
    required DateTime now,
    int limit = defaultLimit,
  }) {
    final standing = _standingPlans(plans, now);
    final suggestions = <Suggestion>[];

    for (final contact in contacts) {
      if (contact.isArchived) continue;
      final reading = freshness.of(contact);
      if (reading.state == FreshnessState.fresh) continue;
      final plan = standing[contact.id];
      if (plan != null && !plan.status.isArranged) continue;
      suggestions.add(
        Suggestion(
          contact: contact,
          freshness: reading,
          score: _scoreOf(contact, reading, damped: plan != null),
          plan: plan,
        ),
      );
    }

    suggestions.sort(_mostPressingFirst);
    return suggestions.length <= limit
        ? List.unmodifiable(suggestions)
        : List.unmodifiable(suggestions.take(limit));
  }

  /// What [contact] scores on [reading], or null when there is nothing to
  /// measure.
  static double? _scoreOf(
    Contact contact,
    Freshness reading, {
    required bool damped,
  }) {
    final ratio = reading.ratio;
    if (ratio == null) return null;
    return ratio.clamp(0.0, maxOverdueRatio) *
        contact.priority.weight *
        (damped ? plannedDamping : 1.0);
  }

  /// The plan standing against each contact as of [now], soonest first.
  ///
  /// One contact can be named by several plans — two partners each arranging
  /// something is a thing that happens — and the soonest is the one that
  /// speaks for them. A snooze that has not run out beats an arrangement, so
  /// that saying "not now" after making a plan still silences the suggestion.
  static Map<String, PlannedHangout> _standingPlans(
    Iterable<PlannedHangout> plans,
    DateTime now,
  ) {
    final standing = <String, PlannedHangout>{};
    for (final plan in plans) {
      if (!plan.isActiveOn(now)) continue;
      for (final contactId in plan.contactIds) {
        final known = standing[contactId];
        if (known == null || _outranks(plan, known)) {
          standing[contactId] = plan;
        }
      }
    }
    return standing;
  }

  /// Whether [plan] is the one to report for a contact [known] also names.
  static bool _outranks(PlannedHangout plan, PlannedHangout known) {
    if (plan.status.isArranged != known.status.isArranged) {
      return !plan.status.isArranged;
    }
    return plan.plannedFor.isBefore(known.plannedFor);
  }

  /// Orders two suggestions the way the section reads them out.
  ///
  /// Highest score first; measured contacts before unmeasured ones, which are
  /// then ordered by priority and by how long they have been on the list. The
  /// ties are broken all the way down to the id, so the section is a total
  /// order and never reshuffles between rebuilds.
  static int _mostPressingFirst(Suggestion a, Suggestion b) {
    final left = a.score;
    final right = b.score;
    if (left == null || right == null) {
      if (left != right) return left == null ? 1 : -1;
      final byPriority = b.contact.priority.weight.compareTo(
        a.contact.priority.weight,
      );
      if (byPriority != 0) return byPriority;
      // Longest on the list first: of two people you have never logged, the
      // one added months ago is the more overlooked.
      final byAdded = a.contact.createdAt.compareTo(b.contact.createdAt);
      if (byAdded != 0) return byAdded;
      return _byName(a, b);
    }

    final byScore = right.compareTo(left);
    if (byScore != 0) return byScore;
    // `docs/PLAN.md`'s tie-break: longest absolute time since last hangout.
    final byDays = (b.freshness.daysSince ?? 0).compareTo(
      a.freshness.daysSince ?? 0,
    );
    return byDays != 0 ? byDays : _byName(a, b);
  }

  static int _byName(Suggestion a, Suggestion b) {
    final byName = a.contact.name.toLowerCase().compareTo(
      b.contact.name.toLowerCase(),
    );
    return byName != 0 ? byName : a.contact.id.compareTo(b.contact.id);
  }
}
