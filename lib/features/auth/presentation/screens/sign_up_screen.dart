// lib/features/auth/presentation/screens/sign_up_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ai_orb.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/premium_button.dart';

/// A premium, warm registration screen for Student AI Companion.
///
/// Creates a real Firebase Authentication account directly (no auth
/// repository/provider exists yet in the project), then hands off to
/// [RouteNames.profileSetup] — this screen never assumes the profile is
/// complete and never fakes success. Google sign-up is exposed as a
/// clean, optional integration point ([onGoogleSignUp]) rather than
/// invented inline, since Google Sign-In isn't wired up yet.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.onGoogleSignUp});

  /// Called when the user taps "Continue with Google". If not provided,
  /// a friendly placeholder message is shown instead of faking the
  /// action.
  final VoidCallback? onGoogleSignUp;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      final UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      if (!mounted) return;
      context.go(RouteNames.profileSetup);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, _friendlyFirebaseMessage(error));
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, ErrorMapper.summarize(ErrorMapper.map(error)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Converts a [FirebaseAuthException] into a short, human-friendly
  /// message. `ErrorMapper` doesn't yet recognize Firebase-specific
  /// error codes, so this is mapped locally rather than expanding the
  /// shared error framework for a single screen's needs.
  String _friendlyFirebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Account creation is temporarily unavailable. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return "We couldn't create your account. Please try again.";
    }
  }

  void _handleGoogleSignUp() {
    if (widget.onGoogleSignUp != null) {
      widget.onGoogleSignUp!();
      return;
    }
    AppSnackbar.info(context, "Google sign-up isn't connected yet.");
  }

  void _handleSignIn() {
    context.go(RouteNames.signIn);
  }

  String? _confirmPasswordValidator(String? value) {
    return AppValidators.confirmPassword(value, _passwordController.text);
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[scheme.primary.withOpacity(0.08), scheme.surface],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl + bottomInset,
              ),
              child: AnimatedOpacity(
                opacity: _entered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _entered ? Offset.zero : const Offset(0, 0.03),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppSpacing.vLg,
                        _Header(scheme: scheme),
                        AppSpacing.vXxl,
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[AutofillHints.name],
                                validator: AppValidators.name,
                                onFieldSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_emailFocusNode),
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              AppSpacing.vLg,
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[AutofillHints.email],
                                validator: AppValidators.email,
                                onFieldSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_passwordFocusNode),
                                decoration: const InputDecoration(
                                  labelText: 'College Email',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                              ),
                              AppSpacing.vLg,
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[AutofillHints.newPassword],
                                validator: AppValidators.password,
                                onFieldSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_confirmPasswordFocusNode),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: _VisibilityToggle(
                                    obscured: _obscurePassword,
                                    onToggle: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.vSm,
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Use 8+ characters with uppercase, lowercase, '
                                  'a number, and a symbol.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurface.withOpacity(0.5),
                                      ),
                                ),
                              ),
                              AppSpacing.vLg,
                              TextFormField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                validator: _confirmPasswordValidator,
                                onFieldSubmitted: (_) => _handleCreateAccount(),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: _VisibilityToggle(
                                    obscured: _obscureConfirmPassword,
                                    onToggle: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.vXl,
                        Semantics(
                          button: true,
                          label: 'Create account',
                          child: PremiumButton.primary(
                            label: 'Create account',
                            isLoading: _isSubmitting,
                            onPressed: _isSubmitting ? null : _handleCreateAccount,
                          ),
                        ),
                        AppSpacing.vXl,
                        _OrDivider(scheme: scheme),
                        AppSpacing.vLg,
                        _GoogleButton(onTap: _handleGoogleSignUp, scheme: scheme),
                        AppSpacing.vXxl,
                        Text(
                          'By creating an account, you agree to the Terms of '
                          'Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.45),
                              ),
                        ),
                        AppSpacing.vLg,
                        _SignInFooter(scheme: scheme, onTap: _handleSignIn),
                        AppSpacing.vLg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        const Center(
          child: AiOrb(size: 76, mood: AiOrbMood.idle, showFace: true),
        ),
        AppSpacing.vLg,
        Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        AppSpacing.vSm,
        Text(
          "Let's build your student journey together.",
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onToggle});

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          key: ValueKey<bool>(obscured),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: scheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: TextStyle(color: scheme.onSurface.withOpacity(0.5), fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, required this.scheme});

  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with Google',
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.onSurface,
            side: BorderSide(color: scheme.outline.withOpacity(0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInFooter extends StatelessWidget {
  const _SignInFooter({required this.scheme, required this.onTap});

  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Sign in to your existing account',
        child: Wrap(
          alignment: WrapAlignment.center,
          children: <Widget>[
            Text(
              'Already have an account? ',
              style: TextStyle(color: scheme.onSurface.withOpacity(0.6), fontSize: 13),
            ),
            GestureDetector(
              onTap: onTap,
              child: Text(
                'Sign in',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

