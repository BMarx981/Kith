import 'package:flutter/foundation.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';

/// How the contact list is ordered.
enum ContactSort {
  /// A to Z, ignoring case.
  name('Name'),

  /// Newest first, so someone added a minute ago is at the top.
  recentlyAdded('Recently added'),

  /// Shortest target interval first: the people you mean to see most often.
  cadence('How often'),

  /// Most overdue first, against each contact's own cadence. Contacts with
  /// nothing logged yet have no ratio to rank on and sort last.
  freshness('Freshness');

  const ContactSort(this.label);

  /// How the ordering is written in the sort menu.
  final String label;
}

/// What the contact list is currently showing.
///
/// A value rather than three loose fields so the pure view function takes one
/// argument and the list controller holds one piece of state.
@immutable
class ContactView {
  const ContactView({
    this.query = '',
    this.relationshipTypeId,
    this.sort = ContactSort.name,
    this.showArchived = false,
  });

  /// What was typed into the search field. Empty matches everything.
  final String query;

  /// Id of the relationship type being filtered to, or null for all of them.
  final String? relationshipTypeId;

  /// How the results are ordered.
  final ContactSort sort;

  /// Whether archived contacts are included.
  final bool showArchived;

  /// Whether anything is narrowing the list, which is what the screen needs
  /// to know to offer a "clear" affordance and to word its empty state.
  bool get isFiltered =>
      query.trim().isNotEmpty || relationshipTypeId != null || showArchived;

  /// Returns a copy with the given fields replaced.
  ContactView copyWith({
    String? query,
    String? relationshipTypeId,
    ContactSort? sort,
    bool? showArchived,
    bool clearRelationshipTypeId = false,
  }) => ContactView(
    query: query ?? this.query,
    relationshipTypeId: clearRelationshipTypeId
        ? null
        : relationshipTypeId ?? this.relationshipTypeId,
    sort: sort ?? this.sort,
    showArchived: showArchived ?? this.showArchived,
  );

  /// [contacts] narrowed and ordered as this view describes.
  ///
  /// Pure: same inputs, same output, no clock and no I/O. Archived contacts
  /// are dropped unless [showArchived] is set, the search matches a contact's
  /// name, tags or guardian name, and the ordering falls back to name so that
  /// every sort is total and the list never reshuffles between rebuilds.
  ///
  /// [freshness] is only consulted by [ContactSort.freshness], and carries
  /// its own "now", so this stays a function of its arguments alone. It
  /// defaults to the empty index, under which every contact reads as never
  /// logged and the freshness sort degrades to the name sort.
  List<Contact> apply(
    List<Contact> contacts, {
    FreshnessIndex? freshness,
  }) {
    final needle = query.trim().toLowerCase();
    final matches = [
      for (final contact in contacts)
        if ((showArchived || !contact.isArchived) &&
            (relationshipTypeId == null ||
                contact.relationshipTypeId == relationshipTypeId) &&
            _matches(contact, needle))
          contact,
    ];
    return matches
      ..sort((a, b) => _compare(a, b, freshness ?? FreshnessIndex.empty));
  }

  int _compare(Contact a, Contact b, FreshnessIndex freshness) {
    final ordered = switch (sort) {
      ContactSort.name => 0,
      ContactSort.recentlyAdded => b.createdAt.compareTo(a.createdAt),
      ContactSort.cadence => a.cadence.days.compareTo(b.cadence.days),
      ContactSort.freshness => freshness.compare(a, b),
    };
    if (ordered != 0) return ordered;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    // Ids break the last tie, so two contacts with the same name and cadence
    // keep a stable order rather than swapping places on every rebuild.
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }

  /// Whether [contact] matches the already-lowercased [needle].
  ///
  /// Name, tags and guardian name: the three things you would search a kid's
  /// friend by. Phone, address and notes are deliberately not searched — a
  /// stray digit in a note should not surface someone.
  static bool _matches(Contact contact, String needle) {
    if (needle.isEmpty) return true;
    if (contact.name.toLowerCase().contains(needle)) return true;
    if ((contact.guardianName ?? '').toLowerCase().contains(needle)) {
      return true;
    }
    return contact.tags.any((tag) => tag.toLowerCase().contains(needle));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactView &&
          other.query == query &&
          other.relationshipTypeId == relationshipTypeId &&
          other.sort == sort &&
          other.showArchived == showArchived;

  @override
  int get hashCode =>
      Object.hash(query, relationshipTypeId, sort, showArchived);

  @override
  String toString() =>
      'ContactView(query: $query, '
      'relationshipTypeId: $relationshipTypeId, sort: ${sort.name}, '
      'showArchived: $showArchived)';
}
