import 'package:flutter/material.dart';

// Importing question types
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/ui/view/widgets/game/questions/copy_stroke.dart';
import 'package:writeright/new/ui/view/widgets/game/questions/fill_in_sentence.dart';
import 'package:writeright/new/ui/view/widgets/game/questions/fill_in_vocab.dart';
import 'package:writeright/new/ui/view/widgets/game/questions/pairing_cards.dart';
import 'package:writeright/new/ui/view/widgets/game/questions/listening.dart';

class QuestionFactory extends StatelessWidget {
  final QuestionBase question;

  const QuestionFactory({
    super.key,
    required this.question,
  });

  /// Set the key as the questionId, to ensure that the widget is rebuilt when the question changes.

  @override
  Widget build(BuildContext context) {
    Key uniqueKey = ValueKey(question.questionId);
    switch (question.questionType) {
      case QuestionType.fillInVocab:
        return FillInvocabView(
            key: uniqueKey, question: question as FillInVocabQuestion);
      case QuestionType.listening:
        return ListeningQuestionView(
          key: uniqueKey,
          question: question as ListeningQuestion,
        );
      case QuestionType.copyStroke:
        return CopyStrokeView(
            key: uniqueKey, question: question as CopyStrokeQuestion);
      case QuestionType.fillInSentence:
        return FillInSentenceView(
          key: uniqueKey,
          question: question as FillInSentenceQuestion,
        );
      case QuestionType.pairingCards:
        return PairingCardsView(
          key: uniqueKey,
          question: question as PairingCardsQuestion,
        );
      default:
        return const Center(child: Text("Unsupported question type"));
    }
  }
}
