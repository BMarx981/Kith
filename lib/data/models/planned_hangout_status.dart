/// Where a `PlannedHangout` sits in its short life.
///
/// Three states, because a household does three things with a suggestion: it
/// arranges the meetup, it puts the arrangement on the calendar, or it says
/// "not now". All three take a date, which is why they are one entity with a
/// status rather than three collections.
enum PlannedHangoutStatus {
  /// Someone tapped "Plan it": there is an intent to meet on a day, and
  /// nothing on a calendar yet.
  proposed('proposed'),

  /// The plan is on the household's calendar, and carries the event's id.
  confirmed('confirmed'),

  /// "Not now": no intent to meet, just don't suggest this contact again
  /// until the day comes round.
  snoozed('snoozed');

  const PlannedHangoutStatus(this.wireName);

  /// Stable identifier persisted to Firestore.
  ///
  /// Spelled out rather than using [name] so renaming an enum value cannot
  /// silently invalidate stored documents.
  final String wireName;

  /// Whether this status means the household means to see the contact.
  ///
  /// Both arranged states do; a snooze does not, which is the whole reason
  /// they are told apart. The suggestion engine damps the first two and hides
  /// the third.
  bool get isArranged =>
      this == PlannedHangoutStatus.proposed ||
      this == PlannedHangoutStatus.confirmed;

  /// Parses a persisted [wireName], falling back to
  /// [PlannedHangoutStatus.proposed] for anything unrecognised.
  ///
  /// Proposed rather than snoozed, because an unknown status written by a
  /// newer client should not silently hide a contact from the suggestions:
  /// the safe reading of "something is arranged, in a way I do not
  /// understand" is that something is arranged.
  static PlannedHangoutStatus fromWireName(String? wireName) {
    for (final status in PlannedHangoutStatus.values) {
      if (status.wireName == wireName) return status;
    }
    return PlannedHangoutStatus.proposed;
  }
}
