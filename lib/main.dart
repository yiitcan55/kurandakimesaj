import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'data/repositories.dart';

/// Kur'an'da ki Mesaj — uygulama giriş noktası.
/// bootstrap() prefs/Supabase/drift'i hazırlar; ProviderScope override'ları
/// (DI konteyneri) ile KuranApp başlatılır.
Future<void> main() async {
  final (prefs, db) = await bootstrap();
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const KuranApp(),
    ),
  );
}
