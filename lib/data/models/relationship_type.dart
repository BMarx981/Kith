import 'package:flutter/foundation.dart';

/// A per-household label for what someone is to you.
///
/// Stored at `households/{hid}/relationshipTypes/{rid}`. Households edit the
/// list freely, which is why this is a document rather than an enum: a label
/// like "Child's friend" is renamed to the kid's actual name in one house and
/// deleted outright in another.
@immutable
class RelationshipType {
  const RelationshipType({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Rebuilds a relationship type from its Firestore document data.
  factory RelationshipType.fromMap(Map<String, dynamic> map) =>
      RelationshipType(
        id: map['id'] as String,
        name: map['name'] as String,
        sortOrder: map['sortOrder'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int,
          isUtc: true,
        ),
      );

  /// Firestore document id.
  final String id;

  /// What the household calls this relationship, e.g. "Neighbor".
  final String name;

  /// Position in the household's list, ascending.
  ///
  /// Held on the document rather than inferred from the name so the manager
  /// can reorder the list without renaming anything. Gaps are allowed; only
  /// the ordering is meaningful.
  final int sortOrder;

  /// When the type was added, in UTC. Breaks ties between equal [sortOrder]s.
  final DateTime createdAt;

  /// Longest a label may be. Mirrors the bound in `firestore.rules`.
  static const maxNameLength = 60;

  /// The starter set every new household gets, in the order they are seeded.
  ///
  /// Taken verbatim from `docs/PLAN.md`. Households rename and delete these
  /// like any other type, so seeding one that does not fit costs a tap.
  static const defaultNames = <String>[
    'Friend',
    'Family',
    'Neighbor',
    "Child's friend",
    'Coworker',
  ];

  /// Serialises to Firestore document data.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
  };

  /// Returns a copy with the given fields replaced.
  RelationshipType copyWith({
    String? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) => RelationshipType(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationshipType &&
          other.id == id &&
          other.name == name &&
          other.sortOrder == sortOrder &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);

  @override
  String toString() =>
      'RelationshipType(id: $id, name: $name, sortOrder: $sortOrder, '
      'createdAt: $createdAt)';
}
