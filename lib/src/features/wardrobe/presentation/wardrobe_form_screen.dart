import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
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
      backgroundColor: Colors.white,
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
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.chip,
                  child: Icon(Icons.photo_library_outlined, color: AppColors.roseDeep),
                ),
                title: Text(
                  'Galeria',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.chip,
                  child: Icon(Icons.photo_camera_outlined, color: AppColors.roseDeep),
                ),
                title: Text(
                  'Câmera',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
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
    AppLoading.show(
      context,
      message: widget.isEditing ? 'Salvando peça...' : 'Adicionando peça...',
    );

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
      if (mounted) {
        AppToast.show(
          context,
          message: widget.isEditing ? 'Peça atualizada' : 'Peça adicionada',
          icon: Icons.check_circle_outline,
        );
        context.go('/roupas');
      }
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Erro ao salvar peça';
      });
    } finally {
      AppLoading.hide();
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.inkSoft),
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.nunito(
        color: AppColors.inkSoft,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: GoogleFonts.nunito(color: AppColors.inkSoft),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.chip),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.chip),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.pinkChip, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final asyncItem = ref.watch(clothingDetailProvider(widget.itemId!));
      return asyncItem.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.blush,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: AppColors.blush,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    err is ApiException ? err.message : 'Erro ao carregar',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(clothingDetailProvider(widget.itemId!)),
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
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
      backgroundColor: AppColors.blush,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEditing ? 'Editar peça' : 'Nova peça',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    GestureDetector(
                      onTap: _showPickerSheet,
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_foto != null)
                                  Image.file(_foto!, fit: BoxFit.cover)
                                else if (_existingFotoUrl != null &&
                                    _existingFotoUrl!.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: _existingFotoUrl!,
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Container(
                                    color: AppColors.chip,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 42,
                                          color: AppColors.roseDeep,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Adicionar foto',
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                        Text(
                                          'Galeria ou câmera',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 16,
                                          color: AppColors.roseDeep,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _foto != null ||
                                                  (_existingFotoUrl?.isNotEmpty ??
                                                      false)
                                              ? 'Trocar'
                                              : 'Foto',
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'NOME',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: _fieldDecoration(
                        label: 'Nome da peça *',
                        hint: 'Ex: Jaqueta Jeans Oversized',
                        icon: Icons.checkroom_outlined,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'Nome com no mínimo 2 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CATEGORIA',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: clothingCategories.map((c) {
                        final selected = _categoria == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: selected,
                          onSelected: (_) => setState(() => _categoria = c),
                          selectedColor: AppColors.pinkChip,
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.nunito(
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          side: BorderSide(
                            color: selected ? AppColors.pinkChip : AppColors.chip,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COR',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _corCtrl,
                                decoration: _fieldDecoration(
                                  label: 'Cor',
                                  icon: Icons.palette_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TAMANHO',
                                style: GoogleFonts.nunito(
                                  fontSize: 11,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _tamanhoCtrl,
                                decoration: _fieldDecoration(
                                  label: 'Tam.',
                                  icon: Icons.straighten,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MARCA',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _marcaCtrl,
                      decoration: _fieldDecoration(
                        label: 'Marca',
                        hint: 'Ex: Levi\'s',
                        icon: Icons.storefront_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'OBSERVAÇÃO',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _obsCtrl,
                      maxLines: 4,
                      decoration: _fieldDecoration(
                        label: 'Observação',
                        hint: 'Combina com… onde comprou…',
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.nunito(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pinkChip,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Salvar alterações'
                                  : 'Adicionar ao closet',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading ? null : () => context.pop(),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
