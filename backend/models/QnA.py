from enum import Enum
from typing import List, Optional, Literal, Union, Self
from pydantic import BaseModel, Field, model_validator
from models.helpers import UUIDStr, ChineseChar, UnicodeInt
from uuid import uuid4
from utils.logger import setup_logger

# Setup logger for this module
logger = setup_logger(__name__)

# ------ Remarks -------------------------
# 1. NOTE: type: ignore is used to suppress inheritance-related type checking errors
# The ellipsis (...) in the type hint is not recognized by Pydantic
# See: https://docs.pydantic.dev/latest/concepts/fields/


# ------ Question and Answer Enums -------------------------
# Enums for Question and Answer Types
class QuestionType(str, Enum):
    PAIRING_CARDS = "pairing_cards"
    MATCH_PIC = "match_pic"
    COMBINE_RADICAL = "combine_radical"
    COMBINE_RADICAL_WITH_HINT = "combine_radical_with_hint"
    FILL_IN_SENTENCE = "fill_in_sentence"
    LISTENING = "listening"
    FILL_IN_VOCAB = "fill_in_vocab"
    IDENT_MIRRORED = "ident_mirrored"
    IDENT_WRONG = "ident_wrong"
    COPY_STROKE = "copy_stroke"
    FILL_IN_RADICAL = "fill_in_radical"


class AnswerType(str, Enum):
    MULTIPLE_CHOICE = "mcq"
    WRITING = "writing"
    PAIRING = "pairing"


class GivenMaterialType(str, Enum):
    TEXT_LONG = "text_long"
    TEXT_SHORT = "text_short"
    IMAGE = "image"
    SOUND = "sound"


class GivenTextLength(Enum):
    LONG = 1
    SHORT = 2


class MCQDisplayType(str, Enum):
    GRID = "grid"
    LIST = "list"


# ------ Display methods -------------------------
class MultiChoiceDisplay(BaseModel):
    display_type: MCQDisplayType  # Type of display for the multi-choice question
    rows: int  # Number of rows in the display
    columns: Optional[int] = (
        None  # Number of columns in the display, optional for list type
    )

    @model_validator(mode="after")
    def validate_display(self) -> Self:
        if self.display_type not in MCQDisplayType:
            raise ValueError(f"Invalid question_type: {self.display_type}")

        if self.display_type == MCQDisplayType.GRID and (
            self.columns is None or self.columns <= 0
        ):
            raise ValueError(
                "columns must be specified and greater than 0 for GRID display type"
            )
        if self.display_type == MCQDisplayType.LIST and (self.columns is not None):
            raise ValueError("columns should not be specified for LIST display type")

        return self


# ------ Given Materials -------------------------
class givenMaterial(BaseModel):
    material_type: GivenMaterialType
    material_id: int
    image_url: Optional[str] = None
    alt_text: Optional[str] = None
    sound_url: Optional[str] = None
    text: Optional[str] = None


class givenImage(givenMaterial):
    # NOTE: See remark 1 at the top of the file
    material_type: GivenMaterialType = GivenMaterialType.IMAGE
    image_url: str  # type: ignore
    alt_text: Optional[str] = None  # Optional alt text for the image


class givenSound(givenMaterial):
    # NOTE: See remark 1 at the top of the file
    material_type: GivenMaterialType = GivenMaterialType.SOUND
    sound_url: str  # type: ignore


class givenText(givenMaterial):
    # NOTE: See remark 1 at the top of the file
    material_type: GivenMaterialType = GivenMaterialType.TEXT_LONG
    text: str  # type: ignore


# ------ Things in user Answers ---------------
class MultiChoiceOption(BaseModel):
    option_id: int  # Unique identifier for the option
    text: Optional[str] = None  # Text of the option
    image: Optional[str] = None  # Image for the option

    @model_validator(mode="after")
    def validate_option(self) -> Self:
        if not (self.text or self.image):
            raise ValueError(
                "Either text or image must be provided for MultiChoiceOption"
            )
        return self


class MultiChoiceAnswer(BaseModel):
    # One combination of correct choices
    answer_id: int  # Unique identifier for the answer
    # List of selected option IDs, ordering matter if strict_order is True
    choices: List[int]


