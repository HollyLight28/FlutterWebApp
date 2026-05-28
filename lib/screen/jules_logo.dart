import 'package:flutter/material.dart';

class JulesLogo extends StatelessWidget {
  final double size;
  const JulesLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.psychology, // Використовуємо іконку психології/мозку як плейсхолдер для AI
          size: size * 0.7,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
