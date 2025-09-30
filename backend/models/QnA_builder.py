from models.QnA import *
from models.LLM import (
    FillInVocabFormat,
    FillInSentenceFormat,
    PairingCardsFormat,
    FillInRadicalFormat,
)
from abc import ABC, abstractmethod
from typing import List, Optional, Sequence, Union
import random

# Q: Ident wrong is handwrite question not MCQ?
# A: No, ident wrong is a MCQ question, it gives some images of wrong handwritten characters


class QuestionBuilder:
    def __init__(self):
        self.question_type = None
        self.answer_type = None

    #######  Pairing Questions #######
    def paring_cards(self):
        self.question_type = QuestionType.PAIRING_CARDS
        self.answer_type = AnswerType.PAIRING
        return ParingQuestionBuilder(self.question_type, self.answer_type)

    #######  MC Questions #######
    def match_pic(self):
        self.question_type = QuestionType.MATCH_PIC
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def combine_radical(self):
        self.question_type = QuestionType.COMBINE_RADICAL
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def combine_radical_with_hint(self):
        self.question_type = QuestionType.COMBINE_RADICAL_WITH_HINT
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def fill_in_sentence(self):
        self.question_type = QuestionType.FILL_IN_SENTENCE
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def fill_in_vocab(self):
        self.question_type = QuestionType.FILL_IN_VOCAB
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def listening(self):
        self.question_type = QuestionType.LISTENING
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def identify_mirrored(self):
        self.question_type = QuestionType.IDENT_MIRRORED
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    def identify_wrong(self):
        self.question_type = QuestionType.IDENT_WRONG
        self.answer_type = AnswerType.MULTIPLE_CHOICE
        return MCQBuilder(self.question_type, self.answer_type)

    #######  Handwrite Questions #######
    def copy_stroke(self):
        self.question_type = QuestionType.COPY_STROKE
        self.answer_type = AnswerType.WRITING
        return HandwriteBuilder(self.question_type, self.answer_type)

    def fill_in_radical(self):
        self.question_type = QuestionType.FILL_IN_RADICAL
        self.answer_type = AnswerType.WRITING
        return HandwriteBuilder(self.question_type, self.answer_type)


class SubBuilder(ABC):
    """
    Abstract base class for sub-builders.
    Each sub-builder should implement the `build` method to return a specific question type.
    """

    def __init__(self, question_type: QuestionType, answer_type: AnswerType):
        # Identifiers
        self.question_id: UUIDStr = uuid4()
        self.question_type = question_type
        self.answer_type = answer_type
        self.prompt = ""
        self.time_limit = 0  # Default time limit in seconds
        self.target_word: Optional[ChineseChar] = None  # Target word for the question

    def set_question_id(self, question_id: UUIDStr):
        if not question_id:
            raise ValueError("Question ID must be provided")
        self.question_id = question_id
        return self

    def set_target_word(self, char: ChineseChar):
        if not char:
            raise ValueError("Target character must be provided")
        self.target_word = char
        return self

    def set_time_limit(self, time_limit: int):
        if time_limit <= 0:
            raise ValueError("Time limit must be a positive integer")
        self.time_limit = time_limit
        return self

    def set_prompt(self, prompt: str):
        self.prompt = prompt
        return self

    @abstractmethod
    def build(self) -> QuestionBase:
        """
        Build and return a question instance.
        """
        pass


