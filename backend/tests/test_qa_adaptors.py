# Add root directory to sys.path
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

from models.QnA import *
from models.db.db import *
import pytest
from models.helpers import to_unicodeInt_from_char


def test_copy_stroke_to_db(
    copy_stroke_question: CopyStrokeQuestion, copy_stroke_db: QuestionEntry
):
    converted_db_entry = QuestionEntry.from_question_base(copy_stroke_question)

    dict1 = converted_db_entry.model_dump()
    dict2 = copy_stroke_db.model_dump()
    # Remove fields that are not relevant for comparison
    dict1.pop("question_id", None)
    dict2.pop("question_id", None)
    dict1.pop("created_at", None)
    dict2.pop("created_at", None)
    assert dict1 == dict2


def test_pairing_card_to_db(
    pairing_cards_question: PairingCardsQuestion, pairing_cards_db: QuestionEntry
):
    converted_db_entry = QuestionEntry.from_question_base(pairing_cards_question)

    dict1 = converted_db_entry.model_dump()
    dict2 = pairing_cards_db.model_dump()
    # Remove fields that are not relevant for comparison
    dict1.pop("question_id", None)
    dict2.pop("question_id", None)
    dict1.pop("created_at", None)
    dict2.pop("created_at", None)
    assert dict1 == dict2


def test_pairing_card_from_db(
    pairing_cards_db: QuestionEntry, pairing_cards_question: PairingCardsQuestion
):
    logger.debug(pairing_cards_db.model_dump())
    converted_question: QuestionBase = pairing_cards_db.to_question_base()

    dict1 = converted_question.model_dump()
    dict2 = pairing_cards_question.model_dump()
    # Remove fields that are not relevant for comparison
    dict1.pop("question_id", None)
    dict2.pop("question_id", None)
    assert dict1 == dict2


def test_fill_vocab_to_db(
    fill_in_vocab_question: FillInVocabQuestion, fill_in_vocab_db: QuestionEntry
):
    converted_db_entry = QuestionEntry.from_question_base(fill_in_vocab_question)

    dict1 = converted_db_entry.model_dump()
    dict2 = fill_in_vocab_db.model_dump()
    # Remove fields that are not relevant for comparison
    dict1.pop("question_id", None)
    dict2.pop("question_id", None)
    dict1.pop("created_at", None)
    dict2.pop("created_at", None)
    assert dict1 == dict2


def test_fill_vocab_from_db(
    fill_in_vocab_db: QuestionEntry, fill_in_vocab_question: FillInVocabQuestion
):
    logger.debug(fill_in_vocab_db.model_dump())
    converted_question: QuestionBase = fill_in_vocab_db.to_question_base()

    dict1 = converted_question.model_dump()
    dict2 = fill_in_vocab_question.model_dump()
    # Remove fields that are not relevant for comparison
    dict1.pop("question_id", None)
    dict2.pop("question_id", None)
    assert dict1 == dict2
