// ,import 'package:flutter/material.dart';
// import '../backend/models/questions.dart';
// import 'cards/chinese_char_display.dart';
// import 'cards/mc_list.dart';
// import 'cards/submit_button.dart';
// import 'package:writeright/utils/logger.dart';

// class FillInvocabView extends StatefulWidget {
//   final FillInVocabQuestion question;
//   final Function(AnswerMethodBase)
//       onAnswer; // Callback to handle the answer submission

//   const FillInvocabView(
//       {Key? key, required this.question, required this.onAnswer})
//       : super(key: key);

//   @override
//   _QuestionType1State createState() => _QuestionType1State();
// }

// class _QuestionType1State extends State<FillInvocabView> {
//   // States
//   String character = "";
//   List<MultiChoiceOption> choices = [];
//   MultiChoiceOption? selectedOption;

//   // Store SubmitButton state
//   final GlobalKey<SubmitButtonState> _submitButtonKey =
//       GlobalKey<SubmitButtonState>();

//   @override
//   void initState() {
//     super.initState();

//     // Extract values from widget.body
//     character = widget.question.given?.isNotEmpty == true
//         ? widget.question.given![0].text ?? ""
//         : "？例"; // Fallback to placeholder (Should never happen)
//     choices = widget.question.mcq.choices;
//   }

//   void _onSubmitButtonPressed() {
//     if (selectedOption != null) {
//       // Handle answer submission
//       widget.question.mcq.addAnswer = [selectedOption!.optionId];
//       _submitButtonKey.currentState
//           ?.deactivateButton(); // Deactivate the button after submission
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
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           flex: 1, // 1:2 ratio for the given text
//           child: Center(
//             child: ChineseCharacterDisplay(
//               input: character,
//             ),
//           ),
//         ),


//         Expanded(
//           flex: 2, // 2:3 ratio for the multiple-choice grid
//           child: MultiChoiceList(
//             options: widget.question.mcq.choices,
//             onSelectionChanged: _onSelectionChanged,
//           ),
//         ),

//         const SizedBox(height: 20), // Spacing between elements

//         // Submit button with fixed height
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: SubmitButton(
//             key: _submitButtonKey,
//             text: "確定",
//             onClick: _onSubmitButtonPressed,
//           ),
//         ),
//       ],
//     );
//   }
// }