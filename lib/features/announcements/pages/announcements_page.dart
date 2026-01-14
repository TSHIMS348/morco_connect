import 'package:flutter/material.dart';

import '../../auth/services/auth_session.dart';

import '../models/announcement.dart';
import '../models/announcement_target_type.dart';
import '../models/announcement_priority.dart';
import '../services/announcement_service.dart';

import '../widgets/announcement_card.dart';
import 'announcement_detail_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  // =============================
  // 🔎 Recherche + filtres
  // =============================
  final _searchCtrl = TextEditingController();
  String _query = '';

  AnnouncementTargetType? _targetFilter; // null = tous
  int _tagFilterIndex = 0; // 0 Tous / 1 HSE / 2 Direction

  // =============================
  // 📜 Pagination locale
  // =============================
  static const int _pageSize = 10;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  final ScrollController _scrollCtrl = ScrollController();

  // =============================
  // 🧠 Data
  // =============================
  List<Announcement> _all = [];
  List<Announcement> _visible = [];

  @override
  void initState() {
    super.initState();
    _loadFirstPage();

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >
              _scrollCtrl.position.maxScrollExtent - 200 &&
          !_loadingMore &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // =============================
  // 🔄 LOAD
  // =============================
  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _page = 1;
      _hasMore = true;
    });

    final list = AnnouncementService.getCachedVisibleForCurrentUser();
    final sorted = _sortByPriorityAndDate(list);

    setState(() {
      _all = sorted;
      _visible = _paginate(sorted, page: 1, size: _pageSize);
      _hasMore = _visible.length < _all.length;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;

    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 200));

    final nextPage = _page + 1;
    final next = _paginate(_all, page: nextPage, size: _pageSize);

    setState(() {
      _page = nextPage;
      _visible = next;
      _hasMore = _visible.length < _all.length;
      _loadingMore = false;
    });
  }

  // =============================
  // 🧠 FILTRAGE FINAL
  // =============================
  List<Announcement> get _finalVisible {
    var list = _applyTargetFilter(_visible);
    list = _applyTagFilter(list);
    list = _applyQuery(list);
    return list;
  }

  // =============================
  // 🔔 BADGES NON LUS
  // =============================
  int _unreadCountForTag(int tagIndex) {
    final me = AuthSession.currentUser?.matricule;
    if (me == null) return 0;

    final list = _applyTagFilter(_all, tagIndex: tagIndex);
    return list.where((a) => !a.readBy.contains(me)).length;
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    final list = _finalVisible;
    final me = AuthSession.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFirstPage,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 🎛️ Tabs
          _TagTabs(
            currentIndex: _tagFilterIndex,
            onChanged: (i) => setState(() => _tagFilterIndex = i),
            unreadAll: _unreadCountForTag(0),
            unreadHse: _unreadCountForTag(1),
            unreadDirection: _unreadCountForTag(2),
          ),

          // 🧷 Ciblage
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('TOUS'),
                  selected: _targetFilter == null,
                  onSelected: (_) {
                    setState(() => _targetFilter = null);
                    _loadFirstPage();
                  },
                ),
                const SizedBox(width: 8),
                ...AnnouncementTargetType.values.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.name.toUpperCase()),
                      selected: _targetFilter == t,
                      onSelected: (_) {
                        setState(() => _targetFilter = t);
                        _loadFirstPage();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(),

          // 📢 LISTE
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadFirstPage,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_loadingMore && i == list.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final a = list[i];

                        return AnnouncementCard(
                          announcement: a,
                          onOpen: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnnouncementDetailPage(
                                  announcementId: a.id,
                                ),
                              ),
                            );
                            await _loadFirstPage();
                          },
                          onMarkRead: () async {
                            if (me == null) return;
                            await AnnouncementService.markAsRead(
                              announcementId: a.id,
                              readerMatricule: me.matricule,
                            );
                            await _loadFirstPage();
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // =============================
  // HELPERS
  // =============================
  List<Announcement> _applyQuery(List<Announcement> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((a) =>
        a.title.toLowerCase().contains(q) ||
        (a.body ?? '').toLowerCase().contains(q)).toList();
  }

  List<Announcement> _applyTagFilter(
    List<Announcement> list, {
    int? tagIndex,
  }) {
    final idx = tagIndex ?? _tagFilterIndex;
    if (idx == 0) return list;

    bool isHse(Announcement a) =>
        a.title.toLowerCase().contains('hse') ||
        (a.body ?? '').toLowerCase().contains('sécurité');

    bool isDirection(Announcement a) =>
        a.title.toLowerCase().contains('direction') ||
        a.title.toLowerCase().contains('dg');

    if (idx == 1) return list.where(isHse).toList();
    return list.where(isDirection).toList();
  }

  List<Announcement> _applyTargetFilter(List<Announcement> list) {
    if (_targetFilter == null) return list;

    return list.where((a) {
      return a.targets.any((t) => t.type == _targetFilter);
    }).toList();
  }

  List<Announcement> _sortByPriorityAndDate(List<Announcement> list) {
    final copy = [...list];
    copy.sort((a, b) {
      final pa = a.priority.index;
      final pb = b.priority.index;
      if (pa != pb) return pb - pa;
      return b.createdAt.compareTo(a.createdAt);
    });
    return copy;
  }

  List<Announcement> _paginate(
    List<Announcement> list, {
    required int page,
    required int size,
  }) {
    final end = page * size;
    return end >= list.length ? list : list.sublist(0, end);
  }
}

// ======================================================
// 🧩 TAG TABS (AJOUTÉ)
// ======================================================
class _TagTabs extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final int unreadAll;
  final int unreadHse;
  final int unreadDirection;

  const _TagTabs({
    required this.currentIndex,
    required this.onChanged,
    required this.unreadAll,
    required this.unreadHse,
    required this.unreadDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _tab('Tous', unreadAll, 0),
        _tab('HSE', unreadHse, 1),
        _tab('Direction', unreadDirection, 2),
      ],
    );
  }

  Widget _tab(String label, int unread, int index) {
    final selected = index == currentIndex;

    return TextButton(
      onPressed: () => onChanged(index),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 9,
              backgroundColor: Colors.red,
              child: Text(
                unread.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
