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

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_kit.dart';
import '../data/models/wishlist_item.dart';
import 'wishlist_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  Future<void> _showCreateDialog() async {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    String? categoria = clothingCategories.first;
    var prioridade = 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Novo desejo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        prefixIcon: Icon(LucideIcons.heart),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoria *',
                        prefixIcon: Icon(LucideIcons.tags),
                      ),
                      items: clothingCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => categoria = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: precoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço alvo',
                        prefixIcon: Icon(LucideIcons.banknote),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link',
                        prefixIcon: Icon(LucideIcons.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: prioridade,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                        prefixIcon: Icon(LucideIcons.star),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Baixa')),
                        DropdownMenuItem(value: 1, child: Text('Média')),
                        DropdownMenuItem(value: 2, child: Text('Alta')),
                      ],
                      onChanged: (v) => setLocal(() => prioridade = v ?? 0),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observação',
                        prefixIcon: Icon(LucideIcons.notebook),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    if (nomeCtrl.text.trim().length < 2 || categoria == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome e categoria são obrigatórios')),
      );
      return;
    }

    try {
      await ref.read(wishlistProvider.notifier).create({
        'nome': nomeCtrl.text.trim(),
        'categoria': categoria,
        if (precoCtrl.text.trim().isNotEmpty)
          'precoAlvo': double.tryParse(
            precoCtrl.text.trim().replaceAll(',', '.'),
          ),
        if (linkCtrl.text.trim().isNotEmpty) 'linkRef': linkCtrl.text.trim(),
        'prioridade': prioridade,
        if (obsCtrl.text.trim().isNotEmpty) 'observacao': obsCtrl.text.trim(),
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
        SnackBar(
          content: Text('${item.nome} entrou no closet'),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => context.go('/roupas'),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (e.code == 'DESEJO_SEM_CATEGORIA') {
        final categoria = await _askCategoria();
        if (categoria == null) return;
        try {
          await ref.read(wishlistProvider.notifier).moverParaCloset(
                item.id,
                categoria: categoria,
              );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.nome} entrou no closet')),
          );
        } catch (err) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                err is ApiException ? err.message : 'Erro ao mover',
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao mover desejo')),
      );
    }
  }

  Future<String?> _askCategoria() async {
    String? selected = clothingCategories.first;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Categoria necessária'),
              content: DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(LucideIcons.tags),
                ),
                items: clothingCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setLocal(() => selected = v),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _delete(WishlistItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir desejo'),
        content: Text('Excluir "${item.nome}"?'),
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
    await ref.read(wishlistProvider.notifier).delete(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(wishlistProvider);

    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                child: Row(
                  children: [
                    SoftIconButton(
                      icon: LucideIcons.arrowLeft,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wishlist',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'peças que a Elisa sonha',
                            style: GoogleFonts.nunito(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: asyncList.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => SoftErrorView(
                    message:
                        err is ApiException ? err.message : 'Erro ao carregar',
                    onRetry: () =>
                        ref.read(wishlistProvider.notifier).refresh(),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return RefreshIndicator(
                        color: AppColors.roseDeep,
                        onRefresh: () =>
                            ref.read(wishlistProvider.notifier).refresh(),
                        child: ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyStateView(
                              icon: LucideIcons.heart,
                              title: 'Nenhum desejo ainda',
                              subtitle:
                                  'Guarde aqui as peças que você quer conquistar',
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.roseDeep,
                      onRefresh: () =>
                          ref.read(wishlistProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.apricot.withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                8,
                                10,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.chip,
                                child: Icon(
                                  LucideIcons.heart,
                                  color: item.prioridade >= 2
                                      ? AppColors.roseDeep
                                      : AppColors.lilacDeep,
                                ),
                              ),
                              title: Text(
                                item.nome,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  item.categoria ?? 'Sem categoria',
                                  if (item.precoAlvo != null)
                                    'R\$ ${item.precoAlvo!.toStringAsFixed(2)}',
                                ].join(' · '),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SoftIconButton(
                                    tooltip: 'Mover para closet',
                                    icon: LucideIcons.shirt,
                                    filled: true,
                                    onPressed: () => _mover(item),
                                  ),
                                  const SizedBox(width: 6),
                                  SoftIconButton(
                                    tooltip: 'Excluir',
                                    icon: LucideIcons.trash2,
                                    onPressed: () => _delete(item),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate(delay: (40 * index).ms)
                              .fadeIn(duration: 350.ms)
                              .slideX(begin: 0.05, end: 0);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Novo desejo'),
      ),
    );
  }
}
