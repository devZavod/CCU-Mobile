class EstudianteModel {
  final int idEstudiante;
  final String correoUsuario;
  final String nombreEstudiante;
  final DateTime fechaRegistro;
  final bool estadoEstudiante;
  final String? profilePic;

  EstudianteModel({
    required this.idEstudiante,
    required this.correoUsuario,
    required this.nombreEstudiante,
    required this.fechaRegistro,
    required this.estadoEstudiante,
    this.profilePic,
  });

  factory EstudianteModel.fromJson(Map<String, dynamic> json) {
    return EstudianteModel(
      idEstudiante: json['id_estudiante'],
      correoUsuario: json['correo_usuario'],
      nombreEstudiante: json['nombre_estudiante'],
      fechaRegistro: DateTime.parse(json['fecha_registro']),
      estadoEstudiante: json['estado_estudiante'],
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_estudiante': idEstudiante,
      'correo_usuario': correoUsuario,
      'nombre_estudiante': nombreEstudiante,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'estado_estudiante': estadoEstudiante,
      'profile_pic': profilePic,
    };
  }
}