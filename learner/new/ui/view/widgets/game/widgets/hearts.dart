import 'package:flutter/material.dart';

class LivesDisplay extends StatelessWidget {
  final int maxHealth; // The maximum health (total hearts)
  final int currentHealth; // The current health (remaining hearts)

  const LivesDisplay({
    super.key,
    required this.maxHealth,
    required this.currentHealth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
        maxHealth, // Total number of hearts to display
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(
            Icons.favorite,
            // Determine the color based on the current health
            color: index < currentHealth ? Colors.pinkAccent : Colors.grey,
            size: 28,
          ),
        ),
      ),
    );
  }
}
