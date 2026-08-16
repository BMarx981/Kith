import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';

/// A household's shareable join code.
///
/// Codes are read off one person's screen and typed into another's, so the
/// encoding is Crockford Base32: no `I`, `L`, `O` or `U`, and the characters
/// people most often substitute are folded back on the way in.
@immutable
class InviteCode {
  const InviteCode._(this.value);

  /// Draws a new random code from [random].
  ///
  /// Callers own the source of randomness so tests can seed it. Uniqueness
  /// within a household is the repository's job, not this function's.
  factory InviteCode.generate(Random random) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return InviteCode._(buffer.toString());
  }

  /// The normalised code, always [length] characters drawn from [alphabet].
  final String value;

  /// Number of characters in a code.
  static const length = 6;

  /// Crockford Base32. `U` is omitted alongside `I`, `L` and `O` so that no
  /// generated code can spell an offensive word by accident.
  static const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Characters typists substitute, mapped to what they meant.
  static const _foldings = {'I': '1', 'L': '1', 'O': '0', 'U': 'V'};

  /// Separators that may appear in typed or pasted input.
  static final _separators = RegExp(r'[\s\-_]');

  /// Normalises and validates user-typed [input].
  ///
  /// Uppercases, strips separators and whitespace, and folds confusable
  /// characters before checking length and alphabet.
  static Result<InviteCode> parse(String input) {
    final normalised = input
        .toUpperCase()
        .replaceAll(_separators, '')
        .split('')
        .map((char) => _foldings[char] ?? char)
        .join();

    if (normalised.isEmpty) {
      return const Err(ValidationFailure('Enter an invite code.'));
    }
    if (normalised.length != length) {
      return const Err(
        ValidationFailure('Invite codes are $length characters long.'),
      );
    }
    for (final char in normalised.split('')) {
      if (!alphabet.contains(char)) {
        return Err(
          ValidationFailure('"$char" is not part of an invite code.'),
        );
      }
    }
    return Ok(InviteCode._(normalised));
  }

  /// The code split for display, e.g. `KH7-RQ2`.
  String get formatted =>
      '${value.substring(0, length ~/ 2)}-${value.substring(length ~/ 2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InviteCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'InviteCode($value)';
}
