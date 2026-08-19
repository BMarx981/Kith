import 'package:flutter/foundation.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

/// Somebody in the device's address book, and whether Kith already has them.
@immutable
class ImportCandidate {
  const ImportCandidate({required this.person, required this.isAlreadyHere});

  /// The address book row.
  final DeviceContact person;

  /// Whether a contact in the household already looks like this person.
  ///
  /// Carried rather than filtered out, because "already here" is worth seeing:
  /// somebody scrolling their address book wants to know why their oldest
  /// friend is not on the list, and a silently shortened list answers nothing.
  final bool isAlreadyHere;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportCandidate &&
          other.person == person &&
          other.isAlreadyHere == isAlreadyHere;

  @override
  int get hashCode => Object.hash(person, isAlreadyHere);

  @override
  String toString() =>
      'ImportCandidate(${person.name}, alreadyHere: $isAlreadyHere)';
}

/// Pairs each of [device] with whether [existing] already covers them, by name.
///
/// Pure, so the matching rule is checkable in a table rather than by importing
/// somebody twice and looking.
///
/// Three things are matched on, any one of which is enough: the same name, the
/// same phone number, or the same email address. A number and an address are
/// each near enough to an identity that sharing one means sharing a person;
/// names are matched case- and space-insensitively so "marcus  bell" does not
/// arrive alongside "Marcus Bell".
///
/// Archived contacts count as already here. Archiving is Kith's removal, and
/// re-importing somebody the household deliberately put away would undo that
/// by the back door.
///
/// Ordering is by name, then by the platform's own id, so the list is a total
/// order and never reshuffles between rebuilds.
List<ImportCandidate> importCandidates({
  required List<DeviceContact> device,
  required List<Contact> existing,
}) {
  final names = <String>{};
  final phones = <String>{};
  final emails = <String>{};
  for (final contact in existing) {
    if (_key(contact.name) case final name?) names.add(name);
    if (_phoneKey(contact.phone) case final phone?) phones.add(phone);
    if (_key(contact.email) case final email?) emails.add(email);
  }

  final candidates = [
    for (final person in device)
      ImportCandidate(
        person: person,
        isAlreadyHere:
            names.contains(_key(person.name)) ||
            phones.contains(_phoneKey(person.phone)) ||
            emails.contains(_key(person.email)),
      ),
  ]..sort((a, b) {
    final byName = a.person.name.toLowerCase().compareTo(
      b.person.name.toLowerCase(),
    );
    return byName != 0 ? byName : a.person.id.compareTo(b.person.id);
  });
  return List.unmodifiable(candidates);
}

/// The draft that would create [person] as a Kith contact.
///
/// The cadence and the label are chosen once for the whole import rather than
/// per person: an address book row says nothing about how often you want to
/// see somebody, and asking twenty times is how an import stops being one.
/// Both are editable afterwards on the contact itself.
ContactDraft draftFor(
  DeviceContact person, {
  required String relationshipTypeId,
  required Cadence cadence,
}) => ContactDraft(
  name: person.name,
  relationshipTypeId: relationshipTypeId,
  cadence: cadence,
  phone: person.phone,
  email: person.email,
  address: person.address,
  birthday: person.birthday,
).normalised();

/// [value] reduced to what two spellings of the same thing share: lower case,
/// with runs of whitespace collapsed. Null when there is nothing left.
String? _key(String? value) {
  final trimmed = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
  return trimmed.isEmpty ? null : trimmed;
}

/// [number] reduced to its digits, so `555-0100`, `(555) 0100` and `5550100`
/// are one number. Null when it holds no digits at all.
///
/// A leading `+` is dropped with everything else: comparing a national number
/// against the same number written internationally is a problem that needs a
/// region to solve, and matching on the digits that are there is the smaller
/// error of the two available.
String? _phoneKey(String? number) {
  final digits = (number ?? '').replaceAll(RegExp('[^0-9]'), '');
  return digits.isEmpty ? null : digits;
}
