import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/chinese_char_display.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/submit_button.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/drawing_pad.dart';
import 'package:writeright/new/ui/view_model/game.dart';
import 'package:writeright/new/utils/logger.dart';

// CopyStrokeQuestion

class CopyStrokeView extends StatefulWidget {
  final CopyStrokeQuestion question;

  const CopyStrokeView({super.key, required this.question});

  @override
  State<CopyStrokeView> createState() => _QuestionType5State();
}

class _QuestionType5State extends State<CopyStrokeView> {
  late String character;
  late String submitUrl;
  List<Offset> strokes = [];

  @override
  void initState() {
    super.initState();
    // Extract values from widget.body
    character = widget.question.writing.handwriteTarget;
    submitUrl = widget.question.writing.submitUrl ?? "";
  }

  void _onStrokeChanged(List<Offset> newStrokes) {
    final gameViewModel = context.read<GameViewModel>();
    strokes = newStrokes; // no need set state
    if (strokes.isNotEmpty) {
      gameViewModel.isSubmitButtonActive =
          true; // Activate if there are strokes
    } else {
      gameViewModel.isSubmitButtonActive = false; // Deactivate if no strokes
    }
  }

  void _onSubmitButtonPressed(BuildContext context) {
    final gameViewModel = context.read<GameViewModel>();
    if (strokes.isNotEmpty) {
      gameViewModel.isSubmitButtonActive =
          false; // Deactivate the button after submission
      context.read<GameViewModel>().submitHandwriteAnswer(strokes);
    } else {
      // Handle case where no strokes are drawn
      AppLogger.info("No strokes drawn");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Chinese Character Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ChineseCharacterDisplay(input: character),
        ),

        const SizedBox(height: 10),

        // Drawing Pad (takes up as much space as possible)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Consumer<GameViewModel>(
              builder: (context, viewModel, child) => DrawingPad(
                onDrawingChanged: _onStrokeChanged,
                isDisabled:
                    viewModel.currentQuestionAnswered ||
                    viewModel.isSubmitButtonLoading,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Submit Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity, // Make the button full width
            child: SubmitButton(
              text: "Submit",
              onClick: () => _onSubmitButtonPressed(context),
            ),
          ),
        ),

        const SizedBox(height: 20), // Add some spacing at the bottom
      ],
    );
  }
}
