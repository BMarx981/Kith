import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/auth/domain/credential_validator.dart';

void main() {
  group('CredentialValidator.email', () {
    const accepted = [
      'brian@example.com',
      'brian.marx@mail.example.co.uk',
      'b+kith@example.io',
      '  brian@example.com  ',
    ];
    for (final input in accepted) {
      test('accepts "$input"', () {
        expect(CredentialValidator.email(input), isNull);
      });
    }

    const rejected = {
      null: 'Enter your email address.',
      '': 'Enter your email address.',
      '   ': 'Enter your email address.',
      'brian': 'That does not look like an email address.',
      'brian@': 'That does not look like an email address.',
      'brian@example': 'That does not look like an email address.',
      '@example.com': 'That does not look like an email address.',
      'brian example@mail.com': 'That does not look like an email address.',
      'brian@@example.com': 'That does not look like an email address.',
    };
    for (final entry in rejected.entries) {
      test('rejects "${entry.key}"', () {
        expect(CredentialValidator.email(entry.key), entry.value);
      });
    }
  });

  group('CredentialValidator.password', () {
    test('accepts anything non-empty, however weak', () {
      expect(CredentialValidator.password('a'), isNull);
    });

    test('rejects null', () {
      expect(CredentialValidator.password(null), 'Enter your password.');
    });

    test('rejects empty', () {
      expect(CredentialValidator.password(''), 'Enter your password.');
    });
  });

  group('CredentialValidator.newPassword', () {
    test('accepts a password at the minimum length', () {
      final password = 'a' * CredentialValidator.minPasswordLength;

      expect(CredentialValidator.newPassword(password), isNull);
    });

    test('rejects one character short', () {
      final password = 'a' * (CredentialValidator.minPasswordLength - 1);

      expect(
        CredentialValidator.newPassword(password),
        'Use at least ${CredentialValidator.minPasswordLength} characters.',
      );
    });

    test('reports emptiness rather than length when there is nothing', () {
      expect(CredentialValidator.newPassword(''), 'Enter your password.');
    });

    test('keeps spaces, which are legitimate password characters', () {
      expect(CredentialValidator.newPassword('        '), isNull);
    });
  });
}
