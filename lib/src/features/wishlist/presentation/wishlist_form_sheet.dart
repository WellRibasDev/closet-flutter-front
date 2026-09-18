import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/categories.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
import '../data/models/wishlist_item.dart';
import 'wishlist_provider.dart';

/// Modal branco (bottom sheet) para criar/editar desejo — layout simples + foto.
Future<void> showWishlistFormSheet(
  BuildContext context,
  WidgetRef ref, {
  WishlistItem? item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => _WishlistFormSheet(item: item),
  );
}

class _WishlistFormSheet extends ConsumerStatefulWidget {
  const _WishlistFormSheet({this.item});

  final WishlistItem? item;

  @override
  ConsumerState<_WishlistFormSheet> createState() => _WishlistFormSheetState();
}

class _WishlistFormSheetState extends ConsumerState<_WishlistFormSheet> {
  final _nomeCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  late String _categoria;
  int _prioridade = 1;
  String? _existingFotoUrl;
  File? _foto;
  var _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _categoria = item?.categoria ?? clothingCategories.first;
    if (item != null) {
      _nomeCtrl.text = item.nome;
      _marcaCtrl.text = item.marca ?? '';
      _precoCtrl.text = item.precoAlvo?.toStringAsFixed(2) ?? '';
      _linkCtrl.text = item.linkRef ?? '';
      _prioridade = item.prioridade;
      _existingFotoUrl = item.fotoUrl;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _marcaCtrl.dispose();
    _precoCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  InputDecoration _input(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.inkSoft),
      filled: true,
      fillColor: AppColors.blush.withValues(alpha: 0.35),
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

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _foto = File(file.path));
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                  color: AppColors.petal,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.roseDeep,
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
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.roseDeep,
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

  Future<void> _save() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.length < 2) {
      AppToast.show(
        context,
        message: 'Informe um nome válido',
        icon: Icons.error_outline,
      );
      return;
    }

    final link = _linkCtrl.text.trim();
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

    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));
    final body = <String, dynamic>{
      'nome': nome,
      'categoria': _categoria,
      'prioridade': _prioridade,
      if (_marcaCtrl.text.trim().isNotEmpty) 'marca': _marcaCtrl.text.trim(),
      if (preco != null) 'precoAlvo': preco,
      if (link.isNotEmpty) 'linkRef': link,
    };

    setState(() => _saving = true);
    AppLoading.show(
      context,
      message: _isEditing ? 'Salvando desejo...' : 'Salvando desejo...',
    );

    try {
      final notifier = ref.read(wishlistProvider.notifier);
      if (_isEditing) {
        await notifier.updateItem(
          id: widget.item!.id,
          body: body,
          foto: _foto,
        );
      } else {
        await notifier.create(body: body, foto: _foto);
      }
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show(
        context,
        message: _isEditing ? 'Desejo atualizado' : 'Desejo adicionado ✨',
        icon: Icons.favorite,
      );
    } on ApiException catch (e) {
      if (e.code == 'FOTO_UNAVAILABLE' && mounted) {
        Navigator.pop(context);
        AppToast.show(
          context,
          message: e.message,
          icon: Icons.warning_amber_rounded,
        );
        return;
      }
      if (mounted) {
        AppToast.show(
          context,
          message: e.message,
          icon: Icons.error_outline,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Erro ao salvar desejo',
          icon: Icons.error_outline,
        );
      }
    } finally {
      AppLoading.hide();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFoto =
        _foto != null || (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
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
              _isEditing ? 'Editar desejo' : 'Novo desejo',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nomeCtrl,
              decoration: _input('Nome *', icon: Icons.favorite_border),
            ),
            const SizedBox(height: 12),
            SoftSelectField<String>(
              label: 'Categoria',
              value: _categoria,
              items: clothingCategories,
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _categoria = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _marcaCtrl,
              decoration: _input(
                'Marca',
                hint: "Ex: Levi's",
                icon: Icons.storefront_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _input(
                'Preço alvo',
                hint: 'Ex: 199.90',
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCtrl,
              keyboardType: TextInputType.url,
              decoration: _input(
                'Link da loja (opcional)',
                hint: 'https://...',
                icon: Icons.link,
              ),
            ),
            const SizedBox(height: 12),
            SoftSelectField<int>(
              label: 'Prioridade',
              value: _prioridade,
              items: const [0, 1, 2],
              labelBuilder: (v) => switch (v) {
                    2 => 'Alta',
                    1 => 'Média',
                    _ => 'Baixa',
                  },
              onChanged: (v) => setState(() => _prioridade = v),
            ),
            const SizedBox(height: 14),
            Text(
              'Foto (opcional)',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showPhotoOptions,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.blush.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.petal),
                ),
                child: hasFoto
                    ? Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(15),
                            ),
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: _foto != null
                                  ? Image.file(_foto!, fit: BoxFit.cover)
                                  : CachedNetworkImage(
                                      imageUrl: _existingFotoUrl!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Toque para trocar a foto',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.roseDeep,
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.roseDeep,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Tirar ou adicionar foto',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.pinkChip,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditing ? 'Salvar alterações' : 'Salvar desejo',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
