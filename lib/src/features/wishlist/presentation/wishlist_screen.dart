import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import 'wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  String _prioLabel(int p) => switch (p) {
        2 => 'Alta',
        1 => 'Média',
        _ => 'Baixa',
      };

  Color _prioColor(int p) => switch (p) {
        2 => const Color(0xFFFFD6DE),
        1 => AppColors.butter,
        _ => AppColors.chip,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.pinkChip),
          ),
          error: (err, _) => Center(
            child: Text(err is ApiException ? err.message : 'Erro'),
          ),
          data: (items) {
            final totalAlvo = items.fold<double>(
              0,
              (a, b) => a + (b.precoAlvo ?? 0),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Text(
                  'Lista de Desejos ✨',
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${items.length} itens',
                  style: GoogleFonts.nunito(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.roseDeep.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            AppColors.pinkChip.withValues(alpha: 0.18),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.roseDeep,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor total dos desejos',
                              style: GoogleFonts.nunito(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'R\$ ${totalAlvo.toStringAsFixed(2)}',
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => context.go('/roupas'),
                          child: const Text('👤 Meu Closet'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.butter,
                            foregroundColor: AppColors.ink,
                          ),
                          child: const Text('✨ Desejos'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push('/desejos/${item.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: item.fotoUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: item.fotoUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: AppColors.chip,
                                          child: const Icon(
                                            Icons.favorite_border,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (item.categoria != null)
                                          _MiniTag(
                                            item.categoria!,
                                            AppColors.softTag(item.categoria),
                                          ),
                                        _MiniTag(
                                          '★ ${_prioLabel(item.prioridade)}',
                                          _prioColor(item.prioridade),
                                        ),
                                        if (item.tamanho != null &&
                                            item.tamanho!.isNotEmpty)
                                          _MiniTag(
                                            'Tam. ${item.tamanho!}',
                                            AppColors.chip,
                                          ),
                                      ],
                                    ),
                                    Text(
                                      item.nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final bits = <String>[
                                          if (item.cor != null &&
                                              item.cor!.isNotEmpty)
                                            item.cor!,
                                          if (item.precoAlvo != null)
                                            'R\$ ${item.precoAlvo!.toStringAsFixed(2)}',
                                        ];
                                        if (bits.isEmpty) {
                                          return Text(
                                            'Toque para ver detalhes',
                                            style: GoogleFonts.nunito(
                                              color: AppColors.inkSoft,
                                              fontSize: 12,
                                            ),
                                          );
                                        }
                                        return Text(
                                          bits.join(' · '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.nunito(
                                            color: AppColors.inkSoft,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.inkSoft,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/desejos/nova'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.roseDeep,
                    side: BorderSide(
                      color: AppColors.roseDeep.withValues(alpha: 0.45),
                      width: 1.4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    '+ Adicionar novo desejo',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
