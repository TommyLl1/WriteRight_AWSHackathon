from enum import Enum
from typing import Optional, List, Self, Dict, Callable, TypeAlias, Union
from pydantic import BaseModel, Field, EmailStr, model_validator
from uuid import uuid4
from models.helpers import *
from models.QnA import *
from models.QnA_builder import *
from utils.logger import setup_logger

logger = setup_logger(__name__)

### NOTE: Without specified, int = INT8 in db


# ------ Database Models -------------------------

# time default: (EXTRACT(epoch FROM now()))::bigint)


class SupabaseTable(str, Enum):
    USERS = "users"
    PASSWORDS = "passwords"
    SESSIONS = "sessions"
    WORDS = "words"
    PAST_WRONG_WORDS = "past_wrong_words"
    QUESTIONS = "questions"
    GAME_DATA = "game_data"
    GAME_QA_HISTORY = "game_qa_history"
    GAME_SESSIONS = "game_sessions"
    HTR_REQUESTS = "ht_requests"
    TASKS = "tasks"
    USER_SETTINGS = "user_settings"
    FLAGGED_QUESTIONS = "flagged_questions"


class GameSessionStatus(str, Enum):
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    ABANDONED = "abandoned"


class SupabaseRPC(str, Enum):
    GET_USER_WRONG_WORDS_BY_USER = "get_past_wrong_words_by_user"
    GET_USER_WRONG_WORDS_BY_USER_AFTER = "get_wrong_words_by_user_after"
    INCREMENT_WRONG_COUNT_FOR_USER = "increment_wrong_count_for_user"
    UPDATE_QUESTION_STATS = "update_question_stats"
    COUNT_QUESTION_BY_TYPE = "count_question_types"
    RUN_RAW_SELECT = "run_arbitrary_select"
    CLEAN_GAME_SESSIONS = "cleanup_game_sessions"
    CLEAN_AUTH_SESSIONS = "cleanup_auth_sessions"
    ADD_NEW_USER_HANDLE_EXIST = "add_new_user"
    GET_OR_CREATE_TODAY_TASKS = "get_or_create_today_tasks"
    SET_TASK_PROGRESS = "set_task_progress"  # updated from MARK_TASK_FINISHED
    UPDATE_USER_EXPERIENCE = "update_user_experience"
    GET_RANDOM_WORDS = "get_random_words"
    GET_EXISTING_WORDS = "get_existing_words"
    GET_EXISTING_WRONG_WORD_IDS = "get_existing_wrong_word_ids"


# Class to hold only the necessary fields for a user's answer
class SubmittedAnswer(BaseModel):
    answer_type: AnswerType
    mc_answers: Optional[List[MultiChoiceAnswer]] = None
    handwriting_answer: Optional[str] = None
    pairing_answers: Optional[List[PairingOption]] = None

    @model_validator(mode="after")
    def validate_answers(self) -> Self:
        # Only one type of answer should be provided
        answer_types = [
            self.mc_answers is not None,
            self.handwriting_answer is not None,
            self.pairing_answers is not None,
        ]
        if sum(answer_types) != 1:
            raise ValueError(
                "Exactly one type of answer must be provided: mc_answers, handwriting_answer, or pairing_answers."
            )
        if self.answer_type == AnswerType.MULTIPLE_CHOICE and not self.mc_answers:
            raise ValueError(
                "Multiple choice answers must be provided for MULTIPLE_CHOICE type."
            )
        if self.answer_type == AnswerType.WRITING and not self.handwriting_answer:
            raise ValueError("Handwriting answer must be provided for WRITING type.")
        if self.answer_type == AnswerType.PAIRING and not self.pairing_answers:
            raise ValueError("Pairing answers must be provided for PAIRING type.")
        return self


class User(BaseModel):
    # user_id: UUIDStr = Field(
    #     default_factory=lambda: uuid4()
    # )  # Unique identifier for the user
    user_id: Optional[UUIDStr] = None
    email: EmailStr = Field(
        max_length=254,
        description="User's email address, must be a valid email format.",
        pattern=r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    )  # User's email address
    name: str = Field(max_length=100, description="User's name, up to 100 characters.")
    level: int = Field(default=1, ge=1)  # User's level, starting from 1
    # User's experience points, starting from 0
    exp: int = Field(default=0, ge=0)
    created_at: UnixTimestamp = Field(default_factory=get_time)


class Password(BaseModel):
    user_id: UUIDStr  # Foreign key to User, primary key
    email: EmailStr = Field(
        max_length=254,
        description="User's email address, must be unique",
    )
    hashed_password: str = Field(description="Bcrypt hashed password")
    salt: str = Field(description="Salt used for hashing")
    sso_provider: Optional[str] = Field(
        default=None, description="SSO provider if applicable (e.g., 'google', 'apple')"
    )
    sso_token: Optional[str] = Field(
        default=None, description="SSO token or identifier if needed"
    )
    created_at: UnixTimestamp = Field(default_factory=get_time)
    updated_at: UnixTimestamp = Field(default_factory=get_time)


