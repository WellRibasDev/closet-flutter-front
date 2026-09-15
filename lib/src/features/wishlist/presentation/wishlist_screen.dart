import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
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
    String categoria = clothingCategories.first;
    int prioridade = 1;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    items: clothingCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setModal(() => categoria = v ?? categoria),
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: precoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Preço alvo'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: prioridade,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Baixa')),
                      DropdownMenuItem(value: 1, child: Text('Média')),
                      DropdownMenuItem(value: 2, child: Text('Alta')),
                    ],
                    onChanged: (v) => setModal(() => prioridade = v ?? 1),
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true || !mounted) return;
    final nome = nomeCtrl.text.trim();
    if (nome.length < 2) return;

    final preco = double.tryParse(precoCtrl.text.replaceAll(',', '.'));
    try {
      await ref.read(wishlistProvider.notifier).create({
        'nome': nome,
        'categoria': categoria,
        'prioridade': prioridade,
        if (preco != null) 'precoAlvo': preco,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : 'Erro ao criar desejo'),
        ),
      );
    }
  }

  Future<void> _mover(WishlistItem item) async {
    try {
      await ref.read(wishlistProvider.notifier).moverParaCloset(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movido para o closet!')),
      );
    } on ApiException catch (e) {
      if (e.code == 'DESEJO_SEM_CATEGORIA') {
        String cat = clothingCategories.first;
        final picked = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Escolha a categoria'),
            content: DropdownButtonFormField<String>(
              value: cat,
              items: clothingCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => cat = v ?? cat,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, cat),
                child: const Text('Mover'),
              ),
            ],
          ),
        );
        if (picked == null) return;
        await ref
            .read(wishlistProvider.notifier)
            .moverParaCloset(item.id, categoria: picked);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movido para o closet!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.blush,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(err is ApiException ? err.message : 'Erro'),
          ),
          data: (items) {
            final totalAlvo = items.fold<double>(
              0,
              (a, b) => a + (b.precoAlvo ?? 0),
            );
            final economizado = totalAlvo * 0.4;
            final progresso = totalAlvo == 0 ? 0.0 : 0.6;

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
                  '${items.length} itens · meta R\$ ${totalAlvo.toStringAsFixed(0)}',
                  style: GoogleFonts.nunito(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: progresso,
                          strokeWidth: 8,
                          backgroundColor: AppColors.chip,
                          color: AppColors.purpleBar,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Poupança estimada',
                              style: GoogleFonts.nunito(
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'R\$ ${economizado.toStringAsFixed(0)} / R\$ ${totalAlvo.toStringAsFixed(0)}',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
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
                    color: AppColors.chip,
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
                      color: Colors.white,
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
                                  'R\$ ${item.precoAlvo!.toStringAsFixed(0)}',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.inkSoft,
                                    fontSize: 12,
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
                              onPressed: () => ref
                                  .read(wishlistProvider.notifier)
                                  .delete(item.id),
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
                      style: BorderStyle.solid,
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
