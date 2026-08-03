// lib/core/constants/asset_paths.dart

/// Central asset registry for Student AI Companion.
///
/// All SVG, Lottie, Rive, image, and font paths are defined here so that
/// no hardcoded asset strings are used anywhere else in the app.
class AssetPaths {
  AssetPaths._();

  // -----------------------------------------------------------------
  // Root folders
  // -----------------------------------------------------------------

  static const String svg = 'assets/svg';
  static const String lottie = 'assets/lottie';
  static const String rive = 'assets/rive';
  static const String fonts = 'assets/fonts';

  // -----------------------------------------------------------------
  // SVG assets
  // -----------------------------------------------------------------

  // Onboarding
  static const String onboardingWelcome =
      'assets/svg/onboarding/welcome.svg';

  static const String onboardingStudy =
      'assets/svg/onboarding/study.svg';

  static const String onboardingAttendance =
      'assets/svg/onboarding/attendance.svg';

  static const String onboardingAi =
      'assets/svg/onboarding/ai_companion.svg';

  // Empty States
  static const String emptyTasks =
      'assets/svg/empty_states/empty_tasks.svg';

  static const String emptyAttendance =
      'assets/svg/empty_states/empty_attendance.svg';

  static const String emptyTimetable =
      'assets/svg/empty_states/empty_timetable.svg';

  static const String emptyNotes =
      'assets/svg/empty_states/empty_notes.svg';

  static const String emptyChat =
      'assets/svg/empty_states/empty_chat.svg';

  // Icons
  static const String iconAttendance =
      'assets/svg/icons/attendance.svg';

  static const String iconTimetable =
      'assets/svg/icons/timetable.svg';

  static const String iconTodo =
      'assets/svg/icons/todo.svg';

  static const String iconStudy =
      'assets/svg/icons/study.svg';

  static const String iconAi =
      'assets/svg/icons/ai.svg';

  static const String iconHealth =
      'assets/svg/icons/health.svg';

  static const String iconExpense =
      'assets/svg/icons/expense.svg';

  // -----------------------------------------------------------------
  // Lottie animations
  // -----------------------------------------------------------------

  static const String loading =
      'assets/lottie/loading.json';

  static const String success =
      'assets/lottie/success.json';

  static const String error =
      'assets/lottie/error.json';

  static const String confetti =
      'assets/lottie/confetti.json';

  static const String forestGrowth =
      'assets/lottie/forest_growth.json';

  // -----------------------------------------------------------------
  // Rive assets
  // -----------------------------------------------------------------

  static const String aiOrb =
      'assets/rive/ai_orb.riv';

  static const String orbStates =
      'assets/rive/orb_states.riv';

  // -----------------------------------------------------------------
  // Font assets
  // -----------------------------------------------------------------

  // Poppins
  static const String poppinsRegular =
      'assets/fonts/Poppins-Regular.ttf';

  static const String poppinsMedium =
      'assets/fonts/Poppins-Medium.ttf';

  static const String poppinsSemiBold =
      'assets/fonts/Poppins-SemiBold.ttf';

  static const String poppinsBold =
      'assets/fonts/Poppins-Bold.ttf';

  // Inter
  static const String interRegular =
      'assets/fonts/Inter-Regular.ttf';

  static const String interMedium =
      'assets/fonts/Inter-Medium.ttf';

  static const String interSemiBold =
      'assets/fonts/Inter-SemiBold.ttf';
}