class ParingQuestionBuilder(SubBuilder):
    def __init__(self, question_type: QuestionType, answer_type: AnswerType):
        super().__init__(question_type, answer_type)
        # Defaulted values
        self.prompt = "Match the items below"
        self.randomize = None

        # Pairing options (Required)
        self.display = None
        self.pairs: List[PairingOption] = []
        self.pairing_counter = 0

    def set_randomize(self, randomize: bool):
        self.randomize = randomize
        return self

    def set_display(
        self, display_type: MCQDisplayType, rows: int, columns: Optional[int] = None
    ) -> Self:
        # check if given type matches row/ column
        self.display = MultiChoiceDisplay(
            display_type=display_type, rows=rows, columns=columns
        )
        return self

    def add_pair(
        self,
        text1: Optional[str] = None,
        image_url1: Optional[str] = None,
        text2: Optional[str] = None,
        image_url2: Optional[str] = None,
    ) -> Self:
        if not (text1 or image_url1) or not (text2 or image_url2):
            raise ValueError(
                "At least one of text or image_url must be provided for both items"
            )

        # Append a new pairing option with an incremented pair_id
        self.pairs.append(
            PairingOption(
                pair_id=self.pairing_counter + 1,
                items=[
                    MultiChoiceOption(
                        option_id=self.pairing_counter * 2 + 1,
                        text=text1,
                        image=image_url1,
                    ),
                    MultiChoiceOption(
                        option_id=self.pairing_counter * 2 + 2,
                        text=text2,
                        image=image_url2,
                    ),
                ],
            )
        )

        self.pairing_counter += 1
        return self

    def build(self):
        pairing_data = {
            "randomize": self.randomize,
            "display": self.display,
            "time_limit": self.time_limit,
        }
        # Create a dict to remove None values
        pairing_data = {k: v for k, v in pairing_data.items() if v is not None}
        # Create the PairingCardsQuestion instance
        if not self.pairs:
            raise ValueError("At least one pair must be added")
        assert self.target_word, "Target word must be set before building the question"

        return PairingCardsQuestion(
            question_id=self.question_id,
            question_type=self.question_type,
            answer_type=self.answer_type,
            prompt=self.prompt,
            target_word=self.target_word,
            pairing=AnswerPairing(
                pairs=self.pairs,
                **pairing_data,
            ),
        )


