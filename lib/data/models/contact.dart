import 'package:flutter/foundation.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

/// Someone the household tracks: a friend, a relative, or a kid's friend.
///
/// Stored at `households/{hid}/contacts/{cid}`. Every optional field is
/// nullable rather than blank, so "no phone number" and "an empty phone
/// number" cannot both exist.
@immutable
class Contact {
  Contact({
    required this.id,
    required this.name,
    required this.relationshipTypeId,
    required this.cadence,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.email,
    this.address,
    this.guardianName,
    this.guardianPhone,
    this.birthday,
    this.notes,
    List<String> tags = const [],
    this.isArchived = false,
  }) : tags = List.unmodifiable(tags);

  /// Rebuilds a contact from its Firestore document data.
  ///
  /// Tolerant where a missing value has an obvious reading — no tags, not
  /// archived, an unrecognised priority — because one odd document should not
  /// take the whole list down with it.
  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
    id: map['id'] as String,
    name: map['name'] as String,
    relationshipTypeId: map['relationshipTypeId'] as String,
    cadence: Cadence.fromDays(map['cadenceDays'] as int),
    priority: ContactPriority.fromWireName(map['priority'] as String?),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      map['createdAt'] as int,
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      map['updatedAt'] as int,
      isUtc: true,
    ),
    phone: map['phone'] as String?,
    email: map['email'] as String?,
    address: map['address'] as String?,
    guardianName: map['guardianName'] as String?,
    guardianPhone: map['guardianPhone'] as String?,
    birthday: Birthday.tryParse(map['birthday'] as String?),
    notes: map['notes'] as String?,
    tags: (map['tags'] as List<dynamic>? ?? const []).cast<String>(),
    isArchived: map['isArchived'] as bool? ?? false,
  );

  /// Firestore document id.
  final String id;

  /// What you call them. For a family unit, the family's name.
  final String name;

  /// Id of the household's `RelationshipType` this contact is filed under.
  ///
  /// A plain id rather than a resolved object: the type list is watched
  /// separately, and a contact whose type was deleted still has to render.
  final String relationshipTypeId;

  /// How often you mean to see them.
  final Cadence cadence;

  /// How hard the suggestion engine should push them up the list.
  final ContactPriority priority;

  /// When the contact was added, in UTC.
  final DateTime createdAt;

  /// When the contact was last edited, in UTC. Equal to [createdAt] until the
  /// first edit.
  final DateTime updatedAt;

  /// Their phone number, unformatted and unvalidated beyond a length bound.
  final String? phone;

  /// Their email address.
  final String? email;

  /// Where they live, as one free-text block.
  final String? address;

  /// Name of the parent or guardian to contact about this person.
  ///
  /// First-class rather than buried in [notes] because for a kid's friend the
  /// person you actually text is the parent.
  final String? guardianName;

  /// Phone number for [guardianName].
  final String? guardianPhone;

  /// The day they were born, with the year only when it is known.
  ///
  /// A [Birthday] rather than a `DateTime` because a birthday recurs: what
  /// the app asks of it is when the next one falls, not which instant in
  /// history it was.
  final Birthday? birthday;

  /// Anything else worth remembering about them.
  final String? notes;

  /// Free-form labels, unmodifiable and stored in the order they were given.
  final List<String> tags;

  /// Whether the contact has been archived: kept, but out of the list, the
  /// suggestions and the counts. Kith has no hard delete for contacts, so
  /// their hangout history survives.
  final bool isArchived;

  /// Longest a contact's name may be. Mirrors the bound in `firestore.rules`.
  static const maxNameLength = 100;

  /// Longest any of the free-text detail fields may be.
  static const maxDetailLength = 200;

  /// Longest [notes] may be.
  static const maxNotesLength = 2000;

  /// Most tags one contact may carry.
  static const maxTags = 20;

  /// Longest a single tag may be.
  static const maxTagLength = 40;

  /// Serialises to Firestore document data.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationshipTypeId': relationshipTypeId,
    'cadenceDays': cadence.days,
    'priority': priority.wireName,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': updatedAt.toUtc().millisecondsSinceEpoch,
    'phone': phone,
    'email': email,
    'address': address,
    'guardianName': guardianName,
    'guardianPhone': guardianPhone,
    'birthday': birthday?.wireValue,
    'notes': notes,
    'tags': tags,
    'isArchived': isArchived,
  };

  /// Returns a copy with the given fields replaced.
  ///
  /// Each optional field has a `clear` flag, because passing null to a named
  /// parameter cannot be told apart from omitting it.
  Contact copyWith({
    String? id,
    String? name,
    String? relationshipTypeId,
    Cadence? cadence,
    ContactPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phone,
    String? email,
    String? address,
    String? guardianName,
    String? guardianPhone,
    Birthday? birthday,
    String? notes,
    List<String>? tags,
    bool? isArchived,
    bool clearPhone = false,
    bool clearEmail = false,
    bool clearAddress = false,
    bool clearGuardianName = false,
    bool clearGuardianPhone = false,
    bool clearBirthday = false,
    bool clearNotes = false,
  }) => Contact(
    id: id ?? this.id,
    name: name ?? this.name,
    relationshipTypeId: relationshipTypeId ?? this.relationshipTypeId,
    cadence: cadence ?? this.cadence,
    priority: priority ?? this.priority,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    phone: clearPhone ? null : phone ?? this.phone,
    email: clearEmail ? null : email ?? this.email,
    address: clearAddress ? null : address ?? this.address,
    guardianName: clearGuardianName ? null : guardianName ?? this.guardianName,
    guardianPhone: clearGuardianPhone
        ? null
        : guardianPhone ?? this.guardianPhone,
    birthday: clearBirthday ? null : birthday ?? this.birthday,
    notes: clearNotes ? null : notes ?? this.notes,
    tags: tags ?? this.tags,
    isArchived: isArchived ?? this.isArchived,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          other.id == id &&
          other.name == name &&
          other.relationshipTypeId == relationshipTypeId &&
          other.cadence == cadence &&
          other.priority == priority &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.phone == phone &&
          other.email == email &&
          other.address == address &&
          other.guardianName == guardianName &&
          other.guardianPhone == guardianPhone &&
          other.birthday == birthday &&
          other.notes == notes &&
          listEquals(other.tags, tags) &&
          other.isArchived == isArchived;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    relationshipTypeId,
    cadence,
    priority,
    createdAt,
    updatedAt,
    phone,
    email,
    address,
    guardianName,
    guardianPhone,
    birthday,
    notes,
    Object.hashAll(tags),
    isArchived,
  );

  @override
  String toString() =>
      'Contact(id: $id, name: $name, '
      'relationshipTypeId: $relationshipTypeId, '
      'cadenceDays: ${cadence.days}, priority: ${priority.wireName}, '
      'createdAt: $createdAt, updatedAt: $updatedAt, phone: $phone, '
      'email: $email, address: $address, guardianName: $guardianName, '
      'guardianPhone: $guardianPhone, birthday: $birthday, '
      'notes: $notes, tags: $tags, '
      'isArchived: $isArchived)';
}
