# CCU Mobile Frontend

Frontend móvil de **CCU** (*Calendario y Calculadora Universitaria*), aplicación orientada a estudiantes universitarios para organizar horarios, gestionar tareas y calcular el rendimiento académico.

## Introducción

CCU unifica en una sola app funciones que suelen estar dispersas: calendario académico, manejo de notas y predicción del **promedio ponderado (PP)** como meta personal. No se limita a saber si el estudiante aprueba; ayuda a planificar cuánto debe sacar en cada actividad para alcanzar un objetivo concreto del semestre.

**Equipo:** Josh R. Ortega Castellón, Diego Ramos De Ávila, Luis Salas Reyes  
**Materia:** Desarrollo de Software  
**Docente:** Marco Antonio Almanza  
**Versión del documento de requisitos:** 1.0 (14/02/2026)

### Funciones principales

- **Calendario y horario:** crear, editar y visualizar clases y actividades con recordatorios.
- **Tareas y eventos:** gestión de pendientes con fechas límite, prioridad y materia asociada.
- **Cálculo de notas:** promedio ponderado por materia, definitiva por corte y proyección de nota final.
- **Metas académicas:** cálculo de la nota necesaria para alcanzar un objetivo de PP.
- **Avisos interactivos:** alertas motivacionales, recordatorios y notificaciones push.
- **Estadísticas:** gráficos de evolución de notas a lo largo del semestre.

La app está pensada para **Android e iOS**, con diseño mobile-first y navegación por pestañas inferiores: Inicio, Horario, Tareas, Notas y Perfil.

---


## Requisitos previos

Antes de instalar dependencias del proyecto, necesitas tener configurado el entorno de desarrollo Flutter:

| Herramienta | Versión recomendada | Descripción |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.x estable | Framework principal del frontend |
| [Dart SDK](https://dart.dev/get-started) | Incluido con Flutter | Lenguaje del proyecto |
| [Android Studio](https://developer.android.com/studio) | Última estable | Emulador Android y herramientas de compilación |
| [Xcode](https://developer.apple.com/xcode/) | Última estable (solo macOS) | Compilación y pruebas en iOS |
| [Git](https://git-scm.com/) | Última estable | Control de versiones |
| Cuenta Firebase | — | Configuración de notificaciones push (FCM) |
 Instalación:

```bash
flutter doctor
flutter pub get
#Para ejecutar
flutter run




