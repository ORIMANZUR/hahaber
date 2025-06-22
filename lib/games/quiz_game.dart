import 'package:flutter/material.dart';
import 'base_game.dart';

// EXAMPLE: Future Quiz Game - shows how easy it is to add new games!
class QuizGame extends BaseGame {
  QuizGame()
      : super(
          id: 'family_quiz',
          name: 'חידון משפחתי',
          description: 'חידון עם שאלות מגוונות לכל המשפחה',
          emoji: '🧠',
          minPlayers: 2,
          maxPlayers: 8,
          estimatedDuration: const Duration(minutes: 10),
          stages: [
            'שאלות היכרות',
            'שאלות כללות',
            'שאלות בונוס',
          ],
        );

  @override
  Widget getGameScreen({
    required List<String> players,
    required Function(Map<String, int>) onGameComplete,
  }) {
    // This would return a QuizGameScreen when implemented
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'חידון משפחתי',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'בקרוב!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Game-specific data
  List<Map<String, dynamic>> getQuizQuestions() {
    return [
      {
        'question': 'מה הצבע של השמש?',
        'options': ['כחול', 'צהוב', 'אדום', 'ירוק'],
        'correct': 1,
        'points': 10,
      },
      {
        'question': 'כמה רגליים יש לעכביש?',
        'options': ['6', '8', '10', '12'],
        'correct': 1,
        'points': 10,
      },
      // Add more questions...
    ];
  }
}

// EXAMPLE: Future Treasure Hunt Game
class TreasureHuntGame extends BaseGame {
  TreasureHuntGame()
      : super(
          id: 'treasure_hunt',
          name: 'ציד האוצר המשפחתי',
          description: 'מצאו רמזים ופתרו חידות לגילוי האוצר',
          emoji: '🗺️',
          minPlayers: 2,
          maxPlayers: 6,
          estimatedDuration: const Duration(minutes: 20),
          stages: [
            'מציאת הרמז הראשון',
            'פתרון החידה',
            'גילוי האוצר',
          ],
        );

  @override
  Widget getGameScreen({
    required List<String> players,
    required Function(Map<String, int>) onGameComplete,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 100, color: Colors.brown),
            SizedBox(height: 20),
            Text(
              'ציד האוצר המשפחתי',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'בקרוב!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
} 