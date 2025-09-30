"""
Test script for the Enhanced Question Generation Service.

This script validates the new 6-step question generation logic
and provides examples of how to use the enhanced service.
"""

import asyncio
import sys
import os
from dotenv import load_dotenv

# Add the workspace root to sys.path
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
load_dotenv()

from features.enhanced_question_service import (
    EnhancedQuestionService,
    ScoredQuestion,
    WordQuestionBatch,
)
from models.db.db import QuestionEntry, QuestionType
from models.helpers import ChineseChar, get_time, UUIDStr
from utils.logger import setup_logger

logger = setup_logger(__name__, level="DEBUG")


class MockDatabaseService:
    """Mock database service for testing."""

    async def execute_complex_query(
        self, query: str, params: dict, return_type=dict, fetch_mode="all"
    ):
        """Mock implementation that returns sample data."""
        from models.helpers import APIResponse

        # Mock response with sample questions
        mock_questions = [
            {
                "question_id": "test-1",
                "question_type": "FILL_IN_VOCAB",
                "answer_type": "MULTIPLE_CHOICE",
                "target_word_id": 20013,  # "中"
                "prompt": "Choose the correct word:",
                "created_at": get_time() - 3600,  # 1 hour ago
                "use_count": 5,
                "correct_count": 4,
                "mc_choices": [],
                "mc_answers": [],
            },
            {
                "question_id": "test-2",
                "question_type": "FILL_IN_SENTENCE",
                "answer_type": "MULTIPLE_CHOICE",
                "target_word_id": 20013,  # "中"
                "prompt": "Fill in the blank:",
                "created_at": get_time() - 7200,  # 2 hours ago
                "use_count": 10,
                "correct_count": 7,
                "mc_choices": [],
                "mc_answers": [],
            },
        ]

        return APIResponse(data=mock_questions, count=len(mock_questions))


class MockWordService:
    """Mock word service for testing."""

    async def get_random_words(self, count: int):
        """Return mock words."""
        from models.db.db import Word

        return [
            Word(word_id=20013, word="中", description="middle, center"),
            Word(word_id=25991, word="国", description="country, nation"),
        ][:count]


class MockUserService:
    """Mock user service for testing."""

    async def get_user_wrong_words(self, user_id: UUIDStr):
        """Return mock wrong words."""
        from models.services import UserWrongChar

        return [
            UserWrongChar(
                word="中",
                word_id=20013,
                wrong_count=3,
                last_wrong_at=get_time() - 86400,  # 1 day ago
                priority=None,
            ),
            UserWrongChar(
                word="国",
                word_id=25991,
                wrong_count=2,
                last_wrong_at=get_time() - 172800,  # 2 days ago
                priority=None,
            ),
        ]


class MockLLMRequestManager:
    """Mock LLM request manager for testing."""

    pass


class MockStorageService:
    """Mock storage service for testing."""

    def get_submit_url(self, user_id: UUIDStr) -> str:
        return f"https://example.com/submit/{user_id}"


class MockQuestionStatisticsService:
    """Mock question statistics service for testing."""

    pass


async def test_question_scoring():
    """Test the question scoring algorithm."""
    logger.info("Testing question scoring algorithm...")

    # Create mock service
    enhanced_service = EnhancedQuestionService(
        db=MockDatabaseService(),
        word_service=MockWordService(),
        user_service=MockUserService(),
        llm_request_manager=MockLLMRequestManager(),
        storage_service=MockStorageService(),
        question_statistics_service=MockQuestionStatisticsService(),
    )

    # Create test questions with different characteristics
    current_time = get_time()

    # New question (should score high on age)
    new_question = QuestionEntry(
        question_id="new-q",
        question_type=QuestionType.FILL_IN_VOCAB,
        answer_type="MULTIPLE_CHOICE",
        target_word_id=20013,
        prompt="Test prompt",
        created_at=current_time - 3600,  # 1 hour ago
        use_count=1,
        correct_count=1,
    )

    # Old, well-used question (should score lower)
    old_question = QuestionEntry(
        question_id="old-q",
        question_type=QuestionType.FILL_IN_VOCAB,
        answer_type="MULTIPLE_CHOICE",
        target_word_id=20013,
        prompt="Test prompt",
        created_at=current_time - 604800,  # 1 week ago
        use_count=50,
        correct_count=30,
    )

    # Score the questions
    new_score = enhanced_service.score_question(new_question)
    old_score = enhanced_service.score_question(old_question)

    logger.info(f"New question score: {new_score:.3f}")
    logger.info(f"Old question score: {old_score:.3f}")

    # Verify newer question scores higher
    assert (
        new_score > old_score
    ), f"New question should score higher: {new_score} vs {old_score}"

    logger.info("✅ Question scoring test passed")


