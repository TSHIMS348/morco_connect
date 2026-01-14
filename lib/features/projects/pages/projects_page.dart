import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';
import '../models/project.dart';
import '../services/project_service.dart';
import 'project_create_page.dart';
import 'project_detail_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Project> _projects = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _projects = ProjectService.getForCurrentUser();
    });
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProjectCreatePage()),
    );
    if (created == true) _reload();
  }

  Future<void> _openDetail(String projectId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailPage(projectId: projectId),
      ),
    );
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
        actions: [
          if (AuthSession.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Créer un projet',
              onPressed: _openCreate,
            ),
        ],
      ),
      body: _projects.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              itemCount: _projects.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(project.name),
                  subtitle: Text(project.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openDetail(project.id),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucun projet disponible', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
