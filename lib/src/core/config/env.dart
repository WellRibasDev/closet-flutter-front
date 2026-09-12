import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get apiUrl {
    final value = dotenv.env['API_URL']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('API_URL não definida no .env');
    }
    return value;
  }
}
