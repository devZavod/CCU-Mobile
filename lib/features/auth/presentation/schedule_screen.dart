import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleEntry {
  final String id;
  String subject;
  String classCode;
  int dayOfWeek;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String classroom;
  String professor;
  Color color;
  bool synced;

  ScheduleEntry({
    required this.id,
    required this.subject,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.classCode = '',
    this.classroom = '',
    this.professor = '',
    this.color = const Color(0xFF7C3AED),
    this.synced = false,
  });

  bool get isPassedToday {
    final now = DateTime.now();
    if (now.weekday != dayOfWeek) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return nowMinutes > endMinutes;
  }

  bool get isActiveNow {
    final now = DateTime.now();
    if (now.weekday != dayOfWeek) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  String formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'classCode': classCode,
      'dayOfWeek': dayOfWeek,
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'classroom': classroom,
      'professor': professor,
      'color': color.value,
      'synced': synced,
    };
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    final endParts = (json['endTime'] as String).split(':');

    return ScheduleEntry(
      id: json['id'] as String,
      subject: json['subject'] as String,
      classCode: json['classCode'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      classroom: json['classroom'] as String? ?? '',
      professor: json['professor'] as String? ?? '',
      color: Color(json['color'] as int),
      synced: json['synced'] as bool? ?? false,
    );
  }
}

const _kScheduleKey = 'ccu_schedule_entries';

Future<List<ScheduleEntry>> _loadFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kScheduleKey);
  if (raw == null) return [];
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => ScheduleEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> _saveToPrefs(List<ScheduleEntry> entries) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
  await prefs.setString(_kScheduleKey, encoded);
}

class ScheduleScreen extends StatefulWidget {
  static var subjectColors = [
    const Color(0xFF7C3AED),
    const Color(0xFF14B8A6),
    const Color(0xFFDC2626),
    const Color(0xFF06B6D4),
    const Color(0xFFF97316),
    const Color(0xFF1E3A8A),
    const Color(0xFFEAB308),
  ];

  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  List<ScheduleEntry> _entries = [];

  late final TabController _tabController;

