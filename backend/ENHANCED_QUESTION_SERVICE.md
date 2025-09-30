# Enhanced Question Generation Service

## Overview

The Enhanced Question Generation Service implements a comprehensive 6-step question generation logic that significantly improves upon the original question service. This service provides better question quality, more efficient database usage, and robust fallback mechanisms.

## Architecture

### Key Components

1. **EnhancedQuestionService**: Main service implementing the 6-step logic
2. **ScoredQuestion**: Data class representing a question with quality score
3. **WordQuestionBatch**: Data class organizing questions by word
4. **Question Scoring System**: Algorithmic quality assessment
5. **Lateral Join Queries**: Efficient database fetching

## 6-Step Question Generation Logic

### Step 1: Fetch Revision Words
- Retrieves user's wrong words using existing priority calculation
- Falls back to random words if no wrong words exist
- Limits to configurable maximum (default: 20 words)

### Step 2: Batch Database Query
- Uses single lateral join query to fetch up to 50 questions per word
- Excludes flagged questions automatically
- Optimized for performance with minimal database calls

### Step 3: Question Quality Scoring
- Scores questions based on multiple factors:
  - **Age Factor (30%)**: Newer questions score higher (exponential decay)
  - **Random Factor (20%)**: Adds variety to selection
  - **Usage Factor (30%)**: Less-used questions score higher
  - **Accuracy Factor (20%)**: Questions with better success rates score higher
- Separates questions above/below configurable threshold (default: 0.6)

### Step 4: AI Question Generation
- Generates questions for words lacking good-quality questions
- Supports batch processing for efficiency
- Validates generated questions match target words
- Drops mismatched questions automatically

### Step 5: Recycling Mechanism
- Falls back to "not good enough" questions when AI fails
- Selects best available from recycled pool
- Maintains question availability even during AI outages

### Step 6: Final Fallback
- Uses any non-flagged questions as last resort
- Returns 500 error only if all mechanisms fail
- Ensures service reliability

## Configuration

Add to `config.yaml`:

```yaml
QuestionGenerator:
  # Enhanced Question Service Configuration
  MaxWords: 20                    # Maximum words to process
  MaxQuestionsPerWord: 50         # Questions fetched per word
  GoodnessThreshold: 0.6          # Quality threshold (0.0-1.0)
  AgeDecayHours: 168              # Age decay period (1 week)
```

## Question Scoring Algorithm

The scoring algorithm combines multiple factors to assess question quality:

```python
score = (
    age_factor * 0.3 +      # Newer questions preferred
    random_factor * 0.2 +   # Randomness for variety
    usage_factor * 0.3 +    # Less-used questions preferred
    accuracy_factor * 0.2   # Higher accuracy preferred
)
```

- **Age Factor**: `exp(-age_hours / decay_hours)`
- **Usage Factor**: `1.0 - min(use_count / 100.0, 1.0)`
- **Accuracy Factor**: `0.5 + (correct_rate * 0.5)`

## Database Query Optimization

The service uses lateral joins to efficiently fetch questions:

```sql
SELECT t_limited.*
FROM (
    SELECT DISTINCT target_word_id
    FROM questions q
    WHERE q.target_word_id = ANY($word_ids)
    AND q.question_id NOT IN (
        SELECT DISTINCT fq.question_id 
        FROM flagged_questions fq
    )
) t_groups
JOIN LATERAL (
    SELECT *
    FROM questions q_all
    WHERE q_all.target_word_id = t_groups.target_word_id
    AND q_all.question_id NOT IN (
        SELECT DISTINCT fq.question_id 
        FROM flagged_questions fq
    )
    ORDER BY q_all.created_at DESC
    LIMIT 50
) t_limited ON true
```

## Backwards Compatibility

The original QuestionService now wraps the enhanced service while maintaining all existing interfaces:

- `generate_by_user_id()` - Main entry point
- Legacy methods preserved for compatibility
- Automatic fallback to original implementation if enhanced service fails

## Benefits

1. **Better Question Quality**: Systematic scoring and selection
2. **Improved Performance**: Single database query vs multiple calls
3. **Enhanced Reliability**: Multiple fallback mechanisms
4. **AI Integration**: Smart batching and validation
5. **Configurable**: Adjustable scoring weights and thresholds
6. **Monitoring**: Comprehensive logging at each step

## Usage

The enhanced service is automatically used by the existing QuestionService:

```python
# Existing code continues to work unchanged
questions = await question_service.generate_by_user_id(
    user_id="user-123",
    count=10
)
```

## Error Handling

The service includes comprehensive error handling:

- Database connection failures
- AI service outages
- Invalid question validation
- Type conversion errors
- Configuration issues

Each step has proper fallback mechanisms to ensure continuous service availability.

## Monitoring and Logging

Detailed logging at each step enables monitoring:

- Step execution time
- Question quality scores
- Fallback mechanism usage
- AI generation success rates
- Database query performance

Log levels:
- `DEBUG`: Detailed step-by-step execution
- `INFO`: Step completion and statistics
- `WARNING`: Fallback mechanism activation
- `ERROR`: Critical failures requiring attention

## Future Enhancements

Potential improvements:

1. **Machine Learning Scoring**: Train models on user interaction data
2. **Adaptive Thresholds**: Dynamic quality thresholds based on available questions
3. **Caching Layer**: Cache scored questions for improved performance
4. **A/B Testing**: Compare different scoring algorithms
5. **Real-time Analytics**: Live monitoring dashboard
