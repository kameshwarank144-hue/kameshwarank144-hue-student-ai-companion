// lib/core/error/failure.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:async';

import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------
// 2. Base Failure
// ---------------------------------------------------------------------

/// The base type for every domain-level failure in Student AI
/// Companion, forming a Clean Architecture compatible error hierarchy
/// shared across authentication, networking, AI chat, timetable,
/// attendance, todo, reminders, study mode, Notes AI, the local
/// database, permissions, and the overlay assistant.
abstract class Failure extends Equatable {
  const Failure({required this.message, this.code, this.cause});

  /// A human-friendly message suitable for direct display in the UI
  /// (e.g. via `AppSnackbar`).
  final String message;

  /// An optional short, stable identifier for this failure (useful for
  /// analytics, logging, or future localization lookups).
  final String? code;

  /// The original error or exception that caused this failure, if any.
  final Object? cause;

  @override
  List<Object?> get props => <Object?>[message, code, cause];

  @override
  String toString() {
    return '$runtimeType(code: ${code ?? '-'}, message: $message)';
  }
}

// ---------------------------------------------------------------------
// 3. Generic Failure
// ---------------------------------------------------------------------

/// A catch-all failure for errors that don't fit a more specific
/// category.
class GenericFailure extends Failure {
  const GenericFailure({
    super.message = 'Something went wrong. Please try again.',
    super.code,
    super.cause,
  });
}

// ---------------------------------------------------------------------
// 4. Network Failure
// ---------------------------------------------------------------------

/// A failure originating from an HTTP/network operation (Dio, REST
/// APIs, OpenAI/Gemini calls, Firebase network calls).
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code, super.cause});

  factory NetworkFailure.noInternet() => const NetworkFailure(
        message: 'No internet connection. Nova AI will continue working '
            'with offline data.',
        code: 'no_internet',
      );

  factory NetworkFailure.timeout() => const NetworkFailure(
        message: 'The server is taking too long to respond.',
        code: 'timeout',
      );

  factory NetworkFailure.serverError([String? message]) => NetworkFailure(
        message: message ??
            'The server encountered a problem. Please try again later.',
        code: 'server_error',
      );

  factory NetworkFailure.rateLimited() => const NetworkFailure(
        message: 'Too many requests right now. Please wait a moment.',
        code: 'rate_limited',
      );

  factory NetworkFailure.cancelled() => const NetworkFailure(
        message: 'Request was cancelled.',
        code: 'cancelled',
      );
}

// ---------------------------------------------------------------------
// 5. Authentication Failure
// ---------------------------------------------------------------------

/// A failure from sign-in, sign-up, or session management.
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.cause});

  factory AuthFailure.invalidCredentials() => const AuthFailure(
        message: 'Incorrect email or password.',
        code: 'invalid_credentials',
      );

  factory AuthFailure.emailAlreadyInUse() => const AuthFailure(
        message: 'This email is already registered.',
        code: 'email_in_use',
      );

  factory AuthFailure.userNotFound() => const AuthFailure(
        message: 'We couldn\'t find an account with that email.',
        code: 'user_not_found',
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        message: 'Please choose a stronger password.',
        code: 'weak_password',
      );

  factory AuthFailure.sessionExpired() => const AuthFailure(
        message: 'Your session has expired. Please sign in again.',
        code: 'session_expired',
      );

  factory AuthFailure.permissionDenied() => const AuthFailure(
        message: 'You don\'t have permission to do that.',
        code: 'permission_denied',
      );
}

// ---------------------------------------------------------------------
// 6. Database Failure
// ---------------------------------------------------------------------

/// A failure from a local database operation (Hive or Isar).
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code, super.cause});

  factory DatabaseFailure.read() => const DatabaseFailure(
        message: 'Unable to read local data.',
        code: 'db_read',
      );

  factory DatabaseFailure.write() => const DatabaseFailure(
        message: 'Unable to save your changes.',
        code: 'db_write',
      );

  factory DatabaseFailure.delete() => const DatabaseFailure(
        message: 'Unable to delete that item.',
        code: 'db_delete',
      );

  factory DatabaseFailure.initialization() => const DatabaseFailure(
        message: 'Database initialization failed.',
        code: 'db_init',
      );

  factory DatabaseFailure.corrupted() => const DatabaseFailure(
        message: 'Your local data appears to be corrupted.',
        code: 'db_corrupted',
      );
}

// ---------------------------------------------------------------------
// 7. Validation Failure
// ---------------------------------------------------------------------