class MCQBuilder(SubBuilder):
    def __init__(self, question_type: QuestionType, answer_type: AnswerType):
        super().__init__(question_type, answer_type)
        self.prompt = "Select the correct answer"

        # MC Settings (Defaulted)
        self.min_choices = None
        self.max_choices = None
        self.strict_order = None
        self.randomize = None
        self.display = MultiChoiceDisplay(display_type=MCQDisplayType.LIST, rows=4)

        # Given materials
        self.given: List[givenMaterial] = []

        # MC data
        self.answers: List[MultiChoiceAnswer] = []
        self.choices: List[MultiChoiceOption] = []

        # Counter
        self.choice_counter = 0
        self.answer_counter = 0
        self.given_counter = 0

    def add_choice(
        self,
        text: Optional[str] = None,
        image_url: Optional[str] = None,
        is_answer: bool = False,
    ) -> Self:
        if not text and not image_url:
            raise ValueError("At least one of text or image_url must be provided")

        # Append a new choice with an incremented option_id
        self.choices.append(
            MultiChoiceOption(
                option_id=self.choice_counter + 1, text=text, image=image_url
            )
        )
        self.choice_counter += 1

        # If it's an answer, create a new MultiChoiceAnswer
        if is_answer:
            self.answers.append(
                MultiChoiceAnswer(
                    answer_id=self.answer_counter + 1,
                    choices=[self.choice_counter],  # Use the current choice's ID
                )
            )
            self.answer_counter += 1

        return self

    def add_choices(
        self,
        choices: Sequence[Union[ChineseChar, str]],
        is_answers: Sequence[bool],
    ) -> Self:
        if len(choices) != len(is_answers):
            raise ValueError("Choices and is_answers must have the same length")

        for i, choice in enumerate(choices):
            self.add_choice(
                text=choice if isinstance(choice, ChineseChar) else None,
                image_url=choice if isinstance(choice, str) else None,
                is_answer=is_answers[i],
            )
        return self

    def add_given_image(self, image_url: str, alt_text: Optional[str] = None):
        if not image_url:
            raise ValueError("Image URL must be provided")

        # Append a new given image
        self.given.append(
            givenImage(
                material_type=GivenMaterialType.IMAGE,
                material_id=self.given_counter + 1,
                image_url=image_url,
                alt_text=alt_text,
            )
        )

        self.given_counter += 1
        return self

    def add_given_text(
        self, text: str, text_length: GivenTextLength = GivenTextLength.SHORT
    ):
        if not text:
            raise ValueError("Text must be provided")

        # Set material type based on text length
        material_type = (
            GivenMaterialType.TEXT_SHORT
            if text_length == GivenTextLength.SHORT
            else GivenMaterialType.TEXT_LONG
        )

        # Append a new given text
        self.given.append(
            givenText(
                material_type=material_type,
                material_id=self.given_counter + 1,
                text=text,
            )
        )
        self.given_counter += 1
        return self

    def add_given_sound(self, sound_url: str, alt_text: Optional[str] = None):
        if not sound_url:
            raise ValueError("Sound URL must be provided")

        # Append a new given sound
        self.given.append(
            givenSound(
                sound_url=sound_url, text=alt_text, material_id=self.given_counter + 1
            )
        )
        self.given_counter += 1
        return self

    def set_strict_order(self, strict: bool):
        self.strict_order = strict
        return self

    def set_randomize(self, randomize: bool):
        self.randomize = randomize
        return self

    def set_display(
        self, display_type: MCQDisplayType, rows: int, columns: Optional[int] = None
    ):
        self.display = MultiChoiceDisplay(
            display_type=display_type, rows=rows, columns=columns
        )
        return self

    def set_min_choices(self, min_choices: int):
        self.min_choices = min_choices
        return self

    def set_max_choices(self, max_choices: int):
        self.max_choices = max_choices
        return self

    def build(self) -> MultiChoiceQuestion:
        class_mapping: dict[QuestionType, type[MultiChoiceQuestion]] = {
            QuestionType.MATCH_PIC: MatchPicQuestion,
            QuestionType.COMBINE_RADICAL: CombineRadicalQuestion,
            QuestionType.COMBINE_RADICAL_WITH_HINT: CombineRadicalWithHintQuestion,
            QuestionType.FILL_IN_SENTENCE: FillInSentenceQuestion,
            QuestionType.FILL_IN_VOCAB: FillInVocabQuestion,
            QuestionType.LISTENING: ListeningQuestion,
            QuestionType.IDENT_MIRRORED: IdentifyMirroredQuestion,
            QuestionType.IDENT_WRONG: IdentifyWrongQuestion,
        }

        if self.question_type not in class_mapping:
            raise ValueError(f"Unsupported question type: {self.question_type}")

        ### TODO: 2 ways of checking the default values
        # Set all default to none, set defaults in each leaf question class
        # Set a setting class to hold all default values
        # Not stored in Database, so there has to be a default value corresponding to each question type
        # In human accessible way, bind each question type with their own display type. Why tf even make this attribute???

        # Did you mean the display type? It wouldnt make sense to show a pic in a list,
        # or a text in a grid, so why not just set the display type in each question class?
        # Because we may want to change the display type later, or we may want to use the same question type with different display types.
        # Or we may want to mix word and image choices in the same question type.

        # Create a dict to remove None values
        question_data = {
            "question_id": self.question_id,
            "question_type": self.question_type,
            "answer_type": self.answer_type,
            "prompt": self.prompt,
            "given": self.given,
            "target_word": self.target_word,
            "time_limit": self.time_limit,
        }
        question_data = {k: v for k, v in question_data.items() if v is not None}

        # Add MCQ specific data
        mc_data = {
            "min_choices": self.min_choices,
            "max_choices": self.max_choices,
            "strict_order": self.strict_order,
            "randomize": self.randomize,
            "display": self.display,
            "time_limit": self.time_limit,
        }
        mc_data = {k: v for k, v in mc_data.items() if v is not None}

        # Create the question instance
        question: MultiChoiceQuestion = class_mapping[self.question_type](
            **question_data,
            mcq=AnswerMultiChoice(
                **mc_data,
                choices=self.choices,
                answers=self.answers,
            ),
        )
        return question


class HandwriteBuilder(SubBuilder):
    def __init__(self, question_type: QuestionType, answer_type: AnswerType):
        super().__init__(question_type, answer_type)
        self.prompt = "Write the character below"

        # Handwrite settings
        self.handwrite_target: Optional[ChineseChar] = None
        self.submit_url: Optional[str] = None
        self.background_image: Optional[str] = None
        self.submitted_image: Optional[str] = None

        # Counter
        # Handwrite questions only have given images for now
        self.given: List[givenImage] = []
        self.given_counter = 0

    def set_handwrite_target(self, char: ChineseChar):
        if not char:
            raise ValueError("Target character must be provided")
        self.target = char
        return self

    def set_submit_url(self, url: str):
        if not url:
            raise ValueError("Submit URL must be provided")
        self.submit_url = url
        return self

    def set_background_image(self, image_url: str):
        if not image_url:
            raise ValueError("Background image URL must be provided")
        self.background_image = image_url
        return self

    def set_submitted_image(self, image_url: str):
        if not image_url:
            raise ValueError("Submitted image URL must be provided")
        self.submitted_image = image_url
        return self

    ## Only given image for now
    def add_given_image(self, image_url: str, alt_text: Optional[str] = None):
        if not image_url:
            raise ValueError("Image URL must be provided")

        # Append a new given image
        self.given.append(
            givenImage(
                material_type=GivenMaterialType.IMAGE,
                material_id=self.given_counter + 1,
                image_url=image_url,
                text=alt_text,
            )
        )
        self.given_counter += 1
        return self

    def build(self) -> CopyStrokeQuestion:
        assert self.target_word, "Target word must be set before building the question"
        assert self.submit_url, "Submit URL must be set before building the question"

        return CopyStrokeQuestion(
            question_id=self.question_id,
            question_type=self.question_type,
            answer_type=self.answer_type,
            prompt=self.prompt,
            target_word=self.target_word,
            given=self.given,
            writing=AnswerHandwrite(
                handwrite_target=self.target,
                submit_url=self.submit_url,
                background_image=self.background_image,
                submitted_image=self.submitted_image,
                time_limit=self.time_limit,
            ),
        )


