// lib/features/auth/presentation/screens/profile_setup_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ai_orb.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/premium_button.dart';

/// The academic-year choices offered during profile setup. Deliberately
/// open-ended ("Other") since not every student follows a four-year
/// program.
const List<String> kAcademicYearOptions = <String>[
  'First Year',
  'Second Year',
  'Third Year',
  'Fourth Year',
  'Postgraduate',
  'Other',
];

/// The study-goal choices offered during profile setup. Multiple
/// selections are allowed.
const List<String> kStudyGoalOptions = <String>[
  'Better focus',
  'Improve attendance',
  'Manage assignments',
  'Prepare for exams',
  'Build better habits',
  'Balance college and personal time',
  'Other',
];

/// The profile information collected by [ProfileSetupScreen], handed to
/// [ProfileSetupScreen.onSaveProfile] for persistence by whatever
/// profile repository/provider the app ends up using.
@immutable
class ProfileSetupResult {
  const ProfileSetupResult({
    required this.name,
    this.college,
    this.course,
    this.department,
    this.academicYear,
    this.studyGoals = const <String>{},
  });

  /// The student's display name. Always present (required field).
  final String name;

  /// The student's college/institution, if provided.
  final String? college;

  /// The student's course/degree, if provided.
  final String? course;

  /// The student's department, if provided.
  final String? department;

  /// The student's selected academic year, if any.
  final String? academicYear;

  /// The student's selected study goals, if any.
  final Set<String> studyGoals;
}

/// Signature for persisting a completed [ProfileSetupResult]. Should
/// throw on failure (ideally something [ErrorMapper] can translate) so
/// [ProfileSetupScreen] can surface a friendly message and let the
/// student retry without losing what they typed.
typedef ProfileSaveCallback = Future<void> Function(ProfileSetupResult result);

