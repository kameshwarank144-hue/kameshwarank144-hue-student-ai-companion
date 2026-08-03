// lib/core/widgets/premium_button.dart

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------
// Default styling constants
// ---------------------------------------------------------------------

const List<Color> _kPrimaryGradientColors = <Color>[
  Color(0xFF7C4DFF),
  Color(0xFF5B8CFF),
  Color(0xFF00E5FF),
];

const Color _kPrimaryGlowColor = Color(0xFF7C4DFF);

/// A reusable, production-ready premium button used throughout Student
/// AI Companion for primary actions (login, sign up, save, continue,
/// starting a study session, asking the AI, creating a reminder, and
/// general navigation).
///
/// Supports three visual variants — a gradient-filled primary button
/// (default), an outlined button, and a frosted glass button — plus a
/// built-in loading state and a soft press-scale animation.
class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.isGlass = false,
    this.width,
    this.height = 56,
    this.borderRadius = 20,
    this.padding,
    this.gradient,
    this.textStyle,
    this.leading,
    this.trailing,
  });

  // ---------------------------------------------------------------------
  // Convenience constructors
  // ---------------------------------------------------------------------

  /// A primary, gradient-filled button. This is equivalent to the
  /// default [PremiumButton] configuration.
  const PremiumButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.borderRadius = 20,
    this.padding,
    this.gradient,
    this.textStyle,
    this.leading,
    this.trailing,
  })  : isOutlined = false,
        isGlass = false;

  /// A transparent, outlined button with no gradient fill.
  const PremiumButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.borderRadius = 20,
    this.padding,
    this.textStyle,
    this.leading,
    this.trailing,
  })  : isOutlined = true,
        isGlass = false,
        gradient = null;

  /// A frosted, translucent glass button suited to dark backgrounds.
  const PremiumButton.glass({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.borderRadius = 20,
    this.padding,
    this.textStyle,
    this.leading,
    this.trailing,
  })  : isOutlined = false,
        isGlass = true,
        gradient = null;

  /// The button's label text.
  final String label;

  /// Callback fired when the button is tapped. If null, the button is
  /// rendered in a disabled state.
  final VoidCallback? onPressed;

  /// Optional leading icon, shown before [label].
  final IconData? icon;

  /// When true, disables taps and shows a centered spinner instead of
  /// the label/icon content.
  final bool isLoading;

  /// When true, renders a transparent, outlined variant instead of the
  /// default gradient fill.
  final bool isOutlined;

  /// When true, renders a frosted glass variant instead of the default
  /// gradient fill.
  final bool isGlass;

  /// Fixed width. If null, the button expands to fill its parent.
  final double? width;

  /// Button height. Defaults to 56, matching the minimum recommended
  /// touch target for accessibility.
  final double height;

  /// Corner radius applied to the button's shape.
  final double borderRadius;

  /// Interior padding. Defaults to a balanced horizontal inset.
  final EdgeInsetsGeometry? padding;

  /// Custom gradient override for the primary variant.
  final Gradient? gradient;

  /// Custom text style override for the label.
  final TextStyle? textStyle;

  /// Optional widget shown before the icon/label (e.g. an avatar).
  final Widget? leading;

  /// Optional widget shown after the label (e.g. a chevron).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _PremiumButtonBody(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isOutlined: isOutlined,
      isGlass: isGlass,
      width: width,
      height: height,
      borderRadius: borderRadius,
      padding: padding,
      gradient: gradient,
      textStyle: textStyle,
      leading: leading,
      trailing: trailing,
    );
  }
}

// ---------------------------------------------------------------------
// Internal stateful body (handles press animation)
// ---------------------------------------------------------------------

class _PremiumButtonBody extends StatefulWidget {
  const _PremiumButtonBody({
    required this.label,
    required this.onPressed,
    required this.icon,
    required this.isLoading,
    required this.isOutlined,
    required this.isGlass,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.padding,
    required this.gradient,
    required this.textStyle,
    required this.leading,
    required this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool isGlass;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final TextStyle? textStyle;
  final Widget? leading;
  final Widget? trailing;

  @override
  State<_PremiumButtonBody> createState() => _PremiumButtonBodyState();
}

class _PremiumButtonBodyState extends State<_PremiumButtonBody> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool pressed) {
    if (!_isEnabled) return;
    setState(() => _isPressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(widget.borderRadius);

    final Gradient? effectiveGradient = widget.isOutlined || widget.isGlass
        ? null
        : (widget.gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _kPrimaryGradientColors,
            ));

    final Color glassFill = Colors.white.withOpacity(0.12);
    final Color glassBorder = Colors.white.withOpacity(0.24);

    final Color contentColor = widget.isOutlined
        ? scheme.onSurface
        : (widget.isGlass ? Colors.white : Colors.white);

    final TextStyle labelStyle = (widget.textStyle ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ))
        .copyWith(color: widget.textStyle?.color ?? contentColor);

    final List<BoxShadow> boxShadow = widget.isGlass
        ? <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ]
        : (widget.isOutlined
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: _kPrimaryGlowColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]);

    final BoxDecoration decoration = BoxDecoration(
      color: widget.isGlass
          ? glassFill
          : (widget.isOutlined ? Colors.transparent : null),
      gradient: effectiveGradient,
      borderRadius: radius,
      border: widget.isOutlined
          ? Border.all(color: scheme.onSurface.withOpacity(0.4), width: 1.4)
          : (widget.isGlass
              ? Border.all(color: glassBorder, width: 1.2)
              : null),
      boxShadow: boxShadow,
    );

    final EdgeInsetsGeometry effectivePadding =
        widget.padding ?? const EdgeInsets.symmetric(horizontal: 24);

    final Widget content = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(contentColor),
            ),
          )
        : Row(
            mainAxisSize: widget.width == null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.leading != null) ...<Widget>[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, color: contentColor, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: labelStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.trailing != null) ...<Widget>[
                const SizedBox(width: 10),
                widget.trailing!,
              ],
            ],
          );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _isEnabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: widget.width,
            height: widget.height,
            constraints: BoxConstraints(minHeight: widget.height),
            padding: effectivePadding,
            decoration: decoration,
            alignment: Alignment.center,
            child: Material(
              type: MaterialType.transparency,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Demo
// ---------------------------------------------------------------------

/// A small preview widget showcasing all [PremiumButton] variants on a
/// dark gradient background.
class PremiumButtonDemo extends StatelessWidget {
  const PremiumButtonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF050816),
              Color(0xFF10102A),
              Color(0xFF1B1040),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                PremiumButton.primary(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                PremiumButton.outlined(
                  label: 'Create Account',
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                PremiumButton.glass(
                  label: 'Ask AI',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
                const PremiumButton.primary(
                  label: 'Saving...',
                  isLoading: true,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

