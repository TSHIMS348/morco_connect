import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../auth/services/auth_session.dart';
import '../../users/services/user_directory_service.dart';

import '../models/announcement_status.dart';
import '../services/announcement_service.dart';

class AdminAnnouncementChartsPage extends StatefulWidget {
  const AdminAnnouncementChartsPage({super.key});

  @override
  State<AdminAnnouncementChartsPage> createState() =>
      _AdminAnnouncementChartsPageState();
}

class _AdminAnnouncementChartsPageState
    extends State<AdminAnnouncementChartsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Accès réservé administrateur')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphiques — Lecture annonces'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Sites'),
            Tab(text: 'Villes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GlobalDonut(),
          _BarChartByTarget(type: _Target.site),
          _BarChartByTarget(type: _Target.city),
        ],
      ),
    );
  }
}

enum _Target { site, city }

/// ======================================================
/// 🍩 DONUT — Lecture globale
/// ======================================================
class _GlobalDonut extends StatelessWidget {
  const _GlobalDonut();

  @override
  Widget build(BuildContext context) {
    final users = UserDirectoryService.getAll(activeOnly: true);

    final published = AnnouncementService.getAllCached()
        .where((a) => a.status == AnnouncementStatus.published)
        .toList();

    int total = 0;
    int read = 0;

    for (final a in published) {
      final targets =
          AnnouncementService.getTargetMatricules(a).toSet();
      final readers = a.readBy.toSet();

      for (final u in users) {
        if (!targets.contains(u.matricule)) continue;
        total++;
        if (readers.contains(u.matricule)) {
          read++;
        }
      }
    }

    final int unread = total - read;
    final bool hasData = total > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Taux de lecture global',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 260,
              child: hasData
                  ? PieChart(
                      PieChartData(
                        centerSpaceRadius: 70,
                        sectionsSpace: 4,
                        sections: [
                          PieChartSectionData(
                            value: read.toDouble(),
                            title: 'Lus\n$read',
                            color: Colors.green,
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: unread.toDouble(),
                            title: 'Non lus\n$unread',
                            color: Colors.red,
                            radius: 60,
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('Aucune donnée')),
            ),
            const SizedBox(height: 20),
            Text(
              hasData
                  ? '${((read / total) * 100).round()} % lus'
                  : 'Audience = 0',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================================================
/// 📊 BAR CHART — Site / Ville
/// ======================================================
class _BarChartByTarget extends StatelessWidget {
  final _Target type;
  const _BarChartByTarget({required this.type});

  @override
  Widget build(BuildContext context) {
    final users = UserDirectoryService.getAll(activeOnly: true);

    final published = AnnouncementService.getAllCached()
        .where((a) => a.status == AnnouncementStatus.published)
        .toList();

    final Map<String, _Stats> map = {};

    for (final a in published) {
      final readers = a.readBy.toSet();
      final targets =
          AnnouncementService.getTargetMatricules(a).toSet();

      for (final u in users) {
        final String key =
            type == _Target.site ? u.site : u.city;
        if (!targets.contains(u.matricule)) continue;

        map.putIfAbsent(key, () => _Stats());
        map[key]!.total++;

        if (readers.contains(u.matricule)) {
          map[key]!.read++;
        }
      }
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: List.generate(entries.length, (i) {
            final e = entries[i];
            final double rate = e.value.total == 0
                ? 0
                : (e.value.read / e.value.total) * 100;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: rate,
                  width: 18,
                  color: _colorForRate(rate),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final int i = value.toInt();
                  if (i < 0 || i >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[i].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Color _colorForRate(double rate) {
    if (rate < 30) return Colors.red;
    if (rate < 50) return Colors.orange;
    return Colors.green;
  }
}

class _Stats {
  int total = 0;
  int read = 0;
}
