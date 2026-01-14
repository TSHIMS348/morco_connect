import 'package:flutter/material.dart';
import 'package:morco_connect/features/auth/services/auth_session.dart';
import 'package:morco_connect/features/auth/models/user_profile.dart';
import 'package:morco_connect/features/auth/services/permission_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _matriculeController;

  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    final user = AuthSession.currentUser;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _matriculeController = TextEditingController(text: user?.matricule ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!PermissionService.canEditProfile()) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isSaving = false);

    final current = AuthSession.currentUser!;
    final updated = UserProfile(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      matricule: _matriculeController.text.trim(),
      role: current.role,
    );

    await AuthSession.updateProfile(updated);

    if (!mounted) return;

    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isLoggedIn || AuthSession.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final canEdit = PermissionService.canEditProfile();
    final readOnly = !(_isEditing && canEdit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          if (canEdit)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              tooltip: _isEditing ? 'Annuler' : 'Modifier',
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthSession.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (_) => false);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Informations utilisateur',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rôle : ${AuthSession.role.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _fullNameController,
                          readOnly: readOnly,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Champ requis'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          readOnly: readOnly,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 6)
                                  ? 'Numéro invalide'
                                  : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          readOnly: readOnly,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Champ requis';
                            }
                            if (!v.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _matriculeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Matricule',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (canEdit)
                          ElevatedButton(
                            onPressed:
                                (_isSaving || !_isEditing) ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Enregistrer'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
