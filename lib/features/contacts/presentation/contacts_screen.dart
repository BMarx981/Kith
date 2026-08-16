import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';

/// The household's contact list, sortable by freshness.
@RoutePage()
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MilestonePlaceholder(
      title: 'Contacts',
      milestone: 'M2',
      icon: Icons.people_outline,
    );
  }
}