class Session(BaseModel):
    session_id: str  # Primary key, unique session identifier
    user_id: UUIDStr  # Foreign key to User
    created_at: UnixTimestamp = Field(default_factory=get_time)
    expires_at: UnixTimestamp  # Session expiration timestamp
    is_active: bool = Field(default=True)


class Word(BaseModel):
    word: ChineseChar
    word_id: UnicodeInt = Field(
        default_factory=get_char_unicode_factory
    )  # Primary key, unique identifier for the word
    description: Optional[str] = None  # Description of the word
    image_url: Optional[str] = None
    pronunciation_url: Optional[str] = None
    strokes_url: Optional[str] = None

    @model_validator(mode="after")
    def validate_word_id(self) -> Self:
        # check if
        if self.word_id != to_unicodeInt_from_char(self.word):
            raise ValueError(
                f"Word ID {self.word_id} does not match the Unicode code point of the word '{self.word}'."
            )
        return self


class PastWrongWord(BaseModel):
    # Unique identifier for the past wrong word entry
    item_id: UUIDStr = Field(default_factory=lambda: uuid4())
    user_id: UUIDStr  # Foreign key to User
    word_id: UnicodeInt  # Foreign key to Word
    # Number of times the word was answered incorrectly
    wrong_count: int = Field(default=1, ge=1)
    wrong_image_url: Optional[str] = None
    last_wrong_at: UnixTimestamp = Field(default_factory=get_time)


class GameData(BaseModel):
    game_id: UUIDStr = Field(default_factory=lambda: uuid4())
    user_id: UUIDStr
    created_at: UnixTimestamp = Field(default_factory=get_time)
    earned_exp: int = Field(default=0, ge=0)  # Experience points earned in the game
    time_spent: int = Field(default=0, ge=0)  # Time spent in the game in seconds
    total_score: int = Field(default=0, ge=0)  # INT4
    question_count: int = Field(default=0, ge=0)  # INT4
    remaining_hearts: int = Field(default=3)  # Remaining hearts at the end of the game
    correct_count: int


class GameQAHistory(BaseModel):
    game_id: UUIDStr
    user_id: UUIDStr
    question_id: UUIDStr
    question_index: int  # Index of the question in the game
    answer: SubmittedAnswer  # The answer submitted by the user
    is_correct: bool
    # Value not present in database, removing this for now


class GameSession(BaseModel):
    game_id: UUIDStr = Field(default_factory=lambda: uuid4())
    user_id: UUIDStr
    question_ids: List[UUIDStr]  # List of question IDs in the game
    start_time: UnixTimestamp = Field(default_factory=get_time)
    status: GameSessionStatus = GameSessionStatus.IN_PROGRESS


