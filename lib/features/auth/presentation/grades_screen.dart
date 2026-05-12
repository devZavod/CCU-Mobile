import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/domain/grade_config.dart';

class GradeActivity {
  final String id;
  String name;
  double grade;
  double weight;

  GradeActivity({
    required this.id,
    required this.name,
    required this.grade,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'weight': weight,
    };
  }

  factory GradeActivity.fromMap(Map<String, dynamic> map) {
    return GradeActivity(
      id: map['id'],
      name: map['name'],
      grade: (map['grade'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
    );
  }
}

class Cut {
  final String id;
  String name;
  double weight;
  List<GradeActivity> activities;

  Cut({
    required this.id,
    required this.name,
    required this.weight,
    List<GradeActivity>? activities,
  }) : activities = activities ?? [];

  double get grade {
    if (activities.isEmpty) return 0.0;
    return activities.fold(
        0.0, (sum, a) => sum + a.grade * (a.weight / 100));
  }

  double get usedWeight =>
      activities.fold(0.0, (sum, a) => sum + a.weight);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'activities': activities.map((a) => a.toMap()).toList(),
    };
  }

  factory Cut.fromMap(Map<String, dynamic> map) {
    return Cut(
      id: map['id'],
      name: map['name'],
      weight: (map['weight'] as num).toDouble(),
      activities: List<GradeActivity>.from(
        (map['activities'] as List).map((a) => GradeActivity.fromMap(a)),
      ),
    );
  }
}

class Subject {
  final String id;
  String name;
  List<Cut> cuts;

  Subject({
    required this.id,
    required this.name,
    List<Cut>? cuts,
  }) : cuts = cuts ??
            [
              Cut(id: '1', name: 'Corte 1', weight: 30),
              Cut(id: '2', name: 'Corte 2', weight: 35),
              Cut(id: '3', name: 'Corte 3', weight: 35),
            ];

  double get finalGrade =>
      cuts.fold(0.0, (sum, c) => sum + c.grade * (c.weight / 100));

  double get totalCutWeight =>
      cuts.fold(0.0, (sum, c) => sum + c.weight);

