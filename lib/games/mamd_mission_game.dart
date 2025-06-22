import 'package:flutter/material.dart';
import 'base_game.dart';
import '../screens/mission_stage_screen.dart';

class MamdMissionGame extends BaseGame {
  MamdMissionGame()
      : super(
          id: 'mamd_family_mission',
          name: 'משימה משפחתית - צוות ממ"ד',
          description: 'משחק של 4 שלבים: פנטומימה, חידות, ציור דיגיטלי וציד צבעים',
          emoji: '🎪',
          minPlayers: 3,
          maxPlayers: 6,
          estimatedDuration: const Duration(minutes: 15),
          stages: [
            'פנטומימה',
            'חידות',
            'ציור דיגיטלי',
            'ציד צבעים',
          ],
        );

  @override
  Widget getGameScreen({
    required List<String> players,
    required Function(Map<String, int>) onGameComplete,
  }) {
    return MissionStageScreen(
      players: players,
      onGameComplete: onGameComplete,
    );
  }

  // Game-specific methods
  List<String> getPantomimeWords() {
    return [
      'פיל', 'מצנח', 'חתול', 'גלאי עשן', 'דג', 'מיקרוסקופ', 'רופא', 'קנאה', 'דמיון', 'געגוע',
      'מגלצה', 'מתקן כביסה תלוי', 'כפפת ', 'כלי לקילוף תפוזים', 'שעון חול', 'פותחן יין', 'פנס ראש', 'מצפן'
    ];
  }

  List<Map<String, String>> getRiddles() {
    return [
      {
        'question': 'מה זה הדבר שכולם רואים אותי אבל אני לא רואה אף אחד?',
        'answer': 'עין'
      },
      {
        'question': 'מה זה הדבר שיש לו שיניים אבל הוא לא נושך?',
        'answer': 'מסרק'
      },
      {
        'question': 'מה זה הדבר שכשהוא רטוב הוא מייבש?',
        'answer': 'מגבת'
      },
      {
        'question': 'מה זה הדבר שגדל כלפי מטה?',
        'answer': 'נטיפים'
      },
      {
        'question': 'מה זה הדבר שיש לו פה אבל הוא לא מדבר?',
        'answer': 'נהר'
      },
      {
        'question': 'מה זה הדבר שכולם צריכים אותו אבל איש לא רוצה אותו?',
        'answer': 'עצה טובה'
      },
    ];
  }

  List<String> getColorsToFind() {
    return [
      'אדום', 'כחול', 'ירוק', 'צהוב', 'סגול', 'כתום', 'ורוד', 'שחור', 'לבן', 'חום'
    ];
  }

  // Drawing prompts for the digital drawing stage
  List<String> getDrawingPrompts() {
    return [
      'בית החלומות שלכם',
      'חיית המחמד המושלמת',
      'הרפתקה במדבר',
      'ארוחת ערב משפחתית',
      'יום שלג',
      'חופשת קיץ',
      'מכונית עתידנית',
      'עץ קסום',
    ];
  }

  @override
  bool canPlayWithPlayerCount(int playerCount) {
    // Override to provide specific logic for this game
    return playerCount >= 3 && playerCount <= 8; // More flexible than base
  }
} 