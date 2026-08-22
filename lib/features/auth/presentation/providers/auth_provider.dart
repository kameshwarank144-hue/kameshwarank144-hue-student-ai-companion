// lib/features/auth/presentation/providers/auth_provider.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';

part 'auth_provider.g.dart';

// ---------------------------------------------------------------------
// Auth status
// ---------------------------------------------------------------------

/// The current session status, independent of any in-flight operation.
enum AuthStatus {
  /// The very first frame, before Firebase has reported an initial
  /// auth state.
  initial,

  /// A Firebase user is currently signed in.
  authenticated,

  /// No Firebase user is currently signed in.
  unauthenticated,
}

// ---------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------

/// Immutable authentication/session state for Student AI Companion.
///
/// [status] and [user] reflect the actual Firebase session; [isLoading]
/// and [failure] reflect the most recent auth *operation* (sign in,
/// sign up, sign out, password reset) and are intentionally kept
/// separate from [status] so that, for example, a failed password-reset
/// request never disturbs an already-authenticated session.
@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isLoading = false,
    this.failure,
  });

  final AuthStatus status;

  /// The current Firebase user, if any. Never a fabricated/fake user.
  final User? user;

  /// Whether an auth operation (sign in/up/out, password reset, Google
  /// sign-in) is currently in flight.
  final bool isLoading;

  /// The failure from the most recent auth operation, if it failed.
  /// Cleared at the start of the next operation.
  final Failure? failure;

  /// True only when a real Firebase session is active.
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

// ---------------------------------------------------------------------
// Auth controller
// ---------------------------------------------------------------------

/// The central Riverpod authentication/session controller for Student
/// AI Companion.
///
/// Listens to `FirebaseAuth.instance.authStateChanges()` so [state]
/// always reflects the real Firebase session, and exposes [signIn],
/// [signUp], [signOut], [sendPasswordResetEmail], [signInWithGoogle],
/// and [refreshUser] as the single, coordinated entry points for every
/// auth-related action in the app. No authentication logic belongs in
/// any screen — screens only watch this controller and call these
/// methods.
///
/// If a dedicated `AuthRepository` is introduced later, this
/// controller's public API is designed to stay the same: swap the
/// direct `FirebaseAuth.instance` calls below for repository calls
/// without touching any screen that already depends on
/// [authControllerProvider].
@riverpod
class AuthController extends _$AuthController {
  StreamSubscription<User?>? _authStateSubscription;

