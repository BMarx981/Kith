import 'package:flutter_contacts/flutter_contacts.dart' as plugin;
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/domain/birthday.dart';

/// The [DeviceContactDirectory] the app ships, over `flutter_contacts`.
///
/// Deliberately thin: what it does is ask for the read permission, pull the
/// four properties Kith has room for, and reduce each row to a
/// [DeviceContact]. Everything worth testing — which of them are already here,
/// what order they go in, what draft each becomes — is pure and lives in
/// `features/contacts/domain/contact_import.dart`.
class FlutterDeviceContactDirectory implements DeviceContactDirectory {
  /// The properties asked for. Narrow on purpose: an address book read is
  /// slow in proportion to what it fetches, and photos and organisations have
  /// nowhere to go in a Kith contact.
  static final Set<plugin.ContactProperty> properties = {
    plugin.ContactProperty.name,
    plugin.ContactProperty.phone,
    plugin.ContactProperty.email,
    plugin.ContactProperty.address,
    plugin.ContactProperty.event,
  };

  @override
  Future<Result<bool>> requestPermission() async {
    try {
      // Read, never readWrite: Kith imports people and never writes back to
      // the phone's address book, so the write half is not asked for.
      final status = await plugin.FlutterContacts.permissions.request(
        plugin.PermissionType.read,
      );
      return Ok(
        status == plugin.PermissionStatus.granted ||
            status == plugin.PermissionStatus.limited,
      );
    } on Object catch (error) {
      return Err(
        UnknownFailure('Could not ask to read your contacts.', cause: error),
      );
    }
  }

  @override
  Future<Result<List<DeviceContact>>> readContacts() async {
    try {
      if (!await plugin.FlutterContacts.permissions.has(
        plugin.PermissionType.read,
      )) {
        return const Err(
          PermissionFailure('Kith may not read the device contacts.'),
        );
      }
      final rows = await plugin.FlutterContacts.getAll(properties: properties);
      return Ok([for (final row in rows) ?_read(row)]);
    } on Object catch (error) {
      return Err(
        UnknownFailure('Could not read your contacts.', cause: error),
      );
    }
  }

  /// [row] as Kith holds it, or null for a row with no name.
  ///
  /// A nameless row is dropped rather than imported as a blank contact: the
  /// address book is full of bare phone numbers, and a contact called nothing
  /// is not somebody the household can be reminded about.
  static DeviceContact? _read(plugin.Contact row) {
    final name = (row.displayName ?? '').trim();
    if (name.isEmpty) return null;
    return DeviceContact(
      id: row.id ?? name,
      name: name,
      phone: row.phones.firstOrNull?.number.trim(),
      email: row.emails.firstOrNull?.address.trim(),
      address: _address(row),
      birthday: _birthday(row),
    );
  }

  /// The first postal address as one block, preferring the platform's own
  /// formatting over one assembled here, which would need a country's
  /// conventions to get right.
  static String? _address(plugin.Contact row) {
    final address = row.addresses.firstOrNull;
    if (address == null) return null;
    final formatted = (address.formatted ?? '').trim();
    if (formatted.isNotEmpty) return formatted;
    final parts = [
      address.street,
      address.city,
      address.state,
      address.postalCode,
      address.country,
    ].map((part) => (part ?? '').trim()).where((part) => part.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// The row's birthday event, if it has one.
  ///
  /// Address book events carry a nullable year exactly as [Birthday] does, so
  /// a birthday whose year the phone never knew arrives here still not
  /// knowing it rather than acquiring a guess.
  static Birthday? _birthday(plugin.Contact row) {
    for (final event in row.events) {
      if (event.label.label != plugin.EventLabel.birthday) continue;
      final read = Birthday(
        month: event.month,
        day: event.day,
        year: event.year,
      );
      // Back through the parser, so a nonsensical stored event is dropped
      // rather than carried into Firestore.
      return Birthday.tryParse(read.wireValue);
    }
    return null;
  }
}
