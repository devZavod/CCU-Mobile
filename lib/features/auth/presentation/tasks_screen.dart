import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum TaskPriority { alta, media, baja }

class Task {
  final String id;
  String title;
  String description;
  DateTime? deadline;
  TaskPriority priority;
  String subject;
  bool completed;
  bool synced;
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.deadline,
    this.priority = TaskPriority.media,
    this.subject = '',
    this.completed = false,
    this.synced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority.name,
      'subject': subject,
      'completed': completed,
      'synced': synced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.media,
      ),
      subject: json['subject'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      synced: json['synced'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    String? subject,
    bool? completed,
    bool? synced,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      subject: subject ?? this.subject,
      completed: completed ?? this.completed,
      synced: synced ?? this.synced,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('tasks');

      if (tasksJson != null && tasksJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        setState(() {
          _tasks.clear();
          _tasks.addAll(decoded.map((json) => Task.fromJson(json)));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tareas: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString('tasks', tasksJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar tareas: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Color _priorityColor(TaskPriority p, ColorScheme cs) {
    switch (p) {
      case TaskPriority.alta:
        return Colors.red.shade400;
      case TaskPriority.media:
        return Colors.orange.shade400;
      case TaskPriority.baja:
        return Colors.green.shade400;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.alta:
        return 'Alta';
      case TaskPriority.media:
        return 'Media';
      case TaskPriority.baja:
        return 'Baja';
    }
  }

  int _priorityValue(TaskPriority p) {
    switch (p) {
      case TaskPriority.alta:
        return 3;
      case TaskPriority.media:
        return 2;
      case TaskPriority.baja:
        return 1;
    }
  }

  void _sortTasks(List<Task> tasks) {
    final now = DateTime.now();

    tasks.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }

      if (a.deadline == null && b.deadline != null) return 1;
      if (a.deadline != null && b.deadline == null) return -1;

      if (a.deadline == null && b.deadline == null) {
        return _priorityValue(b.priority)
            .compareTo(_priorityValue(a.priority));
      }

      final aDate = DateTime(
        a.deadline!.year,
        a.deadline!.month,
        a.deadline!.day,
      );

      final bDate = DateTime(
        b.deadline!.year,
        b.deadline!.month,
        b.deadline!.day,
      );

      final nowDate = DateTime(now.year, now.month, now.day);

      final aDiff = aDate.difference(nowDate).inDays;
      final bDiff = bDate.difference(nowDate).inDays;

      if (aDiff != bDiff) {
        return aDiff.compareTo(bDiff);
      }

      return _priorityValue(b.priority)
          .compareTo(_priorityValue(a.priority));
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Sin fecha';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  void _openForm({Task? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TaskForm(
        existing: existing,
        onSave: (task) {
          setState(() {
            if (existing != null) {
              final i = _tasks.indexWhere((t) => t.id == existing.id);
              if (i != -1) {
                _tasks[i] = task.copyWith(synced: false);
              }
            } else {
              _tasks.add(task);
            }
          });
          _saveTasks();
        },
      ),
    );
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _tasks.removeWhere((t) => t.id == task.id));
              _saveTasks();
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

  void _toggleComplete(Task task) {
    setState(() {
      task.completed = !task.completed;
      task.synced = false;
      task.updatedAt = DateTime.now();
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pending = _tasks.where((t) => !t.completed).toList();
    final done = _tasks.where((t) => t.completed).toList();

    _sortTasks(pending);
    _sortTasks(done);

    return Scaffold(
      body: _tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 72,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Sin tareas por ahora',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(
                  top: 16, left: 16, right: 16, bottom: 90),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader(label: 'Pendientes (${pending.length})'),
                  ...pending.map((t) => _TaskTile(
                        task: t,
                        priorityColor:
                            _priorityColor(t.priority, theme.colorScheme),
                        priorityLabel: _priorityLabel(t.priority),
                        formattedDate: _formatDate(t.deadline),
                        onToggle: () => _toggleComplete(t),
                        onEdit: () => _openForm(existing: t),
                        onDelete: () => _confirmDelete(t),
                      )),
                  const SizedBox(height: 16),
                ],
                if (done.isNotEmpty) ...[
                  _SectionHeader(label: 'Completadas (${done.length})'),
                  ...done.map((t) => _TaskTile(
                        task: t,
                        priorityColor:
                            _priorityColor(t.priority, theme.colorScheme),
                        priorityLabel: _priorityLabel(t.priority),
                        formattedDate: _formatDate(t.deadline),
                        onToggle: () => _toggleComplete(t),
                        onEdit: () => _openForm(existing: t),
                        onDelete: () => _confirmDelete(t),
                      )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final Color priorityColor;
  final String priorityLabel;
  final String formattedDate;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.priorityColor,
    required this.priorityLabel,
    required this.formattedDate,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.completed
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: task.completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: task.completed
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed
                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.subject.isNotEmpty)
              Text(
                task.subject,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined,
                    size: 11,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 3),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}

class _TaskForm extends StatefulWidget {
  final Task? existing;
  final void Function(Task) onSave;

  const _TaskForm({this.existing, required this.onSave});

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _subjectCtrl;

  TaskPriority _priority = TaskPriority.media;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _subjectCtrl = TextEditingController(text: e?.subject ?? '');
    if (e != null) {
      _priority = e.priority;
      _deadline = e.deadline;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      priority: _priority,
      deadline: _deadline,
      completed: widget.existing?.completed ?? false,
      synced: false,
      createdAt: widget.existing?.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(task);
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
      child: SingleChildScrollView(
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
                isEdit ? 'Editar tarea' : 'Nueva tarea',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El título es obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _subjectCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Materia (opcional)',
                  prefixIcon: const Icon(Icons.book_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Prioridad',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                              p.name[0].toUpperCase() + p.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _priority = v);
                },
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha límite (opcional)',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    suffixIcon: _deadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _deadline = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _deadline != null
                        ? '${_deadline!.day.toString().padLeft(2, '0')}/'
                            '${_deadline!.month.toString().padLeft(2, '0')}/'
                            '${_deadline!.year}'
                        : 'Seleccionar fecha',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _deadline != null
                          ? null
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Guardar cambios' : 'Agregar tarea',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}