// lib/core/error/exceptions.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:async';

// ---------------------------------------------------------------------
// 2. Base Exception
// ---------------------------------------------------------------------

/// The base type for every low-level exception thrown by Student AI
/// Companion's data/service layers — networking, authentication, the
/// local database, AI services, timetable, attendance, reminders,
/// permissions, and file/storage operations.
///
/// These are later converted into domain-level failure objects by
/// `error_mapper.dart`; this file only deals with the raw, low-level
/// exception shapes.
abstract class AppException implements Exception {
  const AppException({required this.message, this.code, this.cause});

  /// A description of what went wrong, suitable for logging.
  final String message;

  /// An optional short, stable identifier for this exception.
  final String? code;

  /// The original error that caused this exception, if any.
  final Object? cause;

  @override
  String toString() {
    return '$runtimeType(code: ${code ?? '-'}, message: $message)';
  }
}

// ---------------------------------------------------------------------
// 3. Generic Exception
// ---------------------------------------------------------------------

/// A catch-all exception for errors that don't fit a more specific
/// category.
class GenericException extends AppException {
  const GenericException({
    super.message = 'Something went wrong.',
    super.code,
    super.cause,
  });
}

// ---------------------------------------------------------------------
// 4. Network Exceptions
// ---------------------------------------------------------------------

/// Raised by the networking layer (Dio, REST APIs, OpenAI/Gemini calls,
/// Firebase network calls).
class NetworkException extends AppException {
  const NetworkException({required super.message, super.code, super.cause});

  factory NetworkException.noInternet() => const NetworkException(
        message: 'No internet connection.',
        code: 'no_internet',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'Request timed out.',
        code: 'timeout',
      );

  factory NetworkException.serverError([String? message]) => NetworkException(
        message: message ?? 'The server returned an error.',
        code: 'server_error',
      );

  factory NetworkException.badRequest([String? message]) => NetworkException(
        message: message ?? 'The request was invalid.',
        code: 'bad_request',
      );

  factory NetworkException.unauthorized() => const NetworkException(
        message: 'The request was unauthorized.',
        code: 'unauthorized',
      );

  factory NetworkException.forbidden() => const NetworkException(
        message: 'Access to this resource is forbidden.',
        code: 'forbidden',
      );

  factory NetworkException.notFound() => const NetworkException(
        message: 'The requested resource was not found.',
        code: 'not_found',
      );

  factory NetworkException.rateLimited() => const NetworkException(
        message: 'Too many requests were sent.',
        code: 'rate_limited',
      );

  factory NetworkException.cancelled() => const NetworkException(
        message: 'The request was cancelled.',
        code: 'cancelled',
      );
}

// ---------------------------------------------------------------------
// 5. Authentication Exceptions
// ---------------------------------------------------------------------

/// Raised by the authentication layer.
class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.cause});

  factory AuthException.invalidCredentials() => const AuthException(
        message: 'The email or password is incorrect.',
        code: 'invalid_credentials',
      );

  factory AuthException.emailAlreadyInUse() => const AuthException(
        message: 'This email address is already registered.',
        code: 'email_in_use',
      );

  factory AuthException.userNotFound() => const AuthException(
        message: 'No account was found for this email address.',
        code: 'user_not_found',
      );

  factory AuthException.weakPassword() => const AuthException(
        message: 'The provided password is too weak.',
        code: 'weak_password',
      );

  factory AuthException.sessionExpired() => const AuthException(
        message: 'The user session has expired.',
        code: 'session_expired',
      );

  factory AuthException.permissionDenied() => const AuthException(
        message: 'The user does not have permission for this action.',
        code: 'permission_denied',
      );
}

// ---------------------------------------------------------------------
// 6. Database Exceptions
// ---------------------------------------------------------------------

/// Raised by the local database layer (Hive or Isar).
class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.code, super.cause});

  factory DatabaseException.read() => const DatabaseException(
        message: 'Failed to read from the local database.',
        code: 'db_read',
      );

  factory DatabaseException.write() => const DatabaseException(
        message: 'Failed to write to the local database.',
        code: 'db_write',
      );

  factory DatabaseException.delete() => const DatabaseException(
        message: 'Failed to delete from the local database.',
        code: 'db_delete',
      );

  factory DatabaseException.initialization() => const DatabaseException(
        message: 'Failed to initialize the local database.',
        code: 'db_init',
      );

  factory DatabaseException.corrupted() => const DatabaseException(
        message: 'The local database appears to be corrupted.',
        code: 'db_corrupted',
      );

  factory DatabaseException.notFound() => const DatabaseException(
        message: 'The requested record was not found.',
        code: 'db_not_found',
      );
}

