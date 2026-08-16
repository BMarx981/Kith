/// A member's authority within a household.
enum MemberRole {
  /// Created the household. Can remove members and delete the household.
  owner('owner'),

  /// Joined via an invite code. Full read/write on household data.
  member('member');

  const MemberRole(this.wireName);

  /// Stable identifier persisted to Firestore.
  ///
  /// Spelled out rather than using [name] so renaming an enum value cannot
  /// silently invalidate stored documents.
  final String wireName;

  /// Parses a persisted [wireName], falling back to [MemberRole.member] for
  /// anything unrecognised so a future role cannot lock an old client out.
  static MemberRole fromWireName(String? wireName) {
    for (final role in MemberRole.values) {
      if (role.wireName == wireName) return role;
    }
    return MemberRole.member;
  }
}
