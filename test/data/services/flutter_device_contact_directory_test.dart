import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/flutter_device_contact_directory.dart';
import 'package:kith/features/contacts/domain/birthday.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// The plugin's own channel. Mocked directly rather than through a platform
  /// interface, because `flutter_contacts` has none: a method channel is the
  /// whole of its native contract, so standing in for the native side means
  /// standing in for the channel.
  const channel = MethodChannel('flutter_contacts');

  late List<MethodCall> calls;
  late Map<String, Object?> answers;
  late Exception? throws;

  setUp(() {
    calls = [];
    answers = {};
    throws = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (throws case final error?) throw error;
          return answers[call.method];
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  final directory = FlutterDeviceContactDirectory();

  /// One address book row, in the JSON shape the plugin decodes.
  Map<String, Object?> row(
    String id,
    String displayName, {
    List<Map<String, Object?>> phones = const [],
    List<Map<String, Object?>> emails = const [],
    List<Map<String, Object?>> addresses = const [],
    List<Map<String, Object?>> events = const [],
  }) => {
    'id': id,
    'displayName': displayName,
    'phones': phones,
    'emails': emails,
    'addresses': addresses,
    'events': events,
  };

  Map<String, Object?> event(
    int month,
    int day, {
    int? year,
    String label = 'birthday',
  }) => {
    'month': month,
    'day': day,
    'year': ?year,
    'label': {'label': label},
  };

  group('requestPermission', () {
    test('asks for read access only, and reports a grant', () async {
      answers['permissions.request'] = 'granted';

      final result = await directory.requestPermission();

      expect(result.valueOrNull, isTrue);
      expect(calls.single.method, 'permissions.request');
      expect(calls.single.arguments, {'type': 'read'});
    });

    test('counts limited access as access', () async {
      answers['permissions.request'] = 'limited';

      expect((await directory.requestPermission()).valueOrNull, isTrue);
    });

    test('reads a refusal as false rather than as a failure', () async {
      for (final status in ['denied', 'permanentlyDenied', 'restricted']) {
        answers['permissions.request'] = status;

        final result = await directory.requestPermission();

        expect(result.isOk, isTrue, reason: status);
        expect(result.valueOrNull, isFalse, reason: status);
      }
    });

    test('maps a platform error onto a domain failure', () async {
      throws = PlatformException(code: 'CONCURRENT_REQUEST');

      final result = await directory.requestPermission();

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('readContacts', () {
    test('refuses without asking the address book when not allowed', () async {
      answers['permissions.check'] = 'denied';

      final result = await directory.readContacts();

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(calls.map((c) => c.method), ['permissions.check']);
    });

    test('reads a row down to the fields Kith has room for', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [
        row(
          'row-1',
          'Marcus Bell',
          phones: [
            {'number': '555-0100', 'label': {'label': 'mobile'}},
            {'number': '555-0999', 'label': {'label': 'work'}},
          ],
          emails: [
            {'address': 'marcus@example.com', 'label': {'label': 'home'}},
          ],
          addresses: [
            {'formatted': '12 Elm Street', 'label': {'label': 'home'}},
          ],
          events: [event(3, 14, year: 1988)],
        ),
      ];

      final read = await directory.readContacts();

      final person = read.valueOrNull!.single;
      expect(person.id, 'row-1');
      expect(person.name, 'Marcus Bell');
      // The first of each, the rest dropped: a Kith contact has one phone.
      expect(person.phone, '555-0100');
      expect(person.email, 'marcus@example.com');
      expect(person.address, '12 Elm Street');
      expect(person.birthday, const Birthday(month: 3, day: 14, year: 1988));
    });

    test('assembles an address the platform did not format', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [
        row(
          'row-1',
          'Marcus Bell',
          addresses: [
            {
              'street': '12 Elm Street',
              'city': 'Hartford',
              'postalCode': '06103',
              'label': {'label': 'home'},
            },
          ],
        ),
      ];

      final person = (await directory.readContacts()).valueOrNull!.single;

      expect(person.address, '12 Elm Street, Hartford, 06103');
    });

    test('leaves absent fields absent rather than blank', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [row('row-1', 'Marcus Bell')];

      final person = (await directory.readContacts()).valueOrNull!.single;

      expect(person.phone, isNull);
      expect(person.email, isNull);
      expect(person.address, isNull);
      expect(person.birthday, isNull);
    });

    test('takes a birthday with no year as one with no year', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [
        row('row-1', 'Marcus Bell', events: [event(3, 14)]),
      ];

      final person = (await directory.readContacts()).valueOrNull!.single;

      expect(person.birthday, const Birthday(month: 3, day: 14));
      expect(person.birthday!.hasYear, isFalse);
    });

    test('ignores an event that is not a birthday', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [
        row(
          'row-1',
          'Marcus Bell',
          events: [
            event(6, 1, label: 'anniversary'),
            event(3, 14, year: 1988),
          ],
        ),
      ];

      final person = (await directory.readContacts()).valueOrNull!.single;

      expect(person.birthday, const Birthday(month: 3, day: 14, year: 1988));
    });

    test('drops a birthday event that is not a real date', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [
        row('row-1', 'Marcus Bell', events: [event(2, 31)]),
      ];

      final person = (await directory.readContacts()).valueOrNull!.single;

      expect(person.birthday, isNull);
    });

    test('drops a row with no name at all', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = [
        row('row-1', '   '),
        row('row-2', 'Marcus Bell'),
      ];

      final read = await directory.readContacts();

      expect(read.valueOrNull!.map((p) => p.name), ['Marcus Bell']);
    });

    test('asks only for the properties Kith can use', () async {
      answers['permissions.check'] = 'granted';
      answers['crud.getAll'] = <Object?>[];

      await directory.readContacts();

      final asked =
          (calls.last.arguments as Map)['properties'] as List<dynamic>;
      expect(
        asked.toSet(),
        {'name', 'phone', 'email', 'address', 'event'},
      );
    });

    test('maps a platform error onto a domain failure', () async {
      answers['permissions.check'] = 'granted';
      throws = PlatformException(code: 'unavailable');

      final result = await directory.readContacts();

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });
}
