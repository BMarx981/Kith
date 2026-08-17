import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_onboarding_controller.dart';
import 'package:kith/features/household/application/household_onboarding_state.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/household_field_validator.dart';
import 'package:kith/features/household/presentation/household_failure_message.dart';

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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: membership.hasError
                  ? _Unreadable(
                      error: membership.error!,
                      onRetry: () => ref.invalidate(householdIdsProvider),
                      onSignOut: () => ref.read(authServiceProvider).signOut(),
                    )
                  : _form(context, state),
            ),
          ),
        ),
      ),
    );
  }

  /// The create-or-join form itself.
  Widget _form(BuildContext context, HouseholdOnboardingState state) {
    final theme = Theme.of(context);
    final isJoining = state.mode == HouseholdOnboardingMode.join;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isJoining ? 'Join a household' : 'Start a household',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isJoining
                ? 'Enter the invite code from whoever set yours up.'
                : 'You can invite the rest of your household next.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          if (isJoining)
            TextFormField(
              key: HouseholdOnboardingScreen.codeFieldKey,
              controller: _codeController,
              enabled: !state.isSubmitting,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'KH7-RQ2',
                border: OutlineInputBorder(),
              ),
              validator: HouseholdFieldValidator.inviteCode,
            )
          else
            TextFormField(
              key: HouseholdOnboardingScreen.nameFieldKey,
              controller: _nameController,
              enabled: !state.isSubmitting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Household name',
                hintText: 'The Marx house',
                border: OutlineInputBorder(),
              ),
              validator: HouseholdFieldValidator.name,
            ),
          const SizedBox(height: 16),
          TextFormField(
            key: HouseholdOnboardingScreen.displayNameFieldKey,
            controller: _displayNameController,
            enabled: !state.isSubmitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.givenName],
            decoration: const InputDecoration(
              labelText: 'Your name',
              helperText: 'What the rest of the household will see.',
              border: OutlineInputBorder(),
            ),
            validator: HouseholdFieldValidator.displayName,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (state.failure case final failure?) ...[
            const SizedBox(height: 16),
            Text(
              householdFailureMessage(failure),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            key: HouseholdOnboardingScreen.submitButtonKey,
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isJoining ? 'Join' : 'Create household'),
          ),
          const SizedBox(height: 8),
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
              isJoining
                  ? 'Start a new household instead'
                  : 'I have an invite code',
            ),
          ),
          TextButton(
            key: HouseholdOnboardingScreen.signOutKey,
            onPressed: state.isSubmitting
                ? null
                : () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cannot reach your household',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          switch (error) {
            final Failure failure => householdFailureMessage(failure),
            _ => 'Something went wrong. Try again.',
          },
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: HouseholdOnboardingScreen.retryKey,
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: HouseholdOnboardingScreen.signOutKey,
          onPressed: onSignOut,
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