  bool isPassing(double minPassingGrade) =>
      finalGrade >= minPassingGrade;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuts': cuts.map((c) => c.toMap()).toList(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      cuts: List<Cut>.from(
        (map['cuts'] as List).map((c) => Cut.fromMap(c)),
      ),
    );
  }
}

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final List<Subject> _subjects = [];
  double _maxGrade = 5.0;
  double _minPassingGrade = 3.0;
  double _minValidGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadGradeConfig();
    await _loadSubjects();
  }

  Future<void> _loadGradeConfig() async {
    _maxGrade = await GradeConfig.getMaxGrade();
    _minPassingGrade = await GradeConfig.getMinPassingGrade();
    _minValidGrade = await GradeConfig.getMinValidGrade();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('subjects_data');

    if (raw == null) return;

    final List decoded = jsonDecode(raw);
    _subjects.clear();
    _subjects.addAll(
      decoded.map((e) => Subject.fromMap(e)).toList(),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _subjects.map((s) => s.toMap()).toList();
    await prefs.setString('subjects_data', jsonEncode(data));
  }

  void _openAddSubject({Subject? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SubjectForm(
        existing: existing,
        onSave: (subject) {
          setState(() {
            if (existing != null) {
              final i =
                  _subjects.indexWhere((s) => s.id == existing.id);
              if (i != -1) _subjects[i] = subject;
            } else {
              _subjects.add(subject);
            }
          });
          _saveSubjects();
        },
      ),
    );
  }

  void _deleteSubject(Subject subject) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text('¿Eliminar "${subject.name}" y todas sus notas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() =>
                  _subjects.removeWhere((s) => s.id == subject.id));
              _saveSubjects();
              Navigator.pop(context);
            },
            child: Text('Eliminar',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(Subject subject) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SubjectDetailPage(
          subject: subject,
          onChanged: () async {
            setState(() {});
            await _saveSubjects();
          },
        ),
      ),
    );

    await _loadGradeConfig();

    if (mounted) {
      setState(() {});
    }
  }

  Color _gradeColor(double grade, ColorScheme cs) {
    final excellentThreshold =
        _minPassingGrade +
        ((_maxGrade - _minPassingGrade) * 0.5);

    if (grade >= excellentThreshold) {
      return Colors.green.shade500;
    }

    if (grade >= _minPassingGrade) {
      return Colors.orange.shade500;
    }

    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined,
                      size: 72,
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Sin materias registradas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(
                  top: 16, left: 16, right: 16, bottom: 90),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = _subjects[i];
                final grade = s.finalGrade;
                final color = _gradeColor(grade, theme.colorScheme);

                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _openDetail(s),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: color.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: color.withValues(alpha: 0.10),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: color,
                                size: 15,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Text(
                                    '${s.cuts.where((c) => c.activities.isNotEmpty).length} de ${s.cuts.length} cortes registrados',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.58),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            PopupMenuButton<String>(
                              splashRadius: 20,
                              onSelected: (v) {
                                if (v == 'edit') {
                                  _openAddSubject(existing: s);
                                }

                                if (v == 'delete') {
                                  _deleteSubject(s);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar nombre'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [

                            Text(
                              grade.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 30,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: color.withValues(alpha: 0.12),
                                ),
                                child: Text(
                                  s.isPassing(_minPassingGrade)
                                      ? 'Buen desempeño'
                                      : 'En riesgo',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: s.cuts.isEmpty
                                ? 0
                                : s.cuts
                                        .where((c) => c.activities.isNotEmpty)
                                        .length /
                                    s.cuts.length,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.outline.withValues(alpha: 0.10),
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso académico',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.50),
                              ),
                            ),

                            Text(
                              '${s.cuts.fold<int>(0, (sum, c) => sum + c.activities.length)} actividades',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.60),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSubject(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva materia'),
      ),
    );
  }
}

class _SubjectForm extends StatefulWidget {
  final Subject? existing;
  final void Function(Subject) onSave;

  const _SubjectForm({this.existing, required this.onSave});

  @override
  State<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<_SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  final _w1Ctrl = TextEditingController();
  final _w2Ctrl = TextEditingController();
  final _w3Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _w1Ctrl.text = (e?.cuts[0].weight ?? 30).toStringAsFixed(0);
    _w2Ctrl.text = (e?.cuts[1].weight ?? 35).toStringAsFixed(0);
    _w3Ctrl.text = (e?.cuts[2].weight ?? 35).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _w1Ctrl.dispose();
    _w2Ctrl.dispose();
    _w3Ctrl.dispose();
    super.dispose();
  }

  bool get _weightsValid {
    final w1 = double.tryParse(_w1Ctrl.text) ?? 0;
    final w2 = double.tryParse(_w2Ctrl.text) ?? 0;
    final w3 = double.tryParse(_w3Ctrl.text) ?? 0;
    return (w1 + w2 + w3) == 100;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_weightsValid) {
      ScaffoldMessenger.of(
        Navigator.of(context).context,
      ).hideCurrentSnackBar();

      ScaffoldMessenger.of(
        Navigator.of(context).context,
      ).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          content: Text(
            'Los pesos de los cortes deben sumar 100%',
          ),
        ),
      );
      return;
    }

    final e = widget.existing;
    final subject = Subject(
      id: e?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      cuts: [
        Cut(
          id: e?.cuts[0].id ?? '1',
          name: 'Corte 1',
          weight: double.parse(_w1Ctrl.text),
          activities: e?.cuts[0].activities,
        ),
        Cut(
          id: e?.cuts[1].id ?? '2',
          name: 'Corte 2',
          weight: double.parse(_w2Ctrl.text),
          activities: e?.cuts[1].activities,
        ),
        Cut(
          id: e?.cuts[2].id ?? '3',
          name: 'Corte 3',
          weight: double.parse(_w3Ctrl.text),
          activities: e?.cuts[2].activities,
        ),
      ],
    );

    widget.onSave(subject);
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
                  color:
                      theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEdit ? 'Editar materia' : 'Nueva materia',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre de la materia *',
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                ),
                floatingLabelStyle: TextStyle(
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                ),
                prefixIcon: const Icon(Icons.book_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
            ),
            const SizedBox(height: 16),

            Text(
              'Pesos de cortes (deben sumar 100%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _WeightField(ctrl: _w1Ctrl, label: 'Corte 1 %')),
                const SizedBox(width: 10),
                Expanded(child: _WeightField(ctrl: _w2Ctrl, label: 'Corte 2 %')),
                const SizedBox(width: 10),
                Expanded(child: _WeightField(ctrl: _w3Ctrl, label: 'Corte 3 %')),
              ],
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
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEdit ? 'Guardar cambios' : 'Agregar materia',
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

