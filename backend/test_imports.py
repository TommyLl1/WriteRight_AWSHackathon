#!/usr/bin/env python3
"""
Simple test script to verify all question service imports work correctly.
"""

try:
    print("Testing enhanced question service import...")
    from features.enhanced_question_service import EnhancedQuestionService

    print("✓ Enhanced question service imported successfully")
except Exception as e:
    print(f"✗ Enhanced question service import failed: {e}")

try:
    print("Testing main question service import...")
    from features.question_service import QuestionService

    print("✓ Main question service imported successfully")
except Exception as e:
    print(f"✗ Main question service import failed: {e}")

print("All import tests completed!")