class QuestionEntry(BaseModel):
    # Basicly QuestionBase without individual answer
    question_id: UUIDStr = Field(default_factory=lambda: uuid4())

    # Identifiers for the question
    question_type: QuestionType
    answer_type: AnswerType

    # Properties from QuestionBase
    given_material: Optional[List[givenMaterial]] = None
    target_word_id: UnicodeInt  # Foreign key to Word
    prompt: str

    # Optioal fields for multi-choice questions
    mc_choices: Optional[List[MultiChoiceOption]] = None
    mc_answers: Optional[List[MultiChoiceAnswer]] = None

    # Optional fields for pairing questions
    pairs: Optional[List[PairingOption]] = None
    pairing_display: Optional[MultiChoiceDisplay] = None

    # Optional field for handwriting questions
    handwrite_target: Optional[ChineseChar] = None
    background_image_url: Optional[str] = None  # Background image for the question

    # Additional metadata (Defaulted)
    created_at: UnixTimestamp = Field(default_factory=get_time)
    use_count: int = Field(
        default=0, ge=0
    )  # Number of times this question has been used
    correct_count: int = Field(
        default=0, ge=0
    )  # Number of times this question has been answered correctly

    @classmethod
    def from_question_base(cls, question: QuestionBase) -> Self:
        """
        Populate the QuestionEntry from a QuestionBase instance.
        """
        # Initialize optional arguments for different answer types
        opt_args = {}

        if question.answer_type == AnswerType.MULTIPLE_CHOICE:
            mcq = question.mcq
            if not mcq:
                raise ValueError(
                    "Invalid Object: Multiple choice questions must have a valid MCQ object."
                )
            opt_args["mc_choices"] = mcq.choices or []
            opt_args["mc_answers"] = mcq.answers or []

        elif question.answer_type == AnswerType.WRITING:
            writing = question.writing
            if not writing:
                raise ValueError(
                    "Invalid Object: Writing questions must have a valid Writing object."
                )
            opt_args["handwrite_target"] = writing.handwrite_target
            opt_args["background_image_url"] = writing.background_image

        elif question.answer_type == AnswerType.PAIRING:
            pairing = question.pairing
            if not pairing:
                raise ValueError(
                    "Invalid Object: Pairing questions must have a valid Pairing object."
                )
            opt_args["pairs"] = pairing.pairs or []
            opt_args["pairing_display"] = pairing.display

        # Create and return the instance
        return cls(
            question_id=question.question_id,
            question_type=question.question_type,
            answer_type=question.answer_type,
            given_material=question.given,
            prompt=question.prompt,
            target_word_id=to_unicodeInt_from_char(question.target_word),
            **opt_args,  # Pass optional arguments dynamically
        )

    def to_question_base(self, submit_url: Optional[str] = None) -> QuestionBase:
        """
        Convert the QuestionEntry back to a QuestionBase instance.
        """
        # Initialize the QuestionBuilder based on the answer type
        builder = QuestionBuilder()

        # Main split based on answer type
        sub_builder = None
        if self.answer_type in [AnswerType.MULTIPLE_CHOICE, AnswerType.WRITING]:
            if self.answer_type == AnswerType.MULTIPLE_CHOICE:
                mc_mapping: Dict[QuestionType, Callable[[], MCQBuilder]] = {
                    QuestionType.COMBINE_RADICAL: builder.combine_radical,
                    QuestionType.COMBINE_RADICAL_WITH_HINT: builder.combine_radical_with_hint,
                    QuestionType.FILL_IN_VOCAB: builder.fill_in_vocab,
                    QuestionType.FILL_IN_SENTENCE: builder.fill_in_sentence,
                    QuestionType.IDENT_WRONG: builder.identify_wrong,
                    QuestionType.IDENT_MIRRORED: builder.identify_mirrored,
                    QuestionType.LISTENING: builder.listening,
                    QuestionType.MATCH_PIC: builder.match_pic,
                }

                sub_builder = mc_mapping[self.question_type]()

                ## TODO: The logic in mc builder on multi choice mc is wrong already
                # Decompose the dict to pass as keyword arguments

                # 1. Add choices and answers

                # a. Validate the choices and answers
                if not self.mc_choices or not self.mc_answers:
                    logger.error(
                        "Multiple choice questions must have choices and answers defined."
                        f" Choices: {self.mc_choices}, Answers: {self.mc_answers}"
                        f"{self.question_id}, {self.question_type}, {self.answer_type}"
                    )
                    raise ValueError(
                        "Multiple choice questions must have choices and answers defined."
                    )

                # b. Extract choices and answers (Args to add_choice)
                extracted_choices = [
                    {
                        "text": choice.text,
                        "image_url": choice.image,
                    }
                    for choice in self.mc_choices
                ]
                correct_choices = set()
                for choice in self.mc_answers:
                    correct_choices.update(choice.choices)

                # format the correct choices into a mask
                correct_mask = [
                    choice.option_id in correct_choices for choice in self.mc_choices
                ]
                # c. Add multiple choice attributes
                for idx, choice in enumerate(extracted_choices):
                    sub_builder = sub_builder.add_choice(
                        **choice, is_answer=correct_mask[idx]
                    )

            elif self.answer_type == AnswerType.WRITING:
                w_mapping: Dict[QuestionType, Callable[[], HandwriteBuilder]] = {
                    QuestionType.FILL_IN_RADICAL: builder.fill_in_radical,
                    QuestionType.COPY_STROKE: builder.copy_stroke,
                }
                sub_builder = w_mapping[self.question_type]()
                if not self.handwrite_target:
                    raise ValueError(
                        "Writing questions must have a handwrite target defined."
                    )
                if not submit_url:
                    raise ValueError(
                        "Writing questions must have a submit URL defined."
                    )
                # Add writing attributes
                sub_builder = sub_builder.set_handwrite_target(
                    self.handwrite_target
                ).set_submit_url(
                    submit_url
                )  # alread checked at the front

                # Optionally set the background image if provided
                if self.background_image_url:
                    sub_builder = sub_builder.set_background_image(
                        self.background_image_url
                    )

            if not sub_builder:
                raise ValueError(
                    f"Unexpected: Unsupported question type for answer type {self.answer_type}: {self.question_type}"
                )

            # Common attributes for MCQ and Writing
            if self.given_material:
                for material in self.given_material:
                    if material.material_type == GivenMaterialType.IMAGE:
                        validated = givenImage.model_validate(material.model_dump())
                        # Alt text is defaulted None
                        sub_builder = sub_builder.add_given_image(
                            validated.image_url, validated.alt_text
                        )

                    # If Text
                    elif material.material_type in [
                        GivenMaterialType.TEXT_SHORT,
                        GivenMaterialType.TEXT_LONG,
                    ]:
                        if not isinstance(sub_builder, MCQBuilder):
                            raise ValueError(
                                "Text materials can only be added to MCQ questions."
                            )
                        # logger.debug("current material: %s", material)
                        # Validate the text material
                        validated = givenText.model_validate(material.model_dump())

                        # Map the material type to the appropriate text length
                        length_map = {
                            GivenMaterialType.TEXT_SHORT: GivenTextLength.SHORT,
                            GivenMaterialType.TEXT_LONG: GivenTextLength.LONG,
                        }
                        sub_builder = sub_builder.add_given_text(
                            validated.text, length_map[material.material_type]
                        )

                    elif material.material_type == GivenMaterialType.SOUND:
                        if not isinstance(sub_builder, MCQBuilder):
                            raise ValueError(
                                "Text materials can only be added to MCQ questions."
                            )
                        validated = givenSound.model_validate(material.model_dump())
                        sub_builder = sub_builder.add_given_sound(validated.sound_url)
                    else:
                        raise ValueError(
                            f"Unsupported given material type: {material.material_type}"
                        )

        elif self.answer_type == AnswerType.PAIRING:
            p_mapping: Dict[QuestionType, Callable[[], ParingQuestionBuilder]] = {
                QuestionType.PAIRING_CARDS: builder.paring_cards,
            }
            sub_builder = p_mapping[self.question_type]()
            # Add pairing attributes
            if not self.pairs:
                raise ValueError(
                    "Unexpected: Pairing questions must have pairs defined."
                )

            for pair in self.pairs:
                pair_items = {
                    "text1": pair.items[0].text,
                    "image_url1": pair.items[0].image,
                    "text2": pair.items[1].text,
                    "image_url2": pair.items[1].image,
                }

                sub_builder = sub_builder.add_pair(**pair_items)

            if not self.pairing_display:
                raise ValueError("Pairing questions must have a display type defined.")

            # Set the display type

            logger.debug("display: %s", self.pairing_display.model_dump())
            sub_builder = sub_builder.set_display(**self.pairing_display.model_dump())
        else:
            raise ValueError(
                f"Unexpected: Unsupported answer type {self.answer_type} for question type {self.question_type}."
            )

        # Set common attributes for all question types
        sub_builder = sub_builder.set_target_word(
            to_char_from_unicode(self.target_word_id)
        ).set_prompt(self.prompt)

        question_base = sub_builder.build()
        # Set the question ID
        question_base.question_id = self.question_id
        return question_base


