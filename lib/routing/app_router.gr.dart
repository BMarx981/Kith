// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CalendarSettingsScreen]
class CalendarSettingsRoute extends PageRouteInfo<void> {
  const CalendarSettingsRoute({List<PageRouteInfo>? children})
    : super(CalendarSettingsRoute.name, initialChildren: children);

  static const String name = 'CalendarSettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CalendarSettingsScreen();
    },
  );
}

/// generated route for
/// [ContactEditorScreen]
class ContactEditorRoute extends PageRouteInfo<ContactEditorRouteArgs> {
  ContactEditorRoute({
    String? contactId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ContactEditorRoute.name,
         args: ContactEditorRouteArgs(contactId: contactId, key: key),
         rawPathParams: {'contactId': contactId},
         initialChildren: children,
       );

  static const String name = 'ContactEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ContactEditorRouteArgs>(
        orElse: () => ContactEditorRouteArgs(
          contactId: pathParams.optString('contactId'),
        ),
      );
      return ContactEditorScreen(contactId: args.contactId, key: args.key);
    },
  );
}

class ContactEditorRouteArgs {
  const ContactEditorRouteArgs({this.contactId, this.key});

  final String? contactId;

  final Key? key;

  @override
  String toString() {
    return 'ContactEditorRouteArgs{contactId: $contactId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ContactEditorRouteArgs) return false;
    return contactId == other.contactId && key == other.key;
  }

  @override
  int get hashCode => contactId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ContactsScreen]
class ContactsRoute extends PageRouteInfo<void> {
  const ContactsRoute({List<PageRouteInfo>? children})
    : super(ContactsRoute.name, initialChildren: children);

  static const String name = 'ContactsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ContactsScreen();
    },
  );
}

/// generated route for
/// [HangoutEditorScreen]
class HangoutEditorRoute extends PageRouteInfo<HangoutEditorRouteArgs> {
  HangoutEditorRoute({
    String? hangoutId,
    String? prefilledContactId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         HangoutEditorRoute.name,
         args: HangoutEditorRouteArgs(
           hangoutId: hangoutId,
           prefilledContactId: prefilledContactId,
           key: key,
         ),
         rawPathParams: {'hangoutId': hangoutId},
         rawQueryParams: {'contact': prefilledContactId},
         initialChildren: children,
       );

  static const String name = 'HangoutEditorRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<HangoutEditorRouteArgs>(
        orElse: () => HangoutEditorRouteArgs(
          hangoutId: pathParams.optString('hangoutId'),
          prefilledContactId: queryParams.optString('contact'),
        ),
      );
      return HangoutEditorScreen(
        hangoutId: args.hangoutId,
        prefilledContactId: args.prefilledContactId,
        key: args.key,
      );
    },
  );
}

class HangoutEditorRouteArgs {
  const HangoutEditorRouteArgs({
    this.hangoutId,
    this.prefilledContactId,
    this.key,
  });

  final String? hangoutId;

  final String? prefilledContactId;

  final Key? key;

  @override
  String toString() {
    return 'HangoutEditorRouteArgs{hangoutId: $hangoutId, prefilledContactId: $prefilledContactId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HangoutEditorRouteArgs) return false;
    return hangoutId == other.hangoutId &&
        prefilledContactId == other.prefilledContactId &&
        key == other.key;
  }

  @override
  int get hashCode =>
      hangoutId.hashCode ^ prefilledContactId.hashCode ^ key.hashCode;
}

/// generated route for
/// [HangoutsScreen]
class HangoutsRoute extends PageRouteInfo<HangoutsRouteArgs> {
  HangoutsRoute({String? contactId, Key? key, List<PageRouteInfo>? children})
    : super(
        HangoutsRoute.name,
        args: HangoutsRouteArgs(contactId: contactId, key: key),
        rawPathParams: {'contactId': contactId},
        initialChildren: children,
      );

  static const String name = 'HangoutsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<HangoutsRouteArgs>(
        orElse: () =>
            HangoutsRouteArgs(contactId: pathParams.optString('contactId')),
      );
      return HangoutsScreen(contactId: args.contactId, key: args.key);
    },
  );
}

class HangoutsRouteArgs {
  const HangoutsRouteArgs({this.contactId, this.key});

  final String? contactId;

  final Key? key;

  @override
  String toString() {
    return 'HangoutsRouteArgs{contactId: $contactId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HangoutsRouteArgs) return false;
    return contactId == other.contactId && key == other.key;
  }

  @override
  int get hashCode => contactId.hashCode ^ key.hashCode;
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [HouseholdOnboardingScreen]
class HouseholdOnboardingRoute extends PageRouteInfo<void> {
  const HouseholdOnboardingRoute({List<PageRouteInfo>? children})
    : super(HouseholdOnboardingRoute.name, initialChildren: children);

  static const String name = 'HouseholdOnboardingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HouseholdOnboardingScreen();
    },
  );
}

/// generated route for
/// [HouseholdScreen]
class HouseholdRoute extends PageRouteInfo<void> {
  const HouseholdRoute({List<PageRouteInfo>? children})
    : super(HouseholdRoute.name, initialChildren: children);

  static const String name = 'HouseholdRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HouseholdScreen();
    },
  );
}

/// generated route for
/// [RelationshipTypesScreen]
class RelationshipTypesRoute extends PageRouteInfo<void> {
  const RelationshipTypesRoute({List<PageRouteInfo>? children})
    : super(RelationshipTypesRoute.name, initialChildren: children);

  static const String name = 'RelationshipTypesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RelationshipTypesScreen();
    },
  );
}

/// generated route for
/// [SignInScreen]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
    : super(SignInRoute.name, initialChildren: children);

  static const String name = 'SignInRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignInScreen();
    },
  );
}
