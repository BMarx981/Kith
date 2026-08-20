import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Application title, shown in the task switcher. A proper noun; the same in every locale.
  ///
  /// In en, this message translates to:
  /// **'Kith'**
  String get appTitle;

  /// Placeholder body for a screen whose feature is not built yet
  ///
  /// In en, this message translates to:
  /// **'Arrives in {milestone}'**
  String arrivesInMilestone(String milestone);

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your household.'**
  String get signInTagline;

  /// No description provided for @signUpTagline.
  ///
  /// In en, this message translates to:
  /// **'Create an account, then start or join a household.'**
  String get signUpTagline;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @toggleHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get toggleHaveAccount;

  /// No description provided for @toggleCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get toggleCreateAccount;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}.'**
  String passwordResetSent(String email);

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'That email and password do not match an account.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'That address already has an account. Try signing in instead.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'That password is too easy to guess. Pick a longer one.'**
  String get authWeakPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address.'**
  String get authInvalidEmail;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'That account has been disabled.'**
  String get authUserDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute, then try again.'**
  String get authTooManyRequests;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Try again once you are connected.'**
  String get authNetwork;

  /// No description provided for @authProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That way of signing in is not available yet.'**
  String get authProviderUnavailable;

  /// No description provided for @authCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authCancelled;

  /// No description provided for @authAccountExistsWithDifferentCredential.
  ///
  /// In en, this message translates to:
  /// **'That address already has an account. Sign in the way you did before.'**
  String get authAccountExistsWithDifferentCredential;

  /// No description provided for @authUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get authUnknown;

  /// No description provided for @errorEmailEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get errorEmailEmpty;

  /// No description provided for @errorEmailMalformed.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address.'**
  String get errorEmailMalformed;

  /// No description provided for @errorPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get errorPasswordEmpty;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters.'**
  String errorPasswordTooShort(int min);

  /// No description provided for @errorContactNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give the contact a name.'**
  String get errorContactNameEmpty;

  /// No description provided for @errorLabelNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give the label a name.'**
  String get errorLabelNameEmpty;

  /// No description provided for @errorHouseholdNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give the household a name.'**
  String get errorHouseholdNameEmpty;

  /// No description provided for @errorDisplayNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the name to show others.'**
  String get errorDisplayNameEmpty;

  /// No description provided for @errorTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep it under {max} characters.'**
  String errorTextTooLong(int max);

  /// No description provided for @errorTooManyTags.
  ///
  /// In en, this message translates to:
  /// **'Use at most {max} tags.'**
  String errorTooManyTags(int max);

  /// No description provided for @errorTagTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep each tag under {max} characters.'**
  String errorTagTooLong(int max);

  /// No description provided for @errorCadenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter how many days.'**
  String get errorCadenceEmpty;

  /// No description provided for @errorCadenceNotANumber.
  ///
  /// In en, this message translates to:
  /// **'Use a whole number of days.'**
  String get errorCadenceNotANumber;

  /// No description provided for @errorCadenceTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} day.'**
  String errorCadenceTooShort(int min);

  /// No description provided for @errorCadenceTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use at most {max} days.'**
  String errorCadenceTooLong(int max);

  /// No description provided for @errorBirthdayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a birthday.'**
  String get errorBirthdayEmpty;

  /// No description provided for @errorBirthdayUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Write it like 14 Mar, or 14 Mar 1988.'**
  String get errorBirthdayUnreadable;

  /// No description provided for @errorBirthdayBadMonth.
  ///
  /// In en, this message translates to:
  /// **'That is not a month.'**
  String get errorBirthdayBadMonth;

  /// No description provided for @errorBirthdayYearOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Use a year between {min} and {max}.'**
  String errorBirthdayYearOutOfRange(int min, int max);

  /// month is the localized short month name
  ///
  /// In en, this message translates to:
  /// **'{month} has no day {day}.'**
  String errorBirthdayNoSuchDay(String month, int day);

  /// No description provided for @errorInviteCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter an invite code.'**
  String get errorInviteCodeEmpty;

  /// No description provided for @errorInviteCodeWrongLength.
  ///
  /// In en, this message translates to:
  /// **'Invite codes are {length} characters long.'**
  String errorInviteCodeWrongLength(int length);

  /// No description provided for @errorInviteCodeBadCharacter.
  ///
  /// In en, this message translates to:
  /// **'\"{char}\" is not part of an invite code.'**
  String errorInviteCodeBadCharacter(String char);

  /// No description provided for @cadenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get cadenceDaily;

  /// No description provided for @cadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cadenceWeekly;

  /// No description provided for @cadenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get cadenceBiweekly;

  /// No description provided for @cadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cadenceMonthly;

  /// No description provided for @cadenceQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get cadenceQuarterly;

  /// No description provided for @cadenceTwiceAYear.
  ///
  /// In en, this message translates to:
  /// **'Twice a year'**
  String get cadenceTwiceAYear;

  /// No description provided for @cadenceEveryDays.
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String cadenceEveryDays(int days);

  /// No description provided for @cadencePhraseDaily.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get cadencePhraseDaily;

  /// No description provided for @cadencePhraseWeekly.
  ///
  /// In en, this message translates to:
  /// **'weekly'**
  String get cadencePhraseWeekly;

  /// No description provided for @cadencePhraseBiweekly.
  ///
  /// In en, this message translates to:
  /// **'every 2 weeks'**
  String get cadencePhraseBiweekly;

  /// No description provided for @cadencePhraseMonthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get cadencePhraseMonthly;

  /// No description provided for @cadencePhraseQuarterly.
  ///
  /// In en, this message translates to:
  /// **'every 3 months'**
  String get cadencePhraseQuarterly;

  /// No description provided for @cadencePhraseTwiceAYear.
  ///
  /// In en, this message translates to:
  /// **'twice a year'**
  String get cadencePhraseTwiceAYear;

  /// Mid-sentence: 'you usually see Ana every 14 days'
  ///
  /// In en, this message translates to:
  /// **'every {days} days'**
  String cadencePhraseEveryDays(int days);

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @dayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dayTomorrow;

  /// A date written out, e.g. 'Tue 12 Aug'. Locales reorder the parts.
  ///
  /// In en, this message translates to:
  /// **'{weekday} {day} {month}'**
  String dayFull(String weekday, int day, String month);

  /// dayFull with the year appended, e.g. 'Tue 12 Aug 2025'
  ///
  /// In en, this message translates to:
  /// **'{date} {year}'**
  String dayFullWithYear(String date, int year);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @monthFullJan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthFullJan;

  /// No description provided for @monthFullFeb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFullFeb;

  /// No description provided for @monthFullMar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthFullMar;

  /// No description provided for @monthFullApr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthFullApr;

  /// No description provided for @monthFullMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthFullMay;

  /// No description provided for @monthFullJun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthFullJun;

  /// No description provided for @monthFullJul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthFullJul;

  /// No description provided for @monthFullAug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthFullAug;

  /// No description provided for @monthFullSep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthFullSep;

  /// No description provided for @monthFullOct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthFullOct;

  /// No description provided for @monthFullNov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthFullNov;

  /// No description provided for @monthFullDec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthFullDec;

  /// No description provided for @seenNever.
  ///
  /// In en, this message translates to:
  /// **'Never logged'**
  String get seenNever;

  /// No description provided for @seenToday.
  ///
  /// In en, this message translates to:
  /// **'Seen today'**
  String get seenToday;

  /// No description provided for @seenYesterday.
  ///
  /// In en, this message translates to:
  /// **'Seen yesterday'**
  String get seenYesterday;

  /// Only used for 2-6 days
  ///
  /// In en, this message translates to:
  /// **'Seen {days} days ago'**
  String seenDaysAgo(int days);

  /// No description provided for @seenLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Seen last week'**
  String get seenLastWeek;

  /// No description provided for @seenAgo.
  ///
  /// In en, this message translates to:
  /// **'Seen {elapsed} ago'**
  String seenAgo(String elapsed);

  /// No description provided for @elapsedLessThanADay.
  ///
  /// In en, this message translates to:
  /// **'less than a day'**
  String get elapsedLessThanADay;

  /// No description provided for @elapsedADay.
  ///
  /// In en, this message translates to:
  /// **'a day'**
  String get elapsedADay;

  /// No description provided for @elapsedDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String elapsedDays(int days);

  /// No description provided for @elapsedAWeek.
  ///
  /// In en, this message translates to:
  /// **'a week'**
  String get elapsedAWeek;

  /// No description provided for @elapsedWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks'**
  String elapsedWeeks(int weeks);

  /// No description provided for @elapsedMonths.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String elapsedMonths(int months);

  /// No description provided for @elapsedYears.
  ///
  /// In en, this message translates to:
  /// **'{years}+ years'**
  String elapsedYears(int years);

  /// No description provided for @reasonNothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged with {name} yet.'**
  String reasonNothingLogged(String name);

  /// cadence is a cadencePhrase* value, e.g. 'every 2 weeks'
  ///
  /// In en, this message translates to:
  /// **'It\'s been {elapsed} — you usually see {name} {cadence}.'**
  String reasonOverdue(String elapsed, String name, String cadence);

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortByRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortByRecentlyAdded;

  /// No description provided for @sortByCadence.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get sortByCadence;

  /// No description provided for @sortByFreshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get sortByFreshness;

  /// No description provided for @snoozeButton.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snoozeButton;

  /// No description provided for @dismissButton.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissButton;

  /// No description provided for @whenToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get whenToday;

  /// No description provided for @whenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get whenTomorrow;

  /// Mid-sentence: 'Ana turns 40 on Tue 12 Aug.'
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String whenOnDay(String date);

  /// when is whenToday, whenTomorrow or whenOnDay
  ///
  /// In en, this message translates to:
  /// **'{name}\'s birthday is {when}.'**
  String birthdayHeadline(String name, String when);

  /// No description provided for @birthdayHeadlineTurning.
  ///
  /// In en, this message translates to:
  /// **'{name} turns {age} {when}.'**
  String birthdayHeadlineTurning(String name, int age, String when);

  /// A birthday with no year, e.g. '14 Mar'
  ///
  /// In en, this message translates to:
  /// **'{day} {month}'**
  String birthdayLabel(int day, String month);

  /// birthdayLabel with the birth year appended
  ///
  /// In en, this message translates to:
  /// **'{date} {year}'**
  String birthdayLabelWithYear(String date, int year);

  /// No description provided for @digestTitleOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person is overdue} other{{count} people are overdue}}'**
  String digestTitleOverdue(num count);

  /// No description provided for @digestTitleBirthdays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 birthday this week} other{{count} birthdays this week}}'**
  String digestTitleBirthdays(num count);

  /// The overdue names as a sentence of their own
  ///
  /// In en, this message translates to:
  /// **'{names}.'**
  String digestSentence(String names);

  /// No description provided for @digestBirthdayList.
  ///
  /// In en, this message translates to:
  /// **'Birthdays this week: {names}.'**
  String digestBirthdayList(String names);

  /// Joins the last two entries of a spoken list of names
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String nameListPair(String first, String second);

  /// Separator between earlier entries of a spoken list of names
  ///
  /// In en, this message translates to:
  /// **', '**
  String get nameListSeparator;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Try again once you are connected.'**
  String get errorOffline;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue.'**
  String get errorSignInAgain;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @undoButton.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoButton;

  /// No description provided for @onboardingJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a household'**
  String get onboardingJoinTitle;

  /// No description provided for @onboardingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a household'**
  String get onboardingCreateTitle;

  /// No description provided for @onboardingJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the invite code from whoever set yours up.'**
  String get onboardingJoinSubtitle;

  /// No description provided for @onboardingCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can invite the rest of your household next.'**
  String get onboardingCreateSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @householdNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdNameLabel;

  /// No description provided for @householdNameHint.
  ///
  /// In en, this message translates to:
  /// **'The Marx house'**
  String get householdNameHint;

  /// No description provided for @yourNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameLabel;

  /// No description provided for @yourNameHelper.
  ///
  /// In en, this message translates to:
  /// **'What the rest of the household will see.'**
  String get yourNameHelper;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @createHouseholdButton.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get createHouseholdButton;

  /// No description provided for @toggleStartInstead.
  ///
  /// In en, this message translates to:
  /// **'Start a new household instead'**
  String get toggleStartInstead;

  /// No description provided for @toggleHaveCode.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get toggleHaveCode;

  /// No description provided for @householdUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach your household'**
  String get householdUnreachableTitle;

  /// No description provided for @householdFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'That code does not match a household. Check it and try again.'**
  String get householdFailureNotFound;

  /// No description provided for @householdFailureValidation.
  ///
  /// In en, this message translates to:
  /// **'Check what you typed and try again.'**
  String get householdFailureValidation;

  /// No description provided for @householdFailureConflict.
  ///
  /// In en, this message translates to:
  /// **'Something got in the way. Try that again.'**
  String get householdFailureConflict;

  /// No description provided for @householdTitle.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdTitle;

  /// No description provided for @householdGone.
  ///
  /// In en, this message translates to:
  /// **'This household no longer exists.'**
  String get householdGone;

  /// No description provided for @inviteCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied.'**
  String get inviteCodeCopied;

  /// No description provided for @noInviteCode.
  ///
  /// In en, this message translates to:
  /// **'This household has no invite code right now.'**
  String get noInviteCode;

  /// No description provided for @shareToAdd.
  ///
  /// In en, this message translates to:
  /// **'Share this to add someone.'**
  String get shareToAdd;

  /// No description provided for @copyInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Copy invite code'**
  String get copyInviteCode;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get calendarNotLinked;

  /// No description provided for @calendarPlansGoOn.
  ///
  /// In en, this message translates to:
  /// **'Plans go on \"{name}\"'**
  String calendarPlansGoOn(String name);

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(num count);

  /// No description provided for @ownerChip.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerChip;

  /// The digest setting on the household screen, and the name of the Android notification channel the digest is posted on
  ///
  /// In en, this message translates to:
  /// **'Weekly digest'**
  String get weeklyDigestTitle;

  /// What the Android notification channel is for, shown under its name in the system notification settings
  ///
  /// In en, this message translates to:
  /// **'A weekly summary of who you are overdue to see.'**
  String get digestChannelDescription;

  /// No description provided for @digestOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get digestOff;

  /// No description provided for @digestDayAt.
  ///
  /// In en, this message translates to:
  /// **'{day} at {hour}'**
  String digestDayAt(String day, String hour);

  /// No description provided for @digestDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get digestDay;

  /// No description provided for @digestTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get digestTime;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are switched off for Kith. Turn them on in your phone settings, then try again.'**
  String get notificationsOff;

  /// No description provided for @digestFailureNetwork.
  ///
  /// In en, this message translates to:
  /// **'The digest setting could not be saved. Try again once you are connected.'**
  String get digestFailureNetwork;

  /// No description provided for @digestFailurePermission.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to change this household. Ask whoever set it up.'**
  String get digestFailurePermission;

  /// No description provided for @digestFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'This household is no longer here.'**
  String get digestFailureNotFound;

  /// No description provided for @digestFailureConflict.
  ///
  /// In en, this message translates to:
  /// **'That was changed somewhere else. Try again.'**
  String get digestFailureConflict;

  /// No description provided for @digestFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'The digest could not be set up on this device.'**
  String get digestFailureUnknown;

  /// No description provided for @weekdayFullMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayFullMon;

  /// No description provided for @weekdayFullTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayFullTue;

  /// No description provided for @weekdayFullWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayFullWed;

  /// No description provided for @weekdayFullThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayFullThu;

  /// No description provided for @weekdayFullFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFullFri;

  /// No description provided for @weekdayFullSat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdayFullSat;

  /// No description provided for @weekdayFullSun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdayFullSun;

  /// No description provided for @hourAm.
  ///
  /// In en, this message translates to:
  /// **'am'**
  String get hourAm;

  /// No description provided for @hourPm.
  ///
  /// In en, this message translates to:
  /// **'pm'**
  String get hourPm;

  /// An hour of the day. Every spelling is provided: twelve-hour number with its am/pm suffix, and the 24-hour number; each locale composes the ones its clock uses, e.g. '9am' in English, '9:00' or '9 h' where the clock runs to 24.
  ///
  /// In en, this message translates to:
  /// **'{twelve}{suffix}'**
  String hourLabel(int twelve, String suffix, int hour24);

  /// No description provided for @householdCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Household calendar'**
  String get householdCalendarTitle;

  /// No description provided for @calendarNoneLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'No calendar linked. Plans are kept in Kith and go nowhere else.'**
  String get calendarNoneLinkedBody;

  /// No description provided for @calendarLinkedBody.
  ///
  /// In en, this message translates to:
  /// **'Plans go on \"{name}\". Anything subscribed to that calendar, the frame included, shows them too.'**
  String calendarLinkedBody(String name);

  /// No description provided for @unlinkButton.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlinkButton;

  /// No description provided for @calendarUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Calendar unlinked. Events already on it were left where they are.'**
  String get calendarUnlinked;

  /// No description provided for @calendarConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google account to choose a calendar. Kith reads the list of calendars you already have, and writes only the plans you make here.'**
  String get calendarConnectBody;

  /// No description provided for @calendarConnectButton.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Calendar'**
  String get calendarConnectButton;

  /// No description provided for @calendarNoneWritable.
  ///
  /// In en, this message translates to:
  /// **'This account has no calendar Kith can write to. Make one in Google Calendar, or ask whoever owns the household calendar to share it with you.'**
  String get calendarNoneWritable;

  /// No description provided for @yourCalendars.
  ///
  /// In en, this message translates to:
  /// **'Your calendars'**
  String get yourCalendars;

  /// No description provided for @calendarPrimary.
  ///
  /// In en, this message translates to:
  /// **'Your own calendar'**
  String get calendarPrimary;

  /// No description provided for @linkedChip.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linkedChip;

  /// No description provided for @calendarNowLinked.
  ///
  /// In en, this message translates to:
  /// **'Plans now go on \"{name}\".'**
  String calendarNowLinked(String name);

  /// No description provided for @calendarFailureNetwork.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar could not be reached. Try again once you are connected.'**
  String get calendarFailureNetwork;

  /// No description provided for @calendarFailurePermission.
  ///
  /// In en, this message translates to:
  /// **'Kith is not allowed to use that calendar. Connect the Google account again, and pick a calendar you can write to.'**
  String get calendarFailurePermission;

  /// No description provided for @calendarFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'That calendar is no longer there.'**
  String get calendarFailureNotFound;

  /// No description provided for @calendarFailureConflict.
  ///
  /// In en, this message translates to:
  /// **'That calendar was changed somewhere else. Try again.'**
  String get calendarFailureConflict;

  /// No description provided for @calendarFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the calendar. Try again.'**
  String get calendarFailureUnknown;

  /// No description provided for @calendarOutOfStep.
  ///
  /// In en, this message translates to:
  /// **'Plans may be out of step with the calendar.'**
  String get calendarOutOfStep;

  /// No description provided for @contactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @sortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortTooltip;

  /// No description provided for @importTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import from contacts'**
  String get importTooltip;

  /// No description provided for @labelsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Relationship labels'**
  String get labelsTooltip;

  /// No description provided for @addContactTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get addContactTooltip;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search names, tags or a guardian'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get filterArchived;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No label'**
  String get noLabel;

  /// No description provided for @emptyNeedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a relationship label first, so contacts have somewhere to go.'**
  String get emptyNeedsLabel;

  /// No description provided for @manageLabels.
  ///
  /// In en, this message translates to:
  /// **'Manage labels'**
  String get manageLabels;

  /// No description provided for @emptyNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Nobody here yet. Add the first contact.'**
  String get emptyNoContacts;

  /// No description provided for @emptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches what you are looking for.'**
  String get emptyFiltered;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @contactFailurePermission.
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to change this household.'**
  String get contactFailurePermission;

  /// No description provided for @contactFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'That is no longer there. Go back and try again.'**
  String get contactFailureNotFound;

  /// No description provided for @contactFailureConflict.
  ///
  /// In en, this message translates to:
  /// **'That label already exists.'**
  String get contactFailureConflict;

  /// No description provided for @addContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get addContactTitle;

  /// No description provided for @editContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get editContactTitle;

  /// No description provided for @contactGone.
  ///
  /// In en, this message translates to:
  /// **'That contact is no longer here.'**
  String get contactGone;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @relationshipLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationshipLabel;

  /// No description provided for @cadenceSection.
  ///
  /// In en, this message translates to:
  /// **'How often you want to see them'**
  String get cadenceSection;

  /// No description provided for @customCadenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Every how many days'**
  String get customCadenceLabel;

  /// No description provided for @customCadenceChip.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customCadenceChip;

  /// No description provided for @prioritySection.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get prioritySection;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @reachSection.
  ///
  /// In en, this message translates to:
  /// **'How to reach them'**
  String get reachSection;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @guardianSection.
  ///
  /// In en, this message translates to:
  /// **'Parent or guardian'**
  String get guardianSection;

  /// No description provided for @guardianHelper.
  ///
  /// In en, this message translates to:
  /// **'For a kid\'s friend, the person you actually text.'**
  String get guardianHelper;

  /// No description provided for @guardianNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian name'**
  String get guardianNameLabel;

  /// No description provided for @guardianPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Guardian phone'**
  String get guardianPhoneLabel;

  /// No description provided for @birthdayFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthdayFieldLabel;

  /// No description provided for @birthdayFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'Like 14 Mar, or 14 Mar 1988. The year is optional.'**
  String get birthdayFieldHelper;

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @tagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Separate tags with commas.'**
  String get tagsHelper;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @seeTheirHangouts.
  ///
  /// In en, this message translates to:
  /// **'See their hangouts'**
  String get seeTheirHangouts;

  /// No description provided for @restoreContact.
  ///
  /// In en, this message translates to:
  /// **'Restore contact'**
  String get restoreContact;

  /// No description provided for @archiveContact.
  ///
  /// In en, this message translates to:
  /// **'Archive contact'**
  String get archiveContact;

  /// No description provided for @importContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import contacts'**
  String get importContactsTitle;

  /// No description provided for @importNeedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Add a relationship label first, so imported contacts have somewhere to go.'**
  String get importNeedsLabel;

  /// No description provided for @importPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Kith cannot see your contacts. Allow access in your phone settings, then try again.'**
  String get importPermissionDenied;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contact added.} other{{count} contacts added.}}'**
  String importDone(num count);

  /// No description provided for @importNobody.
  ///
  /// In en, this message translates to:
  /// **'There is nobody in your address book to import.'**
  String get importNobody;

  /// No description provided for @importFileThemAs.
  ///
  /// In en, this message translates to:
  /// **'File them as'**
  String get importFileThemAs;

  /// No description provided for @importSeeThem.
  ///
  /// In en, this message translates to:
  /// **'See them'**
  String get importSeeThem;

  /// No description provided for @importNobodyChosen.
  ///
  /// In en, this message translates to:
  /// **'Nobody chosen'**
  String get importNobodyChosen;

  /// No description provided for @importChosen.
  ///
  /// In en, this message translates to:
  /// **'{count} chosen'**
  String importChosen(int count);

  /// No description provided for @importSelectNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get importSelectNone;

  /// No description provided for @importSelectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get importSelectAll;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import 1 contact} other{Import {count} contacts}}'**
  String importButton(num count);

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Kith can read your phone contacts so you can pick who to track. Nothing is sent anywhere, and nothing is written back to your address book.'**
  String get importIntro;

  /// No description provided for @importChooseButton.
  ///
  /// In en, this message translates to:
  /// **'Choose from contacts'**
  String get importChooseButton;

  /// No description provided for @importAlreadyHere.
  ///
  /// In en, this message translates to:
  /// **'Already in Kith'**
  String get importAlreadyHere;

  /// No description provided for @importNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get importNoDetails;

  /// No description provided for @labelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Relationship labels'**
  String get labelsTitle;

  /// No description provided for @addLabelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add a label'**
  String get addLabelTooltip;

  /// No description provided for @labelFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelFieldLabel;

  /// No description provided for @labelsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No labels yet. Add one, and contacts have somewhere to go.'**
  String get labelsEmpty;

  /// No description provided for @renameLabelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename {name}'**
  String renameLabelTooltip(String name);

  /// No description provided for @deleteLabelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteLabelTooltip(String name);

  /// No description provided for @renameLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename label'**
  String get renameLabelTitle;

  /// No description provided for @keepOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one label for contacts to use.'**
  String get keepOneLabel;

  /// No description provided for @deleteLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"'**
  String deleteLabelTitle(String name);

  /// No description provided for @reassignPrompt.
  ///
  /// In en, this message translates to:
  /// **'Move everyone filed under it to:'**
  String get reassignPrompt;

  /// No description provided for @logHangoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a hangout'**
  String get logHangoutTitle;

  /// No description provided for @editHangoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit hangout'**
  String get editHangoutTitle;

  /// No description provided for @hangoutGone.
  ///
  /// In en, this message translates to:
  /// **'That hangout is no longer here.'**
  String get hangoutGone;

  /// No description provided for @hangoutNeedsContact.
  ///
  /// In en, this message translates to:
  /// **'Add a contact first, so there is somebody to have seen.'**
  String get hangoutNeedsContact;

  /// No description provided for @whenSection.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get whenSection;

  /// No description provided for @whoYouSawSection.
  ///
  /// In en, this message translates to:
  /// **'Who you saw'**
  String get whoYouSawSection;

  /// No description provided for @searchContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContactsHint;

  /// No description provided for @nobodyMatches.
  ///
  /// In en, this message translates to:
  /// **'Nobody matches what you are looking for.'**
  String get nobodyMatches;

  /// No description provided for @chooseWhoYouSaw.
  ///
  /// In en, this message translates to:
  /// **'Choose who you saw.'**
  String get chooseWhoYouSaw;

  /// No description provided for @whoFromHouseSection.
  ///
  /// In en, this message translates to:
  /// **'Who from the house was there'**
  String get whoFromHouseSection;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @noteHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. What made it worth remembering.'**
  String get noteHelper;

  /// No description provided for @logItButton.
  ///
  /// In en, this message translates to:
  /// **'Log it'**
  String get logItButton;

  /// No description provided for @deleteHangout.
  ///
  /// In en, this message translates to:
  /// **'Delete hangout'**
  String get deleteHangout;

  /// No description provided for @hangoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hangouts'**
  String get hangoutsTitle;

  /// No description provided for @hangoutsWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hangouts with {name}'**
  String hangoutsWithTitle(String name);

  /// No description provided for @hangoutsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet. The first hangout goes here.'**
  String get hangoutsEmpty;

  /// No description provided for @someoneSinceRemoved.
  ///
  /// In en, this message translates to:
  /// **'Someone since removed'**
  String get someoneSinceRemoved;

  /// No description provided for @withAttendees.
  ///
  /// In en, this message translates to:
  /// **'With {names}'**
  String withAttendees(String names);

  /// No description provided for @justTheTwoOfYou.
  ///
  /// In en, this message translates to:
  /// **'Just the two of you'**
  String get justTheTwoOfYou;

  /// No description provided for @hangoutFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'That hangout is no longer there.'**
  String get hangoutFailureNotFound;

  /// No description provided for @hangoutFailureConflict.
  ///
  /// In en, this message translates to:
  /// **'That hangout was changed somewhere else. Try again.'**
  String get hangoutFailureConflict;

  /// No description provided for @reconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnectTitle;

  /// No description provided for @birthdaysMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more this month.} other{{count} more this month.}}'**
  String birthdaysMore(num count);

  /// No description provided for @planItButton.
  ///
  /// In en, this message translates to:
  /// **'Plan it'**
  String get planItButton;

  /// No description provided for @plannedWith.
  ///
  /// In en, this message translates to:
  /// **'Planned with {name} for {day}.'**
  String plannedWith(String name, String day);

  /// No description provided for @addedToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Added to the calendar.'**
  String get addedToCalendar;

  /// No description provided for @notAskingUntil.
  ///
  /// In en, this message translates to:
  /// **'Not asking about {name} until {day}.'**
  String notAskingUntil(String name, String day);

  /// No description provided for @plannedChip.
  ///
  /// In en, this message translates to:
  /// **'Planned {day}'**
  String plannedChip(String day);

  /// No description provided for @reconnectAllFresh.
  ///
  /// In en, this message translates to:
  /// **'Nobody is overdue. Everyone you track has been seen inside the cadence you set for them.'**
  String get reconnectAllFresh;

  /// No description provided for @reconnectNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Nobody here yet. Add the people you want to keep up with and they will show up here when it has been a while.'**
  String get reconnectNoContacts;

  /// No description provided for @addContactsButton.
  ///
  /// In en, this message translates to:
  /// **'Add contacts'**
  String get addContactsButton;

  /// No description provided for @suggestionFailureNotFound.
  ///
  /// In en, this message translates to:
  /// **'That plan is no longer there.'**
  String get suggestionFailureNotFound;

  /// No description provided for @suggestionFailureConflict.
  ///
  /// In en, this message translates to:
  /// **'That plan was changed somewhere else. Try again.'**
  String get suggestionFailureConflict;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