class Adaptor:
    """
    Adding another layer to solve problem :(\n
    I hope this will be the last layer\n
    All functions here should be converting a **Structured class** to a **Question class**.
    """

    @classmethod
    def fill_in_vocab(
        cls,
        format_item: FillInVocabFormat,
    ) -> FillInVocabQuestion:
        """
        Converts a CondensedMCQ to a MultiChoiceQuestion.
        """
        # Random get a valid vocabulary and similar characters
        valid_vocabularies = [
            vocab
            for vocab in format_item.vocabularies
            if format_item.given_char in vocab
        ]
        choosen_vocabulary = (
            random.choice(valid_vocabularies) if valid_vocabularies else None
        )
        if not choosen_vocabulary:
            raise ValueError("No valid vocabulary found for the given character")

        # substitude the target word with ?
        for i, char in enumerate(choosen_vocabulary):
            if char == format_item.given_char:
                choosen_vocabulary = (
                    choosen_vocabulary[:i] + "?" + choosen_vocabulary[i + 1 :]
                )
                break

        choices = format_item.similar_characters
        choices.append(str(format_item.given_char))
        answer_mask = [choice == format_item.given_char for choice in choices]

        question = (
            QuestionBuilder()
            .fill_in_vocab()
            .set_prompt("Fill in the blank")
            .set_target_word(format_item.given_char)
            .add_given_text(choosen_vocabulary)
            .add_choices(
                choices=choices,
                is_answers=answer_mask,
            )
            .set_randomize(True)
            .set_display(MCQDisplayType.GRID, rows=2, columns=2)
            .set_time_limit(30)
            .build()
        )

        return FillInVocabQuestion(**question.model_dump())

    @classmethod
    def fill_in_sentence(
        cls,
        format_item: FillInSentenceFormat,
    ) -> FillInSentenceQuestion:
        """
        Converts a FillInSentenceFormat to a FillInSentenceQuestion.
        """
        # Convert the target word to ? in the sentence
        if str(format_item.given_char) not in format_item.sentence:
            raise ValueError(
                f"The given character {format_item.given_char} is not found in the sentence."
            )
        logger.debug(f"Original sentence: {format_item.sentence}")
        sentence_with_blank = format_item.sentence.replace(
            str(format_item.given_char), "?"
        )
        logger.debug(f"sentence_with_blank: {sentence_with_blank}")
        choices = format_item.similar_characters
        choices.append(str(format_item.given_char))
        answer_mask = [choice == str(format_item.given_char) for choice in choices]

        question = (
            QuestionBuilder()
            .fill_in_sentence()
            .set_prompt("Fill in the sentence")
            .set_target_word(format_item.given_char)
            .add_given_text(sentence_with_blank)
            .add_choices(
                choices=choices,
                is_answers=answer_mask,
            )
            .set_randomize(True)
            .set_display(MCQDisplayType.GRID, rows=2, columns=2)
            .set_time_limit(30)
            .build()
        )

        return FillInSentenceQuestion(**question.model_dump())

    @classmethod
    def pairing_cards(
        cls,
        format_item: PairingCardsFormat,
    ) -> PairingCardsQuestion:
        """
        Converts a PairingCardsFormat to a PairingCardsQuestion.
        """
        logger.debug(
            f"Converting PairingCardsFormat to PairingCardsQuestion: {format_item}"
        )
        question = (
            QuestionBuilder()
            .paring_cards()
            .set_prompt("Match the items below")
            .set_target_word(format_item.target_char)
            .set_randomize(True)
            .set_display(MCQDisplayType.GRID, rows=2, columns=2)
        )

        for word in format_item.words:
            if len(word) != 2:
                continue  # Skip if the word does not have exactly two parts
            question = question.add_pair(
                text1=word[0],
                text2=word[1],
            )

        question = question.build()
        return PairingCardsQuestion(**question.model_dump())

    # @classmethod
    # def fill_in_radical(
    #     cls,
    #     format_item: FillInRadicalFormat,
    # ) -> FillInRadicalQuestion:
    #     """
    #     Converts a FillInVocabFormat to a FillInRadicalQuestion.
    #     """
    #     # Mark Correct answer first
    #     answer_mask = [choice == format_item.answer for choice in format_item.choices]
    #     question = (
    #         QuestionBuilder()
    #         .fill_in_radical()
    #         .set_prompt("Fill in the radical")
    #         .set_target_word(format_item.answer)
    #         .add_given_text(format_item.question)
    #         .add_choices(
    #             choices=format_item.choices,
    #             is_answers=answer_mask,
    #         )
    #         .set_randomize(True)
    #         .set_display(MCQDisplayType.GRID, rows=2, columns=2)
    #         .set_time_limit(30)
    #         .build()
    #     )

    # return FillInRadicalQuestion(**question.model_dump())