/// A simple pass-through failure for form/input validation errors,
/// e.g. `ValidationFailure('Please enter a valid email address')`.
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {super.code, super.cause})
      : super(message: message);
}

// ---------------------------------------------------------------------
// 8. Permission Failure
// ---------------------------------------------------------------------

/// A failure from a denied or unavailable device permission.
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code, super.cause});

  factory PermissionFailure.notification() => const PermissionFailure(
        message: 'Notification permission is needed so Nova AI can remind '
            'you about classes, assignments, and study sessions.',
        code: 'permission_notification',
      );

  factory PermissionFailure.microphone() => const PermissionFailure(
        message: 'Microphone permission is needed so you can talk to '
            'Nova AI and create voice reminders.',
        code: 'permission_microphone',
      );

  factory PermissionFailure.storage() => const PermissionFailure(
        message: 'Storage permission is needed to save and open your '
            'notes and study material.',
        code: 'permission_storage',
      );

  factory PermissionFailure.overlay() => const PermissionFailure(
        message: 'Overlay permission is needed so Nova AI\'s floating '
            'assistant can stay with you across other apps.',
        code: 'permission_overlay',
      );

  factory PermissionFailure.usageAccess() => const PermissionFailure(
        message: 'Usage access is needed to show your screen time '
            'insights.',
        code: 'permission_usage_access',
      );

  factory PermissionFailure.location() => const PermissionFailure(
        message: 'Location permission is needed for location-based '
            'reminders.',
        code: 'permission_location',
      );
}

// ---------------------------------------------------------------------
// 9. AI Failure
// ---------------------------------------------------------------------

/// A failure from Nova AI's chat, voice, or generation pipeline.
class AiFailure extends Failure {
  const AiFailure({required super.message, super.code, super.cause});

  factory AiFailure.unavailable() => const AiFailure(
        message: 'Nova AI is temporarily unavailable. I\'ll be back in a '
            'moment 💙',
        code: 'ai_unavailable',
      );

  factory AiFailure.apiKeyMissing() => const AiFailure(
        message: 'Nova AI needs to be set up before we can chat. Please '
            'check your settings.',
        code: 'ai_api_key_missing',
      );

  factory AiFailure.responseGeneration() => const AiFailure(
        message: 'I had trouble putting that into words. Could you try '
            'asking again? 💙',
        code: 'ai_response_generation',
      );

  factory AiFailure.voiceProcessing() => const AiFailure(
        message: 'I couldn\'t quite hear that. Mind trying again?',
        code: 'ai_voice_processing',
      );

  factory AiFailure.contextTooLarge() => const AiFailure(
        message: 'That conversation got a little long for me to follow. '
            'Let\'s start a fresh topic 💙',
        code: 'ai_context_too_large',
      );
}

// ---------------------------------------------------------------------
// 10. Timetable Failure
// ---------------------------------------------------------------------

/// A failure from timetable creation, import, or lookup.
class TimetableFailure extends Failure {
  const TimetableFailure({required super.message, super.code, super.cause});

  factory TimetableFailure.invalidTimeRange() => const TimetableFailure(
        message: 'The class end time must be after the start time.',
        code: 'timetable_invalid_range',
      );

  factory TimetableFailure.overlappingClass() => const TimetableFailure(
        message: 'This class overlaps with another class already on your '
            'timetable.',
        code: 'timetable_overlap',
      );

  factory TimetableFailure.importFailed() => const TimetableFailure(
        message: 'We couldn\'t import your timetable. Please check the '
            'file and try again.',
        code: 'timetable_import_failed',
      );

  factory TimetableFailure.notFound() => const TimetableFailure(
        message: 'That timetable entry could not be found.',
        code: 'timetable_not_found',
      );
}

// ---------------------------------------------------------------------
// 11. Attendance Failure
// ---------------------------------------------------------------------

/// A failure from attendance tracking or calculation.
class AttendanceFailure extends Failure {
  const AttendanceFailure({required super.message, super.code, super.cause});

  factory AttendanceFailure.invalidValues() => const AttendanceFailure(
        message: 'Attended classes can\'t be more than total classes.',
        code: 'attendance_invalid_values',
      );

  factory AttendanceFailure.subjectNotFound() => const AttendanceFailure(
        message: 'We couldn\'t find attendance records for that subject.',
        code: 'attendance_subject_not_found',
      );

  factory AttendanceFailure.calculationFailed() => const AttendanceFailure(
        message: 'We had trouble calculating your attendance. Please try '
            'again.',
        code: 'attendance_calculation_failed',
      );
}

// ---------------------------------------------------------------------
// 12. Reminder Failure
// ---------------------------------------------------------------------

