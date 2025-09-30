import 'package:flutter/material.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/utils/logger.dart';

class PairingCardWidget extends StatefulWidget {
  final MultiChoiceOption option;
  final Function(MultiChoiceOption) onClick;

  const PairingCardWidget({
    super.key,
    required this.option,
    required this.onClick,
  });

  @override
  State<PairingCardWidget> createState() => PairingCardWidgetState();
}

class PairingCardWidgetState extends State<PairingCardWidget> {
  Color _cardColor = Colors.black; // Default color
  Color _borderColor = Colors.transparent; // Default border color
  double _borderWidth = 0.0; // Default border width
  bool _isDisabled = false; // Whether the card is disabled
  Duration _animationDuration =
      const Duration(milliseconds: 200); // Default animation duration

  /// Handle when the card is marked as wrong
  void onWrong() async {
    AppLogger.debug("Card marked as wrong: ${widget.option.text}");

    // Set animation for turning red
    setState(() {
      _animationDuration = const Duration(
          milliseconds: 300); // Shorter animation for turning red
      _cardColor = Colors.red; // Wrong color
      _borderColor = Colors.redAccent; // Border color for wrong state
      _borderWidth = 2.0; // Border width for wrong state
    });

    // Fade back to black with a longer animation duration
    await Future.delayed(
        const Duration(milliseconds: 300)); // Wait for red animation to finish
    if (mounted) {
      setState(() {
        _animationDuration = const Duration(
            milliseconds: 700); // Longer animation for fading back
        _cardColor = Colors.black; // Reset to default color
        _borderColor = Colors.transparent; // Reset border color
        _borderWidth = 0.0; // Reset border width
      });
    }
  }

  /// Handle when the card is marked as correct
  void onCorrect() {
    setState(() {
      _animationDuration =
          const Duration(milliseconds: 200); // Default animation duration
      _cardColor = Colors.green; // Correct color
      _borderColor = Colors.greenAccent; // Border color for correct state
      _borderWidth = 2.0; // Border width for correct state
      _isDisabled = true; // Disable card after correct pairing
    });
  }

  /// Handle when the selection is canceled
  void onCancel() {
    setState(() {
      _animationDuration =
          const Duration(milliseconds: 200); // Default animation duration
      _cardColor = Colors.black; // Reset to default color
      _borderColor = Colors.transparent; // Reset border color
      _borderWidth = 0.0; // Reset border width
    });
  }

  /// Disable the card (e.g., when the game ends)
  void disableCard() {
    setState(() {
      _isDisabled = true;
    });
  }

  void onSelect() {
    setState(() {
      _animationDuration =
          const Duration(milliseconds: 200); // Default animation duration
      _cardColor = Colors.blueAccent; // Change color on selection
      _borderColor = Colors.white; // Border color for selection
      _borderWidth = 2.0; // Border width for selection
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1, // Aspect ratio 1:1 (square)
      child: GestureDetector(
        onTap: _isDisabled
            ? null
            : () => widget
                .onClick(widget.option), // Disable tap if card is disabled
        child: AnimatedContainer(
          duration: _animationDuration, // Dynamic animation duration
          margin: const EdgeInsets.all(10), // Spacing between cards
          decoration: BoxDecoration(
            color: _cardColor, // Dynamic background color
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _borderColor, // Dynamic border color
              width: _borderWidth, // Dynamic border width
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              // Background with opacity
              Opacity(
                opacity: 0.5, // Background opacity
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Text and other content remain fully opaque
              Center(
                child: Text(
                  widget.option.text ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, // Fully opaque text
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
