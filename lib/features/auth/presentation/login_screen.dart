import 'package:flutter/material.dart';
import '../../auth/domain/user.dart';
import 'register_screen.dart';
import 'home_screen.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const LoginScreen({super.key, required this.onToggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String _message = "";
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final user = User(email: email, password: password);

    if (!user.isValidEmail()) {
      setState(() {
        _message = "Correo institucional inválido.";
        _isError = true;
      });
      return;
    }

    if (!user.isValidPassword()) {
      setState(() {
        _message = "La contraseña debe tener mínimo 8 caracteres.";
        _isError = true;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/login"), // EMULADOR
        //Uri.parse("http://xxx.xxx.x.xx:8000/login"), // CELULAR REAL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"emailusu": email, "password": password}),
      );

      final data = json.decode(response.body);

      if (data["success"] == true) {
        setState(() {
          _message = "Login exitoso";
          _isError = false;
        });

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() {
          _message = data["message"] ?? "Credenciales incorrectas";
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error de conexión: $e";
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.brightness_6),
                      onPressed: widget.onToggleTheme,
                    ),
                  ),
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset("assets/images/logo.png", height: 90),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Bienvenido a CCU",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Calendario y Calculadora Universitaria",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) {
                      if (_message.isNotEmpty) setState(() => _message = "");
                    },
                    decoration: InputDecoration(
                      labelText: "Correo institucional",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (_) {
                      if (_message.isNotEmpty) setState(() => _message = "");
                    },
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Ingresar",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_message.isNotEmpty)
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Crear cuenta",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
