import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/device_contact_directory.dart';

/// An in-memory [DeviceContactDirectory] for unit and widget tests.
///
/// Holds an address book the test writes, which is the whole point of the
/// seam: there is no address book under `flutter test`, so what the tests can
/// check is what the app does with the rows it is given.
class FakeDeviceContactDirectory implements DeviceContactDirectory {
  /// The address book this directory hands back, in the order given. The
  /// domain sorts, so an unsorted seed is the honest one.
  final contacts = <DeviceContact>[];

  /// How many times [requestPermission] was called.
  int permissionAsks = 0;

  /// How many times [readContacts] was called.
  int reads = 0;

  /// What [requestPermission] answers. False stands in for a user who
  /// declined the system prompt.
  bool permissionGranted = true;

  /// Failure to return from the next call to any method, instead of
  /// succeeding. Cleared once consumed.
  Failure? nextFailure;

  /// Adds [contact] to the address book.
  void seed(DeviceContact contact) => contacts.add(contact);

  @override
  Future<Result<bool>> requestPermission() async {
    permissionAsks++;
    final failure = _takeFailure();
    return failure != null ? Err(failure) : Ok(permissionGranted);
  }

  @override
  Future<Result<List<DeviceContact>>> readContacts() async {
    reads++;
    final failure = _takeFailure();
    return failure != null ? Err(failure) : Ok(List.of(contacts));
  }

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }
}
