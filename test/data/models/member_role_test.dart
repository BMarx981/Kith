import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/member_role.dart';

void main() {
  group('MemberRole', () {
    test('wire names are stable and distinct', () {
      expect(MemberRole.owner.wireName, 'owner');
      expect(MemberRole.member.wireName, 'member');
      expect(
        MemberRole.values.map((r) => r.wireName).toSet(),
        hasLength(MemberRole.values.length),
      );
    });

    test('round-trips through its wire name', () {
      for (final role in MemberRole.values) {
        expect(MemberRole.fromWireName(role.wireName), role);
      }
    });

    test('falls back to member for unknown or missing values', () {
      expect(MemberRole.fromWireName('admin'), MemberRole.member);
      expect(MemberRole.fromWireName(''), MemberRole.member);
      expect(MemberRole.fromWireName(null), MemberRole.member);
    });
  });
}
