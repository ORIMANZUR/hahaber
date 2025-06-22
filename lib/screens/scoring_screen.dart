import 'package:flutter/material.dart';

class ScoringScreen extends StatelessWidget {
  const ScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ניקוד"),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "מסך ניקוד - לא בשימוש כרגע",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
} 