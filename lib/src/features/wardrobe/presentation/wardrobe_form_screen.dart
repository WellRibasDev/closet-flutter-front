import 'dart:io';

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
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui_kit.dart';
import '../data/models/clothing_item.dart';
import 'wardrobe_provider.dart';

class WardrobeFormScreen extends ConsumerStatefulWidget {
  const WardrobeFormScreen({super.key, this.itemId});

  final String? itemId;

  bool get isEditing => itemId != null;

  @override
  ConsumerState<WardrobeFormScreen> createState() => _WardrobeFormScreenState();
}

class _WardrobeFormScreenState extends ConsumerState<WardrobeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _tamanhoCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String? _categoria;
  String? _existingFotoUrl;
  File? _foto;
  var _loading = false;
  var _hydrated = false;
  String? _error;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _corCtrl.dispose();
    _tamanhoCtrl.dispose();
    _marcaCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  void _hydrate(ClothingItem item) {
    if (_hydrated) return;
    _hydrated = true;
    _nomeCtrl.text = item.nome;
    _categoria = item.categoria;
    _corCtrl.text = item.cor ?? '';
    _tamanhoCtrl.text = item.tamanho ?? '';
    _marcaCtrl.text = item.marca ?? '';
    _obsCtrl.text = item.observacao ?? '';
    _existingFotoUrl = item.fotoUrl;
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _foto = File(file.path));
  }

  Future<void> _showPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.apricotDeep,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.chip,
                  child: Icon(LucideIcons.image, color: AppColors.roseDeep),
                ),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.chip,
                  child: Icon(LucideIcons.camera, color: AppColors.roseDeep),
                ),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoria == null || _categoria!.isEmpty) {
      setState(() => _error = 'Selecione uma categoria');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'categoria': _categoria,
      'cor': _corCtrl.text.trim().isEmpty ? null : _corCtrl.text.trim(),
      'tamanho':
          _tamanhoCtrl.text.trim().isEmpty ? null : _tamanhoCtrl.text.trim(),
      'marca': _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
      'observacao':
          _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    };

    try {
      final notifier = ref.read(wardrobeProvider.notifier);
      if (widget.isEditing) {
        await notifier.updateItem(
          id: widget.itemId!,
          body: body,
          foto: _foto,
        );
        ref.invalidate(clothingDetailProvider(widget.itemId!));
      } else {
        await notifier.create(body: body, foto: _foto);
      }
      if (mounted) context.go('/roupas');
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Erro ao salvar peça';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final asyncItem = ref.watch(clothingDetailProvider(widget.itemId!));
      return asyncItem.when(
        loading: () => const Scaffold(
          body: PastelBackground(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (err, _) => Scaffold(
          body: PastelBackground(
            child: SoftErrorView(
              message: err is ApiException ? err.message : 'Erro ao carregar',
              onRetry: () =>
                  ref.invalidate(clothingDetailProvider(widget.itemId!)),
            ),
          ),
        ),
        data: (item) {
          _hydrate(item);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      body: PastelBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                child: Row(
                  children: [
                    SoftIconButton(
                      icon: LucideIcons.arrowLeft,
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isEditing ? 'Editar peça' : 'Nova peça',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      GestureDetector(
                        onTap: _showPickerSheet,
                        child: AspectRatio(
                          aspectRatio: 1.15,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.card.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.apricot.withValues(alpha: 0.7),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: _foto != null
                                  ? Image.file(_foto!, fit: BoxFit.cover)
                                  : _existingFotoUrl != null &&
                                          _existingFotoUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: _existingFotoUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.imagePlus,
                                              size: 40,
                                              color: AppColors.roseDeep,
                                            ),
                                            SizedBox(height: 10),
                                            Text('Adicionar foto fofa'),
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms)
                          .scale(
                            begin: const Offset(0.97, 0.97),
                            end: const Offset(1, 1),
                          ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome *',
                          prefixIcon: Icon(LucideIcons.tag),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'Nome com no mínimo 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _categoria,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          prefixIcon: Icon(LucideIcons.tags),
                        ),
                        items: clothingCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _categoria = v),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Selecione uma categoria'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _corCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cor',
                          prefixIcon: Icon(LucideIcons.palette),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tamanhoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tamanho',
                          prefixIcon: Icon(LucideIcons.ruler),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _marcaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          prefixIcon: Icon(LucideIcons.store),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _obsCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Observação',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(LucideIcons.notebook),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SoftPrimaryButton(
                        label: widget.isEditing ? 'Salvar' : 'Adicionar ao closet',
                        icon: LucideIcons.heart,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
