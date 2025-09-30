import 'package:flutter/material.dart';

class ChineseCharacterDisplay extends StatelessWidget {
  final String input;

  const ChineseCharacterDisplay({super.key, required this.input});

  /// Factory method to create a widget for each character in the input string
  Widget _buildCharacterWidget(String character) {
    if (character == '？' || character == '?') {
      // Return the placeholder box for the Chinese question mark
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white60,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    } else {
      // Return the word display box for any other character
      return FittedBox(
        fit: BoxFit.scaleDown, // Scale down the text to fit the space
        child: Text(
          character,
          style: const TextStyle(
            fontSize: 36, // Base font size
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate a list of widgets for each character in the input string
    List<Widget> characterWidgets =
        input.split('').map((char) => _buildCharacterWidget(char)).toList();

    // Ensure the container resizes dynamically and text wraps or shrinks accordingly
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double containerWidth =
            constraints.maxWidth > 800 ? 800 : constraints.maxWidth;

        return Container(
          width: containerWidth, // Max width of 800px
          padding: const EdgeInsets.all(20), // Padding around the display
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10, // Horizontal spacing between characters
            runSpacing: 10, // Vertical spacing if the characters overflow
            children: characterWidgets,
          ),
        );
      },
    );
  }
}
