"""
Mock question bank for testing purposes.
Can be ran directly to generate a JSON representation of the questions.
"""

try:
    from models.QnA import (
        FillInVocabQuestion,
        QuestionType,
        AnswerType,
        ListeningQuestion,
        FillInSentenceQuestion,
        IdentifyWrongQuestion,
        QuestionBase,
    )
except ImportError:
    # If running directly, add the workspace root to sys.path
    if __name__ == "__main__":
        import sys
        import os

        # Add the workspace root to sys.path
        sys.path.append(os.path.dirname(os.path.dirname(__file__)))

        from models.QnA import (
            FillInVocabQuestion,
            QuestionType,
            AnswerType,
            ListeningQuestion,
            FillInSentenceQuestion,
            IdentifyWrongQuestion,
            QuestionBase,
        )

# QUESTION_DB: list[QuestionBase] = [
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 1, "text": "？天"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "請"},
#             {"option_id": 2, "text": "清"},
#             {"option_id": 3, "text": "晴"},
#             {"option_id": 4, "text": "精"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [3]}  # Correct answer is "晴"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 2, "text": "？水"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "清"},
#             {"option_id": 2, "text": "請"},
#             {"option_id": 3, "text": "精"},
#             {"option_id": 4, "text": "睛"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "清"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 3, "text": "？飯"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "吃"},
#             {"option_id": 2, "text": "去"},
#             {"option_id": 3, "text": "喝"},
#             {"option_id": 4, "text": "拿"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "吃"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 4, "text": "好？"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "嗎"},
#             {"option_id": 2, "text": "媽"},
#             {"option_id": 3, "text": "馬"},
#             {"option_id": 4, "text": "麻"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "嗎"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 5, "text": "看？"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "書"},
#             {"option_id": 2, "text": "數"},
#             {"option_id": 3, "text": "豬"},
#             {"option_id": 4, "text": "叔"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "書"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 6, "text": "？手"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "洗"},
#             {"option_id": 2, "text": "先"},
#             {"option_id": 3, "text": "西"},
#             {"option_id": 4, "text": "戲"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "洗"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 7, "text": "？茶"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "喝"},
#             {"option_id": 2, "text": "合"},
#             {"option_id": 3, "text": "渴"},
#             {"option_id": 4, "text": "客"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "喝"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 8, "text": "？學"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "上"},
#             {"option_id": 2, "text": "下"},
#             {"option_id": 3, "text": "中"},
#             {"option_id": 4, "text": "去"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "上"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 9, "text": "？月"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "明"},
#             {"option_id": 2, "text": "晶"},
#             {"option_id": 3, "text": "青"},
#             {"option_id": 4, "text": "晴"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "明"
#         ]
#     }
# ),
# FillInVocabQuestion(
#     prompt="選字配詞",
#     given=[{"material_type": "text_short", "material_id": 10, "text": "？家"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "回"},
#             {"option_id": 2, "text": "會"},
#             {"option_id": 3, "text": "灰"},
#             {"option_id": 4, "text": "會"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "回"
#         ]
#     }
# ),
# FillInSentenceQuestion(
#     prompt="填空句子",
#     given=[{"material_type": "text_long",
#             "material_id": 11, "text": "今天的天氣很？朗"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "晴"},
#             {"option_id": 2, "text": "氰"},
#             {"option_id": 3, "text": "青"},
#             {"option_id": 4, "text": "情"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "晴"
#         ]
#     }
# ),
# IdentifyWrongQuestion(
#     prompt="找出句子中的錯誤",
#     given=[{"material_type": "text_long",
#             "material_id": 12, "text": "小明今天吃了平果和香蕉"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "平果"},
#             {"option_id": 2, "text": "香蕉"},
#             {"option_id": 3, "text": "小明"},
#             {"option_id": 4, "text": "今天"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "平果"
#         ]
#     }
# ),
# FillInSentenceQuestion(
#     prompt="填空句子",
#     given=[{"material_type": "text_long",
#             "material_id": 13, "text": "隔壁老王養了一隻小？"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "鳥"},
#             {"option_id": 2, "text": "烏"},
#             {"option_id": 3, "text": "鴉"},
#             {"option_id": 4, "text": "鳳"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [1]}  # Correct answer is "鳥"
#         ]
#     }
# ),
# ListeningQuestion(
#     prompt="聽音辨字",
#     given=[{"material_type": "sound", "material_id": 14,
#             "sound": "https://www.edbchinese.hk/EmbziciwebRes/jyutping/faa1.mp3"}],
#     mcq={
#         "choices": [
#             {"option_id": 1, "text": "話"},
#             {"option_id": 2, "text": "華"},
#             {"option_id": 3, "text": "化"},
#             {"option_id": 4, "text": "花"}
#         ],
#         "display": {"type": "list", "rows": 4},
#         "answers": [
#             {"answer_id": 1, "choices": [4]}  # Correct answer is "花"
#         ]
#     }
# )
# ]

# if __name__ == "__main__":
#     # Dump the questions as JSON and print them
#     [
#         print(
#             q.model_dump_json(indent=2, exclude_none=True), end="\n\n------------\n\n"
#         )
#         for q in QUESTION_DB
#     ]
