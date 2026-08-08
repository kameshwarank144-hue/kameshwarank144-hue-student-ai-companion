// lib/core/utils/validators.dart

import 'package:flutter/material.dart';

/// Centralized validation logic for Student AI Companion.
///
/// Covers authentication, user profile, timetable, attendance, todo
/// tasks, reminders, study sessions, Notes AI, GPA calculator, expense
/// tracker, health logs, and AI chat input — every validator returns a
/// human-friendly error message (or `null` when the value is valid).
class AppValidators {
  AppValidators._();

  // ---------------------------------------------------------------------
  // 1. Generic Helpers
  // ---------------------------------------------------------------------

  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  static String? requiredField(String? value, {String fieldName = 'This field'}) {
    if (isNullOrEmpty(value)) return '$fieldName is required';
    return null;
  }

  // ---------------------------------------------------------------------
  // 2. Authentication Validators
  // ---------------------------------------------------------------------

  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static String? email(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Please enter a valid email address';
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final String pwd = value ?? '';

    if (pwd.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(pwd)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(pwd)) {
      return 'Add at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(pwd)) {
      return 'Add at least one number';
    }
    if (!RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\[\]/\\+=~`]''').hasMatch(pwd)) {
      return 'Add at least one special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value != originalPassword) return 'Passwords do not match';
    return null;
  }

  // ---------------------------------------------------------------------
  // 3. Profile Validators
  // ---------------------------------------------------------------------

  static final RegExp _namePattern = RegExp(r"^[a-zA-Z\s'\-]+$");

  static String? name(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Please enter your name';
    if (trimmed.length < 2) return 'Name is too short';
    if (trimmed.length > 50) return 'Name is too long';
    if (!_namePattern.hasMatch(trimmed)) return 'Name contains invalid characters';
    return null;
  }

  static String? phone(String? value) {
    final String cleaned = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    final RegExp pattern = RegExp(r'^(\+91)?[6-9]\d{9}$');

    if (cleaned.isEmpty || !pattern.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 4. Timetable Validators
  // ---------------------------------------------------------------------

  static String? subject(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Subject name is required';
    if (trimmed.length < 2 || trimmed.length > 40) {
      return 'Subject name must be between 2 and 40 characters';
    }
    return null;
  }

  static String? room(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Room is required';
    if (trimmed.length > 30) return 'Room name is too long';
    return null;
  }

  static String? teacher(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Teacher name is required';
    if (trimmed.length > 50) return 'Teacher name is too long';
    return null;
  }

  static String? timeRange({required TimeOfDay start, required TimeOfDay end}) {
    final int startMinutes = start.hour * 60 + start.minute;
    final int endMinutes = end.hour * 60 + end.minute;

    if (endMinutes <= startMinutes) {
      return 'End time must be after start time';
    }
    if (endMinutes - startMinutes < 15) {
      return 'Class duration must be at least 15 minutes';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 5. Attendance Validators
  // ---------------------------------------------------------------------

  static String? attendanceCount(int? value, {String fieldName = 'Value'}) {
    if (value == null) return '$fieldName is required';
    if (value < 0) return '$fieldName cannot be negative';
    return null;
  }

  static String? attendanceRelationship({required int attended, required int total}) {
    if (total < 0) return 'Total classes cannot be negative';
    if (attended < 0) return 'Attended classes cannot be negative';
    if (attended > total) return 'Attended classes cannot exceed total classes';
    return null;
  }

  // ---------------------------------------------------------------------
  // 6. Todo Validators
  // ---------------------------------------------------------------------

  static String? taskTitle(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Task title is required';
    if (trimmed.length < 3 || trimmed.length > 80) {
      return 'Task title must be between 3 and 80 characters';
    }
    return null;
  }

  static String? taskDescription(String? value) {
    if (value == null) return null;
    if (value.length > 500) return 'Description cannot exceed 500 characters';
    return null;
  }

  static String? futureDate(DateTime? date) {
    if (date == null || date.isBefore(DateTime.now())) {
      return 'Please select a future date and time';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 7. Reminder Validators
  // ---------------------------------------------------------------------

  static String? reminderTitle(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Reminder title is required';
    return null;
  }

  static String? reminderDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Please select a reminder date and time';
    final DateTime minimum = DateTime.now().add(const Duration(minutes: 1));
    if (dateTime.isBefore(minimum)) {
      return 'Reminder must be at least 1 minute in the future';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 8. Study Validators
  // ---------------------------------------------------------------------

  static String? studyDuration(int? minutes) {
    if (minutes == null) return 'Please enter a study duration';
    if (minutes < 5) return 'Study session must be at least 5 minutes';
    if (minutes > 720) return 'Study session cannot exceed 12 hours';
    return null;
  }

  // ---------------------------------------------------------------------
  // 9. Notes AI Validators
  // ---------------------------------------------------------------------

  static String? noteTitle(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Note title is required';
    if (trimmed.length > 100) return 'Note title is too long';
    return null;
  }

  static String? pdfFileName(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return 'Please select a valid PDF file';
    }
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      return 'Please select a valid PDF file';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 10. GPA Validators
  // ---------------------------------------------------------------------

  static String? credit(int? value) {
    if (value == null) return 'Please enter credit hours';
    if (value < 1 || value > 10) return 'Credit hours must be between 1 and 10';
    return null;
  }

  static String? gradePoint(double? value) {
    if (value == null) return 'Please enter a grade point';
    if (value < 0.0 || value > 10.0) {
      return 'Grade point must be between 0.0 and 10.0';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 11. Expense Validators
  // ---------------------------------------------------------------------

  static String? expenseAmount(double? value) {
    if (value == null) return 'Please enter an amount';
    if (value <= 0) return 'Amount must be greater than 0';
    if (value > 1000000) return 'Amount cannot exceed 1,000,000';
    return null;
  }

  static String? expenseTitle(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Expense title is required';
    return null;
  }

  // ---------------------------------------------------------------------
  // 12. Health Validators
  // ---------------------------------------------------------------------

  static String? waterGlasses(int? value) {
    if (value == null) return 'Please enter the number of glasses';
    if (value < 0 || value > 30) {
      return 'Water intake must be between 0 and 30 glasses';
    }
    return null;
  }

  static String? sleepHours(double? value) {
    if (value == null) return 'Please enter sleep hours';
    if (value < 0 || value > 24) {
      return 'Sleep hours must be between 0 and 24';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 13. AI Chat Validators
  // ---------------------------------------------------------------------

  static String? aiMessage(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed.length < 2) {
      return 'Please type a message for Nova AI';
    }
    if (trimmed.length > 2000) {
      return 'Message is too long. Please keep it under 2000 characters.';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // 14. Sanitization Helpers
  // ---------------------------------------------------------------------

  /// Trims whitespace and collapses multiple spaces into one.
  static String sanitize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Trims trailing spaces on each line and collapses excessive blank
  /// lines down to a single blank line.
  static String sanitizeMultiline(String value) {
    final List<String> lines = value
        .split('\n')
        .map((String line) => line.replaceAll(RegExp(r'\s+$'), ''))
        .toList();

    final List<String> collapsed = <String>[];
    bool previousWasBlank = false;

    for (final String line in lines) {
      final bool isBlank = line.trim().isEmpty;
      if (isBlank && previousWasBlank) continue;
      collapsed.add(line);
      previousWasBlank = isBlank;
    }

    return collapsed.join('\n').trim();
  }

  // ---------------------------------------------------------------------
  // 15. Form Validation Helper
  // ---------------------------------------------------------------------

  /// Returns true only if every value in [validations] is null (i.e.
  /// every individual validator passed).
  ///
  /// Example:
  /// ```dart
  /// final isValid = AppValidators.validateForm([
  ///   AppValidators.email(email),
  ///   AppValidators.password(password),
  ///   AppValidators.name(name),
  /// ]);
  /// ```
  static bool validateForm(Iterable<String?> validations) {
    return validations.every((String? result) => result == null);
  }

  // ---------------------------------------------------------------------
  // 16. Password Strength Meter
  // ---------------------------------------------------------------------

  static PasswordStrength passwordStrength(String value) {
    int score = 0;

    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\[\]/\\+=~`]''').hasMatch(value)) {
      score++;
    }

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    if (score <= 5) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  // ---------------------------------------------------------------------
  // 17. Validation Result Model
  // ---------------------------------------------------------------------

  static ValidationResult validateEmail(String? value) {
    final String? error = email(value);
    return error == null
        ? ValidationResult.success()
        : ValidationResult.failure(error);
  }
}

/// Password strength tiers used by [AppValidators.passwordStrength].
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// A lightweight, reusable result of running a single validation.
class ValidationResult {
  const ValidationResult({required this.isValid, this.error});

  final bool isValid;
  final String? error;

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.failure(String error) {
    return ValidationResult(isValid: false, error: error);
  }
}

// ---------------------------------------------------------------------
// 18. Demo
// ---------------------------------------------------------------------

/// A UI-independent demo of [AppValidators], useful for quick manual
/// testing of the major validators.
class ValidatorsDemo {
  ValidatorsDemo._();

  static Map<String, dynamic> runDemo() {
    return <String, dynamic>{
      'validEmail': AppValidators.email('student@college.edu'),
      'invalidEmail': AppValidators.email('not-an-email'),
      'strongPassword': AppValidators.password('Nova@Study2026'),
      'weakPassword': AppValidators.password('abc123'),
      'validTaskTitle': AppValidators.taskTitle('Finish DBMS assignment'),
      'invalidAttendance': AppValidators.attendanceRelationship(
        attended: 25,
        total: 20,
      ),
      'validReminder': AppValidators.reminderDateTime(
        DateTime.now().add(const Duration(hours: 1)),
      ),
      'invalidPdfFileName': AppValidators.pdfFileName('notes.docx'),
      'passwordStrengthLabel': AppValidators.passwordStrengthLabel(
        AppValidators.passwordStrength('Nova@Study2026'),
      ),
    };
  }
}

