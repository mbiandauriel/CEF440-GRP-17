import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static const defaultModel = 'openai/gpt-4o-mini';
  static const fallbackModel = 'google/gemini-2.5-flash';
  static const defaultVisionModel = 'openai/gpt-4o-mini';

  // Supabase (deferred — plug in when auth is added)
  // static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  // static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  static String get openRouterModel =>
      dotenv.env['OPENROUTER_MODEL'] ?? defaultModel;

  static List<String> get openRouterModelCandidates {
    final envModel = dotenv.env['OPENROUTER_MODEL'];
    return {
      if (envModel != null && envModel.trim().isNotEmpty) envModel.trim(),
      defaultModel,
      fallbackModel,
    }.toList();
  }

  static String get openRouterVisionModel =>
      dotenv.env['OPENROUTER_VISION_MODEL'] ?? defaultVisionModel;

  static bool get hasOpenRouterKey =>
      openRouterApiKey.isNotEmpty &&
      openRouterApiKey != 'sk-or-v1-your-key-here';
}
