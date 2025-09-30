import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:writeright/new/utils/logger.dart';

part 'questions.g.dart';

/// Using JsonSerializable for JSON serialization
///
/// Tried using Freezed but it was causing issues with the generated code, wasting time,
/// so i just used JsonSerializable directly (use other libraries or write more condensed code if possible)
/// I assume creating a seperate class for every question type is better than using union classes
/// Even if we can condense the code i think we still need to declear bunch of classes, so i just wrote it in the simplest way
/// also answer models if mutable might be more convenient
///
/// Generate .g code:
/// ```dart run build_runner watch -d```
///
/// TODO: Add answer() to questions ?

// ------ Enums ------ //

// Convert snake_case enums to camelCase for JSON serialization
@JsonEnum(fieldRename: FieldRename.snake)
enum QuestionType {
  pairingCards,
  matchPic,
  combineRadical,
  combineRadicalWithHint,
  fillInSentence,
  listening,
  fillInVocab,
  identMirrored,
  identWrong,
  copyStroke,
  fillInRadical,
}

enum AnswerType {
  mcq,
  writing,
  pairing,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum GivenMaterialType {
  textLong,
  textShort,
  image,
  sound,
}

enum MCQDisplayType {
  grid,
  list,
}

// ------ MultiChoiceDisplay Class ------ //

@JsonSerializable()
class MultiChoiceDisplay {
  final MCQDisplayType displayType;
  final int rows;
  final int? columns;

  MultiChoiceDisplay({
    required this.displayType,
    required this.rows,
    this.columns,
  });

  void validateDisplay() {
    if (displayType == MCQDisplayType.grid) {
      if (columns == null || columns! <= 0) {
        throw ArgumentError(
            'columns must be specified and greater than 0 for GRID display type');
      }
      throw ArgumentError(
          'columns must be specified and greater than 0 for GRID display type');
    }
    if (displayType == MCQDisplayType.list && columns != null) {
      throw ArgumentError(
          'columns should not be specified for LIST display type');
    }
  }

  factory MultiChoiceDisplay.fromJson(Map<String, dynamic> json) =>
      _$MultiChoiceDisplayFromJson(json);

  Map<String, dynamic> toJson() => _$MultiChoiceDisplayToJson(this);
}

// ------ Given Materials ------ //

@JsonSerializable()
class GivenMaterial {
  final GivenMaterialType materialType;
  final int materialId;
  final String? imageUrl;
  final String? altText;
  final String? soundUrl;
  final String? text;

  GivenMaterial({
    required this.materialType,
    required this.materialId,
    this.imageUrl,
    this.altText,
    this.soundUrl,
    this.text,
  });

  factory GivenMaterial.fromJson(Map<String, dynamic> json) =>
      _$GivenMaterialFromJson(json);

  Map<String, dynamic> toJson() => _$GivenMaterialToJson(this);
}

// ------ MultiChoiceOption ------ //

@JsonSerializable()
class MultiChoiceOption {
  final int optionId;
  final String? text;
  final String? image;

  MultiChoiceOption({
    required this.optionId,
    this.text,
    this.image,
  });

  factory MultiChoiceOption.fromJson(Map<String, dynamic> json) =>
      _$MultiChoiceOptionFromJson(json);

  Map<String, dynamic> toJson() => _$MultiChoiceOptionToJson(this);
}

// ------ MultiChoiceAnswer ------ //

@JsonSerializable()
class MultiChoiceAnswer {
  final int answerId;
  final List<int> choices;

  MultiChoiceAnswer({
    required this.answerId,
    required this.choices,
  });

  factory MultiChoiceAnswer.fromJson(Map<String, dynamic> json) =>
      _$MultiChoiceAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$MultiChoiceAnswerToJson(this);
}

// ------ PairingOption ------ //

@JsonSerializable()
class PairingOption {
  final int pairId;
  final List<MultiChoiceOption> items;

  PairingOption({
    required this.pairId,
    required this.items,
  });

  factory PairingOption.fromJson(Map<String, dynamic> json) =>
      _$PairingOptionFromJson(json);

