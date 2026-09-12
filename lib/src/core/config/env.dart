import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  /// Fallback de produção — evita APK sem `.env` ou URL antiga de LAN.
  static const String productionApiUrl = 'https://closet-back.vercel.app/api';

  static String get apiUrl {
    final raw = dotenv.env['API_URL']?.trim();
    final value = (raw == null || raw.isEmpty) ? productionApiUrl : raw;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
