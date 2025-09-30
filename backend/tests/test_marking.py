# Add root directory to sys.path
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

import pytest
from models.QnA import *


@pytest.mark.parametrize(
    "instance_fixture, expected_output",
    [
        ("answered_wrong_fill_in_vocab", False),
        ("answered_correct_fill_in_vocab", True),
        ("answered_wrong_pairing_cards", False),
        ("answered_correct_pairing_cards", True),
        ("answered_wrong_copy_stroke", False),
        ("answered_correct_copy_stroke", True),
    ],
)
def test_is_answered_correctly(instance_fixture, expected_output, request):
    instance = request.getfixturevalue(instance_fixture)
    logger.debug(instance.model_dump())
    logger.debug(type(instance))
    assert instance.is_correct == expected_output
