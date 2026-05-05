class User {
  final String email;
  final String password;

  User({required this.email, required this.password});

  bool isValidEmail() {
    // Ajusta el dominio institucional de tu universidad
    return RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email);
  }

  bool isValidPassword() {
    return password.length >= 8;
  }
}