// ---------------------------------------------------------------------
// 7. Validation Exception
// ---------------------------------------------------------------------

/// A simple pass-through exception for input validation errors, e.g.
/// `ValidationException('Please enter a valid email address')`.
class ValidationException extends AppException {
  const ValidationException(String message, {super.code, super.cause})
      : super(message: message);
}

// ---------------------------------------------------------------------
// 8. Permission Exceptions
// ---------------------------------------------------------------------

/// Raised by the permission manager.
class PermissionException extends AppException {
  const PermissionException({required super.message, super.code, super.cause});

  factory PermissionException.notification() => const PermissionException(
        message: 'Notification permission was denied.',
        code: 'permission_notification',
      );

  factory PermissionException.microphone() => const PermissionException(
        message: 'Microphone permission was denied.',
        code: 'permission_microphone',
      );

  factory PermissionException.storage() => const PermissionException(
        message: 'Storage permission was denied.',
        code: 'permission_storage',
      );

  factory PermissionException.overlay() => const PermissionException(
        message: 'Overlay permission was denied.',
        code: 'permission_overlay',
      );

  factory PermissionException.usageAccess() => const PermissionException(
        message: 'Usage access permission was denied.',
        code: 'permission_usage_access',
      );

  factory PermissionException.location() => const PermissionException(
        message: 'Location permission was denied.',
        code: 'permission_location',
      );
}

// ---------------------------------------------------------------------
// 9. AI Exceptions
// ---------------------------------------------------------------------

/// Raised by Nova AI's chat, voice, or generation services.
class AiException extends AppException {
  const AiException({required super.message, super.code, super.cause});

  factory AiException.unavailable() => const AiException(
        message: 'The AI service is currently unavailable.',
        code: 'ai_unavailable',
      );

  factory AiException.apiKeyMissing() => const AiException(
        message: 'No AI API key is configured.',
        code: 'ai_api_key_missing',
      );

  factory AiException.responseGeneration() => const AiException(
        message: 'Failed to generate an AI response.',
        code: 'ai_response_generation',
      );

  factory AiException.voiceProcessing() => const AiException(
        message: 'Failed to process voice input.',
        code: 'ai_voice_processing',
      );

  factory AiException.contextTooLarge() => const AiException(
        message: 'The conversation context is too large to process.',
        code: 'ai_context_too_large',
      );
}

// ---------------------------------------------------------------------
// 10. Timetable Exceptions
// ---------------------------------------------------------------------

/// Raised by the timetable module.
class TimetableException extends AppException {
  const TimetableException({required super.message, super.code, super.cause});

  factory TimetableException.invalidTimeRange() => const TimetableException(
        message: 'The provided time range is invalid.',
        code: 'timetable_invalid_range',
      );

  factory TimetableException.overlappingClass() => const TimetableException(
        message: 'This class overlaps with an existing timetable entry.',
        code: 'timetable_overlap',
      );

  factory TimetableException.importFailed() => const TimetableException(
        message: 'Failed to import the timetable.',
        code: 'timetable_import_failed',
      );

  factory TimetableException.notFound() => const TimetableException(
        message: 'The timetable entry was not found.',
        code: 'timetable_not_found',
      );
}

// ---------------------------------------------------------------------
// 11. Attendance Exceptions
// ---------------------------------------------------------------------

/// Raised by the attendance module.
class AttendanceException extends AppException {
  const AttendanceException({required super.message, super.code, super.cause});

  factory AttendanceException.invalidValues() => const AttendanceException(
        message: 'Attended classes cannot exceed total classes.',
        code: 'attendance_invalid_values',
      );

  factory AttendanceException.subjectNotFound() => const AttendanceException(
        message: 'No attendance record exists for this subject.',
        code: 'attendance_subject_not_found',
      );

  factory AttendanceException.calculationFailed() => const AttendanceException(
        message: 'Failed to calculate attendance.',
        code: 'attendance_calculation_failed',
      );
}

// ---------------------------------------------------------------------
// 12. Reminder Exceptions
// ---------------------------------------------------------------------

/// Raised by the reminder scheduler.
class ReminderException extends AppException {
  const ReminderException({required super.message, super.code, super.cause});

  factory ReminderException.scheduleFailed() => const ReminderException(
        message: 'Failed to schedule the reminder.',
        code: 'reminder_schedule_failed',
      );

  factory ReminderException.pastDate() => const ReminderException(
        message: 'The reminder date must be in the future.',
        code: 'reminder_past_date',
      );

