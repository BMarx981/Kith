import 'package:flutter/foundation.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// One person the Reconnect section is putting forward, and why.
///
/// Carries the reading it was ranked on rather than only the number, so the
/// card can draw the same gauge the contact list draws without recomputing
/// anything, and so a suggestion can be checked in a test by reading it rather
/// than by re-deriving it.
@immutable
class Suggestion {
  const Suggestion({
    required this.contact,
    required this.freshness,
    required this.score,
    this.plan,
  });

  /// Who is being suggested.
  final Contact contact;

  /// Where they sit against their own cadence, as of the ranking's "now".
  final Freshness freshness;

  /// `overdueRatio * priorityWeight * recencyDamping`, or null for a contact
  /// with no hangout behind them.
  ///
  /// Null rather than zero, and rather than a ratio invented from when they
  /// were added, for the same reason `Freshness.ratio` is null: there is no
  /// measurement to report. Unmeasured suggestions rank below every measured
  /// one instead of being scored against them.
  final double? score;

  /// The arrangement already standing for this contact, if one is.
  ///
  /// Present only for a plan the household means to keep — a snooze removes a
  /// contact from the list rather than annotating them. Its presence is what
  /// damped [score], and the card says so, because a suggestion that looks
  /// unaddressed is how you end up arranging the same coffee twice.
  final PlannedHangout? plan;

  /// Whether an arrangement is already standing, damping [score].
  bool get isPlanned => plan != null;

  /// Whether a hangout has ever been logged for this contact.
  bool get isMeasured => freshness.isMeasured;

  /// Why this person is on the list, in one line.
  ///
  /// Written to stand on its own, name included, so the same sentence works on
  /// a card that already shows the name and in a notification digest that does
  /// not.
  String reason(AppLocalizations l10n) => switch (freshness.elapsedLabel(
    l10n,
  )) {
    null => l10n.reasonNothingLogged(contact.name),
    final elapsed => l10n.reasonOverdue(
      elapsed,
      contact.name,
      contact.cadence.phrase(l10n),
    ),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          other.contact == contact &&
          other.freshness == freshness &&
          other.score == score &&
          other.plan == plan;

  @override
  int get hashCode => Object.hash(contact, freshness, score, plan);

  @override
  String toString() =>
      'Suggestion(contact: ${contact.name}, state: ${freshness.state.name}, '
      'score: $score, plan: ${plan?.id})';
}