class _WeightField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _WeightField({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n <= 0 || n > 100) return 'Inválido';
        return null;
      },
    );
  }
}

class _SubjectDetailPage extends StatefulWidget {
  final Subject subject;
  final Future<void> Function() onChanged;

  const _SubjectDetailPage(
      {required this.subject, required this.onChanged});

  @override
  State<_SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<_SubjectDetailPage> {
  double _maxGrade = 5.0;
  double _minPassingGrade = 3.0;
  double _minValidGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGradeConfig();
  }

  Future<void> _loadGradeConfig() async {
    _maxGrade = await GradeConfig.getMaxGrade();
    _minPassingGrade = await GradeConfig.getMinPassingGrade();
    _minValidGrade = await GradeConfig.getMinValidGrade();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _rebuild() async {
    setState(() {});
    await widget.onChanged();
  }

  void _openAddActivity(Cut cut) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActivityForm(
        cut: cut,
        onSave: (activity) {
          setState(() => cut.activities.add(activity));
          widget.onChanged();
        },
      ),
    );
  }

  void _editActivity(Cut cut, GradeActivity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActivityForm(
        cut: cut,
        existing: activity,
        onSave: (updated) {
          setState(() {
            final i =
                cut.activities.indexWhere((a) => a.id == activity.id);
            if (i != -1) cut.activities[i] = updated;
          });
          widget.onChanged();
        },
      ),
    );
  }

  void _deleteActivity(Cut cut, GradeActivity activity) {
    setState(() =>
        cut.activities.removeWhere((a) => a.id == activity.id));
    widget.onChanged();
  }

  Color _gradeColor(double grade) {
    final excellentThreshold =
        _minPassingGrade +
        ((_maxGrade - _minPassingGrade) * 0.5);

    if (grade >= excellentThreshold) {
      return Colors.green.shade500;
    }

    if (grade >= _minPassingGrade) {
      return Colors.orange.shade500;
    }

    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = widget.subject;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
        children: [
          _FinalGradeCard(
            subject: subject,
            minPassingGrade: _minPassingGrade,
            maxGrade: _maxGrade,
          ),
          const SizedBox(height: 20),

          ...subject.cuts.map((cut) => _CutSection(
                cut: cut,
                gradeColor: _gradeColor,
                onAddActivity: () => _openAddActivity(cut),
                onEditActivity: (a) => _editActivity(cut, a),
                onDeleteActivity: (a) => _deleteActivity(cut, a),
              )),
        ],
      ),
    );
  }
}

class _FinalGradeCard extends StatelessWidget {
  final Subject subject;
  final double minPassingGrade;
  final double maxGrade;

  const _FinalGradeCard({
    required this.subject,
    required this.minPassingGrade,
    required this.maxGrade,
  });

