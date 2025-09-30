import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/game.dart';

class PopupMessageWidget extends StatefulWidget {
  final void Function() onButtonPressed;

  const PopupMessageWidget({super.key, required this.onButtonPressed});

  @override
  PopupMessageWidgetState createState() => PopupMessageWidgetState();
}

class PopupMessageWidgetState extends State<PopupMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Animation duration
    );

    // Slide animation from bottom to center
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Starts off-screen at the bottom
      end: const Offset(0.0, 0.0), // Ends at its position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<GameViewModel>(context);

    // Check the popup's visibility state and trigger animation accordingly
    if (viewModel.isPopupVisible) {
      _animationController.forward(); // Slide in animation
    } else {
      _animationController.reverse(); // Slide out animation
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);

    // Determine colors and text based on whether the answer is correct
    final bool isCorrect = viewModel.isCurrentAnswerCorrect;
    final Color buttonColor = isCorrect == null
        ? Colors.blue // Default color
        : isCorrect
            ? Colors.green // Green for correct
            : Colors.red; // Red for incorrect
    final String statusText = isCorrect == null
        ? "" // No status if not answered
        : isCorrect
            ? "Correct" // Correct message
            : "Incorrect"; // Incorrect message

    return Visibility(
      visible: viewModel.isPopupVisible, // Get visibility state from ViewModel
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(217, 217, 217, 1),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the status ("Correct" or "Incorrect") at the top-left
                if (statusText.isNotEmpty)
                  Text(
                    statusText,
                    style: TextStyle(
                      color: buttonColor, // Match the button color
                      fontSize: 24.0, // Slightly larger font
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8.0), // Space between status and message

                // Display the popup message
                Text(
                  viewModel.popupMessage, // Get the message from ViewModel
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16.0),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.isPopupLoading
                        ? null // Disable button when loading
                        : () async {
                            widget.onButtonPressed();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          buttonColor, // Button color based on correctness
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: viewModel.isPopupLoading
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : Text(
                            viewModel.isLast ? "結束" : "繼續",
                            style: const TextStyle(fontSize: 16.0),
                          ),
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
