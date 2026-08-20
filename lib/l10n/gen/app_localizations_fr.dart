// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Kith';

  @override
  String arrivesInMilestone(String milestone) {
    return 'Arrive avec $milestone';
  }

  @override
  String get signInTagline => 'Connectez-vous à votre foyer.';

  @override
  String get signUpTagline =>
      'Créez un compte, puis créez ou rejoignez un foyer.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get signInButton => 'Se connecter';

  @override
  String get createAccountButton => 'Créer un compte';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get toggleHaveAccount => 'J\'ai déjà un compte';

  @override
  String get toggleCreateAccount => 'Créer un compte';

  @override
  String passwordResetSent(String email) {
    return 'Lien de réinitialisation envoyé à $email.';
  }

  @override
  String get authInvalidCredentials =>
      'Cet e-mail et ce mot de passe ne correspondent à aucun compte.';

  @override
  String get authEmailAlreadyInUse =>
      'Cette adresse a déjà un compte. Essayez plutôt de vous connecter.';

  @override
  String get authWeakPassword =>
      'Ce mot de passe est trop facile à deviner. Choisissez-en un plus long.';

  @override
  String get authInvalidEmail => 'Cela ne ressemble pas à une adresse e-mail.';

  @override
  String get authUserDisabled => 'Ce compte a été désactivé.';

  @override
  String get authTooManyRequests =>
      'Trop de tentatives. Attendez une minute, puis réessayez.';

  @override
  String get authNetwork =>
      'Vous semblez hors ligne. Réessayez une fois connecté.';

  @override
  String get authProviderUnavailable =>
      'Ce mode de connexion n\'est pas encore disponible.';

  @override
  String get authCancelled => 'La connexion a été annulée.';

  @override
  String get authAccountExistsWithDifferentCredential =>
      'Cette adresse a déjà un compte. Connectez-vous comme vous l\'avez fait auparavant.';

  @override
  String get authUnknown => 'Une erreur est survenue. Réessayez.';

  @override
  String get errorEmailEmpty => 'Saisissez votre adresse e-mail.';

  @override
  String get errorEmailMalformed =>
      'Cela ne ressemble pas à une adresse e-mail.';

  @override
  String get errorPasswordEmpty => 'Saisissez votre mot de passe.';

  @override
  String errorPasswordTooShort(int min) {
    return 'Utilisez au moins $min caractères.';
  }

  @override
  String get errorContactNameEmpty => 'Donnez un nom au contact.';

  @override
  String get errorLabelNameEmpty => 'Donnez un nom à l\'étiquette.';

  @override
  String get errorHouseholdNameEmpty => 'Donnez un nom au foyer.';

  @override
  String get errorDisplayNameEmpty =>
      'Saisissez le nom que verront les autres.';

  @override
  String errorTextTooLong(int max) {
    return 'Restez sous $max caractères.';
  }

  @override
  String errorTooManyTags(int max) {
    return 'Utilisez au plus $max tags.';
  }

  @override
  String errorTagTooLong(int max) {
    return 'Chaque tag doit faire moins de $max caractères.';
  }

  @override
  String get errorCadenceEmpty => 'Indiquez le nombre de jours.';

  @override
  String get errorCadenceNotANumber => 'Utilisez un nombre entier de jours.';

  @override
  String errorCadenceTooShort(int min) {
    return 'Utilisez au moins $min jour.';
  }

  @override
  String errorCadenceTooLong(int max) {
    return 'Utilisez au plus $max jours.';
  }

  @override
  String get errorBirthdayEmpty => 'Saisissez un anniversaire.';

  @override
  String get errorBirthdayUnreadable =>
      'Écrivez-le comme 14 mars ou 14 mars 1988.';

  @override
  String get errorBirthdayBadMonth => 'Ce n\'est pas un mois.';

  @override
  String errorBirthdayYearOutOfRange(int min, int max) {
    return 'Utilisez une année entre $min et $max.';
  }

  @override
  String errorBirthdayNoSuchDay(String month, int day) {
    return 'Il n\'y a pas de $day $month.';
  }

  @override
  String get errorInviteCodeEmpty => 'Saisissez un code d\'invitation.';

  @override
  String errorInviteCodeWrongLength(int length) {
    return 'Les codes d\'invitation comptent $length caractères.';
  }

  @override
  String errorInviteCodeBadCharacter(String char) {
    return '« $char » ne fait pas partie d\'un code d\'invitation.';
  }

  @override
  String get cadenceDaily => 'Quotidien';

  @override
  String get cadenceWeekly => 'Hebdomadaire';

  @override
  String get cadenceBiweekly => 'Toutes les 2 semaines';

  @override
  String get cadenceMonthly => 'Mensuel';

  @override
  String get cadenceQuarterly => 'Tous les 3 mois';

  @override
  String get cadenceTwiceAYear => 'Deux fois par an';

  @override
  String cadenceEveryDays(int days) {
    return 'Tous les $days jours';
  }

  @override
  String get cadencePhraseDaily => 'tous les jours';

  @override
  String get cadencePhraseWeekly => 'chaque semaine';

  @override
  String get cadencePhraseBiweekly => 'toutes les 2 semaines';

  @override
  String get cadencePhraseMonthly => 'chaque mois';

  @override
  String get cadencePhraseQuarterly => 'tous les 3 mois';

  @override
  String get cadencePhraseTwiceAYear => 'deux fois par an';

  @override
  String cadencePhraseEveryDays(int days) {
    return 'tous les $days jours';
  }

  @override
  String get dayToday => 'Aujourd\'hui';

  @override
  String get dayYesterday => 'Hier';

  @override
  String get dayTomorrow => 'Demain';

  @override
  String dayFull(String weekday, int day, String month) {
    return '$weekday $day $month';
  }

  @override
  String dayFullWithYear(String date, int year) {
    return '$date $year';
  }

  @override
  String get weekdayMon => 'lun';

  @override
  String get weekdayTue => 'mar';

  @override
  String get weekdayWed => 'mer';

  @override
  String get weekdayThu => 'jeu';

  @override
  String get weekdayFri => 'ven';

  @override
  String get weekdaySat => 'sam';

  @override
  String get weekdaySun => 'dim';

  @override
  String get monthJan => 'janv';

  @override
  String get monthFeb => 'févr';

  @override
  String get monthMar => 'mars';

  @override
  String get monthApr => 'avr';

  @override
  String get monthMay => 'mai';

  @override
  String get monthJun => 'juin';

  @override
  String get monthJul => 'juil';

  @override
  String get monthAug => 'août';

  @override
  String get monthSep => 'sept';

  @override
  String get monthOct => 'oct';

  @override
  String get monthNov => 'nov';

  @override
  String get monthDec => 'déc';

  @override
  String get monthFullJan => 'janvier';

  @override
  String get monthFullFeb => 'février';

  @override
  String get monthFullMar => 'mars';

  @override
  String get monthFullApr => 'avril';

  @override
  String get monthFullMay => 'mai';

  @override
  String get monthFullJun => 'juin';

  @override
  String get monthFullJul => 'juillet';

  @override
  String get monthFullAug => 'août';

  @override
  String get monthFullSep => 'septembre';

  @override
  String get monthFullOct => 'octobre';

  @override
  String get monthFullNov => 'novembre';

  @override
  String get monthFullDec => 'décembre';

  @override
  String get seenNever => 'Aucune rencontre';

  @override
  String get seenToday => 'Dernière fois aujourd\'hui';

  @override
  String get seenYesterday => 'Dernière fois hier';

  @override
  String seenDaysAgo(int days) {
    return 'Dernière fois il y a $days jours';
  }

  @override
  String get seenLastWeek => 'Dernière fois la semaine dernière';

  @override
  String seenAgo(String elapsed) {
    return 'Dernière fois il y a $elapsed';
  }

  @override
  String get elapsedLessThanADay => 'moins d\'un jour';

  @override
  String get elapsedADay => 'un jour';

  @override
  String elapsedDays(int days) {
    return '$days jours';
  }

  @override
  String get elapsedAWeek => 'une semaine';

  @override
  String elapsedWeeks(int weeks) {
    return '$weeks semaines';
  }

  @override
  String elapsedMonths(int months) {
    return '$months mois';
  }

  @override
  String elapsedYears(int years) {
    return 'plus de $years ans';
  }

  @override
  String reasonNothingLogged(String name) {
    return 'Rien d\'enregistré avec $name pour l\'instant.';
  }

  @override
  String reasonOverdue(String elapsed, String name, String cadence) {
    return 'Ça fait $elapsed : vous voyez $name $cadence d\'habitude.';
  }

  @override
  String get sortByName => 'Nom';

  @override
  String get sortByRecentlyAdded => 'Ajoutés récemment';

  @override
  String get sortByCadence => 'Fréquence';

  @override
  String get sortByFreshness => 'Fraîcheur';

  @override
  String get snoozeButton => 'Reporter';

  @override
  String get dismissButton => 'Ignorer';

  @override
  String get whenToday => 'aujourd\'hui';

  @override
  String get whenTomorrow => 'demain';

  @override
  String whenOnDay(String date) {
    return 'le $date';
  }

  @override
  String birthdayHeadline(String name, String when) {
    return 'L\'anniversaire de $name est $when.';
  }

  @override
  String birthdayHeadlineTurning(String name, int age, String when) {
    return '$name fête ses $age ans $when.';
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
      other: '$count personnes à revoir',
      one: '1 personne à revoir',
    );
    return '$_temp0';
  }

  @override
  String digestTitleBirthdays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anniversaires cette semaine',
      one: '1 anniversaire cette semaine',
    );
    return '$_temp0';
  }

  @override
  String digestSentence(String names) {
    return '$names.';
  }

  @override
  String digestBirthdayList(String names) {
    return 'Anniversaires cette semaine : $names.';
  }

  @override
  String nameListPair(String first, String second) {
    return '$first et $second';
  }

  @override
  String get nameListSeparator => ', ';

  @override
  String get errorOffline =>
      'Vous semblez hors ligne. Réessayez une fois connecté.';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String get errorSignInAgain => 'Reconnectez-vous pour continuer.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get undoButton => 'Annuler l\'action';

  @override
  String get onboardingJoinTitle => 'Rejoindre un foyer';

  @override
  String get onboardingCreateTitle => 'Créer un foyer';

  @override
  String get onboardingJoinSubtitle =>
      'Saisissez le code d\'invitation de la personne qui a créé le vôtre.';

  @override
  String get onboardingCreateSubtitle =>
      'Vous pourrez ensuite inviter le reste de votre foyer.';

  @override
  String get inviteCodeLabel => 'Code d\'invitation';

  @override
  String get householdNameLabel => 'Nom du foyer';

  @override
  String get householdNameHint => 'Maison Marx';

  @override
  String get yourNameLabel => 'Votre nom';

  @override
  String get yourNameHelper => 'Ce que verra le reste du foyer.';

  @override
  String get joinButton => 'Rejoindre';

  @override
  String get createHouseholdButton => 'Créer le foyer';

  @override
  String get toggleStartInstead => 'Créer plutôt un nouveau foyer';

  @override
  String get toggleHaveCode => 'J\'ai un code d\'invitation';

  @override
  String get householdUnreachableTitle => 'Impossible d\'accéder à votre foyer';

  @override
  String get householdFailureNotFound =>
      'Ce code ne correspond à aucun foyer. Vérifiez-le et réessayez.';

  @override
  String get householdFailureValidation =>
      'Vérifiez ce que vous avez saisi et réessayez.';

  @override
  String get householdFailureConflict =>
      'Quelque chose a interféré. Réessayez.';

  @override
  String get householdTitle => 'Foyer';

  @override
  String get householdGone => 'Ce foyer n\'existe plus.';

  @override
  String get inviteCodeCopied => 'Code d\'invitation copié.';

  @override
  String get noInviteCode =>
      'Ce foyer n\'a pas de code d\'invitation pour le moment.';

  @override
  String get shareToAdd => 'Partagez-le pour ajouter quelqu\'un.';

  @override
  String get copyInviteCode => 'Copier le code d\'invitation';

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get calendarNotLinked => 'Non lié';

  @override
  String calendarPlansGoOn(String name) {
    return 'Les plans vont sur « $name »';
  }

  @override
  String membersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String get ownerChip => 'Propriétaire';

  @override
  String get weeklyDigestTitle => 'Résumé hebdomadaire';

  @override
  String get digestOff => 'Désactivé';

  @override
  String digestDayAt(String day, String hour) {
    return '$day à $hour';
  }

  @override
  String get digestDay => 'Jour';

  @override
  String get digestTime => 'Heure';

  @override
  String get notificationsOff =>
      'Les notifications de Kith sont désactivées. Activez-les dans les réglages du téléphone, puis réessayez.';

  @override
  String get digestFailureNetwork =>
      'Le réglage du résumé n\'a pas pu être enregistré. Réessayez une fois connecté.';

  @override
  String get digestFailurePermission =>
      'Vous ne pouvez pas modifier ce foyer. Demandez à la personne qui l\'a créé.';

  @override
  String get digestFailureNotFound => 'Ce foyer n\'est plus là.';

  @override
  String get digestFailureConflict => 'Cela a été modifié ailleurs. Réessayez.';

  @override
  String get digestFailureUnknown =>
      'Le résumé n\'a pas pu être configuré sur cet appareil.';

  @override
  String get weekdayFullMon => 'lundi';

  @override
  String get weekdayFullTue => 'mardi';

  @override
  String get weekdayFullWed => 'mercredi';

  @override
  String get weekdayFullThu => 'jeudi';

  @override
  String get weekdayFullFri => 'vendredi';

  @override
  String get weekdayFullSat => 'samedi';

  @override
  String get weekdayFullSun => 'dimanche';

  @override
  String get hourAm => 'am';

  @override
  String get hourPm => 'pm';

  @override
  String hourLabel(int twelve, String suffix, int hour24) {
    return '$hour24 h';
  }

  @override
  String get householdCalendarTitle => 'Calendrier du foyer';

  @override
  String get calendarNoneLinkedBody =>
      'Aucun calendrier lié. Les plans restent dans Kith et ne vont nulle part ailleurs.';

  @override
  String calendarLinkedBody(String name) {
    return 'Les plans vont sur « $name ». Tout ce qui est abonné à ce calendrier, cadre compris, les affiche aussi.';
  }

  @override
  String get unlinkButton => 'Délier';

  @override
  String get calendarUnlinked =>
      'Calendrier délié. Les événements déjà dessus sont restés où ils étaient.';

  @override
  String get calendarConnectBody =>
      'Connectez votre compte Google pour choisir un calendrier. Kith lit la liste de vos calendriers existants et n\'écrit que les plans que vous faites ici.';

  @override
  String get calendarConnectButton => 'Connecter Google Agenda';

  @override
  String get calendarNoneWritable =>
      'Ce compte n\'a aucun calendrier où Kith puisse écrire. Créez-en un dans Google Agenda, ou demandez au propriétaire du calendrier du foyer de le partager avec vous.';

  @override
  String get yourCalendars => 'Vos calendriers';

  @override
  String get calendarPrimary => 'Votre propre calendrier';

  @override
  String get linkedChip => 'Lié';

  @override
  String calendarNowLinked(String name) {
    return 'Les plans vont maintenant sur « $name ».';
  }

  @override
  String get calendarFailureNetwork =>
      'Google Agenda est injoignable. Réessayez une fois connecté.';

  @override
  String get calendarFailurePermission =>
      'Kith n\'est pas autorisé à utiliser ce calendrier. Reconnectez le compte Google et choisissez un calendrier où vous pouvez écrire.';

  @override
  String get calendarFailureNotFound => 'Ce calendrier n\'est plus là.';

  @override
  String get calendarFailureConflict =>
      'Ce calendrier a été modifié ailleurs. Réessayez.';

  @override
  String get calendarFailureUnknown =>
      'Une erreur est survenue avec le calendrier. Réessayez.';

  @override
  String get calendarOutOfStep => 'Les plans peuvent différer du calendrier.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get sortTooltip => 'Trier';

  @override
  String get importTooltip => 'Importer depuis les contacts';

  @override
  String get labelsTooltip => 'Étiquettes de relation';

  @override
  String get addContactTooltip => 'Ajouter un contact';

  @override
  String get searchHint => 'Cherchez un nom, un tag ou un parent';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterArchived => 'Archivés';

  @override
  String get noLabel => 'Sans étiquette';

  @override
  String get emptyNeedsLabel =>
      'Ajoutez d\'abord une étiquette de relation, pour que les contacts aient une place.';

  @override
  String get manageLabels => 'Gérer les étiquettes';

  @override
  String get emptyNoContacts =>
      'Personne pour l\'instant. Ajoutez le premier contact.';

  @override
  String get emptyFiltered => 'Rien ne correspond à votre recherche.';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get contactFailurePermission =>
      'Vous ne pouvez pas modifier ce foyer.';

  @override
  String get contactFailureNotFound =>
      'Ce n\'est plus là. Revenez en arrière et réessayez.';

  @override
  String get contactFailureConflict => 'Cette étiquette existe déjà.';

  @override
  String get addContactTitle => 'Ajouter un contact';

  @override
  String get editContactTitle => 'Modifier le contact';

  @override
  String get contactGone => 'Ce contact n\'est plus là.';

  @override
  String get nameLabel => 'Nom';

  @override
  String get relationshipLabel => 'Relation';

  @override
  String get cadenceSection => 'À quelle fréquence vous voulez le voir';

  @override
  String get customCadenceLabel => 'Tous les combien de jours';

  @override
  String get customCadenceChip => 'Personnalisé';

  @override
  String get prioritySection => 'Priorité';

  @override
  String get priorityLow => 'Basse';

  @override
  String get priorityNormal => 'Normale';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get reachSection => 'Comment le joindre';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get addressLabel => 'Adresse';

  @override
  String get guardianSection => 'Parent ou tuteur';

  @override
  String get guardianHelper =>
      'Pour l\'ami d\'un enfant, la personne à qui vous écrivez vraiment.';

  @override
  String get guardianNameLabel => 'Nom du parent';

  @override
  String get guardianPhoneLabel => 'Téléphone du parent';

  @override
  String get birthdayFieldLabel => 'Anniversaire';

  @override
  String get birthdayFieldHelper =>
      'Comme 14 mars ou 14 mars 1988. L\'année est facultative.';

  @override
  String get tagsLabel => 'Tags';

  @override
  String get tagsHelper => 'Séparez les tags par des virgules.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get seeTheirHangouts => 'Voir ses rencontres';

  @override
  String get restoreContact => 'Restaurer le contact';

  @override
  String get archiveContact => 'Archiver le contact';

  @override
  String get importContactsTitle => 'Importer des contacts';

  @override
  String get importNeedsLabel =>
      'Ajoutez d\'abord une étiquette de relation, pour que les contacts importés aient une place.';

  @override
  String get importPermissionDenied =>
      'Kith ne peut pas voir vos contacts. Autorisez l\'accès dans les réglages du téléphone, puis réessayez.';

  @override
  String importDone(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts ajoutés.',
      one: '1 contact ajouté.',
    );
    return '$_temp0';
  }

  @override
  String get importNobody =>
      'Il n\'y a personne à importer dans votre carnet d\'adresses.';

  @override
  String get importFileThemAs => 'Classer comme';

  @override
  String get importSeeThem => 'Les voir';

  @override
  String get importNobodyChosen => 'Personne de choisi';

  @override
  String importChosen(int count) {
    return '$count choisis';
  }

  @override
  String get importSelectNone => 'Aucun';

  @override
  String get importSelectAll => 'Tous';

  @override
  String importButton(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importer $count contacts',
      one: 'Importer 1 contact',
    );
    return '$_temp0';
  }

  @override
  String get importIntro =>
      'Kith peut lire les contacts de votre téléphone pour que vous choisissiez qui suivre. Rien n\'est envoyé nulle part, et rien n\'est écrit dans votre carnet d\'adresses.';

  @override
  String get importChooseButton => 'Choisir dans les contacts';

  @override
  String get importAlreadyHere => 'Déjà dans Kith';

  @override
  String get importNoDetails => 'Aucun détail';

  @override
  String get labelsTitle => 'Étiquettes de relation';

  @override
  String get addLabelTooltip => 'Ajouter une étiquette';

  @override
  String get labelFieldLabel => 'Étiquette';

  @override
  String get labelsEmpty =>
      'Pas encore d\'étiquettes. Ajoutez-en une, et les contacts auront une place.';

  @override
  String renameLabelTooltip(String name) {
    return 'Renommer $name';
  }

  @override
  String deleteLabelTooltip(String name) {
    return 'Supprimer $name';
  }

  @override
  String get renameLabelTitle => 'Renommer l\'étiquette';

  @override
  String get keepOneLabel => 'Gardez au moins une étiquette pour les contacts.';

  @override
  String deleteLabelTitle(String name) {
    return 'Supprimer « $name »';
  }

  @override
  String get reassignPrompt => 'Déplacer tous ceux qui y sont classés vers :';

  @override
  String get logHangoutTitle => 'Noter une rencontre';

  @override
  String get editHangoutTitle => 'Modifier la rencontre';

  @override
  String get hangoutGone => 'Cette rencontre n\'est plus là.';

  @override
  String get hangoutNeedsContact =>
      'Ajoutez d\'abord un contact, pour qu\'il y ait quelqu\'un à avoir vu.';

  @override
  String get whenSection => 'Quand';

  @override
  String get whoYouSawSection => 'Qui vous avez vu';

  @override
  String get searchContactsHint => 'Chercher un contact';

  @override
  String get nobodyMatches => 'Personne ne correspond à votre recherche.';

  @override
  String get chooseWhoYouSaw => 'Choisissez qui vous avez vu.';

  @override
  String get whoFromHouseSection => 'Qui du foyer était là';

  @override
  String get noteLabel => 'Note';

  @override
  String get noteHelper => 'Facultatif. Ce qui valait la peine d\'être retenu.';

  @override
  String get logItButton => 'Noter';

  @override
  String get deleteHangout => 'Supprimer la rencontre';

  @override
  String get hangoutsTitle => 'Rencontres';

  @override
  String hangoutsWithTitle(String name) {
    return 'Rencontres avec $name';
  }

  @override
  String get hangoutsEmpty =>
      'Rien de noté pour l\'instant. La première rencontre ira ici.';

  @override
  String get someoneSinceRemoved => 'Quelqu\'un depuis supprimé';

  @override
  String withAttendees(String names) {
    return 'Avec $names';
  }

  @override
  String get justTheTwoOfYou => 'Rien que vous deux';

  @override
  String get hangoutFailureNotFound => 'Cette rencontre n\'est plus là.';

  @override
  String get hangoutFailureConflict =>
      'Cette rencontre a été modifiée ailleurs. Réessayez.';

  @override
  String get reconnectTitle => 'Reprendre contact';

  @override
  String birthdaysMore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de plus ce mois-ci.',
      one: '1 de plus ce mois-ci.',
    );
    return '$_temp0';
  }

  @override
  String get planItButton => 'Planifier';

  @override
  String plannedWith(String name, String day) {
    return 'Planifié avec $name pour le $day.';
  }

  @override
  String get addedToCalendar => 'Ajouté au calendrier.';

  @override
  String notAskingUntil(String name, String day) {
    return 'Plus de rappel pour $name avant le $day.';
  }

  @override
  String plannedChip(String day) {
    return 'Planifié $day';
  }

  @override
  String get reconnectAllFresh =>
      'Personne n\'est en attente. Tous ceux que vous suivez ont été vus dans la fréquence que vous avez fixée.';

  @override
  String get reconnectNoContacts =>
      'Personne pour l\'instant. Ajoutez les personnes que vous voulez garder proches et elles apparaîtront ici quand cela fera un moment.';

  @override
  String get addContactsButton => 'Ajouter des contacts';

  @override
  String get suggestionFailureNotFound => 'Ce plan n\'est plus là.';

  @override
  String get suggestionFailureConflict =>
      'Ce plan a été modifié ailleurs. Réessayez.';
}
