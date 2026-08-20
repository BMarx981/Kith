// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kith';

  @override
  String arrivesInMilestone(String milestone) {
    return 'Arrives in $milestone';
  }

  @override
  String get signInTagline => 'Sign in to your household.';

  @override
  String get signUpTagline =>
      'Create an account, then start or join a household.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get toggleHaveAccount => 'I already have an account';

  @override
  String get toggleCreateAccount => 'Create an account';

  @override
  String passwordResetSent(String email) {
    return 'Password reset link sent to $email.';
  }

  @override
  String get authInvalidCredentials =>
      'That email and password do not match an account.';

  @override
  String get authEmailAlreadyInUse =>
      'That address already has an account. Try signing in instead.';

  @override
  String get authWeakPassword =>
      'That password is too easy to guess. Pick a longer one.';

  @override
  String get authInvalidEmail => 'That does not look like an email address.';

  @override
  String get authUserDisabled => 'That account has been disabled.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Wait a minute, then try again.';

  @override
  String get authNetwork =>
      'You appear to be offline. Try again once you are connected.';

  @override
  String get authProviderUnavailable =>
      'That way of signing in is not available yet.';

  @override
  String get authCancelled => 'Sign-in was cancelled.';

  @override
  String get authAccountExistsWithDifferentCredential =>
      'That address already has an account. Sign in the way you did before.';

  @override
  String get authUnknown => 'Something went wrong. Try again.';

  @override
  String get errorEmailEmpty => 'Enter your email address.';

  @override
  String get errorEmailMalformed => 'That does not look like an email address.';

  @override
  String get errorPasswordEmpty => 'Enter your password.';

  @override
  String errorPasswordTooShort(int min) {
    return 'Use at least $min characters.';
  }

  @override
  String get errorContactNameEmpty => 'Give the contact a name.';

  @override
  String get errorLabelNameEmpty => 'Give the label a name.';

  @override
  String get errorHouseholdNameEmpty => 'Give the household a name.';

  @override
  String get errorDisplayNameEmpty => 'Enter the name to show others.';

  @override
  String errorTextTooLong(int max) {
    return 'Keep it under $max characters.';
  }

  @override
  String errorTooManyTags(int max) {
    return 'Use at most $max tags.';
  }

  @override
  String errorTagTooLong(int max) {
    return 'Keep each tag under $max characters.';
  }

  @override
  String get errorCadenceEmpty => 'Enter how many days.';

  @override
  String get errorCadenceNotANumber => 'Use a whole number of days.';

  @override
  String errorCadenceTooShort(int min) {
    return 'Use at least $min day.';
  }

  @override
  String errorCadenceTooLong(int max) {
    return 'Use at most $max days.';
  }

  @override
  String get errorBirthdayEmpty => 'Enter a birthday.';

  @override
  String get errorBirthdayUnreadable => 'Write it like 14 Mar, or 14 Mar 1988.';

  @override
  String get errorBirthdayBadMonth => 'That is not a month.';

  @override
  String errorBirthdayYearOutOfRange(int min, int max) {
    return 'Use a year between $min and $max.';
  }

  @override
  String errorBirthdayNoSuchDay(String month, int day) {
    return '$month has no day $day.';
  }

  @override
  String get errorInviteCodeEmpty => 'Enter an invite code.';

  @override
  String errorInviteCodeWrongLength(int length) {
    return 'Invite codes are $length characters long.';
  }

  @override
  String errorInviteCodeBadCharacter(String char) {
    return '\"$char\" is not part of an invite code.';
  }

  @override
  String get cadenceDaily => 'Daily';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceBiweekly => 'Every 2 weeks';

  @override
  String get cadenceMonthly => 'Monthly';

  @override
  String get cadenceQuarterly => 'Every 3 months';

  @override
  String get cadenceTwiceAYear => 'Twice a year';

  @override
  String cadenceEveryDays(int days) {
    return 'Every $days days';
  }

  @override
  String get cadencePhraseDaily => 'daily';

  @override
  String get cadencePhraseWeekly => 'weekly';

  @override
  String get cadencePhraseBiweekly => 'every 2 weeks';

  @override
  String get cadencePhraseMonthly => 'monthly';

  @override
  String get cadencePhraseQuarterly => 'every 3 months';

  @override
  String get cadencePhraseTwiceAYear => 'twice a year';

  @override
  String cadencePhraseEveryDays(int days) {
    return 'every $days days';
  }

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String dayFull(String weekday, int day, String month) {
    return '$weekday $day $month';
  }

  @override
  String dayFullWithYear(String date, int year) {
    return '$date $year';
  }

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get monthFullJan => 'January';

  @override
  String get monthFullFeb => 'February';

  @override
  String get monthFullMar => 'March';

  @override
  String get monthFullApr => 'April';

  @override
  String get monthFullMay => 'May';

  @override
  String get monthFullJun => 'June';

  @override
  String get monthFullJul => 'July';

  @override
  String get monthFullAug => 'August';

  @override
  String get monthFullSep => 'September';

  @override
  String get monthFullOct => 'October';

  @override
  String get monthFullNov => 'November';

  @override
  String get monthFullDec => 'December';

  @override
  String get seenNever => 'Never logged';

  @override
  String get seenToday => 'Seen today';

  @override
  String get seenYesterday => 'Seen yesterday';

  @override
  String seenDaysAgo(int days) {
    return 'Seen $days days ago';
  }

  @override
  String get seenLastWeek => 'Seen last week';

  @override
  String seenAgo(String elapsed) {
    return 'Seen $elapsed ago';
  }

  @override
  String get elapsedLessThanADay => 'less than a day';

  @override
  String get elapsedADay => 'a day';

  @override
  String elapsedDays(int days) {
    return '$days days';
  }

  @override
  String get elapsedAWeek => 'a week';

  @override
  String elapsedWeeks(int weeks) {
    return '$weeks weeks';
  }

  @override
  String elapsedMonths(int months) {
    return '$months months';
  }

  @override
  String elapsedYears(int years) {
    return '$years+ years';
  }

  @override
  String reasonNothingLogged(String name) {
    return 'Nothing logged with $name yet.';
  }

  @override
  String reasonOverdue(String elapsed, String name, String cadence) {
    return 'It\'s been $elapsed — you usually see $name $cadence.';
  }

  @override
  String get sortByName => 'Name';

  @override
  String get sortByRecentlyAdded => 'Recently added';

  @override
  String get sortByCadence => 'How often';

  @override
  String get sortByFreshness => 'Freshness';

  @override
  String get snoozeButton => 'Snooze';

  @override
  String get dismissButton => 'Dismiss';

  @override
  String get whenToday => 'today';

  @override
  String get whenTomorrow => 'tomorrow';

  @override
  String whenOnDay(String date) {
    return 'on $date';
  }

  @override
  String birthdayHeadline(String name, String when) {
    return '$name\'s birthday is $when.';
  }

  @override
  String birthdayHeadlineTurning(String name, int age, String when) {
    return '$name turns $age $when.';
  }

  @override
  String birthdayLabel(int day, String month) {
    return '$day $month';
  }

  @override
  String birthdayLabelWithYear(String date, int year) {
    return '$date $year';
  }

  @override
  String digestTitleOverdue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people are overdue',
      one: '1 person is overdue',
    );
    return '$_temp0';
  }

  @override
  String digestTitleBirthdays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count birthdays this week',
      one: '1 birthday this week',
    );
    return '$_temp0';
  }

  @override
  String digestSentence(String names) {
    return '$names.';
  }

  @override
  String digestBirthdayList(String names) {
    return 'Birthdays this week: $names.';
  }

  @override
  String nameListPair(String first, String second) {
    return '$first and $second';
  }

  @override
  String get nameListSeparator => ', ';

  @override
  String get errorOffline =>
      'You appear to be offline. Try again once you are connected.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorSignInAgain => 'Sign in again to continue.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get signOut => 'Sign out';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get undoButton => 'Undo';

  @override
  String get onboardingJoinTitle => 'Join a household';

  @override
  String get onboardingCreateTitle => 'Start a household';

  @override
  String get onboardingJoinSubtitle =>
      'Enter the invite code from whoever set yours up.';

  @override
  String get onboardingCreateSubtitle =>
      'You can invite the rest of your household next.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get householdNameLabel => 'Household name';

  @override
  String get householdNameHint => 'The Marx house';

  @override
  String get yourNameLabel => 'Your name';

  @override
  String get yourNameHelper => 'What the rest of the household will see.';

  @override
  String get joinButton => 'Join';

  @override
  String get createHouseholdButton => 'Create household';

  @override
  String get toggleStartInstead => 'Start a new household instead';

  @override
  String get toggleHaveCode => 'I have an invite code';

  @override
  String get householdUnreachableTitle => 'Cannot reach your household';

  @override
  String get householdFailureNotFound =>
      'That code does not match a household. Check it and try again.';

  @override
  String get householdFailureValidation =>
      'Check what you typed and try again.';

  @override
  String get householdFailureConflict =>
      'Something got in the way. Try that again.';

  @override
  String get householdTitle => 'Household';

  @override
  String get householdGone => 'This household no longer exists.';

  @override
  String get inviteCodeCopied => 'Invite code copied.';

  @override
  String get noInviteCode => 'This household has no invite code right now.';

  @override
  String get shareToAdd => 'Share this to add someone.';

  @override
  String get copyInviteCode => 'Copy invite code';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarNotLinked => 'Not linked';

  @override
  String calendarPlansGoOn(String name) {
    return 'Plans go on \"$name\"';
  }

  @override
  String membersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get ownerChip => 'Owner';

  @override
  String get weeklyDigestTitle => 'Weekly digest';

  @override
  String get digestChannelDescription =>
      'A weekly summary of who you are overdue to see.';

  @override
  String get digestOff => 'Off';

  @override
  String digestDayAt(String day, String hour) {
    return '$day at $hour';
  }

  @override
  String get digestDay => 'Day';

  @override
  String get digestTime => 'Time';

  @override
  String get notificationsOff =>
      'Notifications are switched off for Kith. Turn them on in your phone settings, then try again.';

  @override
  String get digestFailureNetwork =>
      'The digest setting could not be saved. Try again once you are connected.';

  @override
  String get digestFailurePermission =>
      'You are not allowed to change this household. Ask whoever set it up.';

  @override
  String get digestFailureNotFound => 'This household is no longer here.';

  @override
  String get digestFailureConflict =>
      'That was changed somewhere else. Try again.';

  @override
  String get digestFailureUnknown =>
      'The digest could not be set up on this device.';

  @override
  String get weekdayFullMon => 'Monday';

  @override
  String get weekdayFullTue => 'Tuesday';

  @override
  String get weekdayFullWed => 'Wednesday';

  @override
  String get weekdayFullThu => 'Thursday';

  @override
  String get weekdayFullFri => 'Friday';

  @override
  String get weekdayFullSat => 'Saturday';

  @override
  String get weekdayFullSun => 'Sunday';

  @override
  String get hourAm => 'am';

  @override
  String get hourPm => 'pm';

  @override
  String hourLabel(int twelve, String suffix, int hour24) {
    return '$twelve$suffix';
  }

  @override
  String get householdCalendarTitle => 'Household calendar';

  @override
  String get calendarNoneLinkedBody =>
      'No calendar linked. Plans are kept in Kith and go nowhere else.';

  @override
  String calendarLinkedBody(String name) {
    return 'Plans go on \"$name\". Anything subscribed to that calendar, the frame included, shows them too.';
  }

  @override
  String get unlinkButton => 'Unlink';

  @override
  String get calendarUnlinked =>
      'Calendar unlinked. Events already on it were left where they are.';

  @override
  String get calendarConnectBody =>
      'Connect your Google account to choose a calendar. Kith reads the list of calendars you already have, and writes only the plans you make here.';

  @override
  String get calendarConnectButton => 'Connect Google Calendar';

  @override
  String get calendarNoneWritable =>
      'This account has no calendar Kith can write to. Make one in Google Calendar, or ask whoever owns the household calendar to share it with you.';

  @override
  String get yourCalendars => 'Your calendars';

  @override
  String get calendarPrimary => 'Your own calendar';

  @override
  String get linkedChip => 'Linked';

  @override
  String calendarNowLinked(String name) {
    return 'Plans now go on \"$name\".';
  }

  @override
  String get calendarFailureNetwork =>
      'Google Calendar could not be reached. Try again once you are connected.';

  @override
  String get calendarFailurePermission =>
      'Kith is not allowed to use that calendar. Connect the Google account again, and pick a calendar you can write to.';

  @override
  String get calendarFailureNotFound => 'That calendar is no longer there.';

  @override
  String get calendarFailureConflict =>
      'That calendar was changed somewhere else. Try again.';

  @override
  String get calendarFailureUnknown =>
      'Something went wrong with the calendar. Try again.';

  @override
  String get calendarOutOfStep => 'Plans may be out of step with the calendar.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get sortTooltip => 'Sort';

  @override
  String get importTooltip => 'Import from contacts';

  @override
  String get labelsTooltip => 'Relationship labels';

  @override
  String get addContactTooltip => 'Add a contact';

  @override
  String get searchHint => 'Search names, tags or a guardian';

  @override
  String get filterAll => 'All';

  @override
  String get filterArchived => 'Archived';

  @override
  String get noLabel => 'No label';

  @override
  String get emptyNeedsLabel =>
      'Add a relationship label first, so contacts have somewhere to go.';

  @override
  String get manageLabels => 'Manage labels';

  @override
  String get emptyNoContacts => 'Nobody here yet. Add the first contact.';

  @override
  String get emptyFiltered => 'Nothing matches what you are looking for.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get contactFailurePermission =>
      'You are not allowed to change this household.';

  @override
  String get contactFailureNotFound =>
      'That is no longer there. Go back and try again.';

  @override
  String get contactFailureConflict => 'That label already exists.';

  @override
  String get addContactTitle => 'Add a contact';

  @override
  String get editContactTitle => 'Edit contact';

  @override
  String get contactGone => 'That contact is no longer here.';

  @override
  String get nameLabel => 'Name';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get cadenceSection => 'How often you want to see them';

  @override
  String get customCadenceLabel => 'Every how many days';

  @override
  String get customCadenceChip => 'Custom';

  @override
  String get prioritySection => 'Priority';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get reachSection => 'How to reach them';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get addressLabel => 'Address';

  @override
  String get guardianSection => 'Parent or guardian';

  @override
  String get guardianHelper =>
      'For a kid\'s friend, the person you actually text.';

  @override
  String get guardianNameLabel => 'Guardian name';

  @override
  String get guardianPhoneLabel => 'Guardian phone';

  @override
  String get birthdayFieldLabel => 'Birthday';

  @override
  String get birthdayFieldHelper =>
      'Like 14 Mar, or 14 Mar 1988. The year is optional.';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagsHelper => 'Separate tags with commas.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get seeTheirHangouts => 'See their hangouts';

  @override
  String get restoreContact => 'Restore contact';

  @override
  String get archiveContact => 'Archive contact';

  @override
  String get importContactsTitle => 'Import contacts';

  @override
  String get importNeedsLabel =>
      'Add a relationship label first, so imported contacts have somewhere to go.';

  @override
  String get importPermissionDenied =>
      'Kith cannot see your contacts. Allow access in your phone settings, then try again.';

  @override
  String importDone(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts added.',
      one: '1 contact added.',
    );
    return '$_temp0';
  }

  @override
  String get importNobody => 'There is nobody in your address book to import.';

  @override
  String get importFileThemAs => 'File them as';

  @override
  String get importSeeThem => 'See them';

  @override
  String get importNobodyChosen => 'Nobody chosen';

  @override
  String importChosen(int count) {
    return '$count chosen';
  }

  @override
  String get importSelectNone => 'None';

  @override
  String get importSelectAll => 'All';

  @override
  String importButton(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count contacts',
      one: 'Import 1 contact',
    );
    return '$_temp0';
  }

  @override
  String get importIntro =>
      'Kith can read your phone contacts so you can pick who to track. Nothing is sent anywhere, and nothing is written back to your address book.';

  @override
  String get importChooseButton => 'Choose from contacts';

  @override
  String get importAlreadyHere => 'Already in Kith';

  @override
  String get importNoDetails => 'No details';

  @override
  String get labelsTitle => 'Relationship labels';

  @override
  String get addLabelTooltip => 'Add a label';

  @override
  String get labelFieldLabel => 'Label';

  @override
  String get labelsEmpty =>
      'No labels yet. Add one, and contacts have somewhere to go.';

  @override
  String renameLabelTooltip(String name) {
    return 'Rename $name';
  }

  @override
  String deleteLabelTooltip(String name) {
    return 'Delete $name';
  }

  @override
  String get renameLabelTitle => 'Rename label';

  @override
  String get keepOneLabel => 'Keep at least one label for contacts to use.';

  @override
  String deleteLabelTitle(String name) {
    return 'Delete \"$name\"';
  }

  @override
  String get reassignPrompt => 'Move everyone filed under it to:';

  @override
  String get logHangoutTitle => 'Log a hangout';

  @override
  String get editHangoutTitle => 'Edit hangout';

  @override
  String get hangoutGone => 'That hangout is no longer here.';

  @override
  String get hangoutNeedsContact =>
      'Add a contact first, so there is somebody to have seen.';

  @override
  String get whenSection => 'When';

  @override
  String get whoYouSawSection => 'Who you saw';

  @override
  String get searchContactsHint => 'Search contacts';

  @override
  String get nobodyMatches => 'Nobody matches what you are looking for.';

  @override
  String get chooseWhoYouSaw => 'Choose who you saw.';

  @override
  String get whoFromHouseSection => 'Who from the house was there';

  @override
  String get noteLabel => 'Note';

  @override
  String get noteHelper => 'Optional. What made it worth remembering.';

  @override
  String get logItButton => 'Log it';

  @override
  String get deleteHangout => 'Delete hangout';

  @override
  String get hangoutsTitle => 'Hangouts';

  @override
  String hangoutsWithTitle(String name) {
    return 'Hangouts with $name';
  }

  @override
  String get hangoutsEmpty =>
      'Nothing logged yet. The first hangout goes here.';

  @override
  String get someoneSinceRemoved => 'Someone since removed';

  @override
  String withAttendees(String names) {
    return 'With $names';
  }

  @override
  String get justTheTwoOfYou => 'Just the two of you';

  @override
  String get hangoutFailureNotFound => 'That hangout is no longer there.';

  @override
  String get hangoutFailureConflict =>
      'That hangout was changed somewhere else. Try again.';

  @override
  String get reconnectTitle => 'Reconnect';

  @override
  String birthdaysMore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more this month.',
      one: '1 more this month.',
    );
    return '$_temp0';
  }

  @override
  String get planItButton => 'Plan it';

  @override
  String plannedWith(String name, String day) {
    return 'Planned with $name for $day.';
  }

  @override
  String get addedToCalendar => 'Added to the calendar.';

  @override
  String notAskingUntil(String name, String day) {
    return 'Not asking about $name until $day.';
  }

  @override
  String plannedChip(String day) {
    return 'Planned $day';
  }

  @override
  String get reconnectAllFresh =>
      'Nobody is overdue. Everyone you track has been seen inside the cadence you set for them.';

  @override
  String get reconnectNoContacts =>
      'Nobody here yet. Add the people you want to keep up with and they will show up here when it has been a while.';

  @override
  String get addContactsButton => 'Add contacts';

  @override
  String get suggestionFailureNotFound => 'That plan is no longer there.';

  @override
  String get suggestionFailureConflict =>
      'That plan was changed somewhere else. Try again.';
}