/// A warm, premium profile-setup screen shown right after account
/// creation, so Nova AI can get to know the student a little before
/// they reach the main app.
///
/// This screen is UI-only: it never invents a database or repository.
/// Saving is delegated entirely to [onSaveProfile] — a clean, isolated
/// integration point that a future profile repository/provider can be
/// plugged into without touching this file again. If [onSaveProfile]
/// isn't supplied yet, the student can still continue (their answers
/// just aren't persisted anywhere until that's wired up), and "Skip for
/// now" always works regardless.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.onSaveProfile,
    this.onSkip,
  });

  /// Called with the completed profile when the student taps Continue.
  final ProfileSaveCallback? onSaveProfile;

  /// Called when the student taps "Skip for now". If not provided,
  /// defaults to navigating straight to [RouteNames.home].
  final VoidCallback? onSkip;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  final FocusNode _collegeFocusNode = FocusNode();
  final FocusNode _courseFocusNode = FocusNode();
  final FocusNode _departmentFocusNode = FocusNode();

  String? _selectedAcademicYear;
  final Set<String> _selectedStudyGoals = <String>{};

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isSaving = false;
  bool _entered = false;

  @override
  void initState() {
    super.initState();

    final String prefillName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _nameController = TextEditingController(text: prefillName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _departmentController.dispose();
    _collegeFocusNode.dispose();
    _courseFocusNode.dispose();
    _departmentFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  String? _cleanOrNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    final bool isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    if (_isSaving) return;

    if (FirebaseAuth.instance.currentUser == null) {
      AppSnackbar.error(context, 'Your session has expired. Please sign in again.');
      return;
    }

    setState(() => _isSaving = true);

    final ProfileSetupResult result = ProfileSetupResult(
      name: _nameController.text.trim(),
      college: _cleanOrNull(_collegeController.text),
      course: _cleanOrNull(_courseController.text),
      department: _cleanOrNull(_departmentController.text),
      academicYear: _selectedAcademicYear,
      studyGoals: _selectedStudyGoals,
    );

    try {
      if (widget.onSaveProfile != null) {
        await widget.onSaveProfile!(result);
      }
      if (!mounted) return;
      context.go(RouteNames.home);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, ErrorMapper.summarize(ErrorMapper.map(error)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleSkip() {
    if (_isSaving) return;

    if (widget.onSkip != null) {
      widget.onSkip!();
      return;
    }
    context.go(RouteNames.home);
  }

  void _toggleStudyGoal(String goal, bool selected) {
    setState(() {
      if (selected) {
        _selectedStudyGoals.add(goal);
      } else {
        _selectedStudyGoals.remove(goal);
      }
    });
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[scheme.primary.withOpacity(0.08), scheme.surface],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl + bottomInset,
              ),
              child: AnimatedOpacity(
                opacity: _entered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                child: AnimatedSlide(
                  offset: _entered ? Offset.zero : const Offset(0, 0.03),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidateMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppSpacing.vLg,
                        _Header(scheme: scheme),
                        AppSpacing.vXxl,
                        _SectionLabel(
                          label: 'Required',
                          color: scheme.primary,
                        ),
                        AppSpacing.vSm,
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const <String>[AutofillHints.name],
                            validator: AppValidators.name,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_collegeFocusNode),
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                        ),
                        AppSpacing.vXxl,
                        _SectionLabel(
                          label: 'Optional — feel free to skip these',
                          color: scheme.onSurface.withOpacity(0.5),
                        ),
                        AppSpacing.vSm,
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _collegeController,
                                focusNode: _collegeFocusNode,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_courseFocusNode),
                                decoration: const InputDecoration(
                                  labelText: 'College / Institution',
                                  hintText: 'e.g. your college name',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                              ),
                              AppSpacing.vLg,
                              TextFormField(
                                controller: _courseController,
                                focusNode: _courseFocusNode,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(context)
                                    .requestFocus(_departmentFocusNode),
                                decoration: const InputDecoration(
                                  labelText: 'Course / Degree',
                                  hintText: 'e.g. B.Tech, B.Sc, M.A.',
                                  prefixIcon: Icon(Icons.menu_book_outlined),
                                ),
                              ),
                              AppSpacing.vLg,
                              TextFormField(
                                controller: _departmentController,
                                focusNode: _departmentFocusNode,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Department',
                                  hintText: 'e.g. Computer Science',
                                  prefixIcon: Icon(Icons.account_tree_outlined),
                                ),
                              ),
                              AppSpacing.vXl,
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Academic Year',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: scheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              AppSpacing.vSm,
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: kAcademicYearOptions.map((String year) {
                                  final bool selected = _selectedAcademicYear == year;
                                  return ChoiceChip(
                                    label: Text(year),
                                    selected: selected,
                                    onSelected: (bool value) {
                                      setState(() {
                                        _selectedAcademicYear = value ? year : null;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              AppSpacing.vXl,
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'What would you like help with?',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: scheme.onSurface.withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              AppSpacing.vSm,
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: kStudyGoalOptions.map((String goal) {
                                  final bool selected = _selectedStudyGoals.contains(goal);
                                  return FilterChip(
                                    label: Text(goal),
                                    selected: selected,
                                    onSelected: (bool value) => _toggleStudyGoal(goal, value),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.vXxl,
                        Semantics(
                          button: true,
                          label: 'Continue',
                          child: PremiumButton.primary(
                            label: 'Continue',
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _handleContinue,
                          ),
                        ),
                        AppSpacing.vMd,
                        Center(
                          child: Semantics(
                            button: true,
                            label: 'Skip profile setup for now',
                            child: TextButton(
                              onPressed: _isSaving ? null : _handleSkip,
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.vLg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: <Widget>[
        const Center(
          child: AiOrb(size: 76, mood: AiOrbMood.happy, showFace: true),
        ),
        AppSpacing.vLg,
        Text(
          "Let's get to know you",
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        AppSpacing.vSm,
        Text(
          'Tell me a little about your student life so I can make your '
          'experience more useful.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------

/// A small, colored section heading distinguishing required fields from
/// optional ones.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        AppSpacing.hSm,
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );
  }
}

