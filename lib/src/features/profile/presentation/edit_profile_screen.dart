import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../auth/presentation/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();

  String? _existingFotoUrl;
  File? _foto;
  var _loading = false;
  var _loadingUser = true;
  String? _error;
  var _changePassword = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);
    try {
      await ref.read(authProvider.notifier).refreshMe();
    } catch (_) {
      // usa o que já estiver em memória
    }
    if (!mounted) return;
    final user = ref.read(authProvider).value?.user;
    if (user != null) {
      _nomeCtrl.text = user.nome ?? '';
      _emailCtrl.text = user.email;
      _existingFotoUrl = user.fotoUrl;
    }
    setState(() => _loadingUser = false);
  }

  Future<void> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;
    setState(() => _foto = File(file.path));
  }

  Future<void> _showPickerSheet() async {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    String? senhaAtual;
    String? novaSenha;

    if (_changePassword) {
      senhaAtual = _senhaAtualCtrl.text;
      novaSenha = _novaSenhaCtrl.text;
      if (novaSenha != _confirmaSenhaCtrl.text) {
        setState(() => _error = 'A confirmação da senha não confere');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    AppLoading.show(context, message: 'Salvando perfil...');

    try {
      await ref.read(authProvider.notifier).updateProfile(
            nome: nome,
            email: email,
            senhaAtual: senhaAtual,
            novaSenha: novaSenha,
            foto: _foto,
          );
      if (mounted) {
        AppToast.show(
          context,
          message: 'Perfil atualizado',
          icon: Icons.check_circle_outline,
        );
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Erro ao salvar perfil');
    } finally {
      AppLoading.hide();
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _input(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.roseDeep),
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.nunito(color: AppColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.petal),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.petal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.pinkChip, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFoto =
        _foto != null || (_existingFotoUrl != null && _existingFotoUrl!.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.blush,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editar perfil',
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
            if (_loadingUser)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.pinkChip),
                ),
              )
            else
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _showPickerSheet,
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.pinkChip,
                                    width: 2.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: AppColors.blush,
                                  backgroundImage: _foto != null
                                      ? FileImage(_foto!)
                                      : (_existingFotoUrl != null &&
                                              _existingFotoUrl!.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              _existingFotoUrl!,
                                            )
                                          : null),
                                  child: hasFoto
                                      ? null
                                      : const Icon(
                                          Icons.person,
                                          size: 52,
                                          color: AppColors.roseDeep,
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 4,
                                bottom: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.pinkChip,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.roseDeep
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Toque para tirar ou escolher foto',
                          style: GoogleFonts.nunito(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: _input('Nome', icon: Icons.badge_outlined),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe seu nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _input(
                          'E-mail',
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty || !value.contains('@')) {
                            return 'Informe um e-mail válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blush.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Alterar senha',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          value: _changePassword,
                          activeThumbColor: AppColors.pinkChip,
                          onChanged: (v) =>
                              setState(() => _changePassword = v),
                        ),
                      ),
                      if (_changePassword) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _senhaAtualCtrl,
                          obscureText: true,
                          decoration: _input(
                            'Senha atual',
                            icon: Icons.lock_outline,
                          ),
                          validator: (v) {
                            if (!_changePassword) return null;
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha atual';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _novaSenhaCtrl,
                          obscureText: true,
                          decoration: _input(
                            'Nova senha',
                            icon: Icons.lock_reset,
                          ),
                          validator: (v) {
                            if (!_changePassword) return null;
                            if (v == null || v.length < 6) {
                              return 'Mínimo de 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmaSenhaCtrl,
                          obscureText: true,
                          decoration: _input(
                            'Confirmar nova senha',
                            icon: Icons.lock_outline,
                          ),
                          validator: (v) {
                            if (!_changePassword) return null;
                            if (v != _novaSenhaCtrl.text) {
                              return 'As senhas não conferem';
                            }
                            return null;
                          },
                        ),
                      ],
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
                      const SizedBox(height: 24),
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
                                'Salvar perfil',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
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
