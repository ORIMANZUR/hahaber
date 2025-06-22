import 'package:flutter/material.dart';
import '../games/game_manager.dart';
import '../games/base_game.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  List<String> _players = [];
  late GameManager _gameManager;

  @override
  void initState() {
    super.initState();
    _gameManager = GameManager();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _players = List<String>.from(arguments['players'] ?? []);
    }
  }

  void _startGame(BaseGame game) {
    // For now, we'll use the old navigation system for compatibility
    // In the future, this will launch the game directly
    Navigator.pushNamed(
      context,
      '/waiting',
      arguments: {
        'players': _players,
        'mission': {
          'name': game.name,
          'description': game.description,
          'emoji': game.emoji,
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<BaseGame> availableGames = _gameManager.getGamesForPlayerCount(_players.length);

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A5F),
      appBar: AppBar(
        title: const Text(
          'בחירת משחק',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      'בחרו את המשחק שלכם!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'שחקנים: ${_players.join(", ")}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFFFD700),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Games list
              Expanded(
                child: ListView.builder(
                  itemCount: availableGames.length,
                  itemBuilder: (context, index) {
                    final game = availableGames[index];
                    return _buildGameCard(game);
                  },
                ),
              ),
              
              // Future games preview
              if (availableGames.length == 1) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.construction,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'משחקים נוספים בפיתוח: חידון משפחתי, ציד אוצר, משחק סיפורים ועוד!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(BaseGame game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startGame(game),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Game emoji/icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      game.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                
                const SizedBox(width: 15),
                
                // Game info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        game.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 14,
                            color: const Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${game.minPlayers}-${game.maxPlayers} שחקנים',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Icon(
                            Icons.timer,
                            size: 14,
                            color: const Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${game.estimatedDuration.inMinutes} דקות',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 