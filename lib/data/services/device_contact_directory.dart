import 'package:flutter/foundation.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/contacts/domain/birthday.dart';

/// One person as the device's address book holds them.
///
/// A Kith-shaped reading of a platform record rather than the platform's own
/// type, for the same reason the repositories return domain models: nothing
/// above `DeviceContactDirectory` should have to know what an address book
/// row looks like, and the import screen and its tests should not be built on
/// a plugin's class.
///
/// Only the fields Kith has somewhere to put survive the crossing. An address
/// book row carries organisations, websites, anniversaries and a dozen phone
/// numbers; a Kith contact has one of each and a birthday, so the reading
/// takes the first of each and drops the rest.
@immutable
class DeviceContact {
  const DeviceContact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.birthday,
  });

  /// The platform's own identifier for the row. Used to tell two people of the
  /// same name apart while the import screen is open, and never stored.
  final String id;

  /// What the address book calls them.
  final String name;

  /// Their first phone number, as written.
  final String? phone;

  /// Their first email address.
  final String? email;

  /// Their first postal address, as one block.
  final String? address;

  /// Their birthday, when the row carries one.
  final Birthday? birthday;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceContact &&
          other.id == id &&
          other.name == name &&
          other.phone == phone &&
          other.email == email &&
          other.address == address &&
          other.birthday == birthday;

  @override
  int get hashCode => Object.hash(id, name, phone, email, address, birthday);

  @override
  String toString() =>
      'DeviceContact(id: $id, name: $name, phone: $phone, email: $email, '
      'address: $address, birthday: $birthday)';
}

/// Reads the device's address book.
///
/// A seam over the platform, for the same reason `CalendarSink` and
/// `NotificationScheduler` are: there is no address book under `flutter test`,
/// so the matching, the de-duplication and the screen are all written against
/// this interface and the one implementation that talks to the plugin stays as
/// thin as it can be.
///
/// Read-only, deliberately. Kith imports people; it never writes back to the
/// phone's contacts, so the write half of the permission is never asked for.
abstract interface class DeviceContactDirectory {
  /// Asks the user to allow reading their contacts, returning whether they are
  /// now readable.
  ///
  /// Answering false is not a failure: declining a permission prompt is a
  /// choice, and the screen says where to change their mind rather than
  /// reporting an error. An `Err` means the ask itself could not be made.
  Future<Result<bool>> requestPermission();

  /// Every readable contact on the device, in whatever order it gives them.
  ///
  /// Ordering and de-duplication are the domain's job, not the platform's, so
  /// they stay pure and testable.
  Future<Result<List<DeviceContact>>> readContacts();
}
