import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/handover/ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HomeHandoverApp()));
}

class HomeHandoverApp extends ConsumerWidget {
  const HomeHandoverApp({super.key});

  static const Color accentCopper = Color(0xFFB45309);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'HomeHandover',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accentCopper),
      darkTheme: AppTheme.dark(accent: accentCopper),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
