import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';

void main() {
  // Listed by hand because the constants cannot be enumerated; a new icon
  // added to KithIcons and not to this map simply is not covered, which is
  // the same trade every hand-written model test makes.
  const icons = <String, IconData>{
    'reconnect': KithIcons.reconnect,
    'people': KithIcons.people,
    'household': KithIcons.household,
    'showPassword': KithIcons.showPassword,
    'hidePassword': KithIcons.hidePassword,
    'signOut': KithIcons.signOut,
    'copy': KithIcons.copy,
    'add': KithIcons.add,
    'search': KithIcons.search,
    'sort': KithIcons.sort,
    'label': KithIcons.label,
    'edit': KithIcons.edit,
    'delete': KithIcons.delete,
    'reorder': KithIcons.reorder,
  };

  group('KithIcons', () {
    test('every icon is drawn from the bundled Phosphor face', () {
      for (final MapEntry(:key, :value) in icons.entries) {
        expect(value.fontFamily, 'Phosphor', reason: key);
        expect(
          value.fontPackage,
          isNull,
          reason: '$key ships with the app, not from a package',
        );
      }
    });

    test('no two icons resolve to the same glyph', () {
      expect(
        icons.values.map((icon) => icon.codePoint).toSet(),
        hasLength(icons.length),
        reason: 'a duplicated codepoint means a copy-paste slip',
      );
    });

    test('every codepoint sits in the private use area', () {
      for (final MapEntry(:key, :value) in icons.entries) {
        expect(
          value.codePoint,
          inInclusiveRange(0xE000, 0xF8FF),
          reason: '$key must land on an icon, not on a real character',
        );
      }
    });

    test('the two password states are different icons', () {
      expect(KithIcons.showPassword, isNot(KithIcons.hidePassword));
    });
  });
}
