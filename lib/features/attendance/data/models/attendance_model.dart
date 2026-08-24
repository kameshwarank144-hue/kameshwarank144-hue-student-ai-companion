// lib/features/attendance/data/models/attendance_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';

part 'attendance_model.freezed.dart';
part 'attendance_model.g.dart';

/// A clean, immutable, JSON-serializable attendance record for a single
/// subject/course.
///
/// This is the **data-layer** model — used for JSON serialization,
/// repository transport, and (eventually) Firestore sync. It is
/// intentionally separate from `AttendanceRecordEntity` in
/// `isar_service.dart`, which is the dedicated Isar persistence model;
/// this file does not add Isar annotations or duplicate that schema.
///
/// Derived values ([attendancePercentage], [absentClasses],
/// [isBelowRequiredAttendance]) are computed on demand and are never
/// serialized, so they can never drift out of sync with the underlying
/// [totalClasses] / [attendedClasses] values.
@freezed
class AttendanceModel with _$AttendanceModel {
  // Private generative constructor, required so custom getters/methods
  // can be added to this class alongside the generated Freezed members.
  const AttendanceModel._();

  const factory AttendanceModel({
    /// Unique identifier for this attendance record.
    required String id,

    /// Identifier of the subject/course this record belongs to.
    required String subjectId,

    /// Denormalized subject name, kept alongside [subjectId] so this
    /// record remains readable without a join/lookup.
    required String subjectName,

    /// Institution-specific subject/course code, if the college uses
    /// one. Not every institution does.
    String? subjectCode,

    /// The teacher/faculty name for this subject, if known.
    String? facultyName,

    /// The semester this record belongs to, if the institution tracks
    /// attendance by semester.
    String? semester,

    /// The academic year this record belongs to (e.g. "2025-2026"), if
    /// applicable.
    String? academicYear,

    /// Total number of classes conducted so far. Never negative.
    @Default(0) int totalClasses,

    /// Number of classes the student attended. Never negative, and
    /// never greater than [totalClasses].
    @Default(0) int attendedClasses,

    /// The minimum attendance percentage required to stay in good
    /// standing. Configurable per institution — defaults to
    /// [AppConstants.minimumAttendance] rather than a value hard-coded
    /// specifically in this model.
    @Default(AppConstants.minimumAttendance) double minimumAttendancePercentage,

    /// When this record was first created.
    required DateTime createdAt,

    /// When this record was last updated.
    required DateTime updatedAt,
  }) = _AttendanceModel;

  /// Deserializes an [AttendanceModel] from JSON. Note this bypasses
  /// [AttendanceModel.create]'s validation — data coming from storage or
  /// the network is assumed to already have been validated when it was
  /// written. Callers constructing a *new* record in application code
  /// should use [AttendanceModel.create] instead of this factory or the
  /// default constructor directly.
  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);

  /// Creates a new, validated [AttendanceModel].
  ///
  /// Throws an [ArgumentError] if the provided values are logically
  /// impossible (negative class counts, attended exceeding total, an
  /// out-of-range required percentage, or empty identifiers/name).
  /// Prefer this over calling the generated constructor directly when
  /// constructing a record from application code.
  factory AttendanceModel.create({
    required String id,
    required String subjectId,
    required String subjectName,
    String? subjectCode,
    String? facultyName,
    String? semester,
    String? academicYear,
    int totalClasses = 0,
    int attendedClasses = 0,
    double minimumAttendancePercentage = AppConstants.minimumAttendance,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError('id must not be empty.');
    }
    if (subjectId.trim().isEmpty) {
      throw ArgumentError('subjectId must not be empty.');
    }
    if (subjectName.trim().isEmpty) {
      throw ArgumentError('subjectName must not be empty.');
    }
    if (totalClasses < 0) {
      throw ArgumentError('totalClasses must not be negative.');
    }
    if (attendedClasses < 0) {
      throw ArgumentError('attendedClasses must not be negative.');
    }
    if (attendedClasses > totalClasses) {
      throw ArgumentError('attendedClasses must not exceed totalClasses.');
    }
    if (minimumAttendancePercentage < 0 || minimumAttendancePercentage > 100) {
      throw ArgumentError('minimumAttendancePercentage must be between 0 and 100.');
    }

    return AttendanceModel(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectCode: subjectCode,
      facultyName: facultyName,
      semester: semester,
      academicYear: academicYear,
      totalClasses: totalClasses,
      attendedClasses: attendedClasses,
      minimumAttendancePercentage: minimumAttendancePercentage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// The current attendance percentage, safely computed as
  /// `attendedClasses / totalClasses * 100`. Returns `0` when
  /// [totalClasses] is `0` rather than dividing by zero, and is always
  /// clamped to the `0`–`100` range.
  double get attendancePercentage {
    if (totalClasses == 0) return 0.0;
    return ((attendedClasses / totalClasses) * 100).clamp(0.0, 100.0);
  }

  /// The number of classes missed, derived from [totalClasses] and
  /// [attendedClasses] rather than stored separately, so it can never
  /// become inconsistent with them.
  int get absentClasses => totalClasses - attendedClasses;

  /// Whether the current [attendancePercentage] has fallen below
  /// [minimumAttendancePercentage].
  bool get isBelowRequiredAttendance {
    return attendancePercentage < minimumAttendancePercentage;
  }
}