/// A failure from creating or scheduling a reminder.
class ReminderFailure extends Failure {
  const ReminderFailure({required super.message, super.code, super.cause});

  factory ReminderFailure.scheduleFailed() => const ReminderFailure(
        message: 'We couldn\'t schedule that reminder. Please try again.',
        code: 'reminder_schedule_failed',
      );

  factory ReminderFailure.pastDate() => const ReminderFailure(
        message: 'Please choose a reminder time in the future.',
        code: 'reminder_past_date',
      );

  factory ReminderFailure.permissionRequired() => const ReminderFailure(
        message: 'Notification permission is required to set reminders.',
        code: 'reminder_permission_required',
      );
}

// ---------------------------------------------------------------------
// 13. Failure Severity
// ---------------------------------------------------------------------

/// How serious a [Failure] is, useful for deciding how loudly to
/// surface it in the UI (snackbar vs. dialog vs. silent log).
enum FailureSeverity {
  low,
  medium,
  high,
  critical,
}

// ---------------------------------------------------------------------
// 14. Failure Extensions
// ---------------------------------------------------------------------

/// Convenience getters for working with any [Failure] generically.
extension FailureX on Failure {
  /// Whether the app can reasonably recover from this failure on its
  /// own (e.g. by retrying), without requiring the user to change
  /// something first.
  bool get isRecoverable {
    if (this is NetworkFailure || this is AiFailure || this is ReminderFailure) {
      return true;
    }
    return false;
  }

  /// A short, user-facing title suitable for a snackbar or dialog
  /// heading.
  String get userFriendlyTitle {
    if (this is NetworkFailure) return 'Connection Problem';
    if (this is AuthFailure) return 'Sign-in Failed';
    if (this is DatabaseFailure) return 'Storage Error';
    if (this is PermissionFailure) return 'Permission Needed';
    if (this is AiFailure) return 'Nova AI';
    if (this is ValidationFailure) return 'Validation Error';
    if (this is TimetableFailure) return 'Timetable Issue';
    if (this is AttendanceFailure) return 'Attendance Issue';
    if (this is ReminderFailure) return 'Reminder Problem';
    return 'Something Went Wrong';
  }

  /// The severity tier for this failure.
  FailureSeverity get severity {
    if (this is ValidationFailure) return FailureSeverity.low;
    if (this is TimetableFailure) return FailureSeverity.low;
    if (this is AttendanceFailure) return FailureSeverity.low;
    if (this is AuthFailure) return FailureSeverity.medium;
    if (this is NetworkFailure) return FailureSeverity.medium;
    if (this is AiFailure) return FailureSeverity.medium;
    if (this is PermissionFailure) return FailureSeverity.medium;
    if (this is ReminderFailure) return FailureSeverity.medium;
    if (this is DatabaseFailure) return FailureSeverity.high;
    if (this is GenericFailure) return FailureSeverity.critical;
    return FailureSeverity.medium;
  }
}

// ---------------------------------------------------------------------
// 15. Failure Mapper
// ---------------------------------------------------------------------

/// Maps raw, low-level exceptions into domain [Failure]s, so
/// repositories and use-cases never need to handle raw exception types
/// directly.
class FailureMapper {
  FailureMapper._();

  static Failure fromException(Object error) {
    if (error is FormatException) {
      return ValidationFailure(error.message);
    }
    if (error is TimeoutException) {
      return NetworkFailure.timeout();
    }
    if (error is StateError) {
      return DatabaseFailure.read();
    }
    return GenericFailure(cause: error);
  }
}

// ---------------------------------------------------------------------
// 16. Demo Utility
// ---------------------------------------------------------------------

/// A UI-independent demo of the failure hierarchy, useful for quick
/// manual testing.
class FailureDemo {
  FailureDemo._();

  /// One example instance of every major failure type.
  static List<Failure> examples() {
    return <Failure>[
      const GenericFailure(),
      NetworkFailure.noInternet(),
      AuthFailure.sessionExpired(),
      DatabaseFailure.write(),
      const ValidationFailure('Please enter a valid email address'),
      PermissionFailure.notification(),
      AiFailure.unavailable(),
      TimetableFailure.overlappingClass(),
      AttendanceFailure.invalidValues(),
      ReminderFailure.pastDate(),
    ];
  }

  /// A map of `userFriendlyTitle -> message` for every example failure.
  static Map<String, String> summary() {
    return <String, String>{
      for (final Failure failure in examples()) failure.userFriendlyTitle: failure.message,
    };
  }
}

