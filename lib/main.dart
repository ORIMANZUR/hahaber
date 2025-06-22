import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/players_screen.dart';
import 'screens/game_selection_screen.dart';
import 'screens/waiting_screen.dart';
import 'screens/mission_stage_screen.dart';
import 'screens/scoring_screen.dart';
import 'screens/results_screen.dart';

void main() {
  runApp(const MamdTeamApp());
}

class MamdTeamApp extends StatelessWidget {
  const MamdTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'צוות ממ"ד - משימה משפחתית',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/players': (context) => const PlayersScreen(),
        '/games': (context) => const GameSelectionScreen(),
        '/waiting': (context) => const WaitingScreen(),
        '/mission': (context) => const MissionStageScreen(),
        '/scoring': (context) => const ScoringScreen(),
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}
