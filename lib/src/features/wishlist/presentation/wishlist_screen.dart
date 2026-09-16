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
import '../data/models/wishlist_item.dart';
import 'wishlist_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  Future<void> _addDesejo() async {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String categoria = clothingCategories.first;
    int prioridade = 1;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
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
                      'Novo desejo',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nomeCtrl,
                      decoration: _input('Nome *'),
                    ),
                    const SizedBox(height: 12),
                    SoftSelectField<String>(
                      label: 'Categoria',
                      value: categoria,
                      items: clothingCategories,
                      labelBuilder: (v) => v,
                      onChanged: (v) => setModal(() => categoria = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _input('Preço alvo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: linkCtrl,
                      keyboardType: TextInputType.url,
                      decoration: _input(
                        'Link da loja (opcional)',
                        hint: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftSelectField<int>(
                      label: 'Prioridade',
                      value: prioridade,
                      items: const [0, 1, 2],
                      labelBuilder: (v) => switch (v) {
                        2 => 'Alta',
                        1 => 'Média',
                        _ => 'Baixa',
                      },
                      onChanged: (v) => setModal(() => prioridade = v),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pinkChip,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Salvar desejo',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (ok != true || !mounted) return;
    final nome = nomeCtrl.text.trim();
    if (nome.length < 2) {
      AppToast.show(context, message: 'Informe um nome válido', icon: Icons.error_outline);
      return;
    }

    final preco = double.tryParse(precoCtrl.text.replaceAll(',', '.'));
    final link = linkCtrl.text.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        AppToast.show(
          context,
          message: 'Link inválido. Use http:// ou https://',
          icon: Icons.link_off,
        );
        return;
      }
    }

    AppLoading.show(context, message: 'Salvando desejo...');
    try {
      await ref.read(wishlistProvider.notifier).create({
        'nome': nome,
        'categoria': categoria,
        'prioridade': prioridade,
        if (preco != null) 'precoAlvo': preco,
        if (link.isNotEmpty) 'linkRef': link,
      });
      if (mounted) {
        AppToast.show(context, message: 'Desejo adicionado ✨', icon: Icons.favorite);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e is ApiException ? e.message : 'Erro ao criar desejo',
        icon: Icons.error_outline,
      );
    } finally {
      AppLoading.hide();
    }
  }

  InputDecoration _input(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.blush.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.petal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.petal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.pinkChip, width: 1.4),
      ),
    );
  }

  Future<void> _mover(WishlistItem item) async {
    AppLoading.show(context, message: 'Movendo para o closet...');
    try {
      await ref.read(wishlistProvider.notifier).moverParaCloset(item.id);
      if (!mounted) return;
      AppToast.show(context, message: 'Movido para o closet!', icon: Icons.checkroom);
    } on ApiException catch (e) {
      AppLoading.hide();
      if (e.code == 'DESEJO_SEM_CATEGORIA') {
        String cat = clothingCategories.first;
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: StatefulBuilder(
              builder: (context, setModal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SoftSelectField<String>(
                      label: 'Categoria',
                      value: cat,
                      items: clothingCategories,
                      labelBuilder: (v) => v,
                      onChanged: (v) => setModal(() => cat = v),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, cat),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pinkChip,
                      ),
                      child: const Text('Mover'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        if (picked == null || !mounted) return;
        AppLoading.show(context, message: 'Movendo para o closet...');
        await ref
            .read(wishlistProvider.notifier)
            .moverParaCloset(item.id, categoria: picked);
        if (!mounted) return;
        AppToast.show(context, message: 'Movido para o closet!', icon: Icons.checkroom);
      } else if (mounted) {
        AppToast.show(context, message: e.message, icon: Icons.error_outline);
      }
    } finally {
      AppLoading.hide();
    }
  }

  String _prioLabel(int p) => switch (p) {
        2 => 'Alta',
        1 => 'Média',
        _ => 'Baixa',
      };

  Color _prioColor(int p) => switch (p) {
        2 => const Color(0xFFFFB4B4),
        1 => AppColors.butter,
        _ => const Color(0xFFB8D4FF),
      };

  Future<void> _openLink(String? link) async {
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppToast.show(context, message: 'Não foi possível abrir o link');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          backgroundColor: AppColors.pinkChip.withValues(alpha: 0.18),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: item.fotoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: item.fotoUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppColors.chip,
                                      child: const Icon(Icons.favorite_border),
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
                                if (item.precoAlvo != null)
                                  Text(
                                    'R\$ ${item.precoAlvo!.toStringAsFixed(2)}',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.inkSoft,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (item.linkRef != null &&
                                    item.linkRef!.isNotEmpty)
                                  InkWell(
                                    onTap: () => _openLink(item.linkRef),
                                    child: Text(
                                      'Abrir link da loja',
                                      style: GoogleFonts.nunito(
                                        color: AppColors.roseDeep,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              SizedBox(
                                height: 34,
                                child: FilledButton(
                                  onPressed: () => _mover(item),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.lilacDeep,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    textStyle: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text('Ao closet'),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  AppLoading.show(context, message: 'Removendo...');
                                  try {
                                    await ref
                                        .read(wishlistProvider.notifier)
                                        .delete(item.id);
                                  } finally {
                                    AppLoading.hide();
                                  }
                                },
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _addDesejo,
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
