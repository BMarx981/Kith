import 'package:kith/core/result/failure.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// The copy for [failure], to show under the field that refused its input.
///
/// One mapper for every field validator in the app, so each `ValidationIssue`
/// has exactly one sentence per locale and the switch is exhaustive: a new
/// issue fails to compile until it has copy. Answers null for no failure, and
/// falls back to the log message for a repository-side failure carrying no
/// issue — those are rare and already sentences.
String? validationMessage(AppLocalizations l10n, ValidationFailure? failure) {
  if (failure == null) return null;
  final args = failure.args;
  return switch (failure.issue) {
    null => failure.message,
    ValidationIssue.emailEmpty => l10n.errorEmailEmpty,
    ValidationIssue.emailMalformed => l10n.errorEmailMalformed,
    ValidationIssue.passwordEmpty => l10n.errorPasswordEmpty,
    ValidationIssue.passwordTooShort => l10n.errorPasswordTooShort(
      args['min']! as int,
    ),
    ValidationIssue.contactNameEmpty => l10n.errorContactNameEmpty,
    ValidationIssue.labelNameEmpty => l10n.errorLabelNameEmpty,
    ValidationIssue.householdNameEmpty => l10n.errorHouseholdNameEmpty,
    ValidationIssue.displayNameEmpty => l10n.errorDisplayNameEmpty,
    ValidationIssue.textTooLong => l10n.errorTextTooLong(args['max']! as int),
    ValidationIssue.tooManyTags => l10n.errorTooManyTags(args['max']! as int),
    ValidationIssue.tagTooLong => l10n.errorTagTooLong(args['max']! as int),
    ValidationIssue.cadenceEmpty => l10n.errorCadenceEmpty,
    ValidationIssue.cadenceNotANumber => l10n.errorCadenceNotANumber,
    ValidationIssue.cadenceTooShort => l10n.errorCadenceTooShort(
      args['min']! as int,
    ),
    ValidationIssue.cadenceTooLong => l10n.errorCadenceTooLong(
      args['max']! as int,
    ),
    ValidationIssue.birthdayEmpty => l10n.errorBirthdayEmpty,
    ValidationIssue.birthdayUnreadable => l10n.errorBirthdayUnreadable,
    ValidationIssue.birthdayBadMonth => l10n.errorBirthdayBadMonth,
    ValidationIssue.birthdayYearOutOfRange => l10n.errorBirthdayYearOutOfRange(
      args['min']! as int,
      args['max']! as int,
    ),
    ValidationIssue.birthdayNoSuchDay => l10n.errorBirthdayNoSuchDay(
      DayLabel.month(args['month']! as int, l10n),
      args['day']! as int,
    ),
    ValidationIssue.inviteCodeEmpty => l10n.errorInviteCodeEmpty,
    ValidationIssue.inviteCodeWrongLength => l10n.errorInviteCodeWrongLength(
      args['length']! as int,
    ),
    ValidationIssue.inviteCodeBadCharacter => l10n.errorInviteCodeBadCharacter(
      args['char']! as String,
    ),
  };
}

/// The month names of [l10n]'s language, lowercased, for `Birthday.parse`.
///
/// Short and full spellings both, mapped to month numbers, so "14 mars" and
/// "14 févr." read the same as "14 Mar" does in English.
Map<String, int> birthdayMonthNames(AppLocalizations l10n) => {
  for (var month = 1; month <= 12; month++)
    DayLabel.month(month, l10n).toLowerCase(): month,
  for (var month = 1; month <= 12; month++)
    _fullMonth(l10n, month).toLowerCase(): month,
};

String _fullMonth(AppLocalizations l10n, int month) => switch (month) {
  1 => l10n.monthFullJan,
  2 => l10n.monthFullFeb,
  3 => l10n.monthFullMar,
  4 => l10n.monthFullApr,
  5 => l10n.monthFullMay,
  6 => l10n.monthFullJun,
  7 => l10n.monthFullJul,
  8 => l10n.monthFullAug,
  9 => l10n.monthFullSep,
  10 => l10n.monthFullOct,
  11 => l10n.monthFullNov,
  _ => l10n.monthFullDec,
};