  factory ReminderException.permissionRequired() => const ReminderException(
        message: 'Notification permission is required to schedule reminders.',
        code: 'reminder_permission_required',
      );
}

// ---------------------------------------------------------------------
// 13. File Storage Exceptions
// ---------------------------------------------------------------------

/// Raised by file and storage operations (uploads, downloads, local
/// file access).
class FileStorageException extends AppException {
  const FileStorageException({required super.message, super.code, super.cause});

  factory FileStorageException.fileNotFound() => const FileStorageException(
        message: 'The requested file was not found.',
        code: 'file_not_found',
      );

  factory FileStorageException.invalidFormat() => const FileStorageException(
        message: 'The file format is not supported.',
        code: 'file_invalid_format',
      );

  factory FileStorageException.uploadFailed() => const FileStorageException(
        message: 'Failed to upload the file.',
        code: 'file_upload_failed',
      );

  factory FileStorageException.downloadFailed() => const FileStorageException(
        message: 'Failed to download the file.',
        code: 'file_download_failed',
      );

  factory FileStorageException.permissionDenied() => const FileStorageException(
        message: 'Permission to access this file was denied.',
        code: 'file_permission_denied',
      );
}

// ---------------------------------------------------------------------
// 14. Sync Exceptions
// ---------------------------------------------------------------------

/// Raised by the cloud synchronization layer.
class SyncException extends AppException {
  const SyncException({required super.message, super.code, super.cause});

  factory SyncException.syncFailed() => const SyncException(
        message: 'Failed to sync data with the server.',
        code: 'sync_failed',
      );

  factory SyncException.conflict() => const SyncException(
        message: 'A sync conflict was detected.',
        code: 'sync_conflict',
      );

  factory SyncException.offline() => const SyncException(
        message: 'Cannot sync while offline.',
        code: 'sync_offline',
      );

  factory SyncException.remoteUnavailable() => const SyncException(
        message: 'The remote sync service is unavailable.',
        code: 'sync_remote_unavailable',
      );
}

// ---------------------------------------------------------------------
// 15. Exception Extensions
// ---------------------------------------------------------------------

/// Convenience getters for working with any [AppException] generically.
extension AppExceptionX on AppException {
  bool get isNetworkError => this is NetworkException;

  bool get isAuthError => this is AuthException;

  bool get isDatabaseError => this is DatabaseException;

  bool get isPermissionError => this is PermissionException;

  bool get isAiError => this is AiException;

  /// A short, stable label identifying this exception's category —
  /// useful for logging and analytics.
  String get debugLabel {
    if (this is NetworkException) return 'NETWORK';
    if (this is AuthException) return 'AUTH';
    if (this is DatabaseException) return 'DATABASE';
    if (this is ValidationException) return 'VALIDATION';
    if (this is PermissionException) return 'PERMISSION';
    if (this is AiException) return 'AI';
    if (this is TimetableException) return 'TIMETABLE';
    if (this is AttendanceException) return 'ATTENDANCE';
    if (this is ReminderException) return 'REMINDER';
    if (this is FileStorageException) return 'STORAGE';
    if (this is SyncException) return 'SYNC';
    return 'UNKNOWN';
  }
}

// ---------------------------------------------------------------------
// 16. Exception Mapper
// ---------------------------------------------------------------------

/// Maps arbitrary raw errors into [AppException]s.
class ExceptionMapper {
  ExceptionMapper._();

  static AppException from(Object error) {
    if (error is AppException) return error;
    if (error is TimeoutException) return NetworkException.timeout();
    if (error is FormatException) return ValidationException(error.message);
    if (error is StateError) return DatabaseException.read();
    return GenericException(cause: error);
  }
}

// ---------------------------------------------------------------------
// 17. Demo Utility
// ---------------------------------------------------------------------

/// A UI-independent demo of the exception hierarchy, useful for quick
/// manual testing.
class ExceptionDemo {
  ExceptionDemo._();

  /// One example instance of every major exception type.
  static List<AppException> examples() {
    return <AppException>[
      const GenericException(),
      NetworkException.noInternet(),
      AuthException.sessionExpired(),
      DatabaseException.write(),
      const ValidationException('Please enter a valid email address'),
      PermissionException.notification(),
      AiException.unavailable(),
      TimetableException.overlappingClass(),
      AttendanceException.invalidValues(),
      ReminderException.pastDate(),
      FileStorageException.uploadFailed(),
      SyncException.conflict(),
    ];
  }

  /// A map of `debugLabel -> message` for every example exception.
  static Map<String, String> summary() {
    return <String, String>{
      for (final AppException exception in examples())
        exception.debugLabel: exception.message,
    };
  }
}

