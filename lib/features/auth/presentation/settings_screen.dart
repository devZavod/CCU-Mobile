import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;
  
  bool _roundGrades = true;
  double _maxGrade = 5.0;
  double _minPassingGrade = 3.0;
  double _minValidGrade = 0.0;
  DateTime? _semesterEnd;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxGrade = prefs.getDouble('maxGrade') ?? 5.0;
      _minPassingGrade = prefs.getDouble('minPassingGrade') ?? 3.0;
      _minValidGrade = prefs.getDouble('minValidGrade') ?? 0.0;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _reminderEnabled = prefs.getBool('reminderEnabled') ?? true;
      _roundGrades = prefs.getBool('roundGrades') ?? true;

      final semesterMs = prefs.getInt('semesterEnd');
      if (semesterMs != null) {
        _semesterEnd =
            DateTime.fromMillisecondsSinceEpoch(semesterMs);
      }
    });
  }

  Future<void> _openMaxGradeDialog() async {
    final maxCtrl = TextEditingController(
      text: _maxGrade.toStringAsFixed(1),
    );
    final passingCtrl = TextEditingController(
      text: _minPassingGrade.toStringAsFixed(1),
    );
    final minCtrl = TextEditingController(
      text: _minValidGrade.toStringAsFixed(1),
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sistema de calificaciones"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: maxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Nota máxima",
                  hintText: "Ej: 5.0",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passingCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Nota mínima aprobatoria",
                  hintText: "Ej: 3.0",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: minCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Nota mínima válida",
                  hintText: "Ej: 0.0",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Todas las notas de la app usarán esta escala automáticamente.",
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () async {
              final maxParsed = double.tryParse(
                maxCtrl.text.trim().replaceAll(',', '.'),
              );
              final passingParsed = double.tryParse(
                passingCtrl.text.trim().replaceAll(',', '.'),
              );
              final minParsed = double.tryParse(
                minCtrl.text.trim().replaceAll(',', '.'),
              );

              if (maxParsed == null ||
                  passingParsed == null ||
                  minParsed == null) {
                return;
              }

              if (maxParsed <= minParsed) return;
              if (passingParsed < minParsed) return;
              if (minParsed >= maxParsed) return;

              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('maxGrade', maxParsed);
              await prefs.setDouble('minPassingGrade', passingParsed);
              await prefs.setDouble('minValidGrade', minParsed);

              setState(() {
                _maxGrade = maxParsed;
                _minPassingGrade = passingParsed;
                _minValidGrade = minParsed;
              });

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSemesterEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'semesterEnd', picked.millisecondsSinceEpoch);
      setState(() => _semesterEnd = picked);
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Exportación disponible próximamente"),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Restablecer aplicación"),
        content: const Text(
          "Esta acción eliminará todas las materias, "
          "tareas, notas y configuraciones guardadas.\n\n"
          "La sesión NO se cerrará.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar todo"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _resetAllData();
    }
  }

  Future<void> _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userName = prefs.getString('userName') ?? "Estudiante";
    final userEmail = prefs.getString('userEmail') ?? "";

    await prefs.clear();

    await prefs.setBool('isLoggedIn', isLoggedIn);
    await prefs.setString('userName', userName);
    await prefs.setString('userEmail', userEmail);

    setState(() {
      _maxGrade = 5.0;
      _minPassingGrade = 3.0;
      _minValidGrade = 0.0;
      _notificationsEnabled = true;
      _reminderEnabled = true;
      _roundGrades = true;
      _semesterEnd = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Todos los datos fueron eliminados"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Configuración",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _SectionLabel(label: "Apariencia"),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Modo oscuro",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isDark ? "Tema oscuro activo" : "Tema claro activo",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  value: isDark,
                  onChanged: (_) => widget.onToggleTheme(),
                ),
              ],
            ),
          ),

          _SectionLabel(label: "Notificaciones"),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Notificaciones generales",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Avisos de tareas y eventos",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (v) async {
                    final prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('notificationsEnabled', v);
                    setState(() => _notificationsEnabled = v);
                  },
                ),

                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),

                SwitchListTile(
                  secondary: Icon(
                    Icons.alarm_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Recordatorios de estudio",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Avisos antes de evaluaciones",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  value: _reminderEnabled,
                  onChanged: _notificationsEnabled
                      ? (v) async {
                          final prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setBool('reminderEnabled', v);
                          setState(() => _reminderEnabled = v);
                        }
                      : null,
                ),
              ],
            ),
          ),

          _SectionLabel(label: "Académico"),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.bar_chart_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Escala de calificaciones",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Máx: ${_maxGrade.toStringAsFixed(1)} · "
                    "Aprueba: ${_minPassingGrade.toStringAsFixed(1)} · "
                    "Mín: ${_minValidGrade.toStringAsFixed(1)}",
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openMaxGradeDialog,
                ),

                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),

                SwitchListTile(
                  secondary: Icon(
                    Icons.rounded_corner,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Redondear notas",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Redondeo automático a 1 o 2 decimales",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  value: _roundGrades,
                  onChanged: (v) async {
                    final prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('roundGrades', v);
                    setState(() => _roundGrades = v);
                  },
                ),

                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),

                ListTile(
                  leading: Icon(
                    Icons.event_available_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Fin de semestre",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _semesterEnd != null
                        ? "${_semesterEnd!.day}/${_semesterEnd!.month}/${_semesterEnd!.year}"
                        : "No definido",
                  ),
                  onTap: _pickSemesterEnd,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionLabel(label: "Datos"),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.download_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    "Exportar datos",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Guardar respaldo de materias y tareas",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  onTap: _exportData,
                ),

                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),

                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    "Restablecer aplicación",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    "Eliminar materias, tareas, notas y datos locales",
                  ),
                  onTap: _confirmReset,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _SectionLabel(label: "Acerca de"),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.info_outline,
                  label: "Versión",
                  value: "1.0.0",
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: "Institución",
                  value: "Universidad Tecnológica de Bolívar",
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            "CCU Mobile · v1.0.0",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        letterSpacing: 1.0,
        fontSize: 12,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}