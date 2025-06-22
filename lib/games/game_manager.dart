import 'base_game.dart';
import 'mamd_mission_game.dart';

class GameManager {
  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();

  // List of all available games
  final List<BaseGame> _availableGames = [
    MamdMissionGame(),
    // Future games will be added here:
    // QuizGame(),
    // TreasureHuntGame(),
    // StorytellingGame(),
    // etc...
  ];

  // Get all available games
  List<BaseGame> get availableGames => List.unmodifiable(_availableGames);

  // Get game by ID
  BaseGame? getGameById(String id) {
    try {
      return _availableGames.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get games suitable for player count
  List<BaseGame> getGamesForPlayerCount(int playerCount) {
    return _availableGames
        .where((game) => game.canPlayWithPlayerCount(playerCount))
        .toList();
  }

  // Add a new game (for future extensibility)
  void addGame(BaseGame game) {
    if (!_availableGames.any((g) => g.id == game.id)) {
      _availableGames.add(game);
    }
  }

  // Get default game (current MAMD mission)
  BaseGame get defaultGame => _availableGames.first;

  // Get game categories (for future organization)
  Map<String, List<BaseGame>> getGamesByCategory() {
    return {
      'משימות משפחתיות': _availableGames.where((g) => g.id.contains('family')).toList(),
      'משחקי חשיבה': _availableGames.where((g) => g.id.contains('quiz')).toList(),
      'משחקי יצירתיות': _availableGames.where((g) => g.id.contains('creative')).toList(),
      // Add more categories as needed
    };
  }
} 