class PairingOption(BaseModel):
    pair_id: int  # Unique identifier for the pair
    # One valid combination of option
    items: List[MultiChoiceOption]  # List of options in the pair

    # validate that all option_id in this pairing option are unique
    @model_validator(mode="after")
    def check_unique_option_ids(self) -> Self:
        all_ids = [item.option_id for item in self.items]
        if len(all_ids) != len(set(all_ids)):
            raise ValueError("All option_ids in PairingOption must be unique")
        return self


# ------ User Answers -------------------------
class AnswerMethodBase(BaseModel):
    time_limit: int = 0  # Time limit for answering in seconds, 0 for no limit


class AnswerHandwrite(AnswerMethodBase):
    handwrite_target: ChineseChar
    submit_url: str  # URL to submit the handwritten answer
    # Background image for the answer, if any
    background_image: Optional[str] = None
    # URL of the submitted handwritten image
    # NOTE: (JEFF): What are the differences between this and submit_url????
    # submit_url is the URL to submit the answer (api endpoint),
    # while submitted_image is the URL of the submitted image, returned after submission
    submitted_image: Optional[str] = None

    # NOTE: (JEFF): I put this here now for easy ans checking
    # If anything broken remove this field
    is_correct: Optional[bool] = None


class AnswerMultiChoice(AnswerMethodBase):
    min_choices: int = Field(
        default=1, ge=1, description="Minimum number of choices to select"
    )
    max_choices: int = Field(
        default=1, ge=1, description="Maximum number of choices to select"
    )
    choices: List[MultiChoiceOption]  # List of choices available for selection
    # strict order used when the order of choices matters
    # e.g. when the user must select options in a specific sequence
    # the correct order will be dictated by order of answer
    strict_order: bool = Field(
        default=False, description="If the order of choices matters"
    )
    randomize: bool = Field(
        default=True, description="If the choices should be placed randomized"
    )
    # Display question_type for the choices
    display: MultiChoiceDisplay
    # List of correct answers, each with a list of selected option IDs
    answers: List[MultiChoiceAnswer]
    # User's submitted answers, if any
    submitted_answers: Optional[List[MultiChoiceAnswer]] = None

    @model_validator(mode="after")
    def validate_min_max_choices(self) -> Self:
        if self.max_choices < self.min_choices:
            raise ValueError("max_choices must be greater than or equal to min_choices")
        return self


class AnswerPairing(AnswerMethodBase):
    # The correct answer is grouping of pairs
    # equivlant to both choices and answers in multi-choice
    pairs: List[PairingOption]  # List of pairing options
    randomize: bool = Field(
        default=True, description="If the choices should be placed randomized"
    )
    # No default display type, must be set by the question
    display: MultiChoiceDisplay
    # User's submitted pairs, if any
    submitted_pairs: Optional[List[PairingOption]] = None

    # verify all pairing options have unique pair_id, and all option_ids within this answer are unique
    @model_validator(mode="after")
    def validate_pairing_options(self) -> Self:
        all_pair_ids = [pair.pair_id for pair in self.pairs]
        if len(all_pair_ids) != len(set(all_pair_ids)):
            raise ValueError("All pair_ids must be unique")

        # Check that all option_ids within pairs are unique
        # Flatten the list of option_ids from all pairs (magic list comprehension)
        all_option_ids = [item.option_id for pair in self.pairs for item in pair.items]
        if len(all_option_ids) != len(set(all_option_ids)):
            raise ValueError("All option_ids within pairs must be unique")

        return self


