import 'package:flutter/material.dart';
import 'package:gamble_game/pages/game_page.dart';
import 'package:gamble_game/pages/game_page2.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withOpacity(0.7),
              Colors.blue.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Gamble Game',
                style: TextStyle(
                  fontFamily: 'manga',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(5.0, 5.0),
                  )],
                ),
              ),
              const SizedBox(height: 50),
              _gameButton(
                context,
                '50/50 Game',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GamePage(title: '50/50 Game'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _gameButton(
                context,
                'Dragon Gate Game',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GamePage2(title: 'Dragon Gate Game'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameButton(BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'manga',
          fontSize: 24,
          color: Colors.purple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
