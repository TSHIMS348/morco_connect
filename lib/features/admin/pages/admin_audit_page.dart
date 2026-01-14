import 'package:flutter/material.dart';
import 'package:morco_connect/features/audit/services/audit_service.dart';
import 'package:morco_connect/features/audit/models/audit_event.dart';
import 'package:morco_connect/features/audit/models/audit_action.dart';
import 'package:morco_connect/features/auth/services/permission_service.dart';

class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  AuditAction? _selectedAction;
  final TextEditingController _userController = TextEditingController();
  DateTime? _fromDate;

  List<AuditEvent> get _filteredEvents {
    return AuditService.filter(
      action: _selectedAction,
      userMatricule: _userController.text.trim(),
      from: _fromDate,
    ).reversed.toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDate: _fromDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔐 Sécurité : admin only
    if (!PermissionService.canViewAdminPanel()) {
      return const Scaffold(
        body: Center(child: Text('Accès refusé')),
      );
    }

    final events = _filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal de sécurité'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔍 FILTRES
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    DropdownButtonFormField<AuditAction>(
                      value: _selectedAction,
                      hint: const Text('Filtrer par action'),
                      items: AuditAction.values.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(a.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedAction = v),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: 'Matricule utilisateur',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fromDate == null
                                ? 'Aucune date sélectionnée'
                                : 'Depuis : ${_fromDate!.toLocal().toString().split(' ')[0]}',
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text('Choisir date'),
                        ),
                        if (_fromDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _fromDate = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 📋 LISTE AUDIT
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text('Aucun événement'))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.security),
                            title: Text(
                              e.action.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(e.description),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  e.timestamp.toLocal().toString(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                if (e.userMatricule != null)
                                  Text(
                                    e.userMatricule!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