# class Tester:
#     def pairing_cards(
#         self,

#     ) -> PairingCardsQuestion:
#         """
#         Builds a PairingCardsQuestion with default values.
#         """
#         return PairingCardsQuestion(
#             question_type=QuestionType.PAIRING_CARDS,
#             answer_type=AnswerType.PAIRING,
#             prompt="Match the items below",

#             # Unique properties
#             pairing=AnswerPairing(
#                 pairs=[
#                     PairingOption(
#                         pair_id=1,
#                         items=[
#                             MultiChoiceOption(
#                                 option_id=1,
#                                 text="Option 1",
#                                 image_url="https://example.com/image1.png"
#                             ),
#                             MultiChoiceOption(
#                                 option_id=2,
#                                 text="Option 2",
#                                 image_url="https://example.com/image2.png"
#                             )
#                         ]
#                     )
#                 ],
#                 randomize=True,
#                 display=MultiChoiceDisplayGrid,
#             )
#             # QuestionBase properties
#         )

#     def match_pic(
#         self,
#     ) -> MatchPicQuestion:
#         """
#         Builds a MatchPicQuestion with default values.
#         """
#         return MatchPicQuestion(
#             question_type=QuestionType.MATCH_PIC,
#             answer_type=AnswerType.MULTIPLE_CHOICE,
#             prompt="Match the pictures below",
#             given=[givenImage(
#                 image_url="https://example.com/given_image.png",
#                 text="Select the matching picture"
#             )],
#             mcq=AnswerMultiChoice(
#                 min_choices=2,
#                 max_choices=4,
#                 choices=[
#                     MultiChoiceOption(
#                         option_id=1,
#                         text="Picture 1",
#                         image_url="https://example.com/pic1.png"
#                     ),
#                     MultiChoiceOption(
#                         option_id=2,
#                         text="Picture 2",
#                         image_url="https://example.com/pic2.png"
#                     )
#                 ],
#                 randomize=True,
#                 display=MultiChoiceDisplayGrid,
#                 answers= MultiChoiceAnswer(
#                     answer_id=1,
#                     choices=[1]
#                 )
#                 timeLimit= 30,  # seconds
#             )
#         )

#     # FillInVocabQuestion = match pic, give text,
#     # identifyMirror = match pic, give image, and >=2 given image
#     # identify Wrong = match pic, give text

#     def copy_stroke(
#         self,
#     ) -> CopyStrokeQuestion:
#         """
#         Builds a CopyStrokesQuestion with default values.
#         """
#         return CopyStrokeQuestion(
#             question_type=QuestionType.COPY_STROKE,
#             answer_type=AnswerType.WRITING,
#             prompt="Copy the strokes of the character below",
#             writing=AnswerHandwrite(
#                 target: ChineseChar(
#                     char="汉"
#                 ),
#                 submit_url="https://example.com/submit_stroke",
#                 background_image= "https://example.com/stroke_background.png",
#                 submitted_image= "https://example.com/submitted_stroke.png",
#                 time_limit=60,  # seconds
#             )
#         )
