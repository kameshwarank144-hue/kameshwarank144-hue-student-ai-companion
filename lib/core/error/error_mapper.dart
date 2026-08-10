// lib/core/error/error_mapper.dart

// ---------------------------------------------------------------------
// 1. Imports
// ---------------------------------------------------------------------

import 'dart:async';

import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failure.dart';

// ---------------------------------------------------------------------
// 2. ErrorMapper
// ---------------------------------------------------------------------

/// The single bridge between every low-level error source in Student AI
/// Companion — Dio/networking, Firebase/auth, Hive/Isar, AI services,
/// timetable, attendance, reminders, permissions, and background sync —
/// and the UI-friendly [Failure] hierarchy. The UI layer (snackbars,
/// dialogs, Riverpod state) should never see a raw exception.
class ErrorMapper {
  ErrorMapper._();

  // ---------------------------------------------------------------------
  // 3. Main Mapping API
  // ---------------------------------------------------------------------

  /// Converts any [error] into a [Failure]. Already-mapped [Failure]s
  /// are returned unchanged.
  static Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;
    if (error is AppException) return _fromAppException(error);
    if (error is DioException) return _fromDioException(error);
    if (error is TimeoutException) return NetworkFailure.timeout();
    if (error is FormatException) return ValidationFailure(error.message);
    if (error is StateError) return DatabaseFailure.read();
    return GenericFailure(cause: error);
  }

  // ---------------------------------------------------------------------
  // 4. AppException Mapping
  // ---------------------------------------------------------------------

  static Failure _fromAppException(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is DatabaseException) {
      return DatabaseFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is ValidationException) {
      return ValidationFailure(
        exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is PermissionException) {
      return PermissionFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is AiException) {
      return AiFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is TimetableException) {
      return TimetableFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is AttendanceException) {
      return AttendanceFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is ReminderException) {
      return ReminderFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is FileStorageException) {
      return GenericFailure(
        message: exception.message,
        code: exception.code,
        cause: exception.cause,
      );
    }
    if (exception is SyncException) {
      return NetworkFailure.serverError(exception.message);
    }

    return GenericFailure(cause: exception);
  }

  // ---------------------------------------------------------------------
  // 5. DioException Mapping
  // ---------------------------------------------------------------------

  static Failure _fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return NetworkFailure.noInternet();
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure.timeout();
      case DioExceptionType.cancel:
        return NetworkFailure.cancelled();
      case DioExceptionType.badResponse:
        return _fromStatusCode(error.response?.statusCode, error);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return GenericFailure(cause: error);
    }
  }

  static Failure _fromStatusCode(int? statusCode, DioException error) {
    if (statusCode == 400) {
      return ValidationFailure(
        error.response?.statusMessage ?? 'Invalid request.',
      );
    }
    if (statusCode == 401) return AuthFailure.sessionExpired();
    if (statusCode == 403) return AuthFailure.permissionDenied();
    if (statusCode == 404) {
      return NetworkFailure.serverError('Requested service was not found.');
    }
    if (statusCode == 429) return NetworkFailure.rateLimited();
    if (statusCode != null && statusCode >= 500) {
      return NetworkFailure.serverError();
    }
    return GenericFailure(cause: error);
  }

  // ---------------------------------------------------------------------
  // 6. Convenience Helpers
  // ---------------------------------------------------------------------

  /// Maps a plain [Exception] into a [Failure].
  static Failure fromException(Exception exception) => map(exception);

  /// Maps a [DioException] into a [Failure].
  static Failure fromDio(DioException exception) => map(exception);

  /// Maps any [error] (of unknown origin) into a [Failure].
  static Failure fromUnknown(Object error) => map(error);

  // ---------------------------------------------------------------------
  // 7. Async Guard Helpers
  // ---------------------------------------------------------------------

  /// Runs [action], converting any thrown error into a [Failure] and
  /// throwing that instead — callers only ever need to catch [Failure].
  static Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      throw map(error, stackTrace);
    }
  }

  /// Runs [action]. If it throws, the error is mapped to a [Failure]:
  /// known, well-understood failures are swallowed (returning `null`,
  /// suitable for optional/best-effort reads), while unmapped/unexpected
  /// errors ([GenericFailure]) are rethrown as a mapped [Failure] so
  /// they aren't silently lost.
  static Future<T?> guardNullable<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      final Failure failure = map(error, stackTrace);
      if (failure is GenericFailure) {
        throw failure;
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // 8. Human-Friendly Summary
  // ---------------------------------------------------------------------

  /// Returns a short, warm, student-facing summary of [failure],
  /// suitable for a snackbar or inline error message.
  static String summarize(Failure failure) {
    if (failure is NetworkFailure && failure.code == 'no_internet') {
      return 'You are currently offline.';
    }
    if (failure is AuthFailure && failure.code == 'invalid_credentials') {
      return 'Please check your email and password.';
    }
    if (failure is DatabaseFailure && failure.code == 'db_write') {
      return 'Unable to save your changes right now.';
    }
    if (failure is AiFailure && failure.code == 'ai_unavailable') {
      return 'Nova AI is temporarily unavailable.';
    }
    return failure.message;
  }

  // ---------------------------------------------------------------------
  // 9. Retry Recommendation
  // ---------------------------------------------------------------------

  /// Whether the UI should offer a "retry" action for [failure].
  static bool shouldRetry(Failure failure) {
    if (failure is ValidationFailure) return false;
    if (failure is AuthFailure && failure.code == 'invalid_credentials') {
      return false;
    }
    if (failure is TimetableFailure &&
        failure.code == 'timetable_invalid_range') {
      return false;
    }
    if (failure is AttendanceFailure &&
        failure.code == 'attendance_invalid_values') {
      return false;
    }

    if (failure is NetworkFailure || failure is AiFailure || failure is ReminderFailure) {
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------
  // 10. Diagnostic Helper
  // ---------------------------------------------------------------------

  /// Builds a structured diagnostic record for logging/analytics,
  /// capturing both the original error and its mapped [Failure].
  static Map<String, dynamic> diagnosticData(Object error, Failure failure) {
    return <String, dynamic>{
      'originalType': error.runtimeType.toString(),
      'mappedType': failure.runtimeType.toString(),
      'message': failure.message,
      'code': failure.code,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

// ---------------------------------------------------------------------
// 11. Demo Utility
// ---------------------------------------------------------------------

/// A UI-independent demo of [ErrorMapper], useful for quick manual
/// testing of the exception -> failure mapping pipeline.
class ErrorMapperDemo {
  ErrorMapperDemo._();

  /// Maps one example of each major error source into a [Failure].
  static List<Failure> mapExamples() {
    return <Failure>[
      ErrorMapper.map(TimeoutException('The operation timed out')),
      ErrorMapper.map(const FormatException('Invalid data format')),
      ErrorMapper.map(NetworkException.noInternet()),
      ErrorMapper.map(AuthException.invalidCredentials()),
      ErrorMapper.map(DatabaseException.write()),
      ErrorMapper.map(AiException.unavailable()),
      ErrorMapper.map(Exception('boom')),
    ];
  }

  /// A map of `userFriendlyTitle -> summarized message` for every
  /// example failure.
  static Map<String, String> summary() {
    return <String, String>{
      for (final Failure failure in mapExamples())
        failure.userFriendlyTitle: ErrorMapper.summarize(failure),
    };
  }
}