  @override
  AuthState build() {
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    ref.onDispose(() {
      _authStateSubscription?.cancel();
    });

    final User? current = FirebaseAuth.instance.currentUser;
    return current != null
        ? AuthState(status: AuthStatus.authenticated, user: current)
        : const AuthState(status: AuthStatus.unauthenticated);
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, clearUser: true);
    }
  }

  // ---------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------

  /// Signs in with [email] and [password]. No-ops if an auth operation
  /// is already in flight, preventing duplicate sign-in attempts.
  Future<void> signIn({required String email, required String password}) async {
    if (state.isLoading) return;

    final String trimmedEmail = email.trim();
    state = state.copyWith(isLoading: true, clearFailure: true);

    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: credential.user,
        isLoading: false,
        clearFailure: true,
      );
      AppLogger.authSignIn(trimmedEmail);
    } on FirebaseAuthException catch (error) {
      final Failure failure = _mapFirebaseAuthError(error);
      state = state.copyWith(isLoading: false, failure: failure);
      AppLogger.authFailure(trimmedEmail, error.code);
    } catch (error) {
      state = state.copyWith(isLoading: false, failure: ErrorMapper.map(error));
    }
  }

  // ---------------------------------------------------------------------
  // Sign up
  // ---------------------------------------------------------------------

  /// Creates a new account with [email] and [password], optionally
  /// setting [displayName] on the resulting Firebase user. Never stores
  /// the password anywhere beyond this single Firebase call.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (state.isLoading) return;

    final String trimmedEmail = email.trim();
    state = state.copyWith(isLoading: true, clearFailure: true);

    try {
      final UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final String? trimmedName = displayName?.trim();
      if (trimmedName != null && trimmedName.isNotEmpty) {
        await credential.user?.updateDisplayName(trimmedName);
        await credential.user?.reload();
      }

      final User? refreshedUser = FirebaseAuth.instance.currentUser;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: refreshedUser,
        isLoading: false,
        clearFailure: true,
      );
      AppLogger.info(
        LogCategory.auth,
        'Account created',
        data: <String, dynamic>{'email': trimmedEmail},
      );
    } on FirebaseAuthException catch (error) {
      final Failure failure = _mapFirebaseAuthError(error);
      state = state.copyWith(isLoading: false, failure: failure);
      AppLogger.authFailure(trimmedEmail, error.code);
    } catch (error) {
      state = state.copyWith(isLoading: false, failure: ErrorMapper.map(error));
    }
  }

  // ---------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------

  /// Signs the current user out. No-ops if already signing out or if no
  /// user is currently signed in, preventing duplicate sign-out calls.
  Future<void> signOut() async {
    if (state.isLoading || !state.isAuthenticated) return;

    state = state.copyWith(isLoading: true, clearFailure: true);

    try {
      await FirebaseAuth.instance.signOut();
      // `_onAuthStateChanged` will flip status/user to unauthenticated;
      // this just clears the loading flag once the call completes.
      state = state.copyWith(isLoading: false, clearFailure: true);
      AppLogger.authSignOut();
    } catch (error) {
      state = state.copyWith(isLoading: false, failure: ErrorMapper.map(error));
    }
  }

  // ---------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------

  /// Sends a password-reset email to [email]. Deliberately does not
  /// alter [AuthState.status] or [AuthState.user] — a failed or
  /// successful reset request never signs the current user out or
  /// changes their session.
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (state.isLoading) return;

    final String trimmedEmail = email.trim();
    state = state.copyWith(isLoading: true, clearFailure: true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmedEmail);
      state = state.copyWith(isLoading: false, clearFailure: true);
      AppLogger.info(
        LogCategory.auth,
        'Password reset email requested',
        data: <String, dynamic>{'email': trimmedEmail},
      );
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(isLoading: false, failure: _mapFirebaseAuthError(error));
    } catch (error) {
      state = state.copyWith(isLoading: false, failure: ErrorMapper.map(error));
    }
  }

  // ---------------------------------------------------------------------
  // Google sign-in
  // ---------------------------------------------------------------------

  /// Signs in with Google via `google_sign_in` + Firebase credential
  /// exchange. Requires the platform-level Google Sign-In configuration
  /// (Android `google-services.json` OAuth client, iOS reversed client
  /// ID URL scheme) to already be in place — this method never fakes a
  /// successful result, and safely no-ops (clearing loading without
  /// setting a failure) if the user cancels the Google account picker.
  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearFailure: true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User cancelled the Google account picker — not a failure.
        state = state.copyWith(isLoading: false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userCredential.user,
        isLoading: false,
        clearFailure: true,
      );
      AppLogger.info(LogCategory.auth, 'Signed in with Google');
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(isLoading: false, failure: _mapFirebaseAuthError(error));
    } catch (error) {
      state = state.copyWith(isLoading: false, failure: ErrorMapper.map(error));
    }
  }

  // ---------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------

  /// Reloads the current Firebase user (e.g. after email verification
  /// or an external profile change) and refreshes [state.user].
  Future<void> refreshUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.reload();
      state = state.copyWith(user: FirebaseAuth.instance.currentUser);
    } catch (error) {
      state = state.copyWith(failure: ErrorMapper.map(error));
    }
  }

  // ---------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------

  /// Maps a [FirebaseAuthException] into the project's existing
  /// [Failure] hierarchy. Codes with a matching [AuthFailure] factory
  /// reuse it directly; the remaining Firebase-specific codes are given
  /// a minimal, locally-defined friendly message via [AuthFailure]'s
  /// public constructor rather than expanding the shared error
  /// framework for Firebase-only concerns.
  Failure _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailure.invalidCredentials();
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'invalid-email':
        return AuthFailure(
          message: 'Please enter a valid email address.',
          code: error.code,
        );
      case 'user-disabled':
        return AuthFailure(
          message: 'This account has been disabled. Please contact support.',
          code: error.code,
        );
      case 'operation-not-allowed':
        return AuthFailure(
          message: 'This sign-in method is currently unavailable.',
          code: error.code,
        );
      case 'too-many-requests':
        return AuthFailure(
          message: 'Too many attempts. Please wait a moment and try again.',
          code: error.code,
        );
      case 'network-request-failed':
        return AuthFailure(
          message: 'No internet connection. Please check your network and try again.',
          code: error.code,
        );
      default:
        return AuthFailure(
          message: "We couldn't complete that request. Please try again.",
          code: error.code,
        );
    }
  }
}

// ---------------------------------------------------------------------
// Derived, copy-safe providers
// ---------------------------------------------------------------------

/// The current Firebase user, or `null` if signed out. Convenient for
/// screens (e.g. profile setup) that only need the user, not the full
/// [AuthState].
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authControllerProvider).user;
}

/// Whether a real, authenticated Firebase session is active — the
/// primary signal future route guards should key off of.
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
}

/// Whether an auth operation is currently in flight.
@riverpod
bool isAuthLoading(IsAuthLoadingRef ref) {
  return ref.watch(authControllerProvider).isLoading;
}

/// The failure from the most recent auth operation, if any.
@riverpod
Failure? authFailure(AuthFailureRef ref) {
  return ref.watch(authControllerProvider).failure;
}

