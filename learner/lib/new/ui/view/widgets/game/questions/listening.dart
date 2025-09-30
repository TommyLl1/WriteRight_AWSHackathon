import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/mc_grid.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/play_audio_widget.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/submit_button.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/ui/view_model/game.dart';

// ListeningQuestion

class ListeningQuestionView extends StatefulWidget {
  final ListeningQuestion
      question; // The question body containing choices and correct answer

  const ListeningQuestionView({super.key, required this.question});

  @override
  _QuestionType3State createState() => _QuestionType3State();
}

class _QuestionType3State extends State<ListeningQuestionView> {
  late String soundUrl;
  MultiChoiceOption? selectedOption;
  late ListeningQuestion questionCopy;

  @override
  void initState() {
    super.initState();
    // Extract sound URL from the question body
    soundUrl = widget.question.given?.isNotEmpty == true
        ? widget.question.given![0].soundUrl ?? ""
        : "";
    questionCopy = widget.question;
  }

  void _onSubmitButtonPressed(BuildContext context) {
    if (selectedOption != null) {
      questionCopy.mcq.addAnswer = [selectedOption!.optionId];
      // Deactivate the button after submission
      context.read<GameViewModel>().isSubmitButtonActive = false;
      // Notify parent with the answer
      context.read<GameViewModel>().submitMcqAnswer([selectedOption!.optionId]);
    } else {
      // Handle case where no option is selected
      AppLogger.info("No option selected");
    }
  }

  void _onSelectionChanged(MultiChoiceOption option) {
    setState(() {
      selectedOption = option;
      if (selectedOption != null) {
        context.read<GameViewModel>().isSubmitButtonActive =
            true; // Activate if an option is selected
      } else {
        context.read<GameViewModel>().isSubmitButtonActive =
            false; // Deactivate if no option is selected
      }
    });
    AppLogger.info("Selected in Row: ${option.text}");
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Ensures the UI is properly constrained to the visible area
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Audio player (takes 1 part of the available space)
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: EdgeInsetsGeometry.all(20),
                // PlayAudioWidget to play the sound
                child: PlayAudioWidget(audioUrl: soundUrl),
              ),
            ),
          ),

          const SizedBox(height: 80), // Spacing between elements

          // Choices grid, takes most of the space (2 parts)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MultiChoiceGrid(
                options: widget.question.mcq.choices,
                onSelectionChanged: _onSelectionChanged,
              ),
            ),
          ),

          const SizedBox(height: 20), // Spacing between elements

          // Confirm button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity, // Make the button full width
              child: SubmitButton(
                text: "確定",
                onClick: () => _onSubmitButtonPressed(context),
              ),
            ),
          ),

          const SizedBox(height: 20), // Add spacing at the bottom
        ],
      ),
    );
  }
}
