// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Kith';

  @override
  String arrivesInMilestone(String milestone) {
    return 'Llega en $milestone';
  }

  @override
  String get signInTagline => 'Inicia sesión en tu hogar.';

  @override
  String get signUpTagline =>
      'Crea una cuenta y luego crea un hogar o únete a uno.';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get signInButton => 'Iniciar sesión';

  @override
  String get createAccountButton => 'Crear cuenta';

  @override
  String get forgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get toggleHaveAccount => 'Ya tengo una cuenta';

  @override
  String get toggleCreateAccount => 'Crear una cuenta';

  @override
  String passwordResetSent(String email) {
    return 'Enlace para restablecer la contraseña enviado a $email.';
  }

  @override
  String get authInvalidCredentials =>
      'Ese correo y esa contraseña no corresponden a ninguna cuenta.';

  @override
  String get authEmailAlreadyInUse =>
      'Esa dirección ya tiene una cuenta. Prueba a iniciar sesión.';

  @override
  String get authWeakPassword =>
      'Esa contraseña es demasiado fácil de adivinar. Elige una más larga.';

  @override
  String get authInvalidEmail => 'Eso no parece un correo electrónico.';

  @override
  String get authUserDisabled => 'Esa cuenta está deshabilitada.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos. Espera un minuto y vuelve a intentarlo.';

  @override
  String get authNetwork =>
      'Parece que no tienes conexión. Vuelve a intentarlo cuando estés conectado.';

  @override
  String get authProviderUnavailable =>
      'Esa forma de iniciar sesión todavía no está disponible.';

  @override
  String get authCancelled => 'Se canceló el inicio de sesión.';

  @override
  String get authAccountExistsWithDifferentCredential =>
      'Esa dirección ya tiene una cuenta. Inicia sesión como lo hiciste antes.';

  @override
  String get authUnknown => 'Algo salió mal. Vuelve a intentarlo.';

  @override
  String get errorEmailEmpty => 'Escribe tu correo electrónico.';

  @override
  String get errorEmailMalformed => 'Eso no parece un correo electrónico.';

  @override
  String get errorPasswordEmpty => 'Escribe tu contraseña.';

  @override
  String errorPasswordTooShort(int min) {
    return 'Usa al menos $min caracteres.';
  }

  @override
  String get errorContactNameEmpty => 'Ponle un nombre al contacto.';

  @override
  String get errorLabelNameEmpty => 'Ponle un nombre a la etiqueta.';

  @override
  String get errorHouseholdNameEmpty => 'Ponle un nombre al hogar.';

  @override
  String get errorDisplayNameEmpty => 'Escribe el nombre que verán los demás.';

  @override
  String errorTextTooLong(int max) {
    return 'No pases de $max caracteres.';
  }

  @override
  String errorTooManyTags(int max) {
    return 'Usa como máximo $max etiquetas.';
  }

  @override
  String errorTagTooLong(int max) {
    return 'Cada etiqueta debe tener menos de $max caracteres.';
  }

  @override
  String get errorCadenceEmpty => 'Indica cuántos días.';

  @override
  String get errorCadenceNotANumber => 'Usa un número entero de días.';

  @override
  String errorCadenceTooShort(int min) {
    return 'Usa al menos $min día.';
  }

  @override
  String errorCadenceTooLong(int max) {
    return 'Usa como máximo $max días.';
  }

  @override
  String get errorBirthdayEmpty => 'Escribe un cumpleaños.';

  @override
  String get errorBirthdayUnreadable => 'Escríbelo como 14 mar o 14 mar 1988.';

  @override
  String get errorBirthdayBadMonth => 'Eso no es un mes.';

  @override
  String errorBirthdayYearOutOfRange(int min, int max) {
    return 'Usa un año entre $min y $max.';
  }

  @override
  String errorBirthdayNoSuchDay(String month, int day) {
    return '$month no tiene día $day.';
  }

  @override
  String get errorInviteCodeEmpty => 'Escribe un código de invitación.';

  @override
  String errorInviteCodeWrongLength(int length) {
    return 'Los códigos de invitación tienen $length caracteres.';
  }

  @override
  String errorInviteCodeBadCharacter(String char) {
    return '\"$char\" no forma parte de un código de invitación.';
  }

  @override
  String get cadenceDaily => 'A diario';

  @override
  String get cadenceWeekly => 'Semanal';

  @override
  String get cadenceBiweekly => 'Cada 2 semanas';

  @override
  String get cadenceMonthly => 'Mensual';

  @override
  String get cadenceQuarterly => 'Cada 3 meses';

  @override
  String get cadenceTwiceAYear => 'Dos veces al año';

  @override
  String cadenceEveryDays(int days) {
    return 'Cada $days días';
  }

  @override
  String get cadencePhraseDaily => 'a diario';

  @override
  String get cadencePhraseWeekly => 'cada semana';

  @override
  String get cadencePhraseBiweekly => 'cada 2 semanas';

  @override
  String get cadencePhraseMonthly => 'cada mes';

  @override
  String get cadencePhraseQuarterly => 'cada 3 meses';

  @override
  String get cadencePhraseTwiceAYear => 'dos veces al año';

  @override
  String cadencePhraseEveryDays(int days) {
    return 'cada $days días';
  }

  @override
  String get dayToday => 'Hoy';

  @override
  String get dayYesterday => 'Ayer';

  @override
  String get dayTomorrow => 'Mañana';

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
  String get weekdayWed => 'mié';

  @override
  String get weekdayThu => 'jue';

  @override
  String get weekdayFri => 'vie';

  @override
  String get weekdaySat => 'sáb';

  @override
  String get weekdaySun => 'dom';

  @override
  String get monthJan => 'ene';

  @override
  String get monthFeb => 'feb';

  @override
  String get monthMar => 'mar';

  @override
  String get monthApr => 'abr';

  @override
  String get monthMay => 'may';

  @override
  String get monthJun => 'jun';

  @override
  String get monthJul => 'jul';

  @override
  String get monthAug => 'ago';

  @override
  String get monthSep => 'sep';

  @override
  String get monthOct => 'oct';

  @override
  String get monthNov => 'nov';

  @override
  String get monthDec => 'dic';

  @override
  String get monthFullJan => 'enero';

  @override
  String get monthFullFeb => 'febrero';

  @override
  String get monthFullMar => 'marzo';

  @override
  String get monthFullApr => 'abril';

  @override
  String get monthFullMay => 'mayo';

  @override
  String get monthFullJun => 'junio';

  @override
  String get monthFullJul => 'julio';

  @override
  String get monthFullAug => 'agosto';

  @override
  String get monthFullSep => 'septiembre';

  @override
  String get monthFullOct => 'octubre';

  @override
  String get monthFullNov => 'noviembre';

  @override
  String get monthFullDec => 'diciembre';

  @override
  String get seenNever => 'Sin registros';

  @override
  String get seenToday => 'Última vez hoy';

  @override
  String get seenYesterday => 'Última vez ayer';

  @override
  String seenDaysAgo(int days) {
    return 'Última vez hace $days días';
  }

  @override
  String get seenLastWeek => 'Última vez la semana pasada';

  @override
  String seenAgo(String elapsed) {
    return 'Última vez hace $elapsed';
  }

  @override
  String get elapsedLessThanADay => 'menos de un día';

  @override
  String get elapsedADay => 'un día';

  @override
  String elapsedDays(int days) {
    return '$days días';
  }

  @override
  String get elapsedAWeek => 'una semana';

  @override
  String elapsedWeeks(int weeks) {
    return '$weeks semanas';
  }

  @override
  String elapsedMonths(int months) {
    return '$months meses';
  }

  @override
  String elapsedYears(int years) {
    return 'más de $years años';
  }

  @override
  String reasonNothingLogged(String name) {
    return 'Todavía no hay nada registrado con $name.';
  }

  @override
  String reasonOverdue(String elapsed, String name, String cadence) {
    return 'Han pasado $elapsed: sueles ver a $name $cadence.';
  }

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByRecentlyAdded => 'Añadidos recientemente';

  @override
  String get sortByCadence => 'Frecuencia';

  @override
  String get sortByFreshness => 'Frescura';

  @override
  String get snoozeButton => 'Posponer';

  @override
  String get dismissButton => 'Descartar';

  @override
  String get whenToday => 'hoy';

  @override
  String get whenTomorrow => 'mañana';

  @override
  String whenOnDay(String date) {
    return 'el $date';
  }

  @override
  String birthdayHeadline(String name, String when) {
    return 'El cumpleaños de $name es $when.';
  }

  @override
  String birthdayHeadlineTurning(String name, int age, String when) {
    return '$name cumple $age años $when.';
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
      other: '$count personas pendientes de ver',
      one: '1 persona pendiente de ver',
    );
    return '$_temp0';
  }

  @override
  String digestTitleBirthdays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cumpleaños esta semana',
      one: '1 cumpleaños esta semana',
    );
    return '$_temp0';
  }

  @override
  String digestSentence(String names) {
    return '$names.';
  }

  @override
  String digestBirthdayList(String names) {
    return 'Cumpleaños esta semana: $names.';
  }

  @override
  String nameListPair(String first, String second) {
    return '$first y $second';
  }

  @override
  String get nameListSeparator => ', ';

  @override
  String get errorOffline =>
      'Parece que no tienes conexión. Vuelve a intentarlo cuando estés conectado.';

  @override
  String get errorGeneric => 'Algo salió mal. Vuelve a intentarlo.';

  @override
  String get errorSignInAgain => 'Inicia sesión de nuevo para continuar.';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get undoButton => 'Deshacer';

  @override
  String get onboardingJoinTitle => 'Únete a un hogar';

  @override
  String get onboardingCreateTitle => 'Crea un hogar';

  @override
  String get onboardingJoinSubtitle =>
      'Escribe el código de invitación de quien creó el vuestro.';

  @override
  String get onboardingCreateSubtitle =>
      'Después podrás invitar al resto de tu hogar.';

  @override
  String get inviteCodeLabel => 'Código de invitación';

  @override
  String get householdNameLabel => 'Nombre del hogar';

  @override
  String get householdNameHint => 'Casa Marx';

  @override
  String get yourNameLabel => 'Tu nombre';

  @override
  String get yourNameHelper => 'Lo que verá el resto del hogar.';

  @override
  String get joinButton => 'Unirse';

  @override
  String get createHouseholdButton => 'Crear hogar';

  @override
  String get toggleStartInstead => 'Mejor crear un hogar nuevo';

  @override
  String get toggleHaveCode => 'Tengo un código de invitación';

  @override
  String get householdUnreachableTitle => 'No se puede acceder a tu hogar';

  @override
  String get householdFailureNotFound =>
      'Ese código no corresponde a ningún hogar. Compruébalo y vuelve a intentarlo.';

  @override
  String get householdFailureValidation =>
      'Revisa lo que escribiste y vuelve a intentarlo.';

  @override
  String get householdFailureConflict =>
      'Algo se interpuso. Vuelve a intentarlo.';

  @override
  String get householdTitle => 'Hogar';

  @override
  String get householdGone => 'Este hogar ya no existe.';

  @override
  String get inviteCodeCopied => 'Código de invitación copiado.';

  @override
  String get noInviteCode =>
      'Este hogar no tiene código de invitación ahora mismo.';

  @override
  String get shareToAdd => 'Compártelo para añadir a alguien.';

  @override
  String get copyInviteCode => 'Copiar código de invitación';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String get calendarNotLinked => 'Sin vincular';

  @override
  String calendarPlansGoOn(String name) {
    return 'Los planes van a \"$name\"';
  }

  @override
  String membersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get ownerChip => 'Propietario';

  @override
  String get weeklyDigestTitle => 'Resumen semanal';

  @override
  String get digestChannelDescription =>
      'Un resumen semanal de a quién llevas tiempo sin ver.';

  @override
  String get digestOff => 'Desactivado';

  @override
  String digestDayAt(String day, String hour) {
    return '$day a las $hour';
  }

  @override
  String get digestDay => 'Día';

  @override
  String get digestTime => 'Hora';

  @override
  String get notificationsOff =>
      'Las notificaciones de Kith están desactivadas. Actívalas en los ajustes del teléfono y vuelve a intentarlo.';

  @override
  String get digestFailureNetwork =>
      'No se pudo guardar el ajuste del resumen. Vuelve a intentarlo cuando estés conectado.';

  @override
  String get digestFailurePermission =>
      'No puedes cambiar este hogar. Pregunta a quien lo creó.';

  @override
  String get digestFailureNotFound => 'Este hogar ya no está aquí.';

  @override
  String get digestFailureConflict =>
      'Eso se cambió en otro sitio. Vuelve a intentarlo.';

  @override
  String get digestFailureUnknown =>
      'No se pudo configurar el resumen en este dispositivo.';

  @override
  String get weekdayFullMon => 'lunes';

  @override
  String get weekdayFullTue => 'martes';

  @override
  String get weekdayFullWed => 'miércoles';

  @override
  String get weekdayFullThu => 'jueves';

  @override
  String get weekdayFullFri => 'viernes';

  @override
  String get weekdayFullSat => 'sábado';

  @override
  String get weekdayFullSun => 'domingo';

  @override
  String get hourAm => 'a. m.';

  @override
  String get hourPm => 'p. m.';

  @override
  String hourLabel(int twelve, String suffix, int hour24) {
    return '$hour24:00';
  }

  @override
  String get householdCalendarTitle => 'Calendario del hogar';

  @override
  String get calendarNoneLinkedBody =>
      'Ningún calendario vinculado. Los planes se quedan en Kith y no van a ningún otro sitio.';

  @override
  String calendarLinkedBody(String name) {
    return 'Los planes van a \"$name\". Todo lo que esté suscrito a ese calendario, incluido el marco, también los muestra.';
  }

  @override
  String get unlinkButton => 'Desvincular';

  @override
  String get calendarUnlinked =>
      'Calendario desvinculado. Los eventos que ya estaban en él se quedaron donde estaban.';

  @override
  String get calendarConnectBody =>
      'Conecta tu cuenta de Google para elegir un calendario. Kith lee la lista de calendarios que ya tienes y solo escribe los planes que hagas aquí.';

  @override
  String get calendarConnectButton => 'Conectar Google Calendar';

  @override
  String get calendarNoneWritable =>
      'Esta cuenta no tiene ningún calendario en el que Kith pueda escribir. Crea uno en Google Calendar, o pide a quien tenga el calendario del hogar que lo comparta contigo.';

  @override
  String get yourCalendars => 'Tus calendarios';

  @override
  String get calendarPrimary => 'Tu propio calendario';

  @override
  String get linkedChip => 'Vinculado';

  @override
  String calendarNowLinked(String name) {
    return 'Los planes ahora van a \"$name\".';
  }

  @override
  String get calendarFailureNetwork =>
      'No se pudo acceder a Google Calendar. Vuelve a intentarlo cuando estés conectado.';

  @override
  String get calendarFailurePermission =>
      'Kith no tiene permiso para usar ese calendario. Vuelve a conectar la cuenta de Google y elige un calendario en el que puedas escribir.';

  @override
  String get calendarFailureNotFound => 'Ese calendario ya no está.';

  @override
  String get calendarFailureConflict =>
      'Ese calendario se cambió en otro sitio. Vuelve a intentarlo.';

  @override
  String get calendarFailureUnknown =>
      'Algo salió mal con el calendario. Vuelve a intentarlo.';

  @override
  String get calendarOutOfStep =>
      'Los planes pueden no coincidir con el calendario.';

  @override
  String get contactsTitle => 'Contactos';

  @override
  String get sortTooltip => 'Ordenar';

  @override
  String get importTooltip => 'Importar de contactos';

  @override
  String get labelsTooltip => 'Etiquetas de relación';

  @override
  String get addContactTooltip => 'Añadir un contacto';

  @override
  String get searchHint => 'Busca nombres, etiquetas o un tutor';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterArchived => 'Archivados';

  @override
  String get noLabel => 'Sin etiqueta';

  @override
  String get emptyNeedsLabel =>
      'Añade primero una etiqueta de relación, para que los contactos tengan dónde ir.';

  @override
  String get manageLabels => 'Gestionar etiquetas';

  @override
  String get emptyNoContacts => 'Aún no hay nadie. Añade el primer contacto.';

  @override
  String get emptyFiltered => 'Nada coincide con lo que buscas.';

  @override
  String get clearFilters => 'Quitar filtros';

  @override
  String get contactFailurePermission => 'No puedes cambiar este hogar.';

  @override
  String get contactFailureNotFound =>
      'Eso ya no está. Vuelve atrás y prueba otra vez.';

  @override
  String get contactFailureConflict => 'Esa etiqueta ya existe.';

  @override
  String get addContactTitle => 'Añadir un contacto';

  @override
  String get editContactTitle => 'Editar contacto';

  @override
  String get contactGone => 'Ese contacto ya no está aquí.';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get relationshipLabel => 'Relación';

  @override
  String get cadenceSection => 'Cada cuánto quieres verle';

  @override
  String get customCadenceLabel => 'Cada cuántos días';

  @override
  String get customCadenceChip => 'Personalizado';

  @override
  String get prioritySection => 'Prioridad';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get reachSection => 'Cómo contactarle';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get guardianSection => 'Padre, madre o tutor';

  @override
  String get guardianHelper =>
      'Para el amigo de un niño, la persona a la que realmente escribes.';

  @override
  String get guardianNameLabel => 'Nombre del tutor';

  @override
  String get guardianPhoneLabel => 'Teléfono del tutor';

  @override
  String get birthdayFieldLabel => 'Cumpleaños';

  @override
  String get birthdayFieldHelper =>
      'Como 14 mar o 14 mar 1988. El año es opcional.';

  @override
  String get tagsLabel => 'Etiquetas';

  @override
  String get tagsHelper => 'Separa las etiquetas con comas.';

  @override
  String get notesLabel => 'Notas';

  @override
  String get seeTheirHangouts => 'Ver sus encuentros';

  @override
  String get restoreContact => 'Restaurar contacto';

  @override
  String get archiveContact => 'Archivar contacto';

  @override
  String get importContactsTitle => 'Importar contactos';

  @override
  String get importNeedsLabel =>
      'Añade primero una etiqueta de relación, para que los contactos importados tengan dónde ir.';

  @override
  String get importPermissionDenied =>
      'Kith no puede ver tus contactos. Permite el acceso en los ajustes del teléfono y vuelve a intentarlo.';

  @override
  String importDone(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contactos añadidos.',
      one: '1 contacto añadido.',
    );
    return '$_temp0';
  }

  @override
  String get importNobody => 'No hay nadie en tu agenda que importar.';

  @override
  String get importFileThemAs => 'Archivar como';

  @override
  String get importSeeThem => 'Verles';

  @override
  String get importNobodyChosen => 'Nadie elegido';

  @override
  String importChosen(int count) {
    return '$count elegidos';
  }

  @override
  String get importSelectNone => 'Ninguno';

  @override
  String get importSelectAll => 'Todos';

  @override
  String importButton(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count contactos',
      one: 'Importar 1 contacto',
    );
    return '$_temp0';
  }

  @override
  String get importIntro =>
      'Kith puede leer los contactos de tu teléfono para que elijas a quién seguir. No se envía nada a ninguna parte, y no se escribe nada en tu agenda.';

  @override
  String get importChooseButton => 'Elegir de contactos';

  @override
  String get importAlreadyHere => 'Ya está en Kith';

  @override
  String get importNoDetails => 'Sin detalles';

  @override
  String get labelsTitle => 'Etiquetas de relación';

  @override
  String get addLabelTooltip => 'Añadir una etiqueta';

  @override
  String get labelFieldLabel => 'Etiqueta';

  @override
  String get labelsEmpty =>
      'Aún no hay etiquetas. Añade una y los contactos tendrán dónde ir.';

  @override
  String renameLabelTooltip(String name) {
    return 'Renombrar $name';
  }

  @override
  String deleteLabelTooltip(String name) {
    return 'Eliminar $name';
  }

  @override
  String get renameLabelTitle => 'Renombrar etiqueta';

  @override
  String get keepOneLabel =>
      'Conserva al menos una etiqueta para los contactos.';

  @override
  String deleteLabelTitle(String name) {
    return 'Eliminar \"$name\"';
  }

  @override
  String get reassignPrompt => 'Mover a todos los que están bajo ella a:';

  @override
  String get logHangoutTitle => 'Registrar un encuentro';

  @override
  String get editHangoutTitle => 'Editar encuentro';

  @override
  String get hangoutGone => 'Ese encuentro ya no está aquí.';

  @override
  String get hangoutNeedsContact =>
      'Añade primero un contacto, para que haya alguien a quien haber visto.';

  @override
  String get whenSection => 'Cuándo';

  @override
  String get whoYouSawSection => 'A quién viste';

  @override
  String get searchContactsHint => 'Buscar contactos';

  @override
  String get nobodyMatches => 'Nadie coincide con lo que buscas.';

  @override
  String get chooseWhoYouSaw => 'Elige a quién viste.';

  @override
  String get whoFromHouseSection => 'Quién de la casa estuvo';

  @override
  String get noteLabel => 'Nota';

  @override
  String get noteHelper => 'Opcional. Lo que lo hizo digno de recordar.';

  @override
  String get logItButton => 'Registrar';

  @override
  String get deleteHangout => 'Eliminar encuentro';

  @override
  String get hangoutsTitle => 'Encuentros';

  @override
  String hangoutsWithTitle(String name) {
    return 'Encuentros con $name';
  }

  @override
  String get hangoutsEmpty =>
      'Aún no hay nada registrado. El primer encuentro va aquí.';

  @override
  String get someoneSinceRemoved => 'Alguien ya eliminado';

  @override
  String withAttendees(String names) {
    return 'Con $names';
  }

  @override
  String get justTheTwoOfYou => 'Solo vosotros dos';

  @override
  String get hangoutFailureNotFound => 'Ese encuentro ya no está.';

  @override
  String get hangoutFailureConflict =>
      'Ese encuentro se cambió en otro sitio. Vuelve a intentarlo.';

  @override
  String get reconnectTitle => 'Reconectar';

  @override
  String birthdaysMore(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count más este mes.',
      one: '1 más este mes.',
    );
    return '$_temp0';
  }

  @override
  String get planItButton => 'Planearlo';

  @override
  String plannedWith(String name, String day) {
    return 'Planeado con $name para el $day.';
  }

  @override
  String get addedToCalendar => 'Añadido al calendario.';

  @override
  String notAskingUntil(String name, String day) {
    return 'No preguntaremos por $name hasta el $day.';
  }

  @override
  String plannedChip(String day) {
    return 'Planeado $day';
  }

  @override
  String get reconnectAllFresh =>
      'No hay nadie pendiente. A todos los que sigues les has visto dentro de la frecuencia que fijaste.';

  @override
  String get reconnectNoContacts =>
      'Aún no hay nadie. Añade a las personas con las que quieres mantener el contacto y aparecerán aquí cuando haga tiempo que no las ves.';

  @override
  String get addContactsButton => 'Añadir contactos';

  @override
  String get suggestionFailureNotFound => 'Ese plan ya no está.';

  @override
  String get suggestionFailureConflict =>
      'Ese plan se cambió en otro sitio. Vuelve a intentarlo.';
}
