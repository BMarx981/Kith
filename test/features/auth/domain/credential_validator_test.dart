import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
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
      null: ValidationIssue.emailEmpty,
      '': ValidationIssue.emailEmpty,
      '   ': ValidationIssue.emailEmpty,
      'brian': ValidationIssue.emailMalformed,
      'brian@': ValidationIssue.emailMalformed,
      'brian@example': ValidationIssue.emailMalformed,
      '@example.com': ValidationIssue.emailMalformed,
      'brian example@mail.com': ValidationIssue.emailMalformed,
      'brian@@example.com': ValidationIssue.emailMalformed,
    };
    for (final entry in rejected.entries) {
      test('rejects "${entry.key}"', () {
        expect(CredentialValidator.email(entry.key)?.issue, entry.value);
      });
    }
  });

  group('CredentialValidator.password', () {
    test('accepts anything non-empty, however weak', () {
      expect(CredentialValidator.password('a'), isNull);
    });

    test('rejects null', () {
      expect(
        CredentialValidator.password(null)?.issue,
        ValidationIssue.passwordEmpty,
      );
    });

    test('rejects empty', () {
      expect(
        CredentialValidator.password('')?.issue,
        ValidationIssue.passwordEmpty,
      );
    });
  });

  group('CredentialValidator.newPassword', () {
    test('accepts a password at the minimum length', () {
      final password = 'a' * CredentialValidator.minPasswordLength;

      expect(CredentialValidator.newPassword(password), isNull);
    });

    test('rejects one character short, naming the floor', () {
      final password = 'a' * (CredentialValidator.minPasswordLength - 1);
      final failure = CredentialValidator.newPassword(password);

      expect(failure?.issue, ValidationIssue.passwordTooShort);
      expect(failure?.args['min'], CredentialValidator.minPasswordLength);
    });

    test('reports emptiness rather than length when there is nothing', () {
      expect(
        CredentialValidator.newPassword('')?.issue,
        ValidationIssue.passwordEmpty,
      );
    });

    test('keeps spaces, which are legitimate password characters', () {
      expect(CredentialValidator.newPassword('        '), isNull);
    });
  });
}
