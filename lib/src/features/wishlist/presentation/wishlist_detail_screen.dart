import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
import 'wishlist_form_sheet.dart';
import 'wishlist_provider.dart';

class WishlistDetailScreen extends ConsumerWidget {
  const WishlistDetailScreen({super.key, required this.id});

  final String id;

  String _prioLabel(int p) => switch (p) {
        2 => 'Alta',
        1 => 'Média',
        _ => 'Baixa',
      };

  Future<void> _openLink(BuildContext context, String? link) async {
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.show(context, message: 'Não foi possível abrir o link');
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir desejo'),
        content: const Text('Tem certeza que deseja excluir este desejo?'),
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
      await ref.read(wishlistProvider.notifier).delete(id);
      if (context.mounted) {
        AppToast.show(context, message: 'Desejo excluído');
        context.go('/desejos');
      }
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        message: e is ApiException ? e.message : 'Erro ao excluir',
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _mover(BuildContext context, WidgetRef ref) async {
    AppLoading.show(context, message: 'Movendo para o closet...');
    try {
      await ref.read(wishlistProvider.notifier).moverParaCloset(id);
      if (context.mounted) {
        AppToast.show(context, message: 'Movido para o closet!', icon: Icons.checkroom);
        context.go('/roupas');
      }
    } on ApiException catch (e) {
      AppLoading.hide();
      if (e.code == 'DESEJO_SEM_CATEGORIA' && context.mounted) {
        String categoria = clothingCategories.first;
        final picked = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Escolha a categoria'),
            content: StatefulBuilder(
              builder: (context, setLocal) {
                return SoftSelectField<String>(
                  label: 'Categoria',
                  value: categoria,
                  items: clothingCategories,
                  labelBuilder: (v) => v,
                  onChanged: (v) => setLocal(() => categoria = v),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, categoria),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
        if (picked == null || !context.mounted) return;
        AppLoading.show(context, message: 'Movendo para o closet...');
        try {
          await ref
              .read(wishlistProvider.notifier)
              .moverParaCloset(id, categoria: picked);
          if (context.mounted) {
            AppToast.show(
              context,
              message: 'Movido para o closet!',
              icon: Icons.checkroom,
            );
            context.go('/roupas');
          }
        } catch (err) {
          if (context.mounted) {
            AppToast.show(
              context,
              message: err is ApiException ? err.message : 'Erro ao mover',
              icon: Icons.error_outline,
            );
          }
        } finally {
          AppLoading.hide();
        }
        return;
      }
      if (context.mounted) {
        AppToast.show(context, message: e.message, icon: Icons.error_outline);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          context,
          message: e is ApiException ? e.message : 'Erro ao mover',
          icon: Icons.error_outline,
        );
      }
    } finally {
      AppLoading.hide();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItem = ref.watch(wishlistDetailProvider(id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: asyncItem.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err is ApiException ? err.message : 'Erro'),
        ),
        data: (item) {
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 320,
                      pinned: true,
                      backgroundColor: Colors.white,
                      leading: _RoundIcon(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => context.pop(),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            item.fotoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: item.fotoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppColors.chip,
                                    child: const Icon(Icons.favorite_border, size: 72),
                                  ),
                            if (item.marca != null && item.marca!.isNotEmpty)
                              Positioned(
                                left: 16,
                                bottom: 24,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.marca!,
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        transform: Matrix4.translationValues(0, -16, 0),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.nome,
                                    style: GoogleFonts.nunito(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (item.categoria != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.butter,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      item.categoria!,
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (item.tamanho != null &&
                                    item.tamanho!.isNotEmpty)
                                  _InfoChip(Icons.straighten, item.tamanho!),
                                if (item.cor != null && item.cor!.isNotEmpty)
                                  _InfoChip(Icons.palette_outlined, item.cor!),
                                _InfoChip(
                                  Icons.star_outline,
                                  _prioLabel(item.prioridade),
                                ),
                                if (item.precoAlvo != null)
                                  _InfoChip(
                                    Icons.attach_money,
                                    'R\$ ${item.precoAlvo!.toStringAsFixed(2)}',
                                    accent: true,
                                  ),
                              ],
                            ),
                            if (item.linkRef != null &&
                                item.linkRef!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _openLink(context, item.linkRef),
                                child: Text(
                                  'Abrir link da loja',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.roseDeep,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            Text(
                              'OBSERVAÇÃO',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.observacao?.trim().isNotEmpty == true
                                  ? item.observacao!
                                  : 'Sem observações ainda.',
                              style: GoogleFonts.nunito(
                                height: 1.45,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _mover(context, ref),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lilacDeep,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.checkroom),
                          label: const Text('Mover para o closet'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => showWishlistFormSheet(
                                context,
                                ref,
                                item: item,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.butter,
                                foregroundColor: AppColors.ink,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Editar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _confirmDelete(context, ref),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFE0E4),
                                foregroundColor: AppColors.danger,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Excluir'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.label, {this.accent = false});
  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? AppColors.mint : AppColors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkSoft),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
