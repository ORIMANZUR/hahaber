import 'package:flutter/material.dart';

// Base class for all games
abstract class BaseGame {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int minPlayers;
  final int maxPlayers;
  final Duration estimatedDuration;
  final List<String> stages;

  BaseGame({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedDuration,
    required this.stages,
  });

  // Abstract methods that each game must implement
  Widget getGameScreen({
    required List<String> players,
    required Function(Map<String, int>) onGameComplete,
  });

  // Virtual methods that games can override
  bool canPlayWithPlayerCount(int playerCount) {
    return playerCount >= minPlayers && playerCount <= maxPlayers;
  }

  // Game info for display
  Map<String, dynamic> getGameInfo() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'duration': estimatedDuration.inMinutes,
      'stages': stages,
    };
  }
}

// Game result class
class GameResult {
  final Map<String, int> playerScores;
  final String winnerName;
  final int winnerScore;
  final DateTime completedAt;
  final Duration gameDuration;

  GameResult({
    required this.playerScores,
    required this.winnerName,
    required this.winnerScore,
    required this.completedAt,
    required this.gameDuration,
  });
} 