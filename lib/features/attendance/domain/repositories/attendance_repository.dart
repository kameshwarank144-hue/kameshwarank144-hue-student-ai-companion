// lib/features/attendance/domain/repositories/attendance_repository.dart

import '../../../../core/error/failure.dart';
import '../entities/attendance.dart';

/// The domain-layer contract for attendance persistence and retrieval.
///
/// This is a pure interface — it says *what* the Attendance feature
/// needs, never *how* it's done. The concrete implementation (backed by
/// Isar, Hive, Firestore, or any combination) belongs in
/// `lib/features/attendance/data/repositories/attendance_repository_impl.dart`
/// and is not defined here.
///
/// Every method operates on the domain [Attendance] entity only — never
/// `AttendanceModel`, Isar objects, Hive objects, or Firestore
/// documents. Following this project's existing error-handling
/// convention (see `core/error/error_mapper.dart`), implementations are
/// expected to throw a [Failure] on error rather than returning a
/// separate Result/Either wrapper type, since no such type currently
/// exists elsewhere in this codebase.
abstract interface class AttendanceRepository {
  /// Returns every attendance record belonging to [userId], for the
  /// attendance dashboard. Throws a [Failure] on error.
  Future<List<Attendance>> getAttendance({required String userId});

  /// Returns every attendance record belonging to [userId] for the
  /// subject identified by [subjectId]. Throws a [Failure] on error.
  Future<List<Attendance>> getAttendanceBySubject({
    required String userId,
    required String subjectId,
  });

  /// Returns the single attendance record with the stable record [id],
  /// or `null` if no such record exists. Throws a [Failure] on error.
  Future<Attendance?> getAttendanceById(String id);

  /// Persists a new [attendance] record and returns the persisted
  /// entity. Throws a [Failure] on error.
  Future<Attendance> addAttendance(Attendance attendance);

  /// Persists changes to an existing [attendance] record, preserving
  /// its stable [Attendance.id]. Throws a [Failure] on error.
  Future<Attendance> updateAttendance(Attendance attendance);

  /// Deletes the attendance record with the stable record [id]. Throws
  /// a [Failure] on error.
  Future<void> deleteAttendance(String id);

  /// Emits an updated list of attendance records belonging to [userId]
  /// whenever the underlying data changes, for reactive dashboard UI.
  Stream<List<Attendance>> watchAttendance({required String userId});
}