  static const List<String> _dayNames = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom',
  ];

  static const List<String> _dayNamesFull = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  @override
  void initState() {
    super.initState();

    final todayIndex = now.weekday == 7 ? 6 : now.weekday - 1;

    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: todayIndex.clamp(0, 6),
    );

    _tabController.addListener(() {
      setState(() {});
    });

    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final loaded = await _loadFromPrefs();
    if (mounted) {
      setState(() => _entries = loaded);
    }
  }

  Future<void> _persistEntries() async {
    await _saveToPrefs(_entries);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get now => DateTime.now();

  String _getGreeting() {
    final hour = now.hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _getWeekSummary() {
    final todayClasses =
        _entriesForDay(now.weekday == 7 ? 7 : now.weekday).length;
    return '$todayClasses clases hoy';
  }

  List<ScheduleEntry> _entriesForDay(int dayOfWeek) {
    final list = _entries.where((e) => e.dayOfWeek == dayOfWeek).toList();
    list.sort((a, b) {
      final aMin = a.startTime.hour * 60 + a.startTime.minute;
      final bMin = b.startTime.hour * 60 + b.startTime.minute;
      return aMin.compareTo(bMin);
    });
    return list;
  }

  void _openForm({ScheduleEntry? existing}) {
    showModalBottomSheet(
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.25,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: _ScheduleForm(
            existing: existing,
            initialDay: _tabController.index + 1,
            onSave: (entries) {
              setState(() {
                if (existing != null) {
                  _entries.removeWhere((e) => e.id == existing.id);
                }
                _entries.addAll(entries);
              });
              _persistEntries();
            },
          ),
        ),
      ),
    );
  }

  void _deleteEntry(ScheduleEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text(
            '¿Eliminar "${entry.subject}" de ${_dayNamesFull[entry.dayOfWeek - 1]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(
                  () => _entries.removeWhere((e) => e.id == entry.id));
              _persistEntries();
              Navigator.pop(context);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIndex = now.weekday == 7 ? 6 : now.weekday - 1;

    return Scaffold(
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_getGreeting()} · ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: _getWeekSummary(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              indicator: const BoxDecoration(),
              labelPadding: const EdgeInsets.symmetric(horizontal: 3),
              dividerColor: Colors.transparent,
              tabs: List.generate(7, (i) {
                final isToday = i == todayIndex;
                final isSelected = _tabController.index == i;
                final weekStart = now.subtract(
                  Duration(days: now.weekday == 7 ? 6 : now.weekday - 1),
                );
                final dayDate = weekStart.add(Duration(days: i));

                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.16)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.45)
                          : theme.colorScheme.outline.withValues(alpha: 0.10),
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayNames[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dayDate.day.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (i) {
                final dayEntries = _entriesForDay(i + 1);
                final isToday = i == todayIndex;

                if (dayEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 56,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sin clases',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                      top: 12, left: 16, right: 16, bottom: 90),
                  itemCount: dayEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, j) {
                    final entry = dayEntries[j];
                    final passed = isToday && entry.isPassedToday;
                    final active = isToday && entry.isActiveNow;
                    final subjectColor = entry.color;

                    return _ScheduleTile(
                      entry: entry,
                      passed: passed,
                      active: active,
                      subjectColor: subjectColor,
                      onEdit: () => _openForm(existing: entry),
                      onDelete: () => _deleteEntry(entry),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 1,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar clase'),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final ScheduleEntry entry;
  final bool passed;
  final bool active;
  final Color subjectColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleTile({
    required this.entry,
    required this.passed,
    required this.active,
    required this.subjectColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? subjectColor.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.12),
          width: active ? 1.4 : 1,
        ),
        color: theme.colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: passed
                      ? theme.colorScheme.outline.withValues(alpha: 0.25)
                      : subjectColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: subjectColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.subject,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          decoration: passed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: passed
                                              ? theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.35)
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (entry.classCode.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            entry.classCode,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: subjectColor
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (active)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    subjectColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Ahora',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: subjectColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 13,
                            color: passed
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.25)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${entry.formatTime(entry.startTime)} – ${entry.formatTime(entry.endTime)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: passed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: passed
                                  ? theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                            ),
                          ),
                          if (passed) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Finalizada',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (entry.classroom.isNotEmpty ||
                          entry.professor.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (entry.classroom.isNotEmpty) ...[
                              Icon(
                                Icons.room_outlined,
                                size: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                    alpha: passed ? 0.2 : 0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.classroom,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(
                                          alpha: passed ? 0.25 : 0.5),
                                ),
                              ),
                            ],
                            if (entry.classroom.isNotEmpty &&
                                entry.professor.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                '·',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            if (entry.professor.isNotEmpty) ...[
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                    alpha: passed ? 0.2 : 0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.professor,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(
                                          alpha: passed ? 0.25 : 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleForm extends StatefulWidget {
  final ScheduleEntry? existing;
  final int initialDay;
  final void Function(List<ScheduleEntry>) onSave;

  const _ScheduleForm({
    this.existing,
    required this.initialDay,
    required this.onSave,
  });

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _classCodeCtrl;
  late final TextEditingController _classroomCtrl;
  late final TextEditingController _professorCtrl;

  List<int> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late Color _selectedColor;

  bool _startError = false;
  bool _endError = false;
  bool _daysError = false;

  static const List<String> _dayNames = [
    'Lunes', 'Martes', 'Miércoles',
    'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedColor = e?.color ?? const Color(0xFF7C3AED);
    _subjectCtrl = TextEditingController(text: e?.subject ?? '');
    _classCodeCtrl = TextEditingController(text: e?.classCode ?? '');
    _classroomCtrl = TextEditingController(text: e?.classroom ?? '');
    _professorCtrl = TextEditingController(text: e?.professor ?? '');
    _selectedDays = [e?.dayOfWeek ?? widget.initialDay];
    _startTime = e?.startTime;
    _endTime = e?.endTime;
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _classCodeCtrl.dispose();
    _classroomCtrl.dispose();
    _professorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 7, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 8, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _startError = _startTime == null;
      _endError = _endTime == null;
      _daysError = _selectedDays.isEmpty;
    });

    if (_startTime == null || _selectedDays.isEmpty) {
      if (_startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona la hora de inicio'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona al menos un día'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la hora de fin'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;

    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser mayor a la de inicio'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final entries = _selectedDays.map((day) {
      return ScheduleEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}-$day',
        subject: _subjectCtrl.text.trim(),
        classCode: _classCodeCtrl.text.trim(),
        dayOfWeek: day,
        startTime: _startTime!,
        endTime: _endTime!,
        classroom: _classroomCtrl.text.trim(),
        professor: _professorCtrl.text.trim(),
        color: _selectedColor,
        synced: false,
      );
    }).toList();

    widget.onSave(entries);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEdit ? 'Editar clase' : 'Nueva clase',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Materia *',
                prefixIcon: const Icon(Icons.book_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _classCodeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código de clase',
                prefixIcon: const Icon(Icons.tag_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Días de la semana *',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 3,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _selectedDays.contains(day);

                    return FilterChip(
                      label: Text(_dayNames[i]),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      backgroundColor: theme.colorScheme.surface,
                      selectedColor: theme.colorScheme.primary
                          .withValues(alpha: 0.16),
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: selected
                            ? theme.colorScheme.primary
                                .withValues(alpha: 0.45)
                            : theme.colorScheme.outline
                                .withValues(alpha: 0.20),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
                if (_daysError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Selecciona al menos un día',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Hora inicio *',
                        prefixIcon:
                            const Icon(Icons.access_time_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _startError
                                ? Colors.red
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _startError
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      child: Text(
                        _startTime != null
                            ? _formatTime(_startTime!)
                            : 'Seleccionar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _startTime != null
                              ? null
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Hora fin *',
                        prefixIcon:
                            const Icon(Icons.access_time_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _endError
                                ? Colors.red
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _endError
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      child: Text(
                        _endTime != null
                            ? _formatTime(_endTime!)
                            : 'Seleccionar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _endTime != null
                              ? null
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _classroomCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Salón (opcional)',
                prefixIcon: const Icon(Icons.room_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _professorCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Profesor (opcional)',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Color de la materia',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ScheduleScreen.subjectColors.map((color) {
                final selected = color == _selectedColor;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)
                            : Colors.transparent,
                        width: 2.2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEdit ? 'Guardar cambios' : 'Agregar clase',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}