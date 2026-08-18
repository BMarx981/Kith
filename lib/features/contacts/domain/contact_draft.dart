import 'package:flutter/foundation.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

/// The editable half of a [Contact]: everything the editor collects.
///
/// A contact's id and timestamps belong to whoever stores it, so the editor
/// never has to invent them, and creating and updating take the same shape.
/// The archived flag is absent too: archiving is its own action, not something
/// you do while editing a phone number.
@immutable
class ContactDraft {
  const ContactDraft({
    required this.name,
    required this.relationshipTypeId,
    required this.cadence,
    this.priority = ContactPriority.normal,
    this.phone,
    this.email,
    this.address,
    this.guardianName,
    this.guardianPhone,
    this.notes,
    this.tags = const [],
  });

  /// The draft that reproduces [contact], for opening it in the editor.
  factory ContactDraft.from(Contact contact) => ContactDraft(
    name: contact.name,
    relationshipTypeId: contact.relationshipTypeId,
    cadence: contact.cadence,
    priority: contact.priority,
    phone: contact.phone,
    email: contact.email,
    address: contact.address,
    guardianName: contact.guardianName,
    guardianPhone: contact.guardianPhone,
    notes: contact.notes,
    tags: contact.tags,
  );

  /// What you call them.
  final String name;

  /// Id of the relationship type they are filed under.
  final String relationshipTypeId;

  /// How often you mean to see them.
  final Cadence cadence;

  /// How hard the suggestion engine should push them up the list.
  final ContactPriority priority;

  /// Their phone number.
  final String? phone;

  /// Their email address.
  final String? email;

  /// Where they live.
  final String? address;

  /// Name of the parent or guardian to contact about this person.
  final String? guardianName;

  /// Phone number for [guardianName].
  final String? guardianPhone;

  /// Anything else worth remembering.
  final String? notes;

  /// Free-form labels.
  final List<String> tags;

  /// The same draft with whitespace taken off and blanks read as absent.
  ///
  /// Run before validation and before storing, so that a field someone
  /// cleared to a space is stored as null rather than as " ", and so two tags
  /// that differ only in padding cannot both survive.
  ContactDraft normalised() => ContactDraft(
    name: name.trim(),
    relationshipTypeId: relationshipTypeId.trim(),
    cadence: cadence,
    priority: priority,
    phone: _blankToNull(phone),
    email: _blankToNull(email),
    address: _blankToNull(address),
    guardianName: _blankToNull(guardianName),
    guardianPhone: _blankToNull(guardianPhone),
    notes: _blankToNull(notes),
    tags: _normalisedTags(tags),
  );

  /// Builds the stored contact this draft describes.
  ///
  /// [createdAt] and [updatedAt] are supplied rather than read from a clock
  /// here, so the repository stays the one place that decides what "now" is
  /// for a write.
  Contact toContact({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool isArchived = false,
  }) => Contact(
    id: id,
    name: name,
    relationshipTypeId: relationshipTypeId,
    cadence: cadence,
    priority: priority,
    createdAt: createdAt,
    updatedAt: updatedAt,
    phone: phone,
    email: email,
    address: address,
    guardianName: guardianName,
    guardianPhone: guardianPhone,
    notes: notes,
    tags: tags,
    isArchived: isArchived,
  );

  /// Returns a copy with the given fields replaced.
  ContactDraft copyWith({
    String? name,
    String? relationshipTypeId,
    Cadence? cadence,
    ContactPriority? priority,
    String? phone,
    String? email,
    String? address,
    String? guardianName,
    String? guardianPhone,
    String? notes,
    List<String>? tags,
    bool clearPhone = false,
    bool clearEmail = false,
    bool clearAddress = false,
    bool clearGuardianName = false,
    bool clearGuardianPhone = false,
    bool clearNotes = false,
  }) => ContactDraft(
    name: name ?? this.name,
    relationshipTypeId: relationshipTypeId ?? this.relationshipTypeId,
    cadence: cadence ?? this.cadence,
    priority: priority ?? this.priority,
    phone: clearPhone ? null : phone ?? this.phone,
    email: clearEmail ? null : email ?? this.email,
    address: clearAddress ? null : address ?? this.address,
    guardianName: clearGuardianName ? null : guardianName ?? this.guardianName,
    guardianPhone: clearGuardianPhone
        ? null
        : guardianPhone ?? this.guardianPhone,
    notes: clearNotes ? null : notes ?? this.notes,
    tags: tags ?? this.tags,
  );

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Trims every tag, drops the empty ones, and keeps the first of any
  /// duplicates so the order the user typed survives.
  static List<String> _normalisedTags(List<String> tags) {
    final seen = <String>{};
    return [
      for (final tag in tags)
        if (tag.trim().isNotEmpty && seen.add(tag.trim().toLowerCase()))
          tag.trim(),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactDraft &&
          other.name == name &&
          other.relationshipTypeId == relationshipTypeId &&
          other.cadence == cadence &&
          other.priority == priority &&
          other.phone == phone &&
          other.email == email &&
          other.address == address &&
          other.guardianName == guardianName &&
          other.guardianPhone == guardianPhone &&
          other.notes == notes &&
          listEquals(other.tags, tags);

  @override
  int get hashCode => Object.hash(
    name,
    relationshipTypeId,
    cadence,
    priority,
    phone,
    email,
    address,
    guardianName,
    guardianPhone,
    notes,
    Object.hashAll(tags),
  );

  @override
  String toString() =>
      'ContactDraft(name: $name, '
      'relationshipTypeId: $relationshipTypeId, '
      'cadenceDays: ${cadence.days}, priority: ${priority.wireName}, '
      'phone: $phone, email: $email, address: $address, '
      'guardianName: $guardianName, guardianPhone: $guardianPhone, '
      'notes: $notes, tags: $tags)';
}
