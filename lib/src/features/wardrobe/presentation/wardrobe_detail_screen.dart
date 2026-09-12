import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_kit.dart';
import 'wardrobe_provider.dart';

class WardrobeDetailScreen extends ConsumerWidget {
  const WardrobeDetailScreen({super.key, required this.id});

  final String id;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir peça'),
        content: const Text('Tem certeza que deseja excluir esta peça?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(wardrobeProvider.notifier).delete(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peça excluída')),
        );
        context.go('/roupas');
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = e is ApiException ? e.message : 'Erro ao excluir';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(clothingDetailProvider(id));

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: asyncItem.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => SoftErrorView(
              message: err is ApiException ? err.message : 'Erro ao carregar',
              onRetry: () => ref.invalidate(clothingDetailProvider(id)),
            ),
            data: (item) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        SoftIconButton(
                          icon: LucideIcons.arrowLeft,
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        SoftIconButton(
                          icon: LucideIcons.pencil,
                          onPressed: () => context.push('/roupas/$id/editar'),
                          tooltip: 'Editar',
                        ),
                        const SizedBox(width: 8),
                        SoftIconButton(
                          icon: LucideIcons.trash2,
                          onPressed: () => _confirmDelete(context, ref),
                          tooltip: 'Excluir',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        Hero(
                          tag: 'roupa-foto-$id',
                          child: AspectRatio(
                            aspectRatio: 0.92,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: item.fotoUrl != null &&
                                      item.fotoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.fotoUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: AppColors.chip,
                                        child: const Icon(
                                          LucideIcons.shirt,
                                          size: 72,
                                          color: AppColors.apricot,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.chip,
                                      child: const Icon(
                                        LucideIcons.shirt,
                                        size: 72,
                                        color: AppColors.apricot,
                                      ),
                                    ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .scale(
                              begin: const Offset(0.97, 0.97),
                              end: const Offset(1, 1),
                            ),
                        const SizedBox(height: 20),
                        Text(
                          item.nome,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Tag(label: item.categoria, emphasize: true),
                            if (item.cor != null && item.cor!.isNotEmpty)
                              _Tag(label: item.cor!),
                            if (item.tamanho != null && item.tamanho!.isNotEmpty)
                              _Tag(label: 'Tam. ${item.tamanho!}'),
                            if (item.marca != null && item.marca!.isNotEmpty)
                              _Tag(label: item.marca!),
                          ],
                        ),
                        if (item.observacao != null &&
                            item.observacao!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Observação',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.observacao!,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.emphasize = false});

  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.categoryFill(label, selected: true)
            : AppColors.categoryFill(label, selected: false),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: AppColors.categoryInk(label, selected: emphasize),
        ),
      ),
    );
  }
}