  Map<String, dynamic> toJson() => _$PairingOptionToJson(this);
}

// ------ AnswerMethodBase ------ //

@JsonSerializable()
class AnswerMethodBase {
  final int timeLimit;

  AnswerMethodBase({this.timeLimit = 0});

  factory AnswerMethodBase.fromJson(Map<String, dynamic> json) =>
      _$AnswerMethodBaseFromJson(json);

  Map<String, dynamic> toJson() => _$AnswerMethodBaseToJson(this);
}

@JsonSerializable()
class AnswerMultiChoice extends AnswerMethodBase {
  final int minChoices;
  final int maxChoices;
  final bool strictOrder;
  final bool randomize;
  final MultiChoiceDisplay display;
  final List<MultiChoiceOption> choices;
  final List<MultiChoiceAnswer> answers;
  // Mutable field to store submitted answers
  List<MultiChoiceAnswer>? submittedAnswers;

  // Getters and Setters are not serialized by default
  bool get isCorrect {
    if (submittedAnswers == null || submittedAnswers!.isEmpty) {
      // AppLogger.info("Submitted answers are empty or null");
      return false;
    }
    // AppLogger.info("answers are: ${answers.map((e) => e.toJson())}");
    // Ensure every submitted answer has a matching correct answer
    return submittedAnswers!
      .every((submittedAns) => answers /// for every submitted answer <MultiChoiceAnswer>
      .any((correctAns) => listEquals(correctAns.choices, submittedAns.choices)));
  }

  set addAnswer(List<int> choices) {
    // Initialize submittedAnswers if null
    submittedAnswers ??= [];

    // Create a new MultiChoiceAnswer with the next available answerId
    int nextAnswerId = submittedAnswers!.isEmpty
        ? 1 // Start from 1 if no answers submitted yet
        : submittedAnswers!.length + 1;
    submittedAnswers!
        .add(MultiChoiceAnswer(answerId: nextAnswerId, choices: choices));
  }

  AnswerMultiChoice({
    super.timeLimit = 0,
    this.minChoices = 1,
    this.maxChoices = 1,
    this.strictOrder = false,
    this.randomize = true,
    required this.display,
    required this.choices,
    required this.answers,
    this.submittedAnswers,
  });

  factory AnswerMultiChoice.fromJson(Map<String, dynamic> json) =>
      _$AnswerMultiChoiceFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnswerMultiChoiceToJson(this);
}

@JsonSerializable()
class AnswerHandwrite extends AnswerMethodBase {
  final String handwriteTarget;
  final String? submitUrl;
  final String? backgroundImage;
  String? submittedImage;
  bool? isCorrect;

  AnswerHandwrite({
    super.timeLimit = 0,
    required this.handwriteTarget,
    this.submitUrl,
    this.backgroundImage,
    this.submittedImage,
    this.isCorrect,
  });

  factory AnswerHandwrite.fromJson(Map<String, dynamic> json) =>
      _$AnswerHandwriteFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnswerHandwriteToJson(this);
}

@JsonSerializable()
class AnswerPairing extends AnswerMethodBase {
  final List<PairingOption> pairs;
  final bool randomize;
  final MultiChoiceDisplay display;
  List<PairingOption>? submittedPairs;

  AnswerPairing({
    super.timeLimit = 0,
    this.randomize = true,
    required this.pairs,
    required this.display,
    this.submittedPairs,
  });

  List<MultiChoiceOption> get allOptions {
    return pairs.expand((pair) => pair.items).toList();
  }

  bool get isCorrect {
    if (submittedPairs == null || submittedPairs!.isEmpty) {
      return false;
    }

    // Compare by sets of optionIds for each pair
    return pairs.every((submittedPair) =>
      pairs.any((correctPair) =>
        setEquals(
          correctPair.items.map((item) => item.optionId).toSet(),
          submittedPair.items.map((item) => item.optionId).toSet(),
        )
      )
    );
  }


  bool containPair(List<MultiChoiceOption> items) {
    if (items.isEmpty) {
      AppLogger.info("Empty items provided for comparison");
      return false;
    }

    // log all items comparing
    AppLogger.info("Comparing items: ${items.map((item) => item.optionId)}");


    // Check if any submitted pair contains the same items
    Set<int> itemsIds = items.map((item) => item.optionId).toSet();
    List<Set<int>> answerIdPairs = pairs
        .map((pair) => pair.items.map((item) => item.optionId).toSet())
        .toList();

    bool contains = answerIdPairs.any((pair) => setEquals(pair, itemsIds));
    return contains;
  }

  factory AnswerPairing.fromJson(Map<String, dynamic> json) =>
      _$AnswerPairingFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AnswerPairingToJson(this);
}

// ------ QuestionBase ------ //

@JsonSerializable()
class QuestionBase {
  final String questionId;
  final QuestionType questionType;
  final AnswerType answerType;
  final int exp;
  final String targetWord;
  final String prompt;
  final List<GivenMaterial>? given;

  QuestionBase({
    required this.questionId,
    required this.questionType,
    required this.answerType,
    this.exp = 10,
    required this.targetWord,
    required this.prompt,
    required this.given,
  });

  factory QuestionBase.fromJson(Map<String, dynamic> json) =>
      _$QuestionBaseFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionBaseToJson(this);
}

@JsonSerializable()
class PairingQuestion extends QuestionBase {
  AnswerPairing pairing;

  PairingQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.given,
    required questionType,
    required answerType,
    required this.pairing, // Card pairing options
  }) : super(
          questionType: questionType,
          answerType: AnswerType.pairing,
        );

  factory PairingQuestion.fromJson(Map<String, dynamic> json) =>
      _$PairingQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PairingQuestionToJson(this);
}

@JsonSerializable()
class MultiChoiceQuestion extends QuestionBase {
  AnswerMultiChoice mcq;

  MultiChoiceQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.given,
    required super.questionType,
    required answerType,
    required this.mcq, // MCQ options
  }) : super(
          answerType: AnswerType.mcq,
        );
  factory MultiChoiceQuestion.fromJson(Map<String, dynamic> json) =>
      _$MultiChoiceQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MultiChoiceQuestionToJson(this);
}

@JsonSerializable()
class HandwriteQuestion extends QuestionBase {
  AnswerHandwrite writing;

  HandwriteQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.given,
    required super.questionType,
    required answerType,
    required this.writing, // Handwriting options
  }) : super(
          answerType: AnswerType.writing,
        );

  factory HandwriteQuestion.fromJson(Map<String, dynamic> json) =>
      _$HandwriteQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$HandwriteQuestionToJson(this);
}

// ------ Specific Question Types ------ //
@JsonSerializable()
class PairingCardsQuestion extends PairingQuestion {
  PairingCardsQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    super.given,
    required super.pairing,
    required super.questionType,
    required super.answerType,
  });

  factory PairingCardsQuestion.fromJson(Map<String, dynamic> json) =>
      _$PairingCardsQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$PairingCardsQuestionToJson(this);
}

@JsonSerializable()
class MatchPicQuestion extends MultiChoiceQuestion {
  MatchPicQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    super.given,
    required super.questionType,
    required super.answerType,
  });

  factory MatchPicQuestion.fromJson(Map<String, dynamic> json) =>
      _$MatchPicQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MatchPicQuestionToJson(this);
}

@JsonSerializable()
class CombineRadicalQuestion extends MultiChoiceQuestion {
  CombineRadicalQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    super.given,
    required super.questionType,
    required super.answerType,
  });

  factory CombineRadicalQuestion.fromJson(Map<String, dynamic> json) =>
      _$CombineRadicalQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CombineRadicalQuestionToJson(this);
}

@JsonSerializable()
class CombineRadicalWithHintQuestion extends MultiChoiceQuestion {
  CombineRadicalWithHintQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    super.given,
    required super.questionType,
    required super.answerType,
  });

  factory CombineRadicalWithHintQuestion.fromJson(Map<String, dynamic> json) =>
      _$CombineRadicalWithHintQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CombineRadicalWithHintQuestionToJson(this);
}

@JsonSerializable()
class FillInSentenceQuestion extends MultiChoiceQuestion {
  FillInSentenceQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    super.given,
    required super.questionType,
    required super.answerType,
  });

  factory FillInSentenceQuestion.fromJson(Map<String, dynamic> json) =>
      _$FillInSentenceQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FillInSentenceQuestionToJson(this);
}

@JsonSerializable()
class ListeningQuestion extends MultiChoiceQuestion {
  ListeningQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    super.given,
    required super.questionType,
    required super.answerType,
  });

  factory ListeningQuestion.fromJson(Map<String, dynamic> json) =>
      _$ListeningQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ListeningQuestionToJson(this);
}

@JsonSerializable()
class FillInVocabQuestion extends MultiChoiceQuestion {
  FillInVocabQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    required super.questionType,
    required super.answerType,
    super.given,
  });

  factory FillInVocabQuestion.fromJson(Map<String, dynamic> json) =>
      _$FillInVocabQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FillInVocabQuestionToJson(this);
}

@JsonSerializable()
class IdentifyMirroredQuestion extends MultiChoiceQuestion {
  IdentifyMirroredQuestion({
    required super.questionId,
    required super.questionType,
    required super.answerType,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    super.given,
  });
  factory IdentifyMirroredQuestion.fromJson(Map<String, dynamic> json) =>
      _$IdentifyMirroredQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IdentifyMirroredQuestionToJson(this);
}

@JsonSerializable()
class IdentifyWrongQuestion extends MultiChoiceQuestion {
  IdentifyWrongQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    required super.mcq,
    required super.questionType,
    required super.answerType,
    super.given,
  });

  factory IdentifyWrongQuestion.fromJson(Map<String, dynamic> json) =>
      _$IdentifyWrongQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$IdentifyWrongQuestionToJson(this);
}

@JsonSerializable()
class CopyStrokeQuestion extends HandwriteQuestion {
  CopyStrokeQuestion({
    required super.questionId,
    required super.answerType,
    required super.questionType,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    super.given,
    required super.writing,
  });

  factory CopyStrokeQuestion.fromJson(Map<String, dynamic> json) =>
      _$CopyStrokeQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$CopyStrokeQuestionToJson(this);
}

@JsonSerializable()
class FillInRadicalQuestion extends HandwriteQuestion {
  FillInRadicalQuestion({
    required super.questionId,
    required super.exp,
    required super.targetWord,
    required super.prompt,
    super.given,
    required super.writing,
  }) : super(
          questionType: QuestionType.fillInRadical,
          answerType: AnswerType.writing,
        );

  factory FillInRadicalQuestion.fromJson(Map<String, dynamic> json) =>
      _$FillInRadicalQuestionFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FillInRadicalQuestionToJson(this);
}

class QuestionFactory {
  static QuestionBase fromJson(Map<String, dynamic> json) {
    final questionType = json['question_type'] as String;

    switch (questionType) {
      case 'pairing_cards':
        return PairingCardsQuestion.fromJson(json);
      case 'match_pic':
        return MatchPicQuestion.fromJson(json);
      case 'combine_radical':
        return CombineRadicalQuestion.fromJson(json);
      case 'combine_radical_with_hint':
        return CombineRadicalWithHintQuestion.fromJson(json);
      case 'fill_in_sentence':
        return FillInSentenceQuestion.fromJson(json);
      case 'listening':
        return ListeningQuestion.fromJson(json);
      case 'fill_in_vocab':
        return FillInVocabQuestion.fromJson(json);
      case 'ident_mirrored':
        return IdentifyMirroredQuestion.fromJson(json);
      case 'ident_wrong':
        return IdentifyWrongQuestion.fromJson(json);
      case 'copy_stroke':
        return CopyStrokeQuestion.fromJson(json);
      case 'fill_in_radical':
        return FillInRadicalQuestion.fromJson(json);
      default:
        throw ArgumentError('Unknown question type: $questionType');
    }
  }
}

