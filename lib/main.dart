import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

const String appName = 'CLUB TENNIS DE VILLEJUST';
const String developerName = 'CLUB TENNIS DE VILLEJUST';
const String supportEmail = 'support@clubtennisdevillejust.fr';
const String _storageFileName = 'club_tennis_villejust_records_v1.json';
const bool _buildScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

const Color _midnight = Color(0xFF161E29);
const Color _courtGreen = Color(0xFF234947);
const Color _slateGreen = Color(0xFF414946);
const Color _courtGold = Color(0xFFAB8C26);
const Color _linen = Color(0xFFF8F5EA);
const Color _paper = Color(0xFFFFFCF2);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClubTennisOpsApp());
}

class ClubTennisOpsApp extends StatefulWidget {
  const ClubTennisOpsApp({
    super.key,
    this.screenshotModeOverride,
    this.storageFileOverride,
  });

  final bool? screenshotModeOverride;
  final File? storageFileOverride;

  @override
  State<ClubTennisOpsApp> createState() => _ClubTennisOpsAppState();
}

class _ClubTennisOpsAppState extends State<ClubTennisOpsApp> {
  List<OpsRecord> _records = const [];
  bool _loaded = false;

  bool get _screenshotMode =>
      widget.screenshotModeOverride ?? _buildScreenshotMode;

  File get _storageFile =>
      widget.storageFileOverride ??
      File('${Directory.systemTemp.path}/$_storageFileName');

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (_screenshotMode) {
      setState(() {
        _records = sampleRecords();
        _loaded = true;
      });
      return;
    }

