import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/ui/view_model/game.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/submit_button.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/chinese_char_display.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/mc_list.dart';

class FillInvocabView extends StatefulWidget {
  final FillInVocabQuestion question;

  const FillInvocabView({super.key, required this.question});

  @override
  _QuestionType1State createState() => _QuestionType1State();
}

class _QuestionType1State extends State<FillInvocabView> {
  // States
  String character = "";
  List<MultiChoiceOption> choices = [];
  MultiChoiceOption? selectedOption;
  late FillInVocabQuestion questionCopy;

  @override
  void initState() {
    super.initState();

    // Extract values from widget.body
    character = widget.question.given?.isNotEmpty == true
        ? widget.question.given![0].text ?? ""
        : "？例"; // Fallback to placeholder (Should never happen)
    choices = widget.question.mcq.choices;
    questionCopy = widget.question;
  }

  void _onSubmitButtonPressed(BuildContext context) {
    final gameViewModel = context.read<GameViewModel>();
    if (selectedOption != null) {
      gameViewModel.isSubmitButtonActive = false;
      // Handle answer submission
      questionCopy.mcq.addAnswer = [selectedOption!.optionId];
      context.read<GameViewModel>().submitMcqAnswer([selectedOption!.optionId]);
    } else {
      // Handle case where no option is selected
      AppLogger.info("No option selected");
    }
  }

  void _onSelectionChanged(MultiChoiceOption option) {
    final gameViewModel = context.read<GameViewModel>();
    setState(() {
      selectedOption = option;
      if (selectedOption != null) {
        gameViewModel.isSubmitButtonActive =
            true; // Activate if an option is selected
      } else {
        gameViewModel.isSubmitButtonActive =
            false; // Deactivate if no option is selected
      }
    });
    AppLogger.info("Selected in Row: ${option.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1, // 1:2 ratio for the given text
          child: Center(
            child: ChineseCharacterDisplay(
              input: character,
            ),
          ),
        ),

        Expanded(
          flex: 2, // 2:3 ratio for the multiple-choice grid
          child: MultiChoiceList(
            options: widget.question.mcq.choices,
            onSelectionChanged: _onSelectionChanged,
          ),
        ),

        const SizedBox(height: 20), // Spacing between elements

        // Submit button with fixed height
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SubmitButton(
            text: "確定",
            onClick: () => _onSubmitButtonPressed(context),
          ),
        ),
      ],
    );
  }
}
