// lib/features/auth/presentation/screens/sign_in_screen.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/premium_button.dart';

// ---------------------------------------------------------------------
// 2. SignInScreen
// ---------------------------------------------------------------------

/// A premium, futuristic sign-in screen for Student AI Companion,
/// designed to feel like Nova AI personally welcoming the student back
/// rather than a standard login form.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _entered = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() => _isLoading = false);
    context.go(RouteNames.home);
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("We'll email you a reset link shortly.")),
    );
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In integration coming soon ðŸš€')),
    );
  }

  void _handleCreateAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account creation is coming soon ðŸ’™')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0B1020),
      body: Stack(
        children: <Widget>[
          const _AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedOpacity(
                opacity: _entered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _entered ? Offset.zero : const Offset(0, 0.04),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 32),
                      const _AiLogoSection(),
                      const SizedBox(height: 32),
                      _buildWelcomeText(context),
                      const SizedBox(height: 28),
                      _buildFormCard(context),
                      const SizedBox(height: 20),
                      _buildContinueSection(),
                      const SizedBox(height: 28),
                      _buildDivider(context),
                      const SizedBox(height: 20),
                      _SocialButton(onTap: _handleGoogleSignIn),
                      const SizedBox(height: 28),
                      _buildFooter(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Welcome text
  // ---------------------------------------------------------------------

  Widget _buildWelcomeText(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        Text(
          'Welcome back ðŸ‘‹',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Let's continue your journey toward better focus, attendance, "
          'and academic success.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.65),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Form card
  // ---------------------------------------------------------------------

  Widget _buildFormCard(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          _AuthTextField(
            controller: _emailController,
            label: 'College Email',
            prefixIcon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: _passwordController,
            label: 'Password',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildRememberMeRow(context),
        ],
      ),
    );
  }

  Widget _buildRememberMeRow(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (bool? value) => setState(() => _rememberMe = value ?? true),
            activeColor: const Color(0xFF7C4DFF),
            side: BorderSide(color: Colors.white.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Remember me',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
        ),
        const Spacer(),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: _handleForgotPassword,
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Continue button + divider + footer
  // ---------------------------------------------------------------------

  Widget _buildContinueSection() {
    return Column(
      children: <Widget>[
        PremiumButton.primary(
          label: 'Continue',
          isLoading: _isLoading,
          onPressed: _handleContinue,
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isLoading
              ? Text(
                  'Signing you inâ€¦',
                  key: const ValueKey<String>('loading'),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                )
              : const SizedBox(key: ValueKey<String>('idle'), height: 0),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: Colors.white.withOpacity(0.14))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.14))),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          children: <InlineSpan>[
            const TextSpan(text: 'New here? '),
            TextSpan(
              text: 'Create an account',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.w700,
              ),
              recognizer: TapGestureRecognizer()..onTap = _handleCreateAccount,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// AI logo section
// ---------------------------------------------------------------------

class _AiLogoSection extends StatelessWidget {
  const _AiLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _FloatingOrb(),
        const SizedBox(height: 16),
        Text(
          'Nova AI',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your caring student companion',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    );
  }
}

/// A glowing, continuously floating gradient orb representing Nova AI.
class _FloatingOrb extends StatefulWidget {
  const _FloatingOrb();

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb> {
  bool _floatUp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _floatUp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _floatUp ? 0 : 6, end: _floatUp ? 6 : 0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      onEnd: () {
        if (mounted) setState(() => _floatUp = !_floatUp);
      },
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(offset: Offset(0, value - 3), child: child);
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF00E5FF), Color(0xFF7C4DFF)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.5),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Auth text field
// ---------------------------------------------------------------------

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _focused
              ? const Color(0xFF00E5FF).withOpacity(0.6)
              : Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: Focus(
        onFocusChange: (bool hasFocus) => setState(() => _focused = hasFocus),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(widget.prefixIcon, color: Colors.white.withOpacity(0.55), size: 20),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 3. Background
// ---------------------------------------------------------------------

/// A living, futuristic gradient background with blurred, gently
/// drifting purple and cyan glow circles.
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B1020), Color(0xFF121A2F)],
          ),
        ),
        child: const Stack(
          children: <Widget>[
            _DriftingGlow(
              alignment: Alignment(-1.1, -0.9),
              color: Color(0xFF7C4DFF),
              size: 260,
            ),
            _DriftingGlow(
              alignment: Alignment(1.2, 0.9),
              color: Color(0xFF00E5FF),
              size: 280,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriftingGlow extends StatefulWidget {
  const _DriftingGlow({
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  State<_DriftingGlow> createState() => _DriftingGlowState();
}

class _DriftingGlowState extends State<_DriftingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double drift = _controller.value * 18;
        return Align(
          alignment: widget.alignment,
          child: Transform.translate(offset: Offset(drift, -drift), child: child),
        );
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 65, sigmaY: 65),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.32),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// 4. Social Button
// ---------------------------------------------------------------------

/// A full-width, glassmorphism "Continue with Google" button.
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Continue with Google',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

