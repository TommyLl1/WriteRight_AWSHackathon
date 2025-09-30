// import 'package:flutter/material.dart';
// import '../new/ui/view/common_widgets/game/widgets/play_audio_widget.dart';
// import '../../../../../../backend/models/questions.dart';
// import '../../../../../../game/cards/submit_button.dart';
// import '../../../../../../game/cards/mc_grid.dart';
// import 'package:writeright/utils/logger.dart';

// // ListeningQuestion

// class QuestionType3 extends StatefulWidget {
//   final ListeningQuestion
//       question; // The question body containing choices and correct answer
//   final Function(AnswerMethodBase)
//       onAnswer; // Callback to notify the parent widget

//   const QuestionType3(
//       {Key? key, required this.question, required this.onAnswer})
//       : super(key: key);

//   @override
//   _QuestionType3State createState() => _QuestionType3State();
// }

// class _QuestionType3State extends State<QuestionType3> {
//   late String soundUrl;
//   MultiChoiceOption? selectedOption;
//   // Store SubmitButton state
//   final GlobalKey<SubmitButtonState> _submitButtonKey =
//       GlobalKey<SubmitButtonState>();

//   @override
//   void initState() {
//     super.initState();
//     // Extract sound URL from the question body
//     soundUrl = widget.question.given?.isNotEmpty == true
//         ? widget.question.given![0].soundUrl ?? ""
//         : "";
//   }

//   void _onSubmitButtonPressed() {
//     if (selectedOption != null) {
//       // TODO: Handle multiple selections if needed

//       widget.question.mcq.addAnswer = [selectedOption!.optionId];
//       _submitButtonKey.currentState
//           ?.deactivateButton(); // Deactivate the button after submission

//       // Notify parent with the answer
//       widget.onAnswer(widget.question.mcq);
//     } else {
//       // Handle case where no option is selected
//       AppLogger.info("No option selected");
//     }
//   }

//   void _onSelectionChanged(MultiChoiceOption option) {
//     setState(() {
//       selectedOption = option;
//       if (selectedOption != null) {
//         _submitButtonKey.currentState
//             ?.activateButton(); // Activate the button when an option is selected
//       } else {
//         _submitButtonKey.currentState
//             ?.deactivateButton(); // Deactivate if no option is selected
//       }
//     });
//     AppLogger.info("Selected in Row: ${option.text}");
//   }

//   @override
// Widget build(BuildContext context) {
//   return SafeArea( // Ensures the UI is properly constrained to the visible area
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         // Audio player (takes 1 part of the available space)
//         Expanded(
//           flex: 1,
//           child: Center(
//             child: Padding(
//               padding:EdgeInsetsGeometry.all(20),
//               // PlayAudioWidget to play the sound
//               child: PlayAudioWidget(audioUrl: soundUrl),
//             ),
//           ),
//         ),

//         const SizedBox(height: 80), // Spacing between elements

//         // Choices grid, takes most of the space (2 parts)
//         Expanded(
//           flex: 2,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: MultiChoiceGrid(
//               options: widget.question.mcq.choices,
//               onSelectionChanged: _onSelectionChanged,
//             ),
//           ),
//         ),

//         const SizedBox(height: 20), // Spacing between elements

//         // Confirm button
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: SizedBox(
//             width: double.infinity, // Make the button full width
//             child: SubmitButton(
//               key: _submitButtonKey,
//               text: "確定",
//               onClick: _onSubmitButtonPressed,
//             ),
//           ),
//         ),

//         const SizedBox(height: 20), // Add spacing at the bottom
//       ],
//     ),
//   );
// }
// }
