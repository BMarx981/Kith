import 'package:flutter/foundation.dart';

/// The signed-in identity, as reported by the auth backend.
///
/// Distinct from `Member`: this is who you are, a `Member` is what you are
/// inside a particular household. A user can be authenticated without
/// belonging to any household yet, which is exactly the state the onboarding
/// flow exists to resolve.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Rebuilds a user from stored or transported data.
  factory AuthUser.fromMap(Map<String, dynamic> map) => AuthUser(
    id: map['id'] as String,
    email: map['email'] as String,
    displayName: map['displayName'] as String?,
    photoUrl: map['photoUrl'] as String?,
  );

  /// Firebase Auth uid. Becomes the member document id on join.
  final String id;

  /// Sign-in address.
  final String email;

  /// Name from the auth provider. Null after an email sign-up that did not
  /// collect one, which is why joining a household asks for it.
  final String? displayName;

  /// Avatar from a federated provider, if it supplied one.
  final String? photoUrl;

  /// Serialises to plain data.
  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
  };

  /// Returns a copy with the given fields replaced.
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool clearDisplayName = false,
    bool clearPhotoUrl = false,
  }) => AuthUser(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: clearDisplayName ? null : displayName ?? this.displayName,
    photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, displayName: $displayName, '
      'photoUrl: $photoUrl)';
}
