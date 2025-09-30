# type: ignore
# Add root directory to sys.path
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

### Test cases for QuestionBuilder ###

from models.QnA import *
from models.QnA_builder import *
import pytest
from models.db.db import *


@pytest.fixture
def fill_in_vocab_question() -> FillInVocabQuestion:
    return FillInVocabQuestion(
        prompt="選字配詞",
        given=[{"material_type": "text_short", "material_id": 1, "text": "？天"}],
        target_word=ChineseChar("晴"),
        mcq={
            "choices": [
                {"option_id": 1, "text": "請"},
                {"option_id": 2, "text": "清"},
                {"option_id": 3, "text": "晴"},
                {"option_id": 4, "text": "精"},
            ],
            "display": {"display_type": "list", "rows": 4},
            "answers": [{"answer_id": 1, "choices": [3]}],  # Correct answer is "晴"
        },
    )


@pytest.fixture
def pairing_cards_question() -> PairingCardsQuestion:
    return PairingCardsQuestion(
        prompt="配對詞語",
        target_word=ChineseChar("晴"),
        pairing={
            "pairs": [
                {
                    "pair_id": 1,
                    "items": [
                        {"text": "請", "option_id": 1},
                        {"text": "求", "option_id": 2},
                    ],
                },
                {
                    "pair_id": 2,
                    "items": [
                        {"text": "清", "option_id": 3},
                        {"text": "潔", "option_id": 4},
                    ],
                },
                {
                    "pair_id": 3,
                    "items": [
                        {"text": "晴", "option_id": 5},
                        {"text": "天", "option_id": 6},
                    ],
                },
                {
                    "pair_id": 4,
                    "items": [
                        {"text": "精", "option_id": 7},
                        {"text": "神", "option_id": 8},
                    ],
                },
            ],
            "display": {"display_type": "grid", "rows": 2, "columns": 2},
        },
    )


@pytest.fixture
def copy_stroke_question() -> CopyStrokeQuestion:
    return CopyStrokeQuestion(
        prompt="請抄寫以下字",
        target_word=ChineseChar("晴"),
        given=[
            {
                "material_id": 1,
                "material_type": "image",
                "image_url": "https://example.com/stroke_image.png",
            }
        ],
        writing={
            "handwrite_target": "晴",
            "submit_url": "https://example.com/submit_stroke",
        },
    )


@pytest.fixture
def fill_in_vocab_db() -> QuestionEntry:
    return QuestionEntry(
        question_type=QuestionType.FILL_IN_VOCAB,
        answer_type=AnswerType.MULTIPLE_CHOICE,
        prompt="選字配詞",
        given_material=[
            {"material_type": "text_short", "material_id": 1, "text": "？天"}
        ],
        target_word_id=to_unicodeInt_from_char("晴"),
        mc_choices=[
            {"option_id": 1, "text": "請"},
            {"option_id": 2, "text": "清"},
            {"option_id": 3, "text": "晴"},
            {"option_id": 4, "text": "精"},
        ],
        mc_answers=[
            {
                "answer_id": 1,
                "choices": [3],  # The correct answer is "晴"
            }
        ],
    )


@pytest.fixture
def pairing_cards_db() -> QuestionEntry:
    return QuestionEntry(
        question_type=QuestionType.PAIRING_CARDS,
        answer_type=AnswerType.PAIRING,
        prompt="配對詞語",
        target_word_id=to_unicodeInt_from_char("晴"),
        pairs=[
            {
                "pair_id": 1,
                "items": [
                    {"text": "請", "option_id": 1},
                    {"text": "求", "option_id": 2},
                ],
            },
            {
                "pair_id": 2,
                "items": [
                    {"text": "清", "option_id": 3},
                    {"text": "潔", "option_id": 4},
                ],
            },
            {
                "pair_id": 3,
                "items": [
                    {"text": "晴", "option_id": 5},
                    {"text": "天", "option_id": 6},
                ],
            },
            {
                "pair_id": 4,
                "items": [
                    {"text": "精", "option_id": 7},
                    {"text": "神", "option_id": 8},
                ],
            },
        ],
        pairing_display={"display_type": "grid", "rows": 2, "columns": 2},
    )


@pytest.fixture
def copy_stroke_db() -> QuestionEntry:
    return QuestionEntry(
        question_type=QuestionType.COPY_STROKE,
        answer_type=AnswerType.WRITING,
        prompt="請抄寫以下字",
        target_word_id=to_unicodeInt_from_char("晴"),
        given_material=[
            {
                "material_type": "image",
                "material_id": 1,
                "image_url": "https://example.com/stroke_image.png",
            }
        ],
        handwrite_target="晴",
        submit_url="https://example.com/submit_stroke",
    )


@pytest.fixture
def answered_wrong_fill_in_vocab() -> FillInVocabQuestion:
    return FillInVocabQuestion(
        question_type=QuestionType.FILL_IN_VOCAB,
        prompt="選字配詞",
        given=[{"material_type": "text_short", "material_id": 1, "text": "？天"}],
        target_word=ChineseChar("晴"),
        mcq={
            "choices": [
                {"option_id": 1, "text": "請"},
                {"option_id": 2, "text": "清"},
                {"option_id": 3, "text": "晴"},
                {"option_id": 4, "text": "精"},
            ],
            "display": {"display_type": "list", "rows": 4},
            "answers": [{"answer_id": 1, "choices": [3]}],  # Correct answer is "晴"
            "submitted_answers": [
                {
                    "answer_id": 1,
                    "choices": [1],  # User selected "請" (wrong answer)
                }
            ],
        },
    )


