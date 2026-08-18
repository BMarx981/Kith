import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/features/contacts/domain/contact_view.dart';

/// Holds what the contact list is currently showing.
///
/// Only the view: the contacts themselves come from `contactsProvider`, and
/// narrowing and ordering them is [ContactView]'s pure job. Keeping the two
/// apart is what makes the list logic testable without a widget.
class ContactListController extends Notifier<ContactView> {
  @override
  ContactView build() => const ContactView();

  /// Sets the search text.
  void search(String query) => state = state.copyWith(query: query);

  /// Filters to one relationship type, or to all of them when [typeId] is
  /// null.
  void filterByType(String? typeId) => state = typeId == null
      ? state.copyWith(clearRelationshipTypeId: true)
      : state.copyWith(relationshipTypeId: typeId);

  /// Reorders the list.
  void sortBy(ContactSort sort) => state = state.copyWith(sort: sort);

  /// Shows or hides archived contacts.
  void showArchived({required bool show}) =>
      state = state.copyWith(showArchived: show);

  /// Drops every filter, keeping the chosen ordering.
  ///
  /// The sort survives because it is a preference about how you read the
  /// list, not a narrowing of it.
  void clearFilters() => state = ContactView(sort: state.sort);
}

/// What the contact list is currently showing.
final contactListControllerProvider =
    NotifierProvider<ContactListController, ContactView>(
      ContactListController.new,
    );
