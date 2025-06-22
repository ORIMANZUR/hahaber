import 'package:flutter/material.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final List<TextEditingController> _controllers = [];
  final List<String> _players = [];
  final int _minPlayers = 3;
  final int _maxPlayers = 6;

  @override
  void initState() {
    super.initState();
    // Start with minimum required players
    for (int i = 0; i < _minPlayers; i++) {
      _controllers.add(TextEditingController());
      _players.add('');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_players.length < _maxPlayers) {
      setState(() {
        _controllers.add(TextEditingController());
        _players.add('');
      });
    }
  }

  void _removePlayer(int index) {
    if (_players.length > _minPlayers) {
      setState(() {
        _controllers[index].dispose();
        _controllers.removeAt(index);
        _players.removeAt(index);
      });
    }
  }

  void _updatePlayer(int index, String value) {
    setState(() {
      _players[index] = value;
    });
  }

  bool _canProceed() {
    final validPlayers = _players.where((name) => name.trim().isNotEmpty).toList();
    return validPlayers.length >= _minPlayers;
  }

  void _proceedToGame() {
    final validPlayers = _players.where((name) => name.trim().isNotEmpty).toList();
    
    if (validPlayers.length >= _minPlayers) {
      Navigator.pushNamed(
        context,
        '/games',
        arguments: {
          'players': validPlayers,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('רישום שחקנים'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.group_add,
                        size: 60,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'רישום המשתתפים',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'רשמו ${_minPlayers}-${_maxPlayers} שחקנים למשימה',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Players list
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'שמות השחקנים:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: _players.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    // Player number
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16),
                                    
                                    // Name input
                                    Expanded(
                                      child: TextField(
                                        controller: _controllers[index],
                                        onChanged: (value) => _updatePlayer(index, value),
                                        decoration: InputDecoration(
                                          hintText: 'שם שחקן ${index + 1}',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Remove button (only if more than minimum)
                                    if (_players.length > _minPlayers) ...[
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: () => _removePlayer(index),
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Add player button
                        if (_players.length < _maxPlayers)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 16),
                            child: OutlinedButton.icon(
                              onPressed: _addPlayer,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'הוסף שחקן',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canProceed() ? _proceedToGame : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canProceed() 
                          ? Colors.white 
                          : Colors.grey[400],
                      foregroundColor: _canProceed() 
                          ? const Color(0xFF1976D2) 
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _canProceed() ? 8 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          size: 24,
                          color: _canProceed() 
                              ? const Color(0xFF1976D2) 
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'המשך למשימה',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Info text
                if (!_canProceed())
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'נדרשים לפחות $_minPlayers שחקנים עם שמות',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 