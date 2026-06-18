import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:orma_dose/views/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return MaterialApp(
      title: 'Orma Dose',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigation(),
    );
  }
}
