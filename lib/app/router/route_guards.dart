// lib/app/router/route_guards.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';

// ---------------------------------------------------------------------
// 2. User Session Model
// ---------------------------------------------------------------------

/// A snapshot of the current user's authentication and onboarding
/// state, used by [AppRouteGuards] to decide whether a navigation
/// should be redirected.
///
/// This is intentionally decoupled from any specific auth provider so
/// it can be produced from Firebase Auth, a Riverpod provider, or any
/// other session source later.
@immutable
class UserSession {
  const UserSession({
    required this.isAuthenticated,
    required this.isFirstLaunch,
    required this.hasCompletedProfile,
  });

  /// Whether the user currently has a valid, signed-in session.
  final bool isAuthenticated;

  /// Whether this is the user's first time opening the app (i.e.
  /// onboarding has not yet been completed).
  final bool isFirstLaunch;

  /// Whether the signed-in user has finished the profile setup step.
  final bool hasCompletedProfile;

  /// A default, signed-out, first-launch session.
  static const UserSession guest = UserSession(
    isAuthenticated: false,
    isFirstLaunch: true,
    hasCompletedProfile: false,
  );

  UserSession copyWith({
    bool? isAuthenticated,
    bool? isFirstLaunch,
    bool? hasCompletedProfile,
  }) {
    return UserSession(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
    );
  }

  @override
  String toString() {
    return 'UserSession(isAuthenticated: $isAuthenticated, '
        'isFirstLaunch: $isFirstLaunch, '
        'hasCompletedProfile: $hasCompletedProfile)';
  }
}

// ---------------------------------------------------------------------
// 3. App Route Guards
// ---------------------------------------------------------------------

/// Centralized route protection for Student AI Companion.
///
/// Decides whether a navigation attempt should be redirected based on
/// the current [UserSession] — protecting authenticated routes,
/// sending unauthenticated users to sign-in, sending first-time users
/// to onboarding, and preventing already-signed-in users from
/// reopening auth screens.
class AppRouteGuards {
  AppRouteGuards._();

  // ---------------------------------------------------------------------
  // 4. Splash Guard
  // ---------------------------------------------------------------------

  /// Decides where the splash screen should send the user.
  static String? handleSplash(UserSession session) {
    _debug('Evaluating splash guard for $session');

    if (session.isFirstLaunch) {
      _debug('First launch — redirecting to onboarding');
      return RouteNames.onboarding;
    }

    if (!session.isAuthenticated) {
      _debug('Not authenticated — redirecting to sign-in');
      return RouteNames.signIn;
    }

    if (!session.hasCompletedProfile) {
      _debug('Profile incomplete — redirecting to profile setup');
      return RouteNames.profileSetup;
    }

    _debug('Session ready — redirecting to home');
    return RouteNames.home;
  }

  // ---------------------------------------------------------------------
  // 5. Auth Guard
  // ---------------------------------------------------------------------

  /// Prevents an already-authenticated user from reopening an auth
  /// screen (sign-in, sign-up, profile setup already complete).
  static String? authGuard(GoRouterState state, UserSession session) {
    if (!session.isAuthenticated) {
      _debug('Guest accessing auth route ${state.matchedLocation} — allowed');
      return null;
    }

    if (!session.hasCompletedProfile) {
      _debug('Authenticated but profile incomplete — redirecting to profile setup');
      return RouteNames.profileSetup;
    }

    _debug('Already authenticated — redirecting away from auth route to home');
    return RouteNames.home;
  }

  // ---------------------------------------------------------------------
  // 6. Protected Guard
  // ---------------------------------------------------------------------

  /// Protects any route that requires a signed-in, fully onboarded
  /// user, preserving the intended destination for post-sign-in
  /// restoration.
  static String? protectedGuard(GoRouterState state, UserSession session) {
    if (!session.isAuthenticated) {
      final String target = state.matchedLocation;
      _debug('Unauthenticated access to $target — redirecting to sign-in');
      return buildSignInRedirect(target);
    }

    if (!session.hasCompletedProfile) {
      _debug('Profile incomplete — redirecting to profile setup');
      return RouteNames.profileSetup;
    }

    return null;
  }

  // ---------------------------------------------------------------------
  // 7. Onboarding Guard
  // ---------------------------------------------------------------------

  /// Prevents a user who has already completed onboarding from seeing
  /// it again.
  static String? onboardingGuard(UserSession session) {
    if (!session.isFirstLaunch) {
      _debug('Onboarding already completed — redirecting to sign-in');
      return RouteNames.signIn;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 8. Global Redirect
  // ---------------------------------------------------------------------

  /// The single entry point wired into `GoRouter(redirect: ...)`,
  /// dispatching to the correct guard based on the current location.
  static String? globalRedirect(GoRouterState state, UserSession session) {
    final String path = state.matchedLocation;

    if (path == RouteNames.splash) {
      return handleSplash(session);
    }

    if (RouteNames.isAuthRoute(path)) {
      return authGuard(state, session);
    }

    if (path == RouteNames.onboarding) {
      return onboardingGuard(session);
    }

    if (RouteNames.isProtectedRoute(path)) {
      return protectedGuard(state, session);
    }

    return null;
  }

  // ---------------------------------------------------------------------
  // 9. Redirect Helpers
  // ---------------------------------------------------------------------

  /// Builds a sign-in URL that preserves [target] via a `from` query
  /// parameter, e.g. `/auth/sign-in?from=%2Fattendance`.
  static String buildSignInRedirect(String target) {
    return '${RouteNames.signIn}?from=${Uri.encodeComponent(target)}';
  }

  /// Reads and safely decodes the `from` query parameter from [uri],
  /// returning [fallback] if it's missing, empty, or malformed.
  static String restoreIntendedRoute(
    Uri uri, {
    String fallback = RouteNames.home,
  }) {
    final String? from = uri.queryParameters['from'];
    if (from == null || from.isEmpty) return fallback;

    try {
      final String decoded = Uri.decodeComponent(from);
      return decoded.isEmpty ? fallback : decoded;
    } catch (_) {
      return fallback;
    }
  }

  // ---------------------------------------------------------------------
  // 10. Debug Utilities
  // ---------------------------------------------------------------------

  static void _debug(String message) {
    if (kDebugMode) {
      debugPrint('[ROUTE_GUARD] $message');
    }
  }
}

// ---------------------------------------------------------------------
// 11. Example Scenarios
// ---------------------------------------------------------------------

/// Simple, dependency-free demonstrations of common [AppRouteGuards]
/// scenarios, useful for quick manual testing without needing a real
/// [GoRouterState].
class RouteGuardExamples {
  RouteGuardExamples._();

  /// A guest (signed out) attempting to open the attendance screen.
  static String guestTryingAttendance() {
    return AppRouteGuards.buildSignInRedirect(RouteNames.attendance);
  }

  /// A brand-new user opening the app for the first time.
  static String firstLaunchFlow() {
    return AppRouteGuards.handleSplash(UserSession.guest) ?? RouteNames.home;
  }

  /// A fully authenticated, fully onboarded user opening the app.
  static String authenticatedHome() {
    const UserSession session = UserSession(
      isAuthenticated: true,
      isFirstLaunch: false,
      hasCompletedProfile: true,
    );
    return AppRouteGuards.handleSplash(session) ?? RouteNames.home;
  }

  /// An authenticated user who has not yet finished profile setup.
  static String incompleteProfileFlow() {
    const UserSession session = UserSession(
      isAuthenticated: true,
      isFirstLaunch: false,
      hasCompletedProfile: false,
    );
    return AppRouteGuards.handleSplash(session) ?? RouteNames.home;
  }
}

