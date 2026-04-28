import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AIStudyHelperApp(),
    ),
  );
}

class AIStudyHelperApp extends StatelessWidget {
  const AIStudyHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Nova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS Blue
          primary: const Color(0xFF007AFF),
          secondary: const Color(0xFF5856D6), // iOS Purple
          surface: Colors.white,
          background: const Color(0xFFF2F2F7), // iOS Background Gray
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFF2F2F7),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
