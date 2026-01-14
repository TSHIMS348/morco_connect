import 'package:flutter/material.dart';
import 'package:morco_connect/features/admin/services/admin_user_service.dart';
import 'package:morco_connect/features/auth/models/user_profile.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late List<UserProfile> _users;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _users = AdminUserService.getPendingUsers();
  }

  Future<void> _validate(UserProfile user) async {
    setState(() => _loading = true);

    try {
      await AdminUserService.validateUser(user);
      setState(() {
        _users = AdminUserService.getPendingUsers();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte validé')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utilisateurs en attente')),
      body: _users.isEmpty
          ? const Center(child: Text('Aucun utilisateur en attente'))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final user = _users[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(user.fullName),
                    subtitle: Text('${user.matricule} • ${user.phone}'),
                    trailing: ElevatedButton(
                      onPressed: _loading ? null : () => _validate(user),
                      child: const Text('Valider'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
