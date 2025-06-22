import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

class MissionStageScreen extends StatefulWidget {
  final List<String>? players;
  final Function(Map<String, int>)? onGameComplete;
  
  const MissionStageScreen({
    super.key,
    this.players,
    this.onGameComplete,
  });

  @override
  State<MissionStageScreen> createState() => _MissionStageScreenState();
}

class _MissionStageScreenState extends State<MissionStageScreen> {
  Timer? _timer;
  int _remainingSeconds = 180; // 3 minutes per stage
  List<String> _players = [];
  Map<String, dynamic> _mission = {};
  int _currentStage = 0;
  Map<String, int> _scores = {};
  
  // NEW: Preparation phase
  bool _isPreparationPhase = true;
  int _preparationSeconds = 10; // 10 seconds preparation time
  Timer? _preparationTimer;
  
  // Drawing stage variables
  int _drawingSubStage = 0; // 0: drawing phase, 1: rating phase, 2: results
  int _currentDrawerIndex = 0;
  int _currentRaterIndex = 0;
  Map<String, Uint8List?> _drawings = {}; // Store drawings as image data
  Map<String, Map<String, int>> _drawingRatings = {}; // player -> {drawer: rating}
  ScribbleNotifier? _scribbleNotifier;
  
  // Drawing customization - now managed by ScribbleNotifier
  Color _currentPenColor = Colors.black;
  double _currentPenWidth = 3.0;
  final List<Color> _availableColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
    Colors.yellow,
    Colors.cyan,
    Colors.lime,
    Colors.indigo,
  ];
  
  // Stage 1: Pantomime words
  final List<String> _pantomimeWords = [
    'פיל', 'מצנח', 'חתול', 'גלאי עשן', 'דג', 'מיקרוסקופ', 'רופא', 'קנאה', 'דמיון', 'געגוע',
    'מגלצה', 'מתקן כביסה תלוי', 'כפפת ', 'כלי לקילוף תפוזים', 'שעון חול', 'פותחן יין', 'פנס ראש', 'מצפן'
  ];
  
  // Stage 2: Riddles
  final List<Map<String, String>> _riddles = [
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
  
  // Stage 4: Colors to find
  final List<String> _colorsToFind = [
    'אדום', 'כחול', 'ירוק', 'צהוב', 'סגול', 'כתום', 'ורוד', 'שחור', 'לבן', 'חום'
  ];
  
  String _currentPantomimeWord = '';
  List<Map<String, String>> _currentRiddles = [];
  List<String> _currentColors = [];
  int _currentColorIndex = 0;
  String _currentManager = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use widget parameters if available (new game architecture)
    if (widget.players != null) {
      _players = List<String>.from(widget.players!);
      _mission = {}; // Initialize empty mission
      _currentStage = 0;
      _scores = {}; // Initialize empty scores
      // Initialize scores for all players
      for (String player in _players) {
        _scores[player] = 0;
      }
      _initializeStage();
    } else {
      // Fallback to route arguments (old architecture)
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        _players = List<String>.from(arguments['players'] ?? []);
        _mission = arguments['mission'] ?? {};
        _currentStage = arguments['currentStage'] ?? 0;
        _scores = Map<String, int>.from(arguments['scores'] ?? {});
        _initializeStage();
      }
    }
  }

  void _initializeStage() {
    if (_currentStage < 4 && _players.isNotEmpty) {
      // Choose manager based on available players, cycling if needed
      int managerIndex = _currentStage % _players.length;
      _currentManager = _players[managerIndex];
      
      // Start with preparation phase
      _isPreparationPhase = true;
      _preparationSeconds = 10;
      
      switch (_currentStage) {
        case 0: // Pantomime
          _currentPantomimeWord = _pantomimeWords[Random().nextInt(_pantomimeWords.length)];
          break;
        case 1: // Riddles
          _currentRiddles = (_riddles..shuffle()).take(2).toList();
          break;
        case 2: // Digital Drawing
          _initializeDrawingStage();
          return; // Drawing stage handles its own preparation
        case 3: // Color finding
          _currentColors = (_colorsToFind..shuffle()).take(5).toList();
          _currentColorIndex = 0;
          break;
      }
      
      _startPreparationTimer();
    }
  }

  void _initializeDrawingStage() {
    _drawingSubStage = 0;
    _currentDrawerIndex = 0;
    _currentRaterIndex = 0;
    _drawings.clear();
    _drawingRatings.clear();
    
    // Initialize drawings map for ALL players (including manager)
    for (String player in _players) {
      _drawings[player] = null;
      _drawingRatings[player] = {};
    }
    
    // Start with preparation phase for drawing
    _isPreparationPhase = true;
    _preparationSeconds = 15; // More time for drawing preparation
    _startPreparationTimer();
  }
  
  void _startPreparationTimer() {
    _preparationTimer?.cancel();
    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (mounted) {
        setState(() {
          if (_preparationSeconds > 0) {
            _preparationSeconds--;
          } else {
            _preparationTimer?.cancel();
            _finishPreparation();
          }
        });
      }
    });
  }
  
  void _finishPreparation() {
    if (!mounted) return;
    
    setState(() {
      _isPreparationPhase = false;
    });
    
    // Start the actual game stage
    if (_currentStage == 2) {
      // Drawing stage
      if (_drawingSubStage == 0) {
        _remainingSeconds = 120; // Drawing time
      } else if (_drawingSubStage == 1) {
        _remainingSeconds = 90;  // Rating time
      }
      _startTimer();
    } else {
      // Other stages
      _remainingSeconds = 180;
      _startTimer();
    }
  }
  
  void _skipPreparation() {
    _preparationTimer?.cancel();
    _finishPreparation();
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer first
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            if (_currentStage == 2) {
              _handleDrawingStageTimeout();
            } else {
              _nextStage();
            }
          }
        });
      }
    });
  }

  void _handleDrawingStageTimeout() {
    if (_drawingSubStage == 0) {
      // Drawing phase timeout - move to next drawer or rating phase
      _nextDrawer();
    } else if (_drawingSubStage == 1) {
      // Rating phase timeout - move to next rater or results
      _nextRater();
    }
  }

  void _nextStage() {
    if (!mounted) return;
    
    if (_currentStage < 3) {
      // Move to next stage
      if (widget.onGameComplete != null) {
        // New architecture - update stage and continue in same screen
        setState(() {
          _currentStage++;
        });
        _initializeStage();
      } else {
        // Old architecture - navigate to new screen
        Navigator.pushReplacementNamed(
          context,
          '/mission',
          arguments: {
            'players': _players,
            'mission': _mission,
            'currentStage': _currentStage + 1,
            'scores': _scores,
          },
        );
      }
    } else {
      // Mission complete
      if (widget.onGameComplete != null) {
        // New architecture - call completion callback
        widget.onGameComplete!(_scores);
      } else {
        // Old architecture - navigate to results
        Navigator.pushReplacementNamed(
          context,
          '/results',
          arguments: {
            'players': _players,
            'scores': _scores,
          },
        );
      }
    }
  }

  void _nextDrawer() {
    if (!mounted) return;
    
    List<String> drawers = _players; // ALL players draw now
    
    if (_currentDrawerIndex < drawers.length - 1) {
      if (mounted) {
        setState(() {
          _currentDrawerIndex++;
          _remainingSeconds = 120; // 2 minutes for next drawer
          // Reset drawing tools for new drawer
          _currentPenColor = Colors.black;
          _currentPenWidth = 3.0;
          _scribbleNotifier?.clear();
          _scribbleNotifier?.setColor(Colors.black);
          _scribbleNotifier?.setStrokeWidth(3.0);
        });
      }
      _startTimer();
    } else {
      // All drawings complete, move to rating phase
      if (mounted) {
        setState(() {
          _drawingSubStage = 1;
          _currentRaterIndex = 0;
          _isPreparationPhase = true;
          _preparationSeconds = 8; // Quick preparation for rating phase
        });
      }
      _startPreparationTimer();
    }
  }

  void _nextRater() {
    if (!mounted) return;
    
    if (_currentRaterIndex < _players.length - 1) {
      if (mounted) {
        setState(() {
          _currentRaterIndex++;
          _isPreparationPhase = true;
          _preparationSeconds = 6; // Quick preparation for next rater
        });
      }
      _startPreparationTimer();
    } else {
      // All ratings complete, calculate scores and move to results
      _calculateDrawingScores();
      if (mounted) {
        setState(() {
          _drawingSubStage = 2;
        });
      }
      // Show results for 10 seconds then continue
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          _nextStage();
        }
      });
    }
  }

  void _calculateDrawingScores() {
    // Calculate average rating for each drawer
    for (String drawer in _drawings.keys) {
      if (_drawingRatings[drawer]!.isNotEmpty) {
        double averageRating = _drawingRatings[drawer]!.values
            .reduce((a, b) => a + b) / _drawingRatings[drawer]!.length;
        _scores[drawer] = (_scores[drawer] ?? 0) + averageRating.round();
      }
    }
  }

  void _saveCurrentDrawing() async {
    if (_scribbleNotifier != null) {
      try {
        final sketchJson = _scribbleNotifier!.currentSketch.toJson();
        final strokes = sketchJson['strokes'] as List?;
        
        if (strokes != null && strokes.isNotEmpty) {
          final imageData = await _scribbleNotifier!.renderImage();
          final signature = imageData.buffer.asUint8List();
          List<String> drawers = _players; // ALL players draw now
          String currentDrawer = drawers[_currentDrawerIndex];
          
          if (mounted) {
            setState(() {
              _drawings[currentDrawer] = signature;
            });
          }
        }
        
        _scribbleNotifier!.clear();
        _nextDrawer();
      } catch (e) {
        // If there's any error, just proceed to next drawer
        _scribbleNotifier!.clear();
        _nextDrawer();
      }
    }
  }

  void _rateDrawing(String drawer, int rating) {
    if (!mounted) return;
    
    String currentRater = _players[_currentRaterIndex];
    
    if (mounted) {
      setState(() {
        _drawingRatings[drawer]![currentRater] = rating;
      });
    }
    
    // Check if current rater has rated all drawings
    List<String> drawers = _drawings.keys.toList();
    bool hasRatedAll = drawers.every((drawer) => 
        _drawingRatings[drawer]!.containsKey(currentRater));
    
    if (hasRatedAll) {
      _nextRater();
    }
  }

  void _updatePenColor(Color color) {
    if (mounted) {
      setState(() {
        _currentPenColor = color;
        _scribbleNotifier?.setColor(color);
      });
    }
  }

  void _updatePenWidth(double width) {
    if (mounted) {
      setState(() {
        _currentPenWidth = width;
        _scribbleNotifier?.setStrokeWidth(width);
      });
    }
  }

  void _toggleEraser() {
    if (_scribbleNotifier != null) {
      _scribbleNotifier!.setEraser();
    }
  }

  void _awardPoint(String playerName) {
    if (!mounted) return;
    
    if (mounted) {
      setState(() {
        _scores[playerName] = (_scores[playerName] ?? 0) + 1;
      });
    }
  }

  void _completeCurrentStage() {
    _timer?.cancel();
    if (_currentStage == 2 && _drawingSubStage == 0) {
      // In drawing phase - save current drawing
      _saveCurrentDrawing();
    } else {
      _nextStage();
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPreparationScreen() {
    List<String> stageNames = ['פנטומימה', 'חידות', 'ציור דיגיטלי', 'חיפוש צבעים'];
    List<String> stageInstructions = [
      'המנהל יקבל מילה וצריך להציג אותה בפנטומימה!\nהשחקנים האחרים מנחשים.',
      'המנהל יקרא חידות והשחקנים מנחשים.\nנקודות למי שפותר ראשון!',
      'כל השחקנים מציירים על הטלפון.\nלאחר מכן כולם מדרגים את הציורים.',
      'המנהל יקרא צבע והשחקנים מחפשים חפצים בצבע זה.\nהראשון שמביא מקבל נקודה!',
    ];
    
    // Special instruction for drawing rating phase
    if (_currentStage == 2 && _drawingSubStage == 1) {
      stageInstructions[2] = 'עכשיו זמן לדרג את הציורים!\nתנו ציון מ-1 עד 5 לכל ציור.\nהציונים יקבעו את הנקודות הסופיות.';
      stageNames[2] = 'דירוג ציורים';
    }
    
    String stageName = _currentStage < stageNames.length ? stageNames[_currentStage] : 'שלב ${_currentStage + 1}';
    String instruction = _currentStage < stageInstructions.length ? stageInstructions[_currentStage] : '';
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50), // Green for preparation
              Color(0xFF45A049),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stage indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: Text(
                    'שלב ${_currentStage + 1} מתוך 4',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Stage icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                  ),
                  child: Icon(
                    _getStageIcon(_currentStage),
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Stage name
                Text(
                  stageName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Manager info or drawing stage info
                if (_currentStage != 2 || _drawingSubStage == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        if (_currentStage == 2 && _drawingSubStage == 1) ...[
                          // Rating phase info
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'שלב דירוג:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _players[_currentRaterIndex],
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '🔄 העבירו את הטלפון למדרג הבא',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          // Regular manager info
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_pin, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'מנהל השלב:',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentManager,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '🔄 העבירו את הטלפון למנהל החדש',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 30),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'איך משחקים:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Countdown
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_preparationSeconds',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Skip button
                TextButton(
                  onPressed: _skipPreparation,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'דלג',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.skip_next, size: 20),
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
  
  IconData _getStageIcon(int stage) {
    switch (stage) {
      case 0:
        return Icons.theater_comedy;
      case 1:
        return Icons.quiz;
      case 2:
        return Icons.brush;
      case 3:
        return Icons.palette;
      default:
        return Icons.games;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _preparationTimer?.cancel();
    _scribbleNotifier?.dispose();
    super.dispose();
  }

  Widget _buildStage1() {
    // Pantomime stage
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.theater_comedy,
                size: 60,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              const Text(
                'המילה שלך:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentPantomimeWord,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'הצג את המילה בפנטומימה!\nללא מילים, רק תנועות',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'מי ניחש נכון?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _players.where((p) => p != _currentManager).map((player) {
            return ElevatedButton(
              onPressed: () => _awardPoint(player),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(player),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStage2() {
    // Riddles stage
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.quiz,
                size: 60,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              const Text(
                'קרא את החידות לקבוצה:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 20),
              ..._currentRiddles.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> riddle = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'חידה ${index + 1}:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        riddle['question']!,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'תשובה: ${riddle['answer']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'מי ענה נכון?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _players.where((p) => p != _currentManager).map((player) {
            return ElevatedButton(
              onPressed: () => _awardPoint(player),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(player),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStage3() {
    if (_drawingSubStage == 0) {
      return _buildDrawingPhase();
    } else if (_drawingSubStage == 1) {
      return _buildRatingPhase();
    } else {
      return _buildDrawingResults();
    }
  }

  Widget _buildDrawingPhase() {
    List<String> drawers = _players; // ALL players draw now
    String currentDrawer = drawers[_currentDrawerIndex];
    
    // Initialize scribble notifier if needed
    if (_scribbleNotifier == null) {
      _scribbleNotifier = ScribbleNotifier();
      _scribbleNotifier!.setColor(_currentPenColor);
      _scribbleNotifier!.setStrokeWidth(_currentPenWidth);
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.brush,
                size: 60,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              Text(
                'תור $currentDrawer לצייר!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'כולם מציירים - אין מנהל בשלב זה',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ציירו "בית" על המסך',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              // Color palette
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    Color color = _availableColors[index];
                    bool isSelected = color == _currentPenColor;
                    
                    return GestureDetector(
                      onTap: () => _updatePenColor(color),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: isSelected ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ) : null,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pen width selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'עובי הקו:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  ...([2.0, 4.0, 6.0, 8.0].map((width) {
                    bool isSelected = width == _currentPenWidth;
                    return GestureDetector(
                      onTap: () => _updatePenWidth(width),
                      child: Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1976D2) : Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1976D2) : Colors.grey,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: width,
                            height: width,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.black,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList()),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Drawing canvas
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Scribble(
                    notifier: _scribbleNotifier!,
                    drawPen: false, // Don't show pen cursor
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ValueListenableBuilder<ScribbleState>(
                    valueListenable: _scribbleNotifier!,
                    builder: (context, state, child) {
                      final isErasing = state is Erasing;
                      return ElevatedButton.icon(
                        onPressed: () {
                          if (isErasing) {
                            _scribbleNotifier!.setColor(_currentPenColor);
                          } else {
                            _toggleEraser();
                          }
                        },
                        icon: Icon(isErasing ? Icons.edit : Icons.auto_fix_high),
                        label: Text(isErasing ? 'ציור' : 'מחק'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isErasing ? Colors.orange : Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _scribbleNotifier!.clear();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('נקה הכל'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveCurrentDrawing,
                    icon: const Icon(Icons.save),
                    label: const Text('שמור'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingPhase() {
    String currentRater = _players[_currentRaterIndex];
    List<String> drawersToRate = _drawings.keys.where((drawer) => 
        !_drawingRatings[drawer]!.containsKey(currentRater)).toList();
    
    if (drawersToRate.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'המתן לשחקן הבא...',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    String currentDrawerToRate = drawersToRate.first;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'תור $currentRater לדרג',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'דרג את הציור של $currentDrawerToRate',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              // Display drawing
              if (_drawings[currentDrawerToRate] != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _drawings[currentDrawerToRate]!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              const Text(
                'בחר ציון (1-5):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 4, 5].map((rating) {
                  return ElevatedButton(
                    onPressed: () => _rateDrawing(currentDrawerToRate, rating),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawingResults() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 60,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              const Text(
                'תוצאות תחרות הציור!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 20),
              ..._drawings.keys.map((drawer) {
                double avgRating = _drawingRatings[drawer]!.isNotEmpty 
                    ? _drawingRatings[drawer]!.values.reduce((a, b) => a + b) / _drawingRatings[drawer]!.length
                    : 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        drawer,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${avgRating.toStringAsFixed(1)} ⭐',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStage4() {
    // Color finding stage
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.palette,
                size: 60,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              const Text(
                'חיפוש צבעים!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 16),
              if (_currentColorIndex < _currentColors.length) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'מצאו חפץ בצבע: ${_currentColors[_currentColorIndex]}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'צבע ${_currentColorIndex + 1} מתוך ${_currentColors.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                const Text(
                  'כל הצבעים נמצאו!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'מי הביא ראשון?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (_currentColorIndex < _currentColors.length)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _players.where((p) => p != _currentManager).map((player) {
              return ElevatedButton(
                onPressed: () {
                  _awardPoint(player);
                  if (mounted) {
                    setState(() {
                      _currentColorIndex++;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(player),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show preparation screen if in preparation phase
    if (_isPreparationPhase) {
      return _buildPreparationScreen();
    }
    
    List<String> stageNames = ['פנטומימה', 'חידות', 'תחרות ציור דיגיטלית', 'חיפוש צבעים'];
    
    // Special handling for drawing stage subtitles
    String stageTitle = '';
    if (_currentStage == 2) {
      switch (_drawingSubStage) {
        case 0:
          stageTitle = 'ציור דיגיטלי';
          break;
        case 1:
          stageTitle = 'דירוג ציורים';
          break;
        case 2:
          stageTitle = 'תוצאות ציור';
          break;
      }
    } else {
      stageTitle = _currentStage < stageNames.length ? stageNames[_currentStage] : 'שלב ${_currentStage + 1}';
    }
    
    return Scaffold(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'שלב ${_currentStage + 1}/4',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_currentStage != 2 || _drawingSubStage != 2)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatTime(_remainingSeconds),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stage title and manager
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                stageTitle,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_currentStage != 2 || (_drawingSubStage != 0 && _drawingSubStage != 1))
                                Text(
                                  'מנהל השלב: $_currentManager',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Stage content
                        if (_currentStage == 0) _buildStage1(),
                        if (_currentStage == 1) _buildStage2(),
                        if (_currentStage == 2) _buildStage3(),
                        if (_currentStage == 3) _buildStage4(),
                        
                        const SizedBox(height: 30),
                        
                        // Continue button - only show when not in rating phase or results
                        if (_currentStage != 2 || (_drawingSubStage != 1 && _drawingSubStage != 2))
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _completeCurrentStage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _currentStage == 3 ? 'סיים משימה' : 
                                (_currentStage == 2 && _drawingSubStage == 0) ? 'שמור ציור' : 'המשך לשלב הבא',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
} 