import 'package:flutter/material.dart'
    hide
        Badge,
        ButtonStyle,
        Card,
        Chip,
        CircularProgressIndicator,
        ColorScheme,
        Theme,
        ThemeData;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart'
    hide
        Column,
        Flex,
        Flexible,
        Positioned,
        Row,
        Stack,
        Tooltip;

import '../theme/app_colors.dart';

export 'package:shadcn_flutter/shadcn_flutter.dart'
    show
        ButtonDensity,
        ButtonShape,
        ButtonSize,
        ButtonStyle,
        Card,
        Chip,
        CircularProgressIndicator,
        GhostButton,
        LucideIcons,
        OutlineButton,
        PrimaryButton,
        SecondaryButton;

class PastelBackground extends StatelessWidget {
  const PastelBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blush,
            Color(0xFFFFE4EF),
            AppColors.blushDeep,
            Color(0xFFFCE8F2),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _Blob(
              size: 180,
              color: AppColors.petal.withValues(alpha: 0.42),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: _Blob(
              size: 150,
              color: AppColors.lilac.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 200,
            left: 28,
            child: _Blob(
              size: 64,
              color: AppColors.butter.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            bottom: 220,
            right: 24,
            child: _Blob(
              size: 56,
              color: AppColors.apricot.withValues(alpha: 0.28),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.08, 1.08),
            duration: 4200.ms,
            curve: Curves.easeInOut,
          )
          .fade(begin: 0.7, end: 1, duration: 4200.ms),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.compact = false,
    this.center = true,
  });

  final bool compact;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 22.0 : 34.0;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Card(
          filled: true,
          fillColor: AppColors.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Icon(
            LucideIcons.shirt,
            size: compact ? 22 : 32,
            color: AppColors.roseDeep,
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
        Text(
          'CLOSET DA ELISA',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.playfairDisplay(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'seu guarda-roupa com carinho',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.nunito(
            fontSize: compact ? 12 : 14,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return column
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}

class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final button = filled
        ? PrimaryButton(
            onPressed: onPressed,
            shape: ButtonShape.circle,
            density: ButtonDensity.icon,
            child: Icon(icon, size: 18),
          )
        : GhostButton(
            onPressed: onPressed,
            shape: ButtonShape.circle,
            density: ButtonDensity.icon,
            child: Icon(icon, size: 18),
          );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class SoftPrimaryButton extends StatelessWidget {
  const SoftPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        onPressed: loading ? null : onPressed,
        leading: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(size: 18),
              )
            : (icon != null ? Icon(icon, size: 18) : null),
        child: Text(label),
      ),
    );
  }
}

class SoftOutlineButton extends StatelessWidget {
  const SoftOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      onPressed: onPressed,
      leading: icon != null ? Icon(icon, size: 18) : null,
      child: Text(label),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              filled: true,
              fillColor: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              padding: const EdgeInsets.all(22),
              child: Icon(icon, size: 36, color: AppColors.roseDeep),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.94, 0.94),
              end: const Offset(1, 1),
            ),
      ),
    );
  }
}

class SoftErrorView extends StatelessWidget {
  const SoftErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Card(
          filled: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cloudOff, size: 36, color: AppColors.rose),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              SoftPrimaryButton(
                label: 'Tentar novamente',
                icon: LucideIcons.refreshCw,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.categoria,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  /// Chave da categoria (`null` = Todas). Se omitido, usa [label].
  final String? categoria;

  @override
  Widget build(BuildContext context) {
    final key = categoria ?? (label == 'Todas' ? null : label);
    final fill = AppColors.categoryFill(key, selected: selected);
    final ink = AppColors.categoryInk(key, selected: selected);

    return Material(
      color: fill,
      elevation: selected ? 1.5 : 0,
      shadowColor: AppColors.rose.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? ink.withValues(alpha: 0.35)
                  : const Color(0x8CFFFFFF),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
