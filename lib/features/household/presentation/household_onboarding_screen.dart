import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/centered_form_shell.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_onboarding_controller.dart';
import 'package:kith/features/household/application/household_onboarding_state.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/household_field_validator.dart';
import 'package:kith/features/household/presentation/household_failure_message.dart';
import 'package:kith/l10n/l10n.dart';
import 'package:kith/l10n/validation_messages.dart';

/// Where a signed-in user without a household lands.
///
/// Creating or joining writes the membership the household guard is waiting
/// on; the guard notices and takes the user onward, so this screen never
/// navigates. Signing out is offered because it is otherwise a dead end for
/// someone who signed in as the wrong person.
///
/// The guard also parks a user here when the membership query fails outright,
/// which is why the form is withheld in that case: a household that cannot be
/// read is not the same as no household, and offering the form would invite a
/// second one to be created alongside it.
@RoutePage()
class HouseholdOnboardingScreen extends ConsumerStatefulWidget {
  const HouseholdOnboardingScreen({super.key});

  /// Identifies the household name field to tests.
  static const nameFieldKey = Key('onboarding.name');

  /// Identifies the invite code field to tests.
  static const codeFieldKey = Key('onboarding.code');

  /// Identifies the display name field to tests.
  static const displayNameFieldKey = Key('onboarding.displayName');

  /// Identifies the submit button to tests.
  static const submitButtonKey = Key('onboarding.submit');

  /// Identifies the create/join toggle to tests.
  static const modeToggleKey = Key('onboarding.modeToggle');

  /// Identifies the sign-out button to tests.
  static const signOutKey = Key('onboarding.signOut');

  /// Identifies the retry button shown when membership cannot be read.
  static const retryKey = Key('onboarding.retry');

  @override
  ConsumerState<HouseholdOnboardingScreen> createState() =>
      _HouseholdOnboardingScreenState();
}

class _HouseholdOnboardingScreenState
    extends ConsumerState<HouseholdOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(householdOnboardingControllerProvider.notifier);
    final displayName = _displayNameController.text;
    switch (ref.read(householdOnboardingControllerProvider).mode) {
      case HouseholdOnboardingMode.create:
        await controller.createHousehold(
          name: _nameController.text,
          displayName: displayName,
        );
      case HouseholdOnboardingMode.join:
        await controller.joinHousehold(
          code: _codeController.text,
          displayName: displayName,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(householdOnboardingControllerProvider);
    final membership = ref.watch(householdIdsProvider);

    return CenteredFormShell(
      child: membership.hasError
          ? _Unreadable(
              error: membership.error!,
              onRetry: () => ref.invalidate(householdIdsProvider),
              onSignOut: () => ref.read(authServiceProvider).signOut(),
            )
          : _form(context, state),
    );
  }

  /// The create-or-join form itself.
  Widget _form(BuildContext context, HouseholdOnboardingState state) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isJoining = state.mode == HouseholdOnboardingMode.join;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isJoining
                ? l10n.onboardingJoinTitle
                : l10n.onboardingCreateTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: KithSpacing.xs),
          Text(
            isJoining
                ? l10n.onboardingJoinSubtitle
                : l10n.onboardingCreateSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KithSpacing.xl),
          if (isJoining)
            TextFormField(
              key: HouseholdOnboardingScreen.codeFieldKey,
              controller: _codeController,
              enabled: !state.isSubmitting,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.inviteCodeLabel,
                // An example code, not a word: the same in every locale.
                hintText: 'KH7-RQ2',
              ),
              validator: (input) => validationMessage(
                l10n,
                HouseholdFieldValidator.inviteCode(input),
              ),
            )
          else
            TextFormField(
              key: HouseholdOnboardingScreen.nameFieldKey,
              controller: _nameController,
              enabled: !state.isSubmitting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.householdNameLabel,
                hintText: l10n.householdNameHint,
              ),
              validator: (input) =>
                  validationMessage(l10n, HouseholdFieldValidator.name(input)),
            ),
          const SizedBox(height: KithSpacing.md),
          TextFormField(
            key: HouseholdOnboardingScreen.displayNameFieldKey,
            controller: _displayNameController,
            enabled: !state.isSubmitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.givenName],
            decoration: InputDecoration(
              labelText: l10n.yourNameLabel,
              helperText: l10n.yourNameHelper,
            ),
            validator: (input) => validationMessage(
              l10n,
              HouseholdFieldValidator.displayName(input),
            ),
            onFieldSubmitted: (_) => _submit(),
          ),
          if (state.failure case final failure?) ...[
            const SizedBox(height: KithSpacing.md),
            Text(
              householdFailureMessage(l10n, failure),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: KithSpacing.lg),
          FilledButton(
            key: HouseholdOnboardingScreen.submitButtonKey,
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(),
                  )
                : Text(
                    isJoining
                        ? l10n.joinButton
                        : l10n.createHouseholdButton,
                  ),
          ),
          const SizedBox(height: KithSpacing.xs),
          TextButton(
            key: HouseholdOnboardingScreen.modeToggleKey,
            onPressed: state.isSubmitting
                ? null
                : () => ref
                      .read(
                        householdOnboardingControllerProvider.notifier,
                      )
                      .setMode(
                        isJoining
                            ? HouseholdOnboardingMode.create
                            : HouseholdOnboardingMode.join,
                      ),
            child: Text(
              isJoining ? l10n.toggleStartInstead : l10n.toggleHaveCode,
            ),
          ),
          TextButton(
            key: HouseholdOnboardingScreen.signOutKey,
            onPressed: state.isSubmitting
                ? null
                : () => ref.read(authServiceProvider).signOut(),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

/// Shown in the form's place when the membership query failed.
///
/// Retrying re-runs the query; if it comes back with a household the guard
/// takes the user onward, and if it comes back empty the form returns.
class _Unreadable extends StatelessWidget {
  const _Unreadable({
    required this.error,
    required this.onRetry,
    required this.onSignOut,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.householdUnreachableTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: KithSpacing.sm),
        Text(
          switch (error) {
            final Failure failure => householdFailureMessage(l10n, failure),
            _ => l10n.errorGeneric,
          },
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: KithSpacing.lg),
        FilledButton(
          key: HouseholdOnboardingScreen.retryKey,
          onPressed: onRetry,
          child: Text(l10n.tryAgain),
        ),
        const SizedBox(height: KithSpacing.xs),
        TextButton(
          key: HouseholdOnboardingScreen.signOutKey,
          onPressed: onSignOut,
          child: Text(l10n.signOut),
        ),
      ],
    );
  }
}
