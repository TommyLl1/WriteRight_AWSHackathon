import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/chinese_char_display.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/mc_list.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/submit_button.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/ui/view_model/game.dart';

// FillInSentence

class FillInSentenceView extends StatefulWidget {
  final FillInSentenceQuestion question;

  const FillInSentenceView({super.key, required this.question});

  @override
  _QuestionType7State createState() => _QuestionType7State();
}

class _QuestionType7State extends State<FillInSentenceView> {
  // States
  String sentence = "";
  List<MultiChoiceOption> choices = [];
  MultiChoiceOption? selectedOption;
  late FillInSentenceQuestion questionCopy;

  @override
  void initState() {
    super.initState();

    // Extract values from widget.body
    sentence = widget.question.given?.isNotEmpty == true
        ? widget.question.given![0].text ?? ""
        : "今天是星？日"; // Fallback to placerholder ( Should never happen )
    choices = widget.question.mcq.choices;
    questionCopy = widget.question;
  }

  void _onSubmitButtonPressed(BuildContext context) {
    final gameViewModel = context.read<GameViewModel>();
    if (selectedOption != null) {
      gameViewModel.isSubmitButtonActive =
          false; // Deactivate the button after submission
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
    return Column(
      children: [
        // Given characters with a fixed ratio
        Center(
          child: ChineseCharacterDisplay(
            input: sentence,
          ),
        ),

        const SizedBox(height: 20), // Spacing between elements

        // Choices list with a fixed ratio
        Expanded(
          child: MultiChoiceList(
            options: widget.question.mcq.choices,
            onSelectionChanged: _onSelectionChanged,
          ),
        ),

        const SizedBox(height: 20), // Spacing between elements

        // Submit button with a fixed ratio
        SubmitButton(
          text: "確定",
          onClick: () => _onSubmitButtonPressed(context),
        ),
      ],
    );
  }
}
