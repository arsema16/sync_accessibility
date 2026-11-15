import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

/// Invoked by [AuthForm] once a session exists.
typedef AuthFormCallback = void Function(SyncUser user);

/// Email + password form used both full-screen ([SignInScreen]) and inside
/// [showAuthPrompt].
///
/// Handles sign-in and account creation (toggled with a text button), client
/// side validation, loading state and [AuthFailure] messages. It only calls
/// [onCompleted] when a session actually exists; if the project requires
/// email confirmation the form switches to sign-in mode and shows a notice
/// instead.
class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({
    super.key,
    this.initialEmail,
    this.notice,
    required this.onCompleted,
    this.showModeToggle = true,
    this.submitLabel,
  });

  /// Prefills the email field (e.g. the address collected during onboarding).
  final String? initialEmail;

  /// Extra context shown above the fields, e.g. why we are asking.
  final String? notice;

  final AuthFormCallback onCompleted;

  /// Whether to show the "I already have an account" / "Create a new
  /// account" switch. Off when the caller has pinned a mode.
  final bool showModeToggle;

  /// Overrides the submit button label (defaults to the current mode).
  final String? submitLabel;

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  bool _signUp = false;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _notice = widget.notice;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    final auth = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final SyncUser user;
      if (_signUp) {
        user = await auth.signUp(email: email, password: password);
        if (auth.currentUser == null) {
          // Account created but email confirmation is pending: switch to
          // sign-in mode and tell the user what to do next.
          if (!mounted) return;
          setState(() {
            _loading = false;
            _notice = AppStrings.confirmationSent(email);
            _signUp = false;
            _passwordController.clear();
          });
          return;
        }
      } else {
        user = await auth.signIn(email: email, password: password);
      }
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onCompleted(user);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppStrings.authFailed;
      });
    }
  }

  void _switchMode() {
    setState(() {
      _signUp = !_signUp;
      _error = null;
      _notice = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return AppStrings.requiredError;
    final looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!looksLikeEmail) return AppStrings.invalidEmailError;
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return AppStrings.requiredError;
    // Only enforce the length rule when creating an account — for sign-in a
    // short password simply fails authentication.
    if (_signUp && password.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitLabel = widget.submitLabel ??
        (_signUp ? AppStrings.createAccountAction : AppStrings.signInAction);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_notice != null) ...[
            _Message(
              message: _notice!,
              icon: Icons.info_outline,
              color: theme.colorScheme.primary,
              background: theme.colorScheme.primaryContainer,
              foreground: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.email],
            autocorrect: false,
            decoration: InputDecoration(
              labelText: AppStrings.emailLabel,
              hintText: AppStrings.authEmailHint,
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: AppColors.pageGradientEnd,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: _signUp
                ? const <String>[AutofillHints.newPassword]
                : const <String>[AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: AppStrings.passwordLabel,
              hintText: AppStrings.passwordHint,
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor: AppColors.pageGradientEnd,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                tooltip:
                    _obscurePassword ? AppStrings.showPassword : AppStrings.hidePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _Message(
              message: _error!,
              icon: Icons.error_outline,
              color: theme.colorScheme.error,
              background: theme.colorScheme.errorContainer,
              foreground: theme.colorScheme.onErrorContainer,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(submitLabel),
          ),
          if (widget.showModeToggle) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loading ? null : _switchMode,
              child: Text(
                _signUp
                    ? AppStrings.iHaveAnAccount
                    : AppStrings.switchToSignUp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An announced message box (errors and notices are read out immediately).
class _Message extends StatelessWidget {
  const _Message({
    required this.message,
    required this.icon,
    required this.color,
    required this.background,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: foreground, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [AuthForm] in a modal dialog and resolves `true` once a session
/// exists (the user signed in or created an account), `false` if dismissed.
///
/// Used by flows that need a user but must not force one upfront — submitting
/// an application or applying for a job.
Future<bool> showAuthPrompt(
  BuildContext context, {
  String? initialEmail,
  String? notice,
}) async {
  // Announce the prompt's title when read-aloud is on. The dialog has no
  // initState of its own, so the title is spoken from here.
  _speakAuthPromptTitle(context);
  final signedIn = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(AppStrings.authPromptTitle),
      content: SizedBox(
        width: 360,
        child: AuthForm(
          initialEmail: initialEmail,
          notice: notice,
          onCompleted: (_) => Navigator.of(dialogContext).pop(true),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.cancel),
        ),
      ],
    ),
  );
  return signedIn ?? false;
}

/// Reads [AppStrings.authPromptTitle] aloud using the providers mounted above
/// [context] — a no-op unless the read-aloud preference is on.
void _speakAuthPromptTitle(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  final access = container.read(accessPreferencesNotifierProvider);
  if (access.readAloud) {
    container.read(readAloudProvider)(AppStrings.authPromptTitle);
  }
}
