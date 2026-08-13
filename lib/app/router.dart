import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/collections/collections_screen.dart';
import '../features/ayah_finder/ayah_finder_screen.dart';
import '../features/community/community_screens.dart';
import '../features/daily_ayah/daily_ayah_screen.dart';
import '../features/dhikr/dhikr_screens.dart';
import '../features/dua/dua_screen.dart';
import '../features/esma/esma_screen.dart';
import '../features/fasting/fasting_screen.dart';
import '../features/holy_days/holy_days_screen.dart';
import '../features/home/home_screens.dart';
import '../features/khatm/khatm_screen.dart';
import '../features/learning/learning_screens.dart';
import '../features/moderation/moderation_screen.dart';
import '../features/onboarding/onboarding_screens.dart';
import '../features/prayer/prayer_screen.dart';
import '../features/progress/progress_screens.dart';
import '../features/qibla/qibla_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/quran/quran_screens.dart';
import '../features/studio/studio_screens.dart';
import '../features/tools/tools_screens.dart';
import '../features/topical/topical_screen.dart';
import '../ui/core/page_transitions.dart';
import '../ui/core/widgets.dart';
import 'feature_catalog.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// 24 özelliğin route → ekran eşlemesi. Eksik kalan olursa FeaturePlaceholder.
final Map<String, WidgetBuilder> _featureBuilders = {
  '/prayer': (_) => const PrayerScreen(),
  '/dhikr': (_) => const DhikrScreen(),
  '/tasbihat': (_) => const TasbihatScreen(),
  '/dua': (_) => const DuaScreen(),
  '/esma': (_) => const EsmaScreen(),
  '/fasting': (_) => const FastingScreen(),
  '/holy-days': (_) => const HolyDaysScreen(),
  '/qibla': (_) => const QiblaScreen(),
  '/quran': (_) => const QuranScreen(),
  '/progress': (_) => const ProgressScreen(),
  '/daily-ayah': (_) => const DailyAyahScreen(),
  '/topical': (_) => const TopicalScreen(),
  '/miracles': (_) => const MiraclesScreen(),
  '/memorize': (_) => const MemorizeScreen(),
  '/juz-tracker': (_) => const JuzTrackerScreen(),
  '/stories': (_) => const StoriesScreen(),
  '/tajweed': (_) => const TajweedScreen(),
  '/quiz': (_) => const SurahQuizScreen(),
  '/studio': (_) => const StudioScreen(),
  '/khatm': (_) => const KhatmScreen(),
  '/collections': (_) => const CollectionsScreen(),
  '/ayah-finder': (_) => const AyahFinderScreen(),
  '/zakat': (_) => const ZakatScreen(),
  '/mosque': (_) => const MosqueScreen(),
  '/donate': (_) => const DonateScreen(),
  '/dream': (_) => const DreamScreen(),
};

/// go_router — 5 sekmeli StatefulShellRoute + tam ekran özellik route'ları.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      // Akış geçişleri (yön taşımayan): fade-through.
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) =>
            AppPageTransitions.fadeThrough(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (_, state) =>
            AppPageTransitions.fadeThrough(key: state.pageKey, child: const SetupScreen()),
      ),
      // Detay/tam ekran geçişleri (ileri-geri yön): shared-axis.
      GoRoute(
        path: '/auth',
        pageBuilder: (_, state) =>
            AppPageTransitions.sharedAxis(key: state.pageKey, child: const AuthScreen()),
      ),
      GoRoute(
        path: '/features',
        pageBuilder: (_, state) => AppPageTransitions.sharedAxis(
            key: state.pageKey, child: const FeaturesCatalogScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => AppPageTransitions.sharedAxis(
            key: state.pageKey, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/blocked-users',
        pageBuilder: (_, state) => AppPageTransitions.sharedAxis(
            key: state.pageKey, child: const BlockedUsersScreen()),
      ),
      GoRoute(
        path: '/moderation',
        pageBuilder: (_, state) => AppPageTransitions.sharedAxis(
            key: state.pageKey, child: const ModerationScreen()),
      ),
      // 5 sekmeli kabuk — her sekme kendi navigasyon yığınını korur.
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/feed', builder: (_, _) => const FeedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/messages', builder: (_, _) => const MessagesScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const UserProfileScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (_, state) => AppPageTransitions.sharedAxis(
                      key: state.pageKey,
                      child: UserProfileScreen(userId: state.pathParameters['id']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // 24 özellik ekranı (tam ekran, sekme dışı) — shared-axis geçişi.
      ...kFeatures.map(
        (f) => GoRoute(
          path: f.route,
          parentNavigatorKey: _rootKey,
          pageBuilder: (context, state) {
            final builder = _featureBuilders[f.route];
            final child = builder != null
                ? builder(context)
                : FeaturePlaceholder(
                    title: f.title,
                    description: f.description,
                    icon: f.icon,
                  );
            return AppPageTransitions.sharedAxis(key: state.pageKey, child: child);
          },
        ),
      ),
    ],
  );
});
