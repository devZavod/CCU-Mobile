import 'package:shared_preferences/shared_preferences.dart';

class GradeConfig {
  static Future<double> getMaxGrade() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('maxGrade') ?? 5.0;
  }

  static Future<double> getMinPassingGrade() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('minPassingGrade') ?? 3.0;
  }

  static Future<double> getMinValidGrade() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('minValidGrade') ?? 0.0;
  }
}