# ------ Question Model -------------------------
class QuestionBase(BaseModel):
    question_id: UUIDStr = Field(default_factory=lambda: uuid4())
    question_type: QuestionType
    answer_type: AnswerType
    exp: int = Field(
        default=10,
        ge=0,
        description="Experience points awarded for answering correctly",
    )
    # NOTE: Logic would be so messy without this
    target_word: ChineseChar
    prompt: str  # The question prompt or text
    # Optional materials provided with the question
    given: Optional[List[givenMaterial]] = None
    # Multi-choice answer method, if applicable
    mcq: Optional[AnswerMultiChoice] = None
    # Pairing answer method, if applicable
    pairing: Optional[AnswerPairing] = None
    # Handwriting answer method, if applicable
    writing: Optional[AnswerHandwrite] = None

    # model validator for answer_type, make sure the corresponding answer method is provided
    @model_validator(mode="after")
    def validate_answer_method(self) -> Self:
        # Ensure only 1 method is provided
        methods = [self.mcq, self.pairing, self.writing]
        if sum(m is not None for m in methods) != 1:
            raise ValueError("Exactly one answer method must be provided")
        # Ensure the answer_type matches the provided method
        if self.answer_type == AnswerType.MULTIPLE_CHOICE and self.mcq is None:
            raise ValueError("AnswerType MULTIPLE_CHOICE requires mcq method")
        if self.answer_type == AnswerType.PAIRING and self.pairing is None:
            raise ValueError("AnswerType PAIRING requires pairing method")
        if self.answer_type == AnswerType.WRITING and self.writing is None:
            raise ValueError("AnswerType WRITING requires writing method")
        return self

    @property
    def is_correct(self) -> bool:
        """
        Base method to check if the user's answer is correct.
        This method should be overridden by specific question types.
        """
        logger.warning("is_correct base method invoked, which should not happen.")

        return False


class MultiChoiceQuestion(QuestionBase):
    # NOTE: See remark 1 at the top of the file
    answer_type: AnswerType = AnswerType.MULTIPLE_CHOICE  # type: ignore
    mcq: AnswerMultiChoice  # type: ignore

    @property
    def is_correct(self) -> bool:
        """
        Determines if the user's submitted answer is correct by comparing it to the valid answers.

        Args:
            user_answer (AnswerMultiChoice): The user's submitted answer, which contains a list of
                                             submitted choices.

        Returns:
            bool: True if the user's submitted answer matches any of the valid answers, False otherwise.

        Behavior:
            - If `user_answer.submitted_answers` is empty, the method returns False.
            - If `self.mcq.strict_order` is True:
                - The method checks if the submitted choices match any valid answer exactly,
                  including order and length.
            - If `self.mcq.strict_order` is False:
                - The method checks if the submitted choices match any valid answer,
                  ignoring order but ensuring all elements match.

        Notes:
            - The comparison is performed against the `self.mcq.answers` list, which contains
              the valid answers for the multiple-choice question.
        """
        user_answer = self.mcq
        if not user_answer.submitted_answers:
            return False
        submitted_choice = user_answer.submitted_answers[0].choices
        if self.mcq.strict_order:
            # If strict order, check if the submitted choices match exactly
            for valid_answer in self.mcq.answers:
                # check if the submitted choices match the valid answer
                if len(submitted_choice) == len(valid_answer.choices) and all(
                    sc == va for sc, va in zip(submitted_choice, valid_answer.choices)
                ):
                    return True
            return False
        # If not strict order, check if any of the submitted choices match any valid answer
        for valid_answer in self.mcq.answers:
            if set(submitted_choice) == set(valid_answer.choices):
                return True
        return False


class PairingQuestion(QuestionBase):
    # NOTE: See remark 1 at the top of the file
    answer_type: AnswerType = AnswerType.PAIRING  # type: ignore
    pairing: AnswerPairing  # type: ignore

    @property
    def is_correct(self) -> bool:
        """
        Check if the submitted pairs match the correct pairs.
        The grouping of option_ids in submitted_pairs must match the grouping in pairs,
        regardless of the pair_id or the order of pairs.

        Args:
            user_answer (AnswerPairing): The user's submitted answer.

        Returns:
            bool: True if the submitted pairs match the correct pairs, False otherwise.
        """
        # Extract the correct groupings of option_ids
        user_answer = self.pairing
        if not user_answer.submitted_pairs:
            return False

        correct_groupings = [
            set(item.option_id for item in pair.items) for pair in self.pairing.pairs
        ]

        # Extract the submitted groupings of option_ids
        submitted_groupings = [
            set(item.option_id for item in pair.items)
            for pair in user_answer.submitted_pairs
        ]

        # Check if the groupings match (ignoring order)
        # Use frozenset to ignore order of pairs and option_ids
        # This allows us to compare sets of sets
        if len(correct_groupings) != len(submitted_groupings):
            return False
        return set(map(frozenset, correct_groupings)) == set(
            map(frozenset, submitted_groupings)
        )


