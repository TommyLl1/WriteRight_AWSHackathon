// import 'package:flutter/material.dart';

// class PopupMessageWidget extends StatefulWidget {
//   final void Function(bool isLast) onButtonPressed;

//   const PopupMessageWidget({Key? key, required this.onButtonPressed})
//       : super(key: key);

//   @override
//   PopupMessageWidgetState createState() => PopupMessageWidgetState();
// }

// class PopupMessageWidgetState extends State<PopupMessageWidget>
//     with SingleTickerProviderStateMixin {
//   String _message = "";
//   bool _isVisible = false;
//   bool _isLast = false; // Determines button behavior
//   Color _buttonColor = Colors.blue; // Default button color
//   String _status = ""; // "Correct" or "Wrong"
//   bool _isLoading = false; // Tracks if the button is in a loading state

//   late AnimationController _animationController;
//   late Animation<Offset> _offsetAnimation;
//   final GlobalKey _buttonKey = GlobalKey(); // Key for the button

//   @override
//   void initState() {
//     super.initState();

//     // Initialize the animation controller for slide effect
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300), // Duration of the slide animation
//       vsync: this,
//     );

//     // Slide animation from bottom to center
//     _offsetAnimation = Tween<Offset>(
//       begin: const Offset(0.0, 1.0), // Starts off-screen at the bottom
//       end: const Offset(0.0, 0.0), // Ends at its position
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   // Show a generic popup (not used for "Correct" or "Wrong")
//   void show(String message, bool isLast) {
//     _displayPopup(message, Colors.blue, "", isLast);
//   }

//   // Show a green popup with "Correct" at the top-left
//   void showCorrect(String message, bool isLast) {
//     _displayPopup(message, Colors.green, "正確", isLast);
//   }

//   // Show a red popup with "Wrong" at the top-left
//   void showWrong(String message, bool isLast) {
//     _displayPopup(message, Colors.red, "錯誤", isLast);
//   }

//   // Hide the popup
//   void hide() {
//     _animationController.reverse().then((_) {
//       setState(() {
//         _isVisible = false;
//         _message = "";
//         _status = "";
//         _isLoading = false; // Reset loading state when hidden
//       });
//     });
//   }

//   // Internal method to display the popup
//   void _displayPopup(String message, Color buttonColor, String status, bool isLast) {
//     setState(() {
//       _message = message;
//       _buttonColor = buttonColor; // Set the button color
//       _status = status; // Set "Correct" or "Wrong"
//       _isLast = isLast;
//       _isVisible = true;
//     });

//     _animationController.forward(
//       from: 0.0, // Start the animation from the beginning
//     );
//   }

//   // Helper to get a paler version of the button color
//   Color _getPaleColor(Color color) {
//     return color.withAlpha(125); // Adjust opacity to make it paler
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isVisible) return const SizedBox.shrink(); // Invisible when not active

//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: SlideTransition(
//         position: _offsetAnimation,
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.9,
//           margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 50), // Margin for spacing
//           padding: const EdgeInsets.all(16.0),
//           decoration: BoxDecoration(
//             color: const Color.fromRGBO(217, 217, 217, 1),
//             borderRadius: BorderRadius.circular(15.0),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left
//             children: [
//               // "Correct" or "Wrong" at the top-left
//               if (_status.isNotEmpty)
//                 Text(
//                   _status,
//                   style: TextStyle(
//                     color: _buttonColor, // Matches the button color
//                     fontSize: 24.0, // Larger font size
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),

//               const SizedBox(height: 8.0), // Space between status and message

//               // Message below the status
//               Text(
//                 _message,
//                 style: const TextStyle(
//                   color: Colors.black, // Black text for the message
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.normal,
//                 ),
//                 textAlign: TextAlign.start,
//               ),

//               const SizedBox(height: 16.0), // Space between message and button

//               // Confirm button taking the full width
//               SizedBox(
//                 width: double.infinity, // Full width of the popup
//                 child: ElevatedButton(
//                   key: _buttonKey,
//                   onPressed: _isLoading
//                       ? null // Disable the button when loading
//                       : () async {
//                           if (_isLast) {
//                             setState(() {
//                               _isLoading = true; // Start loading
//                             });

//                             // Simulate a delay (e.g., API call or logic)
//                             await Future.delayed(const Duration(seconds: 2));

//                             setState(() {
//                               _isLoading = false; // Stop loading after delay
//                             });
//                           }

//                           widget.onButtonPressed(_isLast); // Trigger callback
//                           if (!_isLast) {
//                             hide(); // Hide the popup if it's not the last button
//                           }
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _isLast && _isLoading
//                         ? _getPaleColor(_buttonColor) // Paler if loading and last button
//                         : _buttonColor, // Normal button color
//                     foregroundColor: Colors.white, // Button text color
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 12.0, // Adjust vertical padding
//                     ),
//                   ),
//                   child: _isLast && _isLoading
//                       ? const SizedBox(
//                           height: 20.0,
//                           width: 20.0,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2.0,
//                           ),
//                         )
//                       : Text(
//                           _isLast ? "結束" : "繼續",
//                           style: const TextStyle(fontSize: 16.0),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }