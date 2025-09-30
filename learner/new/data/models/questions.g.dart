// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MultiChoiceDisplay _$MultiChoiceDisplayFromJson(Map<String, dynamic> json) =>
    MultiChoiceDisplay(
      displayType: $enumDecode(_$MCQDisplayTypeEnumMap, json['display_type']),
      rows: (json['rows'] as num).toInt(),
      columns: (json['columns'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MultiChoiceDisplayToJson(MultiChoiceDisplay instance) =>
    <String, dynamic>{
      'display_type': _$MCQDisplayTypeEnumMap[instance.displayType]!,
      'rows': instance.rows,
      'columns': instance.columns,
    };

const _$MCQDisplayTypeEnumMap = {
  MCQDisplayType.grid: 'grid',
  MCQDisplayType.list: 'list',
};

GivenMaterial _$GivenMaterialFromJson(Map<String, dynamic> json) =>
    GivenMaterial(
      materialType: $enumDecode(
        _$GivenMaterialTypeEnumMap,
        json['material_type'],
      ),
      materialId: (json['material_id'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
      altText: json['alt_text'] as String?,
      soundUrl: json['sound_url'] as String?,
      text: json['text'] as String?,
    );

Map<String, dynamic> _$GivenMaterialToJson(GivenMaterial instance) =>
    <String, dynamic>{
      'material_type': _$GivenMaterialTypeEnumMap[instance.materialType]!,
      'material_id': instance.materialId,
      'image_url': instance.imageUrl,
      'alt_text': instance.altText,
      'sound_url': instance.soundUrl,
      'text': instance.text,
    };

const _$GivenMaterialTypeEnumMap = {
  GivenMaterialType.textLong: 'text_long',
  GivenMaterialType.textShort: 'text_short',
  GivenMaterialType.image: 'image',
  GivenMaterialType.sound: 'sound',
};

MultiChoiceOption _$MultiChoiceOptionFromJson(Map<String, dynamic> json) =>
    MultiChoiceOption(
      optionId: (json['option_id'] as num).toInt(),
      text: json['text'] as String?,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$MultiChoiceOptionToJson(MultiChoiceOption instance) =>
    <String, dynamic>{
      'option_id': instance.optionId,
      'text': instance.text,
      'image': instance.image,
    };

MultiChoiceAnswer _$MultiChoiceAnswerFromJson(Map<String, dynamic> json) =>
    MultiChoiceAnswer(
      answerId: (json['answer_id'] as num).toInt(),
      choices: (json['choices'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MultiChoiceAnswerToJson(MultiChoiceAnswer instance) =>
    <String, dynamic>{
      'answer_id': instance.answerId,
      'choices': instance.choices,
    };

PairingOption _$PairingOptionFromJson(Map<String, dynamic> json) =>
    PairingOption(
      pairId: (json['pair_id'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => MultiChoiceOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PairingOptionToJson(PairingOption instance) =>
    <String, dynamic>{'pair_id': instance.pairId, 'items': instance.items};

AnswerMethodBase _$AnswerMethodBaseFromJson(Map<String, dynamic> json) =>
    AnswerMethodBase(timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0);

Map<String, dynamic> _$AnswerMethodBaseToJson(AnswerMethodBase instance) =>
    <String, dynamic>{'time_limit': instance.timeLimit};

AnswerMultiChoice _$AnswerMultiChoiceFromJson(Map<String, dynamic> json) =>
    AnswerMultiChoice(
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      minChoices: (json['min_choices'] as num?)?.toInt() ?? 1,
      maxChoices: (json['max_choices'] as num?)?.toInt() ?? 1,
      strictOrder: json['strict_order'] as bool? ?? false,
      randomize: json['randomize'] as bool? ?? true,
      display: MultiChoiceDisplay.fromJson(
        json['display'] as Map<String, dynamic>,
      ),
      choices: (json['choices'] as List<dynamic>)
          .map((e) => MultiChoiceOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      answers: (json['answers'] as List<dynamic>)
          .map((e) => MultiChoiceAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      submittedAnswers: (json['submitted_answers'] as List<dynamic>?)
          ?.map((e) => MultiChoiceAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnswerMultiChoiceToJson(AnswerMultiChoice instance) =>
    <String, dynamic>{
      'time_limit': instance.timeLimit,
      'min_choices': instance.minChoices,
      'max_choices': instance.maxChoices,
      'strict_order': instance.strictOrder,
      'randomize': instance.randomize,
      'display': instance.display,
      'choices': instance.choices,
      'answers': instance.answers,
      'submitted_answers': instance.submittedAnswers,
    };

AnswerHandwrite _$AnswerHandwriteFromJson(Map<String, dynamic> json) =>
    AnswerHandwrite(
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      handwriteTarget: json['handwrite_target'] as String,
      submitUrl: json['submit_url'] as String?,
      backgroundImage: json['background_image'] as String?,
      submittedImage: json['submitted_image'] as String?,
      isCorrect: json['is_correct'] as bool?,
    );

Map<String, dynamic> _$AnswerHandwriteToJson(AnswerHandwrite instance) =>
    <String, dynamic>{
      'time_limit': instance.timeLimit,
      'handwrite_target': instance.handwriteTarget,
      'submit_url': instance.submitUrl,
      'background_image': instance.backgroundImage,
      'submitted_image': instance.submittedImage,
      'is_correct': instance.isCorrect,
    };

AnswerPairing _$AnswerPairingFromJson(Map<String, dynamic> json) =>
    AnswerPairing(
      timeLimit: (json['time_limit'] as num?)?.toInt() ?? 0,
      randomize: json['randomize'] as bool? ?? true,
      pairs: (json['pairs'] as List<dynamic>)
          .map((e) => PairingOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      display: MultiChoiceDisplay.fromJson(
        json['display'] as Map<String, dynamic>,
      ),
      submittedPairs: (json['submitted_pairs'] as List<dynamic>?)
          ?.map((e) => PairingOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AnswerPairingToJson(AnswerPairing instance) =>
    <String, dynamic>{
      'time_limit': instance.timeLimit,
      'pairs': instance.pairs,
      'randomize': instance.randomize,
      'display': instance.display,
      'submitted_pairs': instance.submittedPairs,
    };

QuestionBase _$QuestionBaseFromJson(Map<String, dynamic> json) => QuestionBase(
  questionId: json['question_id'] as String,
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
  answerType: $enumDecode(_$AnswerTypeEnumMap, json['answer_type']),
  exp: (json['exp'] as num?)?.toInt() ?? 10,
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$QuestionBaseToJson(QuestionBase instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
      'exp': instance.exp,
      'target_word': instance.targetWord,
      'prompt': instance.prompt,
      'given': instance.given,
    };

const _$QuestionTypeEnumMap = {
  QuestionType.pairingCards: 'pairing_cards',
  QuestionType.matchPic: 'match_pic',
  QuestionType.combineRadical: 'combine_radical',
  QuestionType.combineRadicalWithHint: 'combine_radical_with_hint',
  QuestionType.fillInSentence: 'fill_in_sentence',
  QuestionType.listening: 'listening',
  QuestionType.fillInVocab: 'fill_in_vocab',
  QuestionType.identMirrored: 'ident_mirrored',
  QuestionType.identWrong: 'ident_wrong',
  QuestionType.copyStroke: 'copy_stroke',
  QuestionType.fillInRadical: 'fill_in_radical',
};

const _$AnswerTypeEnumMap = {
  AnswerType.mcq: 'mcq',
  AnswerType.writing: 'writing',
  AnswerType.pairing: 'pairing',
};

PairingQuestion _$PairingQuestionFromJson(Map<String, dynamic> json) =>
    PairingQuestion(
      questionId: json['question_id'] as String,
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionType: json['question_type'],
      answerType: json['answer_type'],
      pairing: AnswerPairing.fromJson(json['pairing'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PairingQuestionToJson(PairingQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
      'exp': instance.exp,
      'target_word': instance.targetWord,
      'prompt': instance.prompt,
      'given': instance.given,
      'pairing': instance.pairing,
    };

MultiChoiceQuestion _$MultiChoiceQuestionFromJson(Map<String, dynamic> json) =>
    MultiChoiceQuestion(
      questionId: json['question_id'] as String,
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
      answerType: json['answer_type'],
      mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MultiChoiceQuestionToJson(
  MultiChoiceQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

HandwriteQuestion _$HandwriteQuestionFromJson(Map<String, dynamic> json) =>
    HandwriteQuestion(
      questionId: json['question_id'] as String,
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
      answerType: json['answer_type'],
      writing: AnswerHandwrite.fromJson(
        json['writing'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$HandwriteQuestionToJson(HandwriteQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
      'exp': instance.exp,
      'target_word': instance.targetWord,
      'prompt': instance.prompt,
      'given': instance.given,
      'writing': instance.writing,
    };

PairingCardsQuestion _$PairingCardsQuestionFromJson(
  Map<String, dynamic> json,
) => PairingCardsQuestion(
  questionId: json['question_id'] as String,
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
  pairing: AnswerPairing.fromJson(json['pairing'] as Map<String, dynamic>),
  questionType: json['question_type'],
  answerType: json['answer_type'],
);

Map<String, dynamic> _$PairingCardsQuestionToJson(
  PairingCardsQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'pairing': instance.pairing,
};

MatchPicQuestion _$MatchPicQuestionFromJson(Map<String, dynamic> json) =>
    MatchPicQuestion(
      questionId: json['question_id'] as String,
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
      answerType: json['answer_type'],
    );

Map<String, dynamic> _$MatchPicQuestionToJson(MatchPicQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
      'exp': instance.exp,
      'target_word': instance.targetWord,
      'prompt': instance.prompt,
      'given': instance.given,
      'mcq': instance.mcq,
    };

CombineRadicalQuestion _$CombineRadicalQuestionFromJson(
  Map<String, dynamic> json,
) => CombineRadicalQuestion(
  questionId: json['question_id'] as String,
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
  answerType: json['answer_type'],
);

Map<String, dynamic> _$CombineRadicalQuestionToJson(
  CombineRadicalQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

CombineRadicalWithHintQuestion _$CombineRadicalWithHintQuestionFromJson(
  Map<String, dynamic> json,
) => CombineRadicalWithHintQuestion(
  questionId: json['question_id'] as String,
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
  answerType: json['answer_type'],
);

Map<String, dynamic> _$CombineRadicalWithHintQuestionToJson(
  CombineRadicalWithHintQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

FillInSentenceQuestion _$FillInSentenceQuestionFromJson(
  Map<String, dynamic> json,
) => FillInSentenceQuestion(
  questionId: json['question_id'] as String,
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
  answerType: json['answer_type'],
);

Map<String, dynamic> _$FillInSentenceQuestionToJson(
  FillInSentenceQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

ListeningQuestion _$ListeningQuestionFromJson(Map<String, dynamic> json) =>
    ListeningQuestion(
      questionId: json['question_id'] as String,
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
      answerType: json['answer_type'],
    );

Map<String, dynamic> _$ListeningQuestionToJson(ListeningQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
      'exp': instance.exp,
      'target_word': instance.targetWord,
      'prompt': instance.prompt,
      'given': instance.given,
      'mcq': instance.mcq,
    };

FillInVocabQuestion _$FillInVocabQuestionFromJson(Map<String, dynamic> json) =>
    FillInVocabQuestion(
      questionId: json['question_id'] as String,
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
      questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
      answerType: json['answer_type'],
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FillInVocabQuestionToJson(
  FillInVocabQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

IdentifyMirroredQuestion _$IdentifyMirroredQuestionFromJson(
  Map<String, dynamic> json,
) => IdentifyMirroredQuestion(
  questionId: json['question_id'] as String,
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
  answerType: json['answer_type'],
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IdentifyMirroredQuestionToJson(
  IdentifyMirroredQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

IdentifyWrongQuestion _$IdentifyWrongQuestionFromJson(
  Map<String, dynamic> json,
) => IdentifyWrongQuestion(
  questionId: json['question_id'] as String,
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  mcq: AnswerMultiChoice.fromJson(json['mcq'] as Map<String, dynamic>),
  questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
  answerType: json['answer_type'],
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$IdentifyWrongQuestionToJson(
  IdentifyWrongQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
  'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'mcq': instance.mcq,
};

CopyStrokeQuestion _$CopyStrokeQuestionFromJson(Map<String, dynamic> json) =>
    CopyStrokeQuestion(
      questionId: json['question_id'] as String,
      answerType: json['answer_type'],
      questionType: $enumDecode(_$QuestionTypeEnumMap, json['question_type']),
      exp: (json['exp'] as num).toInt(),
      targetWord: json['target_word'] as String,
      prompt: json['prompt'] as String,
      given: (json['given'] as List<dynamic>?)
          ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      writing: AnswerHandwrite.fromJson(
        json['writing'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$CopyStrokeQuestionToJson(CopyStrokeQuestion instance) =>
    <String, dynamic>{
      'question_id': instance.questionId,
      'question_type': _$QuestionTypeEnumMap[instance.questionType]!,
      'answer_type': _$AnswerTypeEnumMap[instance.answerType]!,
      'exp': instance.exp,
      'target_word': instance.targetWord,
      'prompt': instance.prompt,
      'given': instance.given,
      'writing': instance.writing,
    };

FillInRadicalQuestion _$FillInRadicalQuestionFromJson(
  Map<String, dynamic> json,
) => FillInRadicalQuestion(
  questionId: json['question_id'] as String,
  exp: (json['exp'] as num).toInt(),
  targetWord: json['target_word'] as String,
  prompt: json['prompt'] as String,
  given: (json['given'] as List<dynamic>?)
      ?.map((e) => GivenMaterial.fromJson(e as Map<String, dynamic>))
      .toList(),
  writing: AnswerHandwrite.fromJson(json['writing'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FillInRadicalQuestionToJson(
  FillInRadicalQuestion instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'exp': instance.exp,
  'target_word': instance.targetWord,
  'prompt': instance.prompt,
  'given': instance.given,
  'writing': instance.writing,
};
