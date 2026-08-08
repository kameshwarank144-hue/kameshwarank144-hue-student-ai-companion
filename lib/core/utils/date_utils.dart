// lib/core/utils/date_utils.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Human-friendly date and time formatting for Student AI Companion.
///
/// Powers Nova AI's conversational tone across timetable reminders,
/// attendance reports, tasks, study sessions, and notifications — e.g.
/// "Tomorrow", "In 2 hours", "5 minutes ago", "Next Monday", "Today at
/// 8:30 PM", "Class starts in 20 minutes", "Exam in 3 days".
class AppDateUtils {
  AppDateUtils._();

  // ---------------------------------------------------------------------
  // Basic Formatters
  // ---------------------------------------------------------------------

  /// e.g. "Aug 7, 2026"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// e.g. "07/08/2026"
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// e.g. "Friday, August 7, 2026"
  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// e.g. "8:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// e.g. "Aug 7, 2026 • 8:30 PM"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} • ${formatTime(date)}';
  }

  /// e.g. "August 2026"
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// e.g. "Friday"
  static String formatWeekday(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// e.g. "Fri"
  static String formatWeekdayShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  // ---------------------------------------------------------------------
  // Relative Day Helpers
  // ---------------------------------------------------------------------

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isTomorrow(DateTime date) {
    return isSameDay(date, DateTime.now().add(const Duration(days: 1)));
  }

  static bool isYesterday(DateTime date) {
    return isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Number of whole calendar days between [date] and today (positive
  /// for future dates, negative for past dates), ignoring time-of-day.
  static int _calendarDayDifference(DateTime date) {
    final DateTime today = DateTime.now();
    final DateTime dateOnly = DateTime(date.year, date.month, date.day);
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    return dateOnly.difference(todayOnly).inDays;
  }

  /// Returns "Today", "Tomorrow", "Yesterday", a weekday name for dates
  /// within the next 7 days, or a formatted date otherwise.
  static String relativeDay(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    if (isYesterday(date)) return 'Yesterday';

    final int dayDiff = _calendarDayDifference(date);
    if (dayDiff > 1 && dayDiff <= 7) {
      return formatWeekday(date);
    }

    return formatDate(date);
  }

  // ---------------------------------------------------------------------
  // Conversational Formatting
  // ---------------------------------------------------------------------

  /// Combines [relativeDay] with a formatted time, e.g. "Today at 8:30
  /// PM", "Tomorrow at 8:30 AM", "Monday at 9:00 AM", or "Aug 7, 2026 at
  /// 8:30 PM" for older/farther dates.
  static String conversationalDateTime(DateTime date) {
    final String time = formatTime(date);

    if (isToday(date)) return 'Today at $time';
    if (isTomorrow(date)) return 'Tomorrow at $time';
    if (isYesterday(date)) return 'Yesterday at $time';

    final int dayDiff = _calendarDayDifference(date);
    if (dayDiff > 1 && dayDiff <= 7) {
      return '${formatWeekday(date)} at $time';
    }

    return '${formatDate(date)} at $time';
  }

  // ---------------------------------------------------------------------
  // Time Ago
  // ---------------------------------------------------------------------

  static String _pluralize(int count, String word) {
    return '$count $word${count == 1 ? '' : 's'}';
  }

  /// Formats a past [date] relative to now, e.g. "Just now", "2 minutes
  /// ago", "Yesterday", "3 days ago", "2 weeks ago", "4 months ago", "1
  /// year ago".
  static String timeAgo(DateTime date) {
    final Duration diff = DateTime.now().difference(date);

    if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${_pluralize(diff.inMinutes, 'minute')} ago';
    if (diff.inHours < 24) return '${_pluralize(diff.inHours, 'hour')} ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${_pluralize(diff.inDays, 'day')} ago';
    if (diff.inDays < 30) {
      return '${_pluralize((diff.inDays / 7).floor(), 'week')} ago';
    }
    if (diff.inDays < 365) {
      return '${_pluralize((diff.inDays / 30).floor(), 'month')} ago';
    }
    return '${_pluralize((diff.inDays / 365).floor(), 'year')} ago';
  }

  // ---------------------------------------------------------------------
  // Future Countdown
  // ---------------------------------------------------------------------

  /// Formats a future [future] date relative to now, e.g. "In 30
  /// seconds", "In 5 minutes", "In 2 hours", "In 3 days", "In 2 weeks",
  /// "In 4 months". Returns "Already passed" if [future] is in the past.
  static String timeUntil(DateTime future) {
    final Duration diff = future.difference(DateTime.now());

    if (diff.isNegative) return 'Already passed';
    if (diff.inSeconds < 60) return 'In ${_pluralize(diff.inSeconds, 'second')}';
    if (diff.inMinutes < 60) return 'In ${_pluralize(diff.inMinutes, 'minute')}';
    if (diff.inHours < 24) return 'In ${_pluralize(diff.inHours, 'hour')}';
    if (diff.inDays < 7) return 'In ${_pluralize(diff.inDays, 'day')}';
    if (diff.inDays < 30) {
      return 'In ${_pluralize((diff.inDays / 7).floor(), 'week')}';
    }
    return 'In ${_pluralize((diff.inDays / 30).floor(), 'month')}';
  }

  /// A smart, notification-ready reminder phrase, e.g. "In 15 minutes"
  /// (same hour), "Today at 7:00 PM" (later today), "Tomorrow at 8:30
  /// AM", "Monday at 9:00 AM" (within a week), or "Aug 12 at 10:00 AM"
  /// otherwise.
  static String reminderPhrase(DateTime date) {
    final Duration diff = date.difference(DateTime.now());
    final String time = formatTime(date);

    if (isToday(date)) {
      if (!diff.isNegative && diff.inMinutes <= 60) {
        return 'In ${_pluralize(diff.inMinutes, 'minute')}';
      }
      return 'Today at $time';
    }

    if (isTomorrow(date)) return 'Tomorrow at $time';

    final int dayDiff = _calendarDayDifference(date);
    if (dayDiff > 0 && dayDiff <= 7) {
      return '${formatWeekday(date)} at $time';
    }

    return '${DateFormat('MMM d').format(date)} at $time';
  }

  // ---------------------------------------------------------------------
  // Timetable Helpers
  // ---------------------------------------------------------------------

  /// e.g. "Starts in 20 minutes", "Starts in 2 hours", "Started 5
  /// minutes ago".
  static String classStartsIn(DateTime classTime) {
    final Duration diff = classTime.difference(DateTime.now());

    if (diff.isNegative) {
      final Duration ago = -diff;
      if (ago.inMinutes < 60) return 'Started ${_pluralize(ago.inMinutes, 'minute')} ago';
      if (ago.inHours < 24) return 'Started ${_pluralize(ago.inHours, 'hour')} ago';
      return 'Started ${_pluralize(ago.inDays, 'day')} ago';
    }

    if (diff.inMinutes < 60) return 'Starts in ${_pluralize(diff.inMinutes, 'minute')}';
    if (diff.inHours < 24) return 'Starts in ${_pluralize(diff.inHours, 'hour')}';
    return 'Starts in ${_pluralize(diff.inDays, 'day')}';
  }

  static bool hasClassStarted(DateTime classTime) {
    return DateTime.now().isAfter(classTime);
  }

  static bool isClassOngoing(DateTime start, DateTime end) {
    final DateTime now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  // ---------------------------------------------------------------------
  // Attendance Helpers
  // ---------------------------------------------------------------------

  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month, daysInMonth(date), 23, 59, 59);
  }

  /// Every calendar date in the month containing [month].
  static List<DateTime> generateMonthDays(DateTime month) {
    final int total = daysInMonth(month);
    return List<DateTime>.generate(
      total,
      (int index) => DateTime(month.year, month.month, index + 1),
    );
  }

  // ---------------------------------------------------------------------
  // Study Helpers
  // ---------------------------------------------------------------------

  /// e.g. "45m", "1h 20m", "2h", "3h 15m".
  static String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);

    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String formatStudyDuration(int minutes) {
    return formatDuration(Duration(minutes: minutes));
  }

  // ---------------------------------------------------------------------
  // Greeting Helpers
  // ---------------------------------------------------------------------

  static String greetingForNow() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  static String motivationalTimePhrase() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return "Let's make today productive ✨";
    if (hour < 17) return 'A little progress today matters 💙';
    if (hour < 21) return 'Time for a focused study session 📚';
    return "Don't forget to take care of yourself 🌿";
  }

  // ---------------------------------------------------------------------
  // Sleep Helper
  // ---------------------------------------------------------------------

  /// True between 11 PM and 5 AM.
  static bool isLateNight(DateTime date) {
    return date.hour >= 23 || date.hour < 5;
  }

  // ---------------------------------------------------------------------
  // TimeOfDay Helpers
  // ---------------------------------------------------------------------

  /// e.g. "08:30 AM".
  static String formatTimeOfDay(TimeOfDay time) {
    final int hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static TimeOfDay addMinutes(TimeOfDay time, int minutes) {
    final int totalMinutes =
        ((time.hour * 60 + time.minute + minutes) % 1440 + 1440) % 1440;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  // ---------------------------------------------------------------------
  // Parsing Helpers
  // ---------------------------------------------------------------------

  static DateTime? tryParse(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  static DateTime parseOrNow(String value) {
    return tryParse(value) ?? DateTime.now();
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A UI-independent demo of [AppDateUtils], useful for quick manual
/// testing of the major formatters.
class DateUtilsDemo {
  DateUtilsDemo._();

  static Map<String, String> generateDemo() {
    final DateTime now = DateTime.now();

    return <String, String>{
      'currentDate': AppDateUtils.formatDate(now),
      'currentTime': AppDateUtils.formatTime(now),
      'conversationalDate': AppDateUtils.conversationalDateTime(now),
      'timeAgo': AppDateUtils.timeAgo(now.subtract(const Duration(hours: 2))),
      'timeUntilTomorrow':
          AppDateUtils.timeUntil(now.add(const Duration(days: 1))),
      'classStartsIn':
          AppDateUtils.classStartsIn(now.add(const Duration(minutes: 20))),
      'studyDuration': AppDateUtils.formatStudyDuration(95),
      'greeting': AppDateUtils.greetingForNow(),
      'reminderPhrase':
          AppDateUtils.reminderPhrase(now.add(const Duration(hours: 3))),
    };
  }
}