  @override
  Widget build(BuildContext context) {
    final grade = subject.finalGrade;
    final isPassing = subject.isPassing(minPassingGrade);

    final List<Color> gradient = isPassing
        ? [const Color(0xFF059669), const Color(0xFF10B981)]
        : [const Color(0xFFDC2626), const Color(0xFFEF4444)];

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Definitiva estimada',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                grade.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPassing ? 'Buen desempeño' : 'Riesgo académico',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CutSection extends StatelessWidget {
  final Cut cut;
  final Color Function(double) gradeColor;
  final VoidCallback onAddActivity;
  final void Function(GradeActivity) onEditActivity;
  final void Function(GradeActivity) onDeleteActivity;

  const _CutSection({
    required this.cut,
    required this.gradeColor,
    required this.onAddActivity,
    required this.onEditActivity,
    required this.onDeleteActivity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = 100 - cut.usedWeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cut.name}  ·  ${cut.weight.toStringAsFixed(0)}% del total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Nota del corte: ${cut.grade.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: remaining > 0 ? onAddActivity : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar actividad'),
            ),
          ],
        ),

        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: cut.usedWeight / 100,
            minHeight: 9,
            backgroundColor:
                theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              cut.usedWeight > 100
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),

        if (remaining <= 0 && cut.activities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Peso completo (100%)',
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.primary),
            ),
          ),

        const SizedBox(height: 8),

        if (cut.activities.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Sin actividades aún',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          )
        else
          ...cut.activities.map((a) => _ActivityTile(
                activity: a,
                gradeColor: gradeColor(a.grade),
                onEdit: () => onEditActivity(a),
                onDelete: () => onDeleteActivity(a),
              )),

        const SizedBox(height: 28),
        Divider(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final GradeActivity activity;
  final Color gradeColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityTile({
    required this.activity,
    required this.gradeColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        dense: false,
        title: Text(
          activity.name,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Peso: ${activity.weight.toStringAsFixed(0)}%',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activity.grade.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: gradeColor,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityForm extends StatefulWidget {
  final Cut cut;
  final GradeActivity? existing;
  final void Function(GradeActivity) onSave;

  const _ActivityForm(
      {required this.cut, this.existing, required this.onSave});

  @override
  State<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<_ActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _gradeCtrl;
  late final TextEditingController _weightCtrl;

  double _maxGrade = 5.0;
  double _minValidGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGradeConfig();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _gradeCtrl =
        TextEditingController(text: e != null ? e.grade.toString() : '');
    _weightCtrl = TextEditingController(
        text: e != null ? e.weight.toStringAsFixed(0) : '');
  }

  Future<void> _loadGradeConfig() async {
    _maxGrade = await GradeConfig.getMaxGrade();
    _minValidGrade = await GradeConfig.getMinValidGrade();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gradeCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _availableWeight {
    final used = widget.cut.usedWeight;
    final existing = widget.existing?.weight ?? 0;
    return 100 - used + existing;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final activity = GradeActivity(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      grade: double.parse(_gradeCtrl.text),
      weight: double.parse(_weightCtrl.text),
    );

    widget.onSave(activity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final available = _availableWeight;

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
                  color:
                      theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEdit ? 'Editar actividad' : 'Nueva actividad — ${widget.cut.name}',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Peso disponible: ${available.toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre de la actividad *',
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                ),
                floatingLabelStyle: TextStyle(
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                ),
                prefixIcon: const Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gradeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Nota ($_minValidGrade – $_maxGrade) *',
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                      ),
                      prefixIcon: const Icon(Icons.grade_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'Nota inválida';
                      if (n < _minValidGrade || n > _maxGrade) {
                        return 'Rango $_minValidGrade - $_maxGrade';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Peso % *',
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                      ),
                      prefixIcon: const Icon(Icons.percent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null) return 'Inválido';
                      if (n <= 0 || n > 100) return '1 - 100%';
                      if (n > available + 0.01) {
                        return 'Máx ${available.toStringAsFixed(0)}%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
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
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEdit ? 'Guardar cambios' : 'Agregar actividad',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],git add .
        ),
      ),
    );
  }
}