@pytest.fixture
def answered_correct_fill_in_vocab() -> FillInVocabQuestion:
    return FillInVocabQuestion(
        question_type=QuestionType.FILL_IN_VOCAB,
        prompt="選字配詞",
        given=[{"material_type": "text_short", "material_id": 1, "text": "？天"}],
        target_word=ChineseChar("晴"),
        mcq={
            "choices": [
                {"option_id": 1, "text": "請"},
                {"option_id": 2, "text": "清"},
                {"option_id": 3, "text": "晴"},
                {"option_id": 4, "text": "精"},
            ],
            "display": {"display_type": "list", "rows": 4},
            "answers": [{"answer_id": 1, "choices": [3]}],  # Correct answer is "晴"
            "submitted_answers": [
                {
                    "answer_id": 1,
                    "choices": [3],  # User selected "晴"
                }
            ],
        },
    )


@pytest.fixture
def answered_wrong_pairing_cards() -> PairingCardsQuestion:
    return PairingCardsQuestion(
        question_type=QuestionType.PAIRING_CARDS,
        prompt="配對詞語",
        target_word=ChineseChar("晴"),
        pairing={
            "pairs": [
                {
                    "pair_id": 1,
                    "items": [
                        {"text": "請", "option_id": 1},
                        {"text": "求", "option_id": 2},
                    ],
                },
                {
                    "pair_id": 2,
                    "items": [
                        {"text": "清", "option_id": 3},
                        {"text": "潔", "option_id": 4},
                    ],
                },
                {
                    "pair_id": 3,
                    "items": [
                        {"text": "晴", "option_id": 5},
                        {"text": "天", "option_id": 6},
                    ],
                },
                {
                    "pair_id": 4,
                    "items": [
                        {"text": "精", "option_id": 7},
                        {"text": "神", "option_id": 8},
                    ],
                },
            ],
            "submitted_pairs": [
                {
                    "pair_id": 1,
                    "items": [
                        {"text": "精", "option_id": 7},
                        {"text": "神", "option_id": 8},
                    ],
                },
                {
                    "pair_id": 2,
                    "items": [
                        {"text": "請", "option_id": 1},
                        {"text": "求", "option_id": 2},
                    ],
                },
                {
                    "pair_id": 3,
                    "items": [
                        {"text": "清", "option_id": 3},
                        {"text": "晴", "option_id": 5},
                    ],
                },
                {
                    "pair_id": 4,
                    "items": [
                        {"text": "清", "option_id": 3},
                        {"text": "天", "option_id": 6},
                    ],
                },
            ],
            "display": {"display_type": "grid", "rows": 2, "columns": 2},
        },
    )


@pytest.fixture
def answered_correct_pairing_cards() -> PairingCardsQuestion:
    return PairingCardsQuestion(
        question_type=QuestionType.PAIRING_CARDS,
        prompt="配對詞語",
        target_word=ChineseChar("晴"),
        pairing={
            "pairs": [
                {
                    "pair_id": 1,
                    "items": [
                        {"text": "請", "option_id": 1},
                        {"text": "求", "option_id": 2},
                    ],
                },
                {
                    "pair_id": 2,
                    "items": [
                        {"text": "清", "option_id": 3},
                        {"text": "潔", "option_id": 4},
                    ],
                },
                {
                    "pair_id": 3,
                    "items": [
                        {"text": "晴", "option_id": 5},
                        {"text": "天", "option_id": 6},
                    ],
                },
                {
                    "pair_id": 4,
                    "items": [
                        {"text": "精", "option_id": 7},
                        {"text": "神", "option_id": 8},
                    ],
                },
            ],
            "submitted_pairs": [
                {
                    "pair_id": 1,
                    "items": [
                        {"text": "精", "option_id": 7},
                        {"text": "神", "option_id": 8},
                    ],
                },
                {
                    "pair_id": 2,
                    "items": [
                        {"text": "請", "option_id": 1},
                        {"text": "求", "option_id": 2},
                    ],
                },
                {
                    "pair_id": 3,
                    "items": [
                        {"text": "清", "option_id": 3},
                        {"text": "潔", "option_id": 4},
                    ],
                },
                {
                    "pair_id": 4,
                    "items": [
                        {"text": "晴", "option_id": 5},
                        {"text": "天", "option_id": 6},
                    ],
                },
            ],
            "display": {"display_type": "grid", "rows": 2, "columns": 2},
        },
    )


@pytest.fixture
def answered_wrong_copy_stroke() -> CopyStrokeQuestion:
    return CopyStrokeQuestion(
        question_type=QuestionType.COPY_STROKE,
        prompt="請抄寫以下字",
        target_word=ChineseChar("晴"),
        given=[
            {
                "material_type": "image",
                "material_id": 1,
                "image_url": "https://example.com/stroke_image.png",
            }
        ],
        submit_url="https://example.com/submit_stroke",
        writing={
            "handwrite_target": "晴",
            "submit_url": "https://example.com/submit_stroke",
            "is_correct": False,
        },
    )


@pytest.fixture
def answered_correct_copy_stroke() -> CopyStrokeQuestion:
    return CopyStrokeQuestion(
        question_type=QuestionType.COPY_STROKE,
        prompt="請抄寫以下字",
        target_word=ChineseChar("晴"),
        given=[
            {
                "material_type": "image",
                "material_id": 1,
                "image_url": "https://example.com/stroke_image.png",
            }
        ],
        submit_url="https://example.com/submit_stroke",
        writing={
            "handwrite_target": "晴",
            "submit_url": "https://example.com/submit_stroke",
            "is_correct": True,
            "submitted_image": "https://example.com/submitted_stroke_image.png",
        },
    )


@pytest.fixture(scope="session")
def wrong_words_test_user_id():
    # Use a fixed UUID for all stress tests
    return "b2977f0b-b464-4be3-9057-984e7ac4c9a9"