    final records = <OpsRecord>[];
    final file = _storageFile;
    if (file.existsSync()) {
      final raw = file.readAsStringSync();
      final decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        for (final entry in decoded) {
          if (entry is Map<String, dynamic>) {
            records.add(OpsRecord.fromJson(entry));
          }
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _loaded = true;
    });
  }

  void _upsertRecord(OpsRecord record) {
    setState(() {
      final index = _records.indexWhere((item) => item.id == record.id);
      if (index == -1) {
        _records = [record, ..._records];
      } else {
        final nextRecords = [..._records];
        nextRecords[index] = record;
        _records = nextRecords;
      }
    });
    _persistRecords();
  }

  void _deleteRecord(String id) {
    setState(() {
      _records = _records.where((record) => record.id != id).toList();
    });
    _persistRecords();
  }

  void _clearRecords() {
    setState(() {
      _records = const [];
    });
    _persistRecords();
  }

  Future<void> _persistRecords() async {
    if (_screenshotMode) {
      return;
    }
    final payload = jsonEncode(
      _records.map((record) => record.toJson()).toList(),
    );
    final file = _storageFile;
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(payload, flush: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _courtGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: _courtGreen,
          onPrimary: Colors.white,
          secondary: _courtGold,
          onSecondary: _midnight,
          tertiary: _slateGreen,
          onTertiary: Colors.white,
          surface: _paper,
          onSurface: _midnight,
          surfaceContainerHighest: const Color(0xFFECE4CE),
          outline: const Color(0xFF7E7A6D),
        );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _linen,
        appBarTheme: const AppBarTheme(
          backgroundColor: _linen,
          foregroundColor: _midnight,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _paper,
          indicatorColor: _courtGold,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? _midnight : _slateGreen,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 11,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _courtGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9D2BD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9D2BD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _courtGreen, width: 1.5),
          ),
        ),
      ),
      home: HomeShell(
        records: _records,
        loaded: _loaded,
        screenshotMode: _screenshotMode,
        onSave: _upsertRecord,
        onDelete: _deleteRecord,
        onClear: _clearRecords,
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.records,
    required this.loaded,
    required this.screenshotMode,
    required this.onSave,
    required this.onDelete,
    required this.onClear,
  });

  final List<OpsRecord> records;
  final bool loaded;
  final bool screenshotMode;
  final ValueChanged<OpsRecord> onSave;
  final ValueChanged<String> onDelete;
  final VoidCallback onClear;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  String get _title {
    switch (_selectedIndex) {
      case 1:
        return 'Lead pipeline';
      case 2:
        return 'Asset board';
      case 3:
        return 'Schedule and visits';
      case 4:
        return 'Settings';
      default:
        return 'Operations today';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(records: widget.records, onOpen: _openDetail),
      CategoryPage(
        category: RecordCategory.lead,
        records: widget.records,
        onOpen: _openDetail,
      ),
      CategoryPage(
        category: RecordCategory.asset,
        records: widget.records,
        onOpen: _openDetail,
      ),
      SchedulePage(records: widget.records, onOpen: _openDetail),
      SettingsPage(
        records: widget.records,
        screenshotMode: widget.screenshotMode,
        onClear: widget.onClear,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Local only'),
              backgroundColor: _paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFD9D2BD)),
              ),
            ),
          ),
        ],
      ),
      body: widget.loaded
          ? IndexedStack(index: _selectedIndex, children: pages)
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _selectedIndex == 4
          ? null
          : FloatingActionButton.extended(
              key: const Key('create-record-button'),
              tooltip: 'Create record',
              onPressed: () => _openEditor(
                initialCategory: _categoryForIndex(_selectedIndex),
              ),
              backgroundColor: _courtGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  RecordCategory _categoryForIndex(int index) {
    switch (index) {
      case 2:
        return RecordCategory.asset;
      case 3:
        return RecordCategory.interview;
      default:
        return RecordCategory.lead;
    }
  }

  void _openDetail(OpsRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RecordDetailPage(
          record: record,
          onSave: widget.onSave,
          onDelete: widget.onDelete,
        ),
      ),
    );
  }

  void _openEditor({required RecordCategory initialCategory}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RecordEditorSheet(
        initialCategory: initialCategory,
        onSave: (record) {
          widget.onSave(record);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.records, required this.onOpen});

  final List<OpsRecord> records;
  final ValueChanged<OpsRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final upcoming =
        records
            .where((record) => record.status != record.category.doneStatus)
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
    final highPriority = upcoming.take(4).toList();
    final totalOpen = upcoming.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        const BrandHeader(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SummaryTile(
                  width: tileWidth,
                  label: 'Open work',
                  value: '$totalOpen',
                  icon: Icons.assignment_outlined,
                ),
                SummaryTile(
                  width: tileWidth,
                  label: 'Leads',
                  value: '${records.ofCategory(RecordCategory.lead).length}',
                  icon: Icons.trending_up,
                ),
                SummaryTile(
                  width: tileWidth,
                  label: 'Assets',
                  value: '${records.ofCategory(RecordCategory.asset).length}',
                  icon: Icons.inventory_2_outlined,
                ),
                SummaryTile(
                  width: tileWidth,
                  label: 'Visits',
                  value: '${records.ofCategory(RecordCategory.visitor).length}',
                  icon: Icons.badge_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Priority queue',
          actionText: '${highPriority.length} active',
        ),
        const SizedBox(height: 8),
        if (highPriority.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No open work',
            body: 'Create a record when the next daily operation arrives.',
          )
        else
          ...highPriority.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordListTile(
                record: record,
                onTap: () => onOpen(record),
              ),
            ),
          ),
        const SizedBox(height: 10),
        const SectionHeader(title: 'Status lanes', actionText: 'Club desk'),
        const SizedBox(height: 8),
        StatusLanePanel(records: records),
      ],
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _midnight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'docs/icon.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Lead, asset, interview, and visitor desk for daily club operations.',
                  style: TextStyle(
                    color: Color(0xFFECE4CE),
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9D2BD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _courtGreen),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: _midnight,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: _slateGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({
    super.key,
    required this.category,
    required this.records,
    required this.onOpen,
  });

  final RecordCategory category;
  final List<OpsRecord> records;
  final ValueChanged<OpsRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final items = records.ofCategory(category);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        WorkstreamHeader(category: category, count: items.length),
        const SizedBox(height: 14),
        if (items.isEmpty)
          EmptyState(
            icon: category.icon,
            title: 'No ${category.plural.toLowerCase()} yet',
            body: 'Tap New to create the first ${category.singular}.',
          )
        else
          ...items.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RecordListTile(
                record: record,
                onTap: () => onOpen(record),
              ),
            ),
          ),
      ],
    );
  }
}

