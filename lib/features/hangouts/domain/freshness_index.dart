import 'package:flutter/foundation.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';

/// Every contact's freshness, as of one instant.
///
/// Built once from the household's hangouts and then read many times — by the
/// list rows, by the sort, and by the gauge — so the timeline is walked once
/// per rebuild rather than once per contact. "Now" is baked in at
/// construction, which is what lets [compare] order contacts without every
/// caller carrying a clock.
@immutable
class FreshnessIndex {
  const FreshnessIndex._(this._lastSeen, this.now);

  /// The index [hangouts] describes as of [now].
  ///
  /// A contact's last-seen day is the latest day any hangout naming them
  /// happened on, whatever order the hangouts arrive in.
  factory FreshnessIndex.from({
    required Iterable<Hangout> hangouts,
    required DateTime now,
  }) {
    final lastSeen = <String, DateTime>{};
    for (final hangout in hangouts) {
      for (final contactId in hangout.contactIds) {
        final known = lastSeen[contactId];
        if (known == null || hangout.occurredOn.isAfter(known)) {
          lastSeen[contactId] = hangout.occurredOn;
        }
      }
    }
    return FreshnessIndex._(Map.unmodifiable(lastSeen), now);
  }

  /// The index of a household with nothing logged yet.
  ///
  /// Every contact reads as [FreshnessState.never], so the instant it is
  /// pinned to is never consulted; it is there to satisfy the type.
  static final empty = FreshnessIndex._(
    const <String, DateTime>{},
    DateTime.utc(1970),
  );

  final Map<String, DateTime> _lastSeen;

  /// The instant every reading in this index is measured against.
  final DateTime now;

  /// The day [contactId] was last seen, as midnight UTC, or null if never.
  DateTime? lastSeenOn(String contactId) => _lastSeen[contactId];

  /// Where [contact] sits against their own cadence.
  Freshness of(Contact contact) => Freshness.of(
    cadence: contact.cadence,
    lastSeenOn: _lastSeen[contact.id],
    now: now,
  );

  /// Orders two contacts most-overdue-first.
  ///
  /// Contacts with no hangout behind them sort last rather than first: there
  /// is no ratio to rank them by, and inventing one from when they were added
  /// would make someone entered yesterday look years overdue. They are not
  /// hidden — they sit at the bottom with a neutral gauge, which is the same
  /// thing the gauge says everywhere else.
  int compare(Contact a, Contact b) {
    final left = of(a).ratio;
    final right = of(b).ratio;
    if (left == null || right == null) {
      if (left == right) return 0;
      return left == null ? 1 : -1;
    }
    return right.compareTo(left);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreshnessIndex &&
          other.now == now &&
          mapEquals(other._lastSeen, _lastSeen);

  @override
  int get hashCode => Object.hash(now, Object.hashAllUnordered(_lastSeen.keys));

  @override
  String toString() =>
      'FreshnessIndex(now: $now, contacts: ${_lastSeen.length})';
}