class HandwriteQuestion(QuestionBase):
    # NOTE: See remark 1 at the top of the file
    answer_type: AnswerType = AnswerType.WRITING  # type: ignore
    writing: AnswerHandwrite  # type: ignore

    @property
    def is_correct(self) -> bool:
        """
        Checks if the user's handwritten answer is correct.

        Returns:
            bool: True if the user's handwritten answer is correct and an image
            has been submitted; otherwise, False.
        """

        # If the user has not submitted an image, return False
        # If the user has submitted, extract the correctness from the AnswerHandwrite object
        return (
            (self.writing.is_correct or False)
            if self.writing.submitted_image
            else False
        )


# ------ Question Types -------------------------
class PairingCardsQuestion(PairingQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.PAIRING_CARDS  # type: ignore


class MatchPicQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.MATCH_PIC  # type: ignore
    # List of images to match
    given: List[givenImage]  # type: ignore


class CombineRadicalQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.COMBINE_RADICAL  # type: ignore
    # server-side generated target Character image with placeholder boxes
    given: List[givenImage]  # type: ignore

    @model_validator(mode="after")
    def validate_strict_order(self) -> Self:
        if not self.mcq.strict_order:
            raise ValueError(
                "strict_order must be set to True for CombineRadicalQuestion"
            )
        return self


class CombineRadicalWithHintQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = (  # type: ignore
        QuestionType.COMBINE_RADICAL_WITH_HINT
    )
    # server-side generated target Character image with placeholder boxes
    # And also a hint image with full character
    given: List[givenImage]  # type: ignore

    @model_validator(mode="after")
    def validate_strict_order(self) -> Self:
        if not self.mcq.strict_order:
            raise ValueError(
                "strict_order must be set for CombineRadicalWithHintQuestion"
            )
        if len(self.given) < 2:
            raise ValueError(
                "CombineRadicalWithHintQuestion requires at least 2 given images"
            )
        return self


class FillInSentenceQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.FILL_IN_SENTENCE  # type: ignore
    given: List[givenText]  # type: ignore # Sentence text with placeholders


class ListeningQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.LISTENING  # type: ignore
    given: List[givenSound]  # type: ignore # List of audio files to listen to


class FillInVocabQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.FILL_IN_VOCAB  # type: ignore
    given: List[givenText]  # type: ignore # Vocab with placeholders


class IdentifyMirroredQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.IDENT_MIRRORED  # type: ignore
    given: List[givenImage]  # type: ignore # List of images to identify mirrored characters

    @model_validator(mode="after")
    def validate_strict_order(self) -> Self:
        if len(self.given) < 2:
            raise ValueError(
                "IdentifyMirroredQuestion requires at least 2 given images"
            )
        return self


class IdentifyWrongQuestion(MultiChoiceQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.IDENT_WRONG  # type: ignore
    given: List[givenText]  # type: ignore # Find the wrong character in the given text


class CopyStrokeQuestion(HandwriteQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.COPY_STROKE  # type: ignore
    # The target character to copy, provided as an image
    given: List[givenImage]  # type: ignore  # List of images with the target character to copy


class FillInRadicalQuestion(HandwriteQuestion):
    # NOTE: See remark 1 at the top of the file
    question_type: QuestionType = QuestionType.FILL_IN_RADICAL  # type: ignore
    # The target radical to fill in, provided as an image
    # List of images with the target radical replaced with placeholder boxes
    given: List[givenImage]  # type: ignore

    @model_validator(mode="after")
    def validate_strict_order(self) -> Self:
        if len(self.given) > 1:
            raise ValueError(
                "FillInRadicalQuestion should have exactly one given image"
            )
        return self
