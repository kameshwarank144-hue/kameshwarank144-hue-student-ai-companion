// lib/features/attendance/domain/entities/attendance.dart

import 'package:equatable/equatable.dart';

/// The pure-Dart domain representation of a student's attendance record
/// for a single subject/course.
///
/// This entity carries no persistence, serialization, or framework
/// dependencies — `AttendanceModel` in the data layer is responsible
/// for converting to/from this entity. Attendance business rules
/// (validity of counts, the required-percentage invariant) live here
/// rather than in the data layer.
class Attendance extends Equatable {
  Attendance({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    this.facultyName,
    this.semester,
    this.academicYear,
    this.totalClasses = 0,
    this.attendedClasses = 0,
    this.minimumAttendancePercentage = 75.0,
    required this.createdAt,
    required this.updatedAt,
  })  : assert(id.trim().isNotEmpty, 'id must not be empty.'),
        assert(subjectId.trim().isNotEmpty, 'subjectId must not be empty.'),
        assert(subjectName.trim().isNotEmpty, 'subjectName must not be empty.'),
        assert(totalClasses >= 0, 'totalClasses must not be negative.'),
        assert(attendedClasses >= 0, 'attendedClasses must not be negative.'),
        assert(
          attendedClasses <= totalClasses,
          'attendedClasses must not exceed totalClasses.',
        ),
        assert(
          minimumAttendancePercentage >= 0 && minimumAttendancePercentage <= 100,
          'minimumAttendancePercentage must be between 0 and 100.',
        );

  /// Uniquely identifies this attendance record.
  final String id;

  /// Identifies the subject/course independently of its display name.
  final String subjectId;

  /// The human-readable subject name.
  final String subjectName;

  /// Institution-specific subject/course code, if the college uses one.
  final String? subjectCode;

  /// The teacher/faculty name for this subject, if known.
  final String? facultyName;

  /// The semester this record belongs to, if the institution tracks
  /// attendance by semester.
  final String? semester;

  /// The academic year this record belongs to, if applicable.
  final String? academicYear;

  /// Total number of classes conducted so far. Never negative.
  final int totalClasses;

  /// Number of classes attended. Never negative, and never greater than
  /// [totalClasses].
  final int attendedClasses;

  /// The minimum attendance percentage required to stay in good
  /// standing. Configurable per institution — `75.0` is only a default,
  /// not a universal policy.
  final double minimumAttendancePercentage;

  /// When this record was first created.
  final DateTime createdAt;

  /// When this record was last updated.
  final DateTime updatedAt;

  /// The current attendance percentage, computed as
  /// `(attendedClasses / totalClasses) * 100`. Returns `0.0` when
  /// [totalClasses] is `0` instead of dividing by zero, and is always
  /// clamped to the `0`–`100` range.
  double get attendancePercentage {
    if (totalClasses == 0) return 0.0;
    return ((attendedClasses / totalClasses) * 100).clamp(0.0, 100.0);
  }

  /// The number of classes missed (`totalClasses - attendedClasses`).
  /// Never negative.
  int get absentClasses {
    final int value = totalClasses - attendedClasses;
    return value < 0 ? 0 : value;
  }

  /// Whether [attendancePercentage] has fallen below
  /// [minimumAttendancePercentage].
  bool get isBelowMinimumAttendance => attendancePercentage < minimumAttendancePercentage;

  /// Returns a copy of this entity with the given fields replaced.
  /// Omitted parameters preserve their existing value.
  Attendance copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? facultyName,
    String? semester,
    String? academicYear,
    int? totalClasses,
    int? attendedClasses,
    double? minimumAttendancePercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Attendance(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      facultyName: facultyName ?? this.facultyName,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      totalClasses: totalClasses ?? this.totalClasses,
      attendedClasses: attendedClasses ?? this.attendedClasses,
      minimumAttendancePercentage:
          minimumAttendancePercentage ?? this.minimumAttendancePercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        subjectId,
        subjectName,
        subjectCode,
        facultyName,
        semester,
        academicYear,
        totalClasses,
        attendedClasses,
        minimumAttendancePercentage,
        createdAt,
        updatedAt,
      ];
}

