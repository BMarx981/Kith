import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/centered_form_shell.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/auth/application/sign_in_controller.dart';
import 'package:kith/features/auth/application/sign_in_state.dart';
import 'package:kith/features/auth/domain/credential_validator.dart';
import 'package:kith/features/auth/presentation/auth_failure_message.dart';
import 'package:kith/l10n/l10n.dart';
import 'package:kith/l10n/validation_messages.dart';

/// Entry point for unauthenticated users.
///
/// Signing in or creating an account changes the signed-in identity; the auth
/// guard notices and takes the user onward, so this screen never navigates.
/// Apple sign-in is not offered until its provider is wired up, rather than
/// shown as a button that always fails.
@RoutePage()
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  /// Identifies the email field to tests.
  static const emailFieldKey = Key('signIn.email');

  /// Identifies the password field to tests.
  static const passwordFieldKey = Key('signIn.password');

  /// Identifies the submit button to tests.
  static const submitButtonKey = Key('signIn.submit');

  /// Identifies the sign-in/sign-up toggle to tests.
  static const modeToggleKey = Key('signIn.modeToggle');

  /// Identifies the password reset button to tests.
  static const forgotPasswordKey = Key('signIn.forgotPassword');

  /// Identifies the Google sign-in button to tests.
  static const googleButtonKey = Key('signIn.google');

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(signInControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _sendPasswordReset() => ref
      .read(signInControllerProvider.notifier)
      .sendPasswordReset(_emailController.text);

  Future<void> _signInWithGoogle() =>
      ref.read(signInControllerProvider.notifier).signInWithGoogle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider);
    final isSignUp = state.mode == SignInMode.signUp;

    ref.listen(signInControllerProvider, (previous, next) {
      final sentTo = next.passwordResetSentTo;
      if (sentTo == null || previous?.passwordResetSentTo == sentTo) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetSent(sentTo))),
      );
    });

    return CenteredFormShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kith',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: KithSpacing.xs),
            Text(
              isSignUp ? l10n.signUpTagline : l10n.signInTagline,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KithSpacing.xl),
            TextFormField(
              key: SignInScreen.emailFieldKey,
              controller: _emailController,
              enabled: !state.isSubmitting,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(labelText: l10n.emailLabel),
              validator: (input) =>
                  validationMessage(l10n, CredentialValidator.email(input)),
            ),
            const SizedBox(height: KithSpacing.md),
            TextFormField(
              key: SignInScreen.passwordFieldKey,
              controller: _passwordController,
              enabled: !state.isSubmitting,
              obscureText: _obscurePassword,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              autofillHints: [
                if (isSignUp)
                  AutofillHints.newPassword
                else
                  AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  icon: Icon(
                    _obscurePassword
                        ? KithIcons.showPassword
                        : KithIcons.hidePassword,
                  ),
                  tooltip: _obscurePassword
                      ? l10n.showPassword
                      : l10n.hidePassword,
                ),
              ),
              validator: (input) => validationMessage(
                l10n,
                isSignUp
                    ? CredentialValidator.newPassword(input)
                    : CredentialValidator.password(input),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: KithSpacing.md),
              Text(
                authFailureMessage(l10n, failure),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              // Debug builds only, and only for the reasons whose
              // copy cannot name the actual problem: an unrecognised
              // code, or a configuration error whose detail decides
              // which switch in the console is the wrong one. The text
              // is otherwise captured and thrown away.
              if (kDebugMode &&
                  const {
                    AuthFailureReason.unknown,
                    AuthFailureReason.providerUnavailable,
                  }.contains(failure.reason)) ...[
                const SizedBox(height: KithSpacing.xxs),
                Text(
                  failure.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            const SizedBox(height: KithSpacing.lg),
            FilledButton(
              key: SignInScreen.submitButtonKey,
              onPressed: state.isSubmitting ? null : _submit,
              child: state.isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(),
                    )
                  : Text(
                      isSignUp ? l10n.createAccountButton : l10n.signInButton,
                    ),
            ),
            if (!isSignUp)
              TextButton(
                key: SignInScreen.forgotPasswordKey,
                onPressed: state.isSubmitting ? null : _sendPasswordReset,
                child: Text(l10n.forgotPassword),
              ),
            const SizedBox(height: KithSpacing.md),
            // Google's own asset rather than an icon-font approximation: the
            // branding guidelines require the mark unaltered, and it is not a
            // Phosphor glyph to begin with. See assets/brand/google.
            OutlinedButton.icon(
              key: SignInScreen.googleButtonKey,
              onPressed: state.isSubmitting ? null : _signInWithGoogle,
              icon: const Image(
                image: AssetImage('assets/brand/google/g-logo.png'),
                width: 20,
                height: 20,
                // The mark carries its own colours and must keep them, so it
                // does not follow the button's foreground like an icon would.
                excludeFromSemantics: true,
              ),
              label: Text(l10n.continueWithGoogle),
            ),
            const SizedBox(height: KithSpacing.xs),
            TextButton(
              key: SignInScreen.modeToggleKey,
              onPressed: state.isSubmitting
                  ? null
                  : () => ref
                        .read(signInControllerProvider.notifier)
                        .setMode(
                          isSignUp ? SignInMode.signIn : SignInMode.signUp,
                        ),
              child: Text(
                isSignUp ? l10n.toggleHaveAccount : l10n.toggleCreateAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