class WorkstreamHeader extends StatelessWidget {
  const WorkstreamHeader({
    super.key,
    required this.category,
    required this.count,
  });

  final RecordCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: category.color,
            child: Icon(category.icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.plural,
                  style: const TextStyle(
                    color: _midnight,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  category.description,
                  style: const TextStyle(
                    color: _slateGreen,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          CountBadge(label: '$count'),
        ],
      ),
    );
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key, required this.records, required this.onOpen});

  final List<OpsRecord> records;
  final ValueChanged<OpsRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final interviews = records.ofCategory(RecordCategory.interview);
    final visitors = records.ofCategory(RecordCategory.visitor);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9D2BD)),
            ),
            child: const TabBar(
              labelColor: _midnight,
              unselectedLabelColor: _slateGreen,
              indicatorColor: _courtGold,
              tabs: [
                Tab(icon: Icon(Icons.groups_2_outlined), text: 'Interviews'),
                Tab(icon: Icon(Icons.badge_outlined), text: 'Visitors'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ScheduleList(
                  emptyTitle: 'No interviews scheduled',
                  emptyBody:
                      'Create interviews and keep follow-up owners clear.',
                  items: interviews,
                  onOpen: onOpen,
                ),
                ScheduleList(
                  emptyTitle: 'No visitors expected',
                  emptyBody: 'Log arrivals, host names, and visit outcomes.',
                  items: visitors,
                  onOpen: onOpen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleList extends StatelessWidget {
  const ScheduleList({
    super.key,
    required this.emptyTitle,
    required this.emptyBody,
    required this.items,
    required this.onOpen,
  });

  final String emptyTitle;
  final String emptyBody;
  final List<OpsRecord> items;
  final ValueChanged<OpsRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyState(
          icon: Icons.event_busy_outlined,
          title: emptyTitle,
          body: emptyBody,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        for (final record in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecordListTile(record: record, onTap: () => onOpen(record)),
          ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.records,
    required this.screenshotMode,
    required this.onClear,
  });

  final List<OpsRecord> records;
  final bool screenshotMode;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD9D2BD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local workspace',
                style: TextStyle(
                  color: _midnight,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${records.length} records are stored on this device only.',
                style: const TextStyle(color: _slateGreen),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.storage_outlined, color: _courtGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      screenshotMode
                          ? 'Sample records are shown for store screenshots.'
                          : 'Records remain available after closing the app.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const PrivacyPanel(),
        const SizedBox(height: 14),
        FilledButton.icon(
          key: const Key('clear-records-button'),
          onPressed: records.isEmpty
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear local records?'),
                      content: const Text(
                        'This removes saved leads, assets, interviews, and visitor records from this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    onClear();
                  }
                },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear local records'),
        ),
      ],
    );
  }
}

class PrivacyPanel extends StatelessWidget {
  const PrivacyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _courtGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Privacy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'No account, cloud sync, analytics, advertising ID, contacts, photos, microphone, payment, health, or location collection is used.',
            style: TextStyle(color: Color(0xFFECE4CE), height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            'Support: $supportEmail',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class RecordDetailPage extends StatefulWidget {
  const RecordDetailPage({
    super.key,
    required this.record,
    required this.onSave,
    required this.onDelete,
  });

  final OpsRecord record;
  final ValueChanged<OpsRecord> onSave;
  final ValueChanged<String> onDelete;

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  late OpsRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_record.category.singular),
        actions: [
          IconButton(
            tooltip: 'Edit record',
            onPressed: _editRecord,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete record',
            onPressed: _deleteRecord,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _paper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9D2BD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _record.category.tint,
                      foregroundColor: _record.category.color,
                      child: Icon(_record.category.icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _record.title,
                        style: const TextStyle(
                          color: _midnight,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(label: _record.status),
                    InfoChip(
                      icon: Icons.flag_outlined,
                      label: _record.priorityLabel,
                    ),
                    InfoChip(
                      icon: Icons.schedule_outlined,
                      label: _record.dueLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DetailRow(
                  icon: Icons.person_outline,
                  label: _record.category.ownerLabel,
                  value: _record.owner,
                ),
                DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: _record.note,
                ),
                DetailRow(
                  icon: Icons.update,
                  label: 'Updated',
                  value: formatDateTime(_record.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('advance-status-button'),
            onPressed: _advanceStatus,
            icon: const Icon(Icons.arrow_forward),
            label: Text('Move to ${_record.nextStatus}'),
          ),
        ],
      ),
    );
  }

  void _advanceStatus() {
    final updated = _record.copyWith(
      status: _record.nextStatus,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _record = updated;
    });
    widget.onSave(updated);
  }

  void _editRecord() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => RecordEditorSheet(
        existing: _record,
        initialCategory: _record.category,
        onSave: (record) {
          setState(() {
            _record = record;
          });
          widget.onSave(record);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _deleteRecord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete record?'),
        content: Text('Remove "${_record.title}" from local storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDelete(_record.id);
      Navigator.of(context).pop();
    }
  }
}

class RecordEditorSheet extends StatefulWidget {
  const RecordEditorSheet({
    super.key,
    required this.initialCategory,
    required this.onSave,
    this.existing,
  });

  final RecordCategory initialCategory;
  final OpsRecord? existing;
  final ValueChanged<OpsRecord> onSave;

  @override
  State<RecordEditorSheet> createState() => _RecordEditorSheetState();
}

class _RecordEditorSheetState extends State<RecordEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late RecordCategory _category;
  late String _status;
  late int _priority;
  late final TextEditingController _titleController;
  late final TextEditingController _ownerController;
  late final TextEditingController _dueController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _category = existing?.category ?? widget.initialCategory;
    _status = existing?.status ?? _category.statuses.first;
    _priority = existing?.priority ?? 2;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _ownerController = TextEditingController(text: existing?.owner ?? '');
    _dueController = TextEditingController(text: existing?.dueLabel ?? 'Today');
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ownerController.dispose();
    _dueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'New record' : 'Edit record',
                      style: const TextStyle(
                        color: _midnight,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecordCategory>(
                key: const Key('record-category-field'),
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Workstream'),
                items: RecordCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.singular),
                      ),
                    )
                    .toList(),
                onChanged: (category) {
                  if (category == null) {
                    return;
                  }
                  setState(() {
                    _category = category;
                    _status = category.statuses.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-title-field'),
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: _category.titleLabel),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-owner-field'),
                controller: _ownerController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: _category.ownerLabel),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('record-status-field'),
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _category.statuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (status) {
                        if (status != null) {
                          setState(() {
                            _status = status;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: const Key('record-priority-field'),
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('High')),
                        DropdownMenuItem(value: 2, child: Text('Normal')),
                        DropdownMenuItem(value: 3, child: Text('Low')),
                      ],
                      onChanged: (priority) {
                        if (priority != null) {
                          setState(() {
                            _priority = priority;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-due-field'),
                controller: _dueController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Due window'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('record-note-field'),
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notes'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('save-record-button'),
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Save record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final now = DateTime.now();
    widget.onSave(
      OpsRecord(
        id: widget.existing?.id ?? now.microsecondsSinceEpoch.toString(),
        category: _category,
        title: _titleController.text.trim(),
        owner: _ownerController.text.trim(),
        status: _status,
        dueLabel: _dueController.text.trim(),
        note: _noteController.text.trim(),
        priority: _priority,
        updatedAt: now,
      ),
    );
  }
}

class RecordListTile extends StatelessWidget {
  const RecordListTile({super.key, required this.record, required this.onTap});

  final OpsRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _paper,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD9D2BD)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: record.category.tint,
                foregroundColor: record.category.color,
                child: Icon(record.category.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _midnight,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.owner} - ${record.dueLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _slateGreen, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusChip(label: record.status),
                        InfoChip(
                          icon: Icons.flag_outlined,
                          label: record.priorityLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _slateGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusLanePanel extends StatelessWidget {
  const StatusLanePanel({super.key, required this.records});

  final List<OpsRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D2BD)),
      ),
      child: Column(
        children: RecordCategory.values
            .map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.plural,
                        style: const TextStyle(
                          color: _midnight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    CountBadge(label: '${records.ofCategory(category).length}'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.actionText,
  });

  final String title;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _midnight,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          actionText,
          style: const TextStyle(
            color: _slateGreen,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D2BD)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: _courtGreen),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _midnight,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _slateGreen, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _courtGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _slateGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _midnight,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _midnight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      backgroundColor: const Color(0xFFECE4CE),
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: _midnight,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14, color: _courtGreen),
      label: Text(label),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD9D2BD)),
      labelStyle: const TextStyle(
        color: _slateGreen,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class OpsRecord {
  const OpsRecord({
    required this.id,
    required this.category,
    required this.title,
    required this.owner,
    required this.status,
    required this.dueLabel,
    required this.note,
    required this.priority,
    required this.updatedAt,
  });

  final String id;
  final RecordCategory category;
  final String title;
  final String owner;
  final String status;
  final String dueLabel;
  final String note;
  final int priority;
  final DateTime updatedAt;

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'High';
      case 3:
        return 'Low';
      default:
        return 'Normal';
    }
  }

  String get nextStatus {
    final statuses = category.statuses;
    final index = statuses.indexOf(status);
    if (index == -1 || index == statuses.length - 1) {
      return statuses.first;
    }
    return statuses[index + 1];
  }

  OpsRecord copyWith({
    RecordCategory? category,
    String? title,
    String? owner,
    String? status,
    String? dueLabel,
    String? note,
    int? priority,
    DateTime? updatedAt,
  }) {
    return OpsRecord(
      id: id,
      category: category ?? this.category,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      dueLabel: dueLabel ?? this.dueLabel,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'owner': owner,
      'status': status,
      'dueLabel': dueLabel,
      'note': note,
      'priority': priority,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OpsRecord.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String? ?? 'lead';
    final category = RecordCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () => RecordCategory.lead,
    );

    return OpsRecord(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      category: category,
      title: json['title'] as String? ?? category.singular,
      owner: json['owner'] as String? ?? 'Desk team',
      status: json['status'] as String? ?? category.statuses.first,
      dueLabel: json['dueLabel'] as String? ?? 'Today',
      note: json['note'] as String? ?? 'No notes saved.',
      priority: json['priority'] as int? ?? 2,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

enum RecordCategory { lead, asset, interview, visitor }

extension RecordCategoryCopy on RecordCategory {
  String get singular {
    switch (this) {
      case RecordCategory.lead:
        return 'Lead';
      case RecordCategory.asset:
        return 'Asset';
      case RecordCategory.interview:
        return 'Interview';
      case RecordCategory.visitor:
        return 'Visitor';
    }
  }

  String get plural {
    switch (this) {
      case RecordCategory.lead:
        return 'Leads';
      case RecordCategory.asset:
        return 'Assets';
      case RecordCategory.interview:
        return 'Interviews';
      case RecordCategory.visitor:
        return 'Visitors';
    }
  }

  String get titleLabel {
    switch (this) {
      case RecordCategory.lead:
        return 'Opportunity or organization';
      case RecordCategory.asset:
        return 'Asset name';
      case RecordCategory.interview:
        return 'Candidate or role';
      case RecordCategory.visitor:
        return 'Visitor or company';
    }
  }

  String get ownerLabel {
    switch (this) {
      case RecordCategory.lead:
        return 'Owner';
      case RecordCategory.asset:
        return 'Responsible person';
      case RecordCategory.interview:
        return 'Interviewer';
      case RecordCategory.visitor:
        return 'Host';
    }
  }

  String get description {
    switch (this) {
      case RecordCategory.lead:
        return 'Track prospects, status, and next contact owners.';
      case RecordCategory.asset:
        return 'Keep equipment, rooms, and shared items accountable.';
      case RecordCategory.interview:
        return 'Plan candidate meetings and follow-up decisions.';
      case RecordCategory.visitor:
        return 'Prepare arrivals, hosts, and visit outcomes.';
    }
  }

  IconData get icon {
    switch (this) {
      case RecordCategory.lead:
        return Icons.trending_up;
      case RecordCategory.asset:
        return Icons.inventory_2_outlined;
      case RecordCategory.interview:
        return Icons.groups_2_outlined;
      case RecordCategory.visitor:
        return Icons.badge_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RecordCategory.lead:
        return _courtGreen;
      case RecordCategory.asset:
        return const Color(0xFF725F15);
      case RecordCategory.interview:
        return _slateGreen;
      case RecordCategory.visitor:
        return const Color(0xFF495B78);
    }
  }

  Color get tint {
    switch (this) {
      case RecordCategory.lead:
        return const Color(0xFFDCE8DF);
      case RecordCategory.asset:
        return const Color(0xFFF1E5B8);
      case RecordCategory.interview:
        return const Color(0xFFDDE5E4);
      case RecordCategory.visitor:
        return const Color(0xFFE0E4EC);
    }
  }

  List<String> get statuses {
    switch (this) {
      case RecordCategory.lead:
        return const ['New lead', 'Contacted', 'Proposal sent', 'Won'];
      case RecordCategory.asset:
        return const ['In service', 'Needs review', 'Reserved', 'Retired'];
      case RecordCategory.interview:
        return const ['Scheduled', 'Confirmed', 'Completed'];
      case RecordCategory.visitor:
        return const ['Expected', 'Checked in', 'Follow up'];
    }
  }

  String get doneStatus => statuses.last;
}

extension OpsRecordList on List<OpsRecord> {
  List<OpsRecord> ofCategory(RecordCategory category) {
    return where((record) => record.category == category).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}

List<OpsRecord> sampleRecords() {
  final base = DateTime(2026, 5, 12, 9, 30);
  return [
    OpsRecord(
      id: 'sample-lead-1',
      category: RecordCategory.lead,
      title: 'Corporate membership renewal',
      owner: 'Front desk',
      status: 'Contacted',
      dueLabel: 'Today 14:00',
      note: 'Prepare a renewal quote and confirm court access requirements.',
      priority: 1,
      updatedAt: base,
    ),
    OpsRecord(
      id: 'sample-lead-2',
      category: RecordCategory.lead,
      title: 'Villejust youth program',
      owner: 'Operations lead',
      status: 'Proposal sent',
      dueLabel: 'Tomorrow',
      note: 'Follow up on session capacity and coach availability.',
      priority: 2,
      updatedAt: base.subtract(const Duration(hours: 2)),
    ),
    OpsRecord(
      id: 'sample-asset-1',
      category: RecordCategory.asset,
      title: 'Court 2 ball machine',
      owner: 'Maintenance',
      status: 'Needs review',
      dueLabel: 'Before evening bookings',
      note: 'Battery check requested after inconsistent feed speed.',
      priority: 1,
      updatedAt: base.subtract(const Duration(hours: 4)),
    ),
    OpsRecord(
      id: 'sample-asset-2',
      category: RecordCategory.asset,
      title: 'Clubhouse access badges',
      owner: 'Desk team',
      status: 'In service',
      dueLabel: 'Weekly count',
      note: 'Reconcile loaned badges with reception binder.',
      priority: 3,
      updatedAt: base.subtract(const Duration(days: 1)),
    ),
    OpsRecord(
      id: 'sample-interview-1',
      category: RecordCategory.interview,
      title: 'Assistant coach interview',
      owner: 'Club manager',
      status: 'Confirmed',
      dueLabel: 'Today 16:30',
      note: 'Review weekend availability and youth session experience.',
      priority: 1,
      updatedAt: base.subtract(const Duration(minutes: 45)),
    ),
    OpsRecord(
      id: 'sample-visitor-1',
      category: RecordCategory.visitor,
      title: 'Supplier visit for nets',
      owner: 'Facilities',
      status: 'Expected',
      dueLabel: 'Today 11:15',
      note: 'Escort to courts 1 and 3 for replacement measurement.',
      priority: 2,
      updatedAt: base.subtract(const Duration(hours: 1)),
    ),
    OpsRecord(
      id: 'sample-visitor-2',
      category: RecordCategory.visitor,
      title: 'New family orientation',
      owner: 'Reception',
      status: 'Checked in',
      dueLabel: 'In progress',
      note: 'Walk through bookings, clubhouse rules, and guest policy.',
      priority: 2,
      updatedAt: base.subtract(const Duration(minutes: 20)),
    ),
  ];
}

String formatDateTime(DateTime value) {
  final minutes = value.minute.toString().padLeft(2, '0');
  return '${value.month}/${value.day}/${value.year} ${value.hour}:$minutes';
}
