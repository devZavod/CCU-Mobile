# CCU Mobile - Gestión Universitaria Inteligente 🎓

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org/)

**CCU Mobile** es una plataforma integral diseñada para estudiantes universitarios, enfocada en la optimización de la vida académica. Combina una aplicación móvil moderna con un backend ligero para gestionar horarios, calificaciones, tareas y perfiles de usuario de manera eficiente.

---

## Módulos de la Aplicación

La aplicación se divide en módulos clave diseñados para cubrir cada aspecto del rendimiento estudiantil:

### 1. Gestión Académica
* **Horario Dinámico:** Visualización y registro de clases, profesores y salones con indicadores de tiempo real.
* **Calculadora de Rendimiento:** Herramientas avanzadas para calcular:
    * Promedio Ponderado Acumulado (PPA).
    * Notas necesarias para aprobar el corte o la materia.
    * Simuladores de metas académicas.
* **Gestor de Tareas y Notas:** Seguimiento de entregas y control de calificaciones por corte.

### 2. Autenticación y Perfil
* **Sistema de Usuarios:** Registro seguro e inicio de sesión con persistencia de datos (Shared Preferences).
* **Personalización:** Subida de fotos de perfil directamente desde la cámara o galería del móvil.
* **Seguridad:** Módulo de cambio de contraseña con validación de credenciales actuales.

### 3. Personalización de Interfaz
* **Modo Oscuro/Claro:** Soporte nativo para temas dinámicos que se adaptan a la preferencia del usuario.
* **Diseño Moderno:** Basado en una paleta de colores profesional (Azul CCU) y componentes de Material Design 3.

---

## 🛠️ Tecnologías Utilizadas

### Frontend (Mobile)
* **Framework:** [Flutter](https://flutter.dev/)
* **Lenguaje:** Dart
* **Gestión de Estado:** `StatefulWidgets` con integración de `SharedPreferences`.
* **Networking:** `http` para comunicación RESTful.
* **Multimedia:** `image_picker` para gestión de fotos de perfil.

### Backend (Server)
* **Framework:** [FastAPI](https://fastapi.tiangolo.com/)
* **Lenguaje:** Python 3.x
* **Servidor:** Uvicorn
* **Persistencia:** JSON (Base de datos ligera) y almacenamiento local para archivos estáticos.

---

## Estructura General del Proyecto

<pre>
CCU-Project/
├── ccu_mobile/            # Proyecto Flutter completo
│   ├── lib/
│   │   ├── core/          # Temas, colores y constantes
│   │   ├── features/      # Módulos: Auth, Schedule, Calculations
│   │   └── main.dart      # Punto de entrada
│   └── pubspec.yaml
├── backend/               # Servidor FastAPI
    ├── main.py            # Lógica central y endpoints
    ├── users.json         # Base de datos de prueba
    └── uploads/           # Fotos de perfil almacenadas
</pre>   

### Autores: Josh4OP, Luis-Salas-Reyes, devZavod
