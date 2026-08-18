import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/routing/app_router.dart';

/// Landing screen; will host the ranked "Reconnect" suggestions.
///
/// Its controls are the ways through to the contact list and to the household
/// screen, which is where the members, the invite code and sign-out live.
@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Identifies the household action to tests.
  static const householdKey = Key('home.household');

  /// Identifies the contacts action to tests.
  static const contactsKey = Key('home.contacts');

  /// Identifies the hangouts action to tests.
  static const hangoutsKey = Key('home.hangouts');

  @override
  Widget build(BuildContext context) {
    return MilestonePlaceholder(
      title: 'Reconnect',
      milestone: 'M4',
      icon: KithIcons.reconnect,
      actions: [
        IconButton(
          key: hangoutsKey,
          onPressed: () => context.router.push(HangoutsRoute()),
          icon: const Icon(KithIcons.hangout),
          tooltip: 'Hangouts',
        ),
        IconButton(
          key: contactsKey,
          onPressed: () => context.router.push(const ContactsRoute()),
          icon: const Icon(KithIcons.people),
          tooltip: 'Contacts',
        ),
        IconButton(
          key: householdKey,
          onPressed: () => context.router.push(const HouseholdRoute()),
          icon: const Icon(KithIcons.household),
          tooltip: 'Household',
        ),
      ],
    );
  }
}
