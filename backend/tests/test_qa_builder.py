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


def test_copy_stroke_question(copy_stroke_question: CopyStrokeQuestion):
    builder = QuestionBuilder()
    question = (
        builder.copy_stroke()
        .set_target_word(ChineseChar("晴"))
        .add_given_image(image_url=str("https://example.com/stroke_image.png"))
        .set_prompt("請抄寫以下字")
        .set_handwrite_target("晴")
        .set_submit_url(str("https://example.com/submit_stroke"))
        .build()
    )

    q1_dict = copy_stroke_question.model_dump()
    q2_dict = question.model_dump()
    q1_dict.pop("question_id", None)  # Remove question_id for comparison
    q2_dict.pop("question_id", None)  # Remove question_id for comparison

    # Check if the question is correctly built
    assert q1_dict == q2_dict


def test_pairing_card_question(pairing_cards_question: PairingCardsQuestion):
    builder = QuestionBuilder()
    question = (
        builder.paring_cards()
        .set_target_word(ChineseChar("晴"))
        .add_pair("請", None, "求", None)
        .add_pair("清", None, "潔", None)
        .add_pair("晴", None, "天", None)
        .add_pair("精", None, "神", None)
        .set_display(MCQDisplayType.GRID, rows=2, columns=2)
        .set_prompt("配對詞語")
        .build()
    )

    q1_dict = pairing_cards_question.model_dump()
    q2_dict = question.model_dump()
    q1_dict.pop("question_id", None)  # Remove question_id for comparison
    q2_dict.pop("question_id", None)  # Remove question_id for comparison

    # Check if the question is correctly built
    assert q1_dict == q2_dict


def test_fill_in_vocab_question(fill_in_vocab_question: FillInVocabQuestion):
    builder = QuestionBuilder()
    question = (
        builder.fill_in_vocab()
        .add_choice("請", is_answer=False)
        .add_choice("清", is_answer=False)
        .add_choice("晴", is_answer=True)
        .add_choice("精", is_answer=False)
        .set_prompt("選字配詞")
        .add_given_text("？天", GivenTextLength.SHORT)
        .set_target_word(ChineseChar("晴"))
        .build()
    )

    q1_dict = fill_in_vocab_question.model_dump()
    q2_dict = question.model_dump()
    q1_dict.pop("question_id", None)  # Remove question_id for comparison
    q2_dict.pop("question_id", None)  # Remove question_id for comparison

    # Check if the question is correctly built
    assert q1_dict == q2_dict