# ------ RPC Models -------------------------
class GetPastWrongWordsByUserRPC(BaseModel):
    p_user_id: UUIDStr  # User ID to fetch past wrong words for
    p_limit: int = Field(
        default=10, ge=1, le=6000
    )  # Limit the number of results returned
    p_offset: int = Field(default=0, ge=0)  # Offset for pagination, default is 0


class GetPastWrongWordsByUserResponse(BaseModel):
    word_id: UnicodeInt
    word: ChineseChar
    description: Optional[str] = None
    image_url: Optional[str] = None
    pronunciation_url: Optional[str] = None
    strokes_url: Optional[str] = None
    wrong_count: int
    wrong_image_url: Optional[str] = None
    last_wrong_at: UnixTimestamp
    created_at: UnixTimestamp


class IncrementWrongCountForUserRPC(BaseModel):
    p_user_id: UUIDStr  # User ID to increment wrong count for
    p_word_ids: List[UnicodeInt]  # Word ID to increment wrong count for


class UpdateQuestionStatsRPC(BaseModel):
    p_answered_questions: List[UUIDStr]
    p_wrong_questions: List[UUIDStr]


class UpdateQuestionStatsResponse(BaseModel):
    answered_count: int
    wrong_count: int


class GetRandomWordsRPC(BaseModel):
    count: int


class GetExistingWordsRPC(BaseModel):
    word_ids: List[UnicodeInt]  # List of word IDs to check for existence


class GetExistingWrongWordIdsRPC(BaseModel):
    p_user_id: UUIDStr  # User ID to check for existing wrong words
    word_ids: List[UnicodeInt]  # List of word IDs to check for existence


# ------ Service Models -------------------------
class AuthServiceMethod(str, Enum):
    COGNITO = "cognito"
    GOOGLE = "google"
    FACEBOOK = "facebook"


class FlaggedQuestionStatus(str, Enum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    REJECTED = "rejected"
    RESOLVED = "resolved"
    ERROR = "error"