async def test_revision_words_fetching():
    """Test fetching revision words."""
    logger.info("Testing revision words fetching...")

    enhanced_service = EnhancedQuestionService(
        db=MockDatabaseService(),
        word_service=MockWordService(),
        user_service=MockUserService(),
        llm_request_manager=MockLLMRequestManager(),
        storage_service=MockStorageService(),
        question_statistics_service=MockQuestionStatisticsService(),
    )

    # Test with a mock user
    user_id = "test-user-123"
    revision_words = await enhanced_service.get_revision_words(user_id, max_words=5)

    logger.info(f"Fetched {len(revision_words)} revision words")
    for word in revision_words:
        logger.info(f"  - {word.word} (priority: {word.priority})")

    assert len(revision_words) > 0, "Should fetch at least one revision word"
    assert all(
        word.priority is not None for word in revision_words
    ), "All words should have priority"

    logger.info("✅ Revision words fetching test passed")


async def test_question_classification():
    """Test question classification by goodness."""
    logger.info("Testing question classification...")

    enhanced_service = EnhancedQuestionService(
        db=MockDatabaseService(),
        word_service=MockWordService(),
        user_service=MockUserService(),
        llm_request_manager=MockLLMRequestManager(),
        storage_service=MockStorageService(),
        question_statistics_service=MockQuestionStatisticsService(),
    )

    # Create a batch with mixed quality questions
    current_time = get_time()

    good_question = QuestionEntry(
        question_id="good-q",
        question_type=QuestionType.FILL_IN_VOCAB,
        answer_type="MULTIPLE_CHOICE",
        target_word_id=20013,
        prompt="Test prompt",
        created_at=current_time - 1800,  # 30 min ago
        use_count=2,
        correct_count=2,
    )

    bad_question = QuestionEntry(
        question_id="bad-q",
        question_type=QuestionType.FILL_IN_VOCAB,
        answer_type="MULTIPLE_CHOICE",
        target_word_id=20013,
        prompt="Test prompt",
        created_at=current_time - 2592000,  # 30 days ago
        use_count=100,
        correct_count=20,
    )

    batch = WordQuestionBatch(
        word_id=20013,
        word="中",
        questions=[good_question, bad_question],
        scored_questions=[],
        good_questions=[],
        not_good_questions=[],
    )

    # Classify questions
    batches = enhanced_service.classify_questions_by_goodness([batch])
    classified_batch = batches[0]

    logger.info(f"Good questions: {len(classified_batch.good_questions)}")
    logger.info(f"Not good questions: {len(classified_batch.not_good_questions)}")

    # Verify classification
    good_scores = [sq.score for sq in classified_batch.good_questions]
    bad_scores = [sq.score for sq in classified_batch.not_good_questions]

    logger.info(f"Good scores: {good_scores}")
    logger.info(f"Bad scores: {bad_scores}")

    # At least one question should be classified
    assert len(classified_batch.scored_questions) == 2, "Should have 2 scored questions"

    logger.info("✅ Question classification test passed")


async def run_all_tests():
    """Run all tests."""
    logger.info("Starting Enhanced Question Service Tests")
    logger.info("=" * 50)

    try:
        await test_question_scoring()
        await test_revision_words_fetching()
        await test_question_classification()

        logger.info("=" * 50)
        logger.info("🎉 All tests passed successfully!")

    except Exception as e:
        logger.error(f"❌ Test failed: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(run_all_tests())
