import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_kit.dart' as kit;
import '../../auth/presentation/auth_provider.dart';
import '../../wardrobe/presentation/wardrobe_provider.dart';

final styleGuideProvider = FutureProvider<Map<String, int>>((ref) async {
  final token = ref.watch(authProvider.select((s) => s.value?.token));
  if (token == null || token.isEmpty) {
    return const {};
  }

  final repo = ref.watch(wardrobeRepositoryProvider);
  final page1 = await repo.list(page: 1, limit: 100);
  final counts = <String, int>{};
  for (final item in page1.data) {
    counts[item.categoria] = (counts[item.categoria] ?? 0) + 1;
  }

  // se houver mais páginas, busca até ~300 itens
  var page = 2;
  var loaded = page1.data.length;
  while (loaded < page1.total && page <= 3) {
    final next = await repo.list(page: page, limit: 100);
    for (final item in next.data) {
      counts[item.categoria] = (counts[item.categoria] ?? 0) + 1;
    }
    loaded += next.data.length;
    if (next.data.isEmpty) break;
    page++;
  }
  return counts;
});

class StyleGuideScreen extends ConsumerWidget {
  const StyleGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(styleGuideProvider);

    return kit.PastelBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          title: Text(
            'Guia de estilo',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
        body: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pinkChip),
          ),
          error: (err, _) => Center(
            child: Text(
              err is ApiException ? err.message : 'Erro ao carregar',
              style: GoogleFonts.nunito(),
            ),
          ),
          data: (counts) {
            final total = counts.values.fold<int>(0, (a, b) => a + b);
            final entries = counts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            if (total == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.checkroom, size: 48, color: AppColors.inkSoft),
                      const SizedBox(height: 12),
                      Text(
                        'Seu closet ainda está vazio',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Adicione peças para ver a distribuição por categoria.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.roseDeep.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Distribuição do closet',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total peças analisadas',
                        style: GoogleFonts.nunito(
                          color: AppColors.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            slices: entries
                                .map(
                                  (e) => _Slice(
                                    value: e.value / total,
                                    color: AppColors.softTag(e.key),
                                  ),
                                )
                                .toList(),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$total',
                                  style: GoogleFonts.nunito(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'peças',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: entries.map((e) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.softTag(e.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                e.key,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Por categoria',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...entries.map((e) {
                  final pct = e.value / total;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softTag(e.key),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                e.key,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${e.value} peça${e.value == 1 ? '' : 's'}',
                              style: GoogleFonts.nunito(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(pct * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: AppColors.chip,
                            color: AppColors.softTag(e.key),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Slice {
  const _Slice({required this.value, required this.color});
  final double value;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.slices});

  final List<_Slice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    var start = -math.pi / 2;
    final stroke = radius * 0.34;

    for (final slice in slices) {
      final sweep = slice.value * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