void main() {
  // Example usage
  final questionJson = [
    {
      "question_id": "1505c4da-aa28-4cfd-bd17-cb65996e6872",
      "question_type": "copy_stroke",
      "answer_type": "writing",
      "exp": 10,
      "target_word": "尬",
      "prompt": "Write the character below",
      "given": [],
      "mcq": null,
      "pairing": null,
      "writing": {
        "time_limit": 0,
        "handwrite_target": "尬",
        "submit_url":
            "https://mock-s3-service.com/submit/b2977f0b-b464-4be3-9057-984e7ac4c9a9",
        "background_image": null,
        "submitted_image": null,
        "is_correct": null
      }
    },
    {
      "question_id": "f8efe52f-bc40-487d-b636-0f7be533810f",
      "question_type": "listening",
      "answer_type": "mcq",
      "exp": 10,
      "target_word": "尬",
      "prompt": "Select the correct answer",
      "given": [
        {
          "material_type": "sound",
          "material_id": 1,
          "image_url": null,
          "alt_text": null,
          "sound_url":
              "https://www.secmenu.com/apps/words/www/audio/cantonese/gaai3.mp3",
          "text": null
        }
      ],
      "mcq": {
        "time_limit": 0,
        "min_choices": 1,
        "max_choices": 1,
        "choices": [
          {"option_id": 1, "text": "尬", "image": "尬"},
          {"option_id": 2, "text": "的", "image": "的"},
          {"option_id": 3, "text": "是", "image": "是"},
          {"option_id": 4, "text": "草", "image": "草"}
        ],
        "strict_order": false,
        "randomize": true,
        "display": {"display_type": "list", "rows": 4, "columns": null},
        "answers": [
          {
            "answer_id": 1,
            "choices": [1]
          }
        ],
        "submitted_answers": null
      },
      "pairing": null,
      "writing": null
    },
    {
      "question_id": "b2039119-2103-410f-9056-68a77ed047d9",
      "question_type": "copy_stroke",
      "answer_type": "writing",
      "exp": 10,
      "target_word": "哪",
      "prompt": "Write the character below",
      "given": [],
      "mcq": null,
      "pairing": null,
      "writing": {
        "time_limit": 0,
        "handwrite_target": "哪",
        "submit_url":
            "https://mock-s3-service.com/submit/b2977f0b-b464-4be3-9057-984e7ac4c9a9",
        "background_image": null,
        "submitted_image": null,
        "is_correct": null
      }
    },
    {
      "question_id": "6952c7de-3adb-48ef-8efc-b946471336f6",
      "question_type": "fill_in_vocab",
      "answer_type": "mcq",
      "exp": 10,
      "target_word": "哇",
      "prompt": "Fill in the blank",
      "given": [
        {
          "material_type": "text_short",
          "material_id": 1,
          "image_url": null,
          "alt_text": null,
          "sound_url": null,
          "text": "？塞"
        }
      ],
      "mcq": {
        "time_limit": 0,
        "min_choices": 1,
        "max_choices": 1,
        "choices": [
          {"option_id": 1, "text": "口", "image": "口"},
          {"option_id": 2, "text": "娃", "image": "娃"},
          {"option_id": 3, "text": "哇", "image": "哇"},
          {"option_id": 4, "text": "蛙", "image": "蛙"}
        ],
        "strict_order": false,
        "randomize": true,
        "display": {"display_type": "list", "rows": 4, "columns": null},
        "answers": [
          {
            "answer_id": 1,
            "choices": [3]
          }
        ],
        "submitted_answers": null
      },
      "pairing": null,
      "writing": null
    }
  ];
  for (var questionJson in questionJson) {
    final question = QuestionFactory.fromJson(questionJson);
    AppLogger.debug('Question JSON: ${question.toJson()}');
    AppLogger.debug('Question Type: ${question.questionType}');
    AppLogger.debug('Answer Type: ${question.answerType}');
    if (question is MultiChoiceQuestion) {
      AppLogger.debug('MCQ: ${question.mcq.toJson()}');
    } else if (question is PairingQuestion) {
      AppLogger.debug('Pairing: ${question.pairing.toJson()}');
    } else if (question is HandwriteQuestion) {
      AppLogger.debug('Writing: ${question.writing.toJson()}');
    }
    AppLogger.debug('---');
  }
}
