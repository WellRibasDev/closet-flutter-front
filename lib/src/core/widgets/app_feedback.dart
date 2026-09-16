import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Toast suave no topo, nas cores do sistema.
abstract final class AppToast {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Duration duration = const Duration(seconds: 2),
  }) {
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (context) {
        final top = MediaQuery.of(context).padding.top + 12;
        return Positioned(
          top: top,
          right: 16,
          left: 16,
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.petal),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.roseDeep.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.pinkChip.withValues(alpha: 0.2),
                        child: Icon(icon, size: 18, color: AppColors.roseDeep),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          style: GoogleFonts.nunito(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    Future<void>.delayed(duration, () {
      _entry?.remove();
      _entry = null;
    });
  }

  static void comingSoon(BuildContext context, [String? feature]) {
    show(
      context,
      message: feature == null
          ? 'Essa opção chega em breve ✨'
          : '$feature chega em breve ✨',
      icon: Icons.auto_awesome,
    );
  }
}

/// Overlay de carregamento rosa pastel.
abstract final class AppLoading {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {String message = 'Carregando...'}) {
    hide();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (context) => Material(
        color: const Color(0xFFFFD1DC).withValues(alpha: 0.72),
        child: Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.roseDeep.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.pinkChip,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

/// Seletor estilizado (evita dropdown nativo Android).
class SoftSelectField<T> extends StatelessWidget {
  const SoftSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.petal,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = item == value;
                      return Material(
                        color: selected
                            ? AppColors.pinkChip.withValues(alpha: 0.18)
                            : AppColors.blush.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context, item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    labelBuilder(item),
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.pinkChip,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _open(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.petal),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labelBuilder(value),
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.roseDeep),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
