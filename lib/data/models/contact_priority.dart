import 'package:kith/l10n/gen/app_localizations.dart';

/// How much a contact's overdueness should count for.
///
/// Feeds the suggestion score as `overdueRatio * priorityWeight *
/// recencyDamping`, so the weights are part of the domain rather than a
/// presentation detail.
enum ContactPriority {
  /// Nice to see, but not something to be prompted about often.
  low('low', 0.5),

  /// The default: ranked purely on how overdue they are.
  normal('normal', 1),

  /// Someone you want pushed up the list.
  high('high', 1.5);

  const ContactPriority(this.wireName, this.weight);

  /// Stable identifier persisted to Firestore.
  ///
  /// Spelled out rather than using [name] so renaming an enum value cannot
  /// silently invalidate stored documents.
  final String wireName;

  /// Multiplier applied to the suggestion score.
  final double weight;

  /// How the level is written in the UI.
  String label(AppLocalizations l10n) => switch (this) {
    ContactPriority.low => l10n.priorityLow,
    ContactPriority.normal => l10n.priorityNormal,
    ContactPriority.high => l10n.priorityHigh,
  };

  /// Parses a persisted [wireName], falling back to [ContactPriority.normal]
  /// for anything unrecognised so a future level cannot break an old client.
  static ContactPriority fromWireName(String? wireName) {
    for (final priority in ContactPriority.values) {
      if (priority.wireName == wireName) return priority;
    }
    return ContactPriority.normal;
  }
}
