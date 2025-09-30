if __name__ == "__main__":
    import sys
    import os
    from dotenv import load_dotenv

    # Add the workspace root to sys.path
    sys.path.append(os.path.dirname(os.path.dirname(__file__)))
    load_dotenv()  # Load environment variables from .env file


import json
from typing import Optional, List, Dict, Type, Callable, TypedDict, Any, Union
from enum import Enum
from utils.LLMService import LLMService
from models.LLM import (
    LLMModels,
    AIQuestionType,
    FillInVocabFormat,
    FillInSentenceFormat,
    PairingCardsFormat,
    FillInRadicalFormat,
)
from models.helpers import ChineseChar
from utils.logger import setup_logger
from utils.config import config
from pydantic import BaseModel
from models.QnA import (
    QuestionBase,
    FillInVocabQuestion,
    FillInSentenceQuestion,
    PairingCardsQuestion,
    FillInRadicalQuestion,
)
from models.QnA_builder import Adaptor

logger = setup_logger(__name__)

# SYS_PROMPT = """
# Given a list of Chinese characters, create corresponding number of word-matching questions matching the following criteria:
# by replacing one character in a word that contains the given character with "?",
# and provide 4 different choices as possible answers, where only one is correct.
# Ensure that the question is clear, the choices are not duplicated and the correct answer is easily identifiable.
# E.g.: 上面 and 入面 are both valid words so 上 and 入 should not be used together in "？面".
# The options can visually look similar, pronounced similarly in cantonese (**NOT mandarin**), form similar vocabularies, or have similar meanings, but only one should be correct.
# The return should be in condenced JSON format, remove the unnecessary whitespace, newlines and codeblocks, and be easy to extract.
# ## Example Input:
# ```
# ['請', '蘋']
# ```
# ## Example Output:
# ```
# [{"question": "？求", "choices": ["情", "清", "精", "請"],"answer": "請"},{"question": "？果", "choices": ["平", "蘋", "評", "拼"],"answer": "蘋"}]
# ```
# """
PROMPT_FILL_VOCAB = """
Generate "fill in the sentence" questions based on a list of Chinese characters. The process is as follows:
1. Generate 5 Chinese vocabularies (if possible) consisting of 2 characters that contains the given character.
2. Generate 3 other characters that are similar to the selected character, ensuring all 4 characters (selected and 3 others) are distinct. They can be:
   - Similar looking (e.g., sharing radicals, like 目 and 日).
   - Similar pronunciation in Cantonese (Jyutping), NOT Mandarin.
   - Similar in meaning but result in nonsensical sentences when substituted.

NOTE:
If no similar words can be found, randomly select 3 other characters that are distinct from the given character.
DO NOT return the given char in similar characters.
Return format must be in JSON, properly formatted with double quotes for property names.

Example Input:
['請', '蘋', '上']
Output: 
{
    "questions": [
        {
            "given_char": "請",
            "vocabularies": ["請求", "請假", "請客", "請教", "請安"],
            "similar_characters": [
                "情",
                "清",
                "精",
            ],
        },
        {
            "given_char": "蘋",
            "vocabularies": [
                "蘋果",
            ],
            "similar_characters": ["平", "評", "拼"],
        },
        {
            "given_char": "上",
            "vocabularies": ["上面", "上升", "上課", "上網", "上班"],
            "similar_characters": ["尚", "卜", "卡"],
        },
    ]
}



# """


# Given a list of Chinese characters, generate "fill in the word" questions. Here are the steps:

# 1. Find a common word with the Chinese character.
# 2. Find 3 other characters that are similar to the selected character, and ensure all 4 characters (selected and 3 others) are distinct. They can be
#   - Similar looking (have same or similar radicals, like 目 and 日)
#   - Similar pronunciation in **Cantonese** (Jyutping), NOT Mandarin
#   - Similar in meaning but does not make sense when combined as a word
# 3. Replace the character given in the word with a ？, and make sure none of the 3 other characters form sensible words when substituting for the ？
# 4. Create a CondensedMCQ Object, which looks like: `{"question": "？求", "choices": ["情", "清", "精", "請"],"answer": "請"}`
# 5. Repeat for all Chinese characters in the given list. Order of choices does not matter.

# if there is only one character in the list, then just return a single question in a list format, e.g.:
# [{"question": "？求", "choices": ["情", "清", "精", "請"],"answer": "請"}]

# The return should be in minimized JSON format for easier extraction. Remove unnecessary whitespace, newlines, indents and/or codeblocks.
# ## Example Input:
# ['請', '蘋', '上']

# ## Example Output:
# [{"question": "？求", "choices": ["情", "清", "精", "請"],"answer": "請"},
# {"question": "？果", "choices": ["平", "蘋", "評", "拼"],"answer": "蘋"},
# {"question": "樓？", "choices": ["尚", "卜", "上", "卡"],"answer": "上"}]

# """

PROMPT_FILL_SENTENCE = """
Generate "fill in the sentence" questions based on a list of Chinese characters. The process is as follows:
1. Find a common sentence containing the Chinese character.
2. Identify 3 other characters that are similar to the selected character and ensure all 4 characters (selected and the 3 others) are distinct. They can be:
   - Similar looking (e.g., sharing radicals, like 目 and 日).
   - Similar pronunciation in Cantonese (Jyutping), NOT Mandarin.
   - Similar in meaning but result in nonsensical sentences when substituted.

Note:
No punctuations other than commas are allowed in the sentence.
The sentence should be a complete sentence, not just a phrase.
Sentence should be within 15 characters.
If no similar characters can be found, randomly select 3 other characters that are distinct from the given character.
DO NOT return the given char in similar characters.
The given character should only appear once in the sentence.
Child friendly language should be used.
STRICTLY follow json object format, with double quotes for property names.
If not I will not give you cookies


Example Input:
['請', '蘋', '上']
Output: 
{
    "questions": [
        {
            "given_char": "請",
            "sentence": "他們正在請客",
            "similar_characters": [
                "情",
                "清",
                "精",
            ],
        },
        {
            "given_char": "蘋",
            "sentence": "我每天都喝蘋果汁",
            "similar_characters": ["平", "評", "拼"],
        },
        {
            "given_char": "上",
            "sentence": "他站在樓上看風景",
            "similar_characters": ["尚", "卜", "卡"],
        },
    ]
}
"""

# """
# Steps:
# Find a common sentence containing the Chinese character.
# Identify 3 other characters that are similar to the selected character and ensure all 4 characters (selected and the 3 others) are distinct. They can be:
# Similar looking (e.g., sharing radicals, like 目 and 日).
# Similar pronunciation in Cantonese (Jyutping), NOT Mandarin.
# Similar in meaning but result in nonsensical sentences when substituted.
# Replace the character in the sentence with a ？. Ensure that substituting with any of the 3 other characters forms nonsensical or incorrect meanings.
# Create a CondensedMCQ Object for each sentence, structured as:
# {"question": "Sentence with ？", "choices": ["Choice1", "Choice2", "Choice3", "CorrectChoice"], "answer": "CorrectChoice"}
# Repeat the process for all characters in the given list.
# The return should be in minimized JSON format for easier extraction. Remove unnecessary whitespace, newlines, indents and/or codeblocks.
# if there is only one character in the list, then just return a single question in a list format, e.g.:
# [{"question": "Sentence with ？", "choices": ["Choice1", "Choice2", "Choice3", "CorrectChoice"], "answer": "CorrectChoice"}]

# Example Input:
# ['請', '蘋', '上']

# Example Output:
# [{"question":"他們正在？客。","choices":["情","清","精","請"],"answer":"請"},
# {"question":"我每天都喝？果汁。","choices":["平","蘋","評","拼"],"answer":"蘋"},
# {"question":"他站在樓？看風景。","choices":["尚","卜","上","卡"],"answer":"上"}]
# """


PROMPT_PAIRING_CARDS = """
You are tasked with generating vocabulary lists based on a given list of tuples. Each tuple contains:

A Chinese character or word (target_char), which must appear in a final vocabulary word.
n, the desired word length (2 to 4).
k, the number of vocabulary words to generate (1 correct word + k-1 similar alternatives).

Steps:
For each tuple (target_char, n, k):
Generate one valid vocabulary word of length n that includes the given target_char.
Generate k-1 other vocabulary words of the same length (n) and similar difficulty. These alternative words must:
NOT contain the given target_char.
NOT overlap in meaning, pronunciation, or radicals with the correct word.
Be unique and unrelated to each other.
Ensure none of the generated words can recombine to form other valid words.
Output Format:
Return the results as a minimized JSON array where each object contains:

target_char: The given target character.
n: Desired length of the word.
words: A list of k vocabulary words, starting with the correct word followed by the alternatives.

if there is only one character in the list, then just return a single question in a list format, e.g.:
[{"target_char": "請", "n": 3, "words": ["邀請函", "出發點", "動物園", "經理人"]}]

Example Input:
[("請", 3, 4), ("蘋", 2, 3), ("上", 3, 4), ("愛", 4, 5)]

Example Output:
[
  {"target_char":"請","n":3,"words":["邀請函","出發點","動物園","經理人"]},
  {"target_char":"蘋","n":2,"words":["蘋果","香蕉","橘子"]},
  {"target_char":"上","n":3,"words":["樓上層","高山峰","沙漠島","陽光房"]},
  {"target_char":"愛","n":4,"words":["我的愛心","朋友之情","家庭幸福","美好時光","永恆記憶"]}
]
"""

PROMPT_FILL_IN_RADICAL = """
生成填空題，目標是根據給定的漢字，拆分其部首或構成部分，並讓用戶選擇缺失的部分。具體要求如下：
1. 輸入：
   - 一個漢字列表，例如：["意", "國", "蛋", "魚", "明"]。

2. 對每個漢字進行如下處理：
   - 嘗試將其拆分爲合理的部首或構成部分（radicals）。
   - 如果不能合理拆分，則設置類型（type）爲 "difficult"，並返回 null 作爲 radicals 和其他相關屬性。
   - 常見的拆分類型包括：
     - "right-left"（左右結構，例如：明 → 日 + 月）
     - "top-bottom"（上下結構，例如：意 → 音 + 心）
     - "inside-out"（內外結構，例如：國 → 口 + 或）
     - "complex"（複雜結構，超過兩個部分，例如：魚 → 𠂊 + 田 + 灬）

3. 爲每個漢字選擇一個常見的詞彙（question），該詞彙包含目標漢字（target_char），用於爲問題提供語境。例如：
   - 目標漢字：意，選擇的詞彙：意思
   - 目標漢字：魚，選擇的詞彙：魚類

4. 隨機隱藏一個部首或構成部分，用 "?" 表示，生成填空題。例如：
   - 目標漢字：意
   - 部首拆分：音 + 心
   - 提問：[(?, 心), 意思]

5. 爲每個問題生成 4 個選項（choices），包括：
   - 一個正確答案（answer）。
   - 三個相似但錯誤的干擾項（與正確答案在形狀或意義上相似但不正確）。
   - 例如：
     - 正確答案：音
     - 干擾項：木、火、口
     - 選項：["音", "木", "火", "口"]

6. 輸出：
   - 每個漢字生成一個 JSON 對象，包含以下字段：
     - "target_char"：目標漢字。
     - "radicals"：目標漢字拆分的部首或構成部分（列表形式）。
     - "type"：漢字的拆分類型（"right-left"、"top-bottom"、"inside-out"、"complex"、"difficult"）。
     - "question"：選定的詞彙。
     - "choices"：選項列表。
     - "answer"：正確答案。

7. 如果某個漢字不能拆分，返回如下格式：
   - 示例：
     {
         "target_char": "龍",
         "radicals": null,
         "type": "difficult",
         "question": null,
         "choices": null,
         "answer": null
     }

8. 示例輸入：
   ["意", "國", "蛋", "魚", "明"]

9. 示例輸出：
   [
       {
           "target_char": "意",
           "radicals": ["音", "心"],
           "type": "top-bottom",
           "question": "意思",
           "choices": ["音", "木", "火", "口"],
           "answer": "音"
       },
       {
           "target_char": "國",
           "radicals": ["口", "或"],
           "type": "inside-out",
           "question": "國家",
           "choices": ["口", "木", "火", "日"],
           "answer": "口"
       },
       {
           "target_char": "蛋",
           "radicals": ["疋", "蟲"],
           "type": "top-bottom",
           "question": "蛋糕",
           "choices": ["疋", "亻", "木", "日"],
           "answer": "疋"
       },
       {
           "target_char": "魚",
           "radicals": ["𠂊", "田", "灬"],
           "type": "complex",
           "question": "魚類",
           "choices": ["𠂊", "木", "口", "日"],
           "answer": "𠂊"
       },
       {
           "target_char": "明",
           "radicals": ["日", "月"],
           "type": "right-left",
           "question": "明白",
           "choices": ["日", "木", "口", "手"],
           "answer": "日"
       }
   ]
"""


class FillInvocabList(BaseModel):
    """
    A list format for fill-in-the-blank vocabulary questions.
    """

    questions: List[FillInVocabFormat]
    count: Optional[int] = None


class FillInSentenceList(BaseModel):
    """
    A list format for fill-in-the-blank sentence questions.
    """

    questions: List[FillInSentenceFormat]
    count: Optional[int] = None


class PairingCardsList(BaseModel):
    """
    A list format for pairing cards questions.
    """

    questions: List[PairingCardsFormat]
    count: Optional[int] = None


class FillInRadicalList(BaseModel):
    """
    A list format for fill-in-the-blank radical questions.
    """

    questions: List[FillInRadicalFormat]
    count: Optional[int] = None


# class QuestionTypeProperties(TypedDict):
#     list_type: Type[BaseModel]
#     prompt: str
#     format: Type[BaseModel]
#     adaptor: Callable


# Define the TYPE_TO_PROPERTIES dictionary with type checking
# TYPE_TO_PROPERTIES: Dict[AIQuestionType, QuestionTypeProperties] = {
#     AIQuestionType.FILL_IN_VOCAB: {
#         "list_type": FillInvocabList,
#         "prompt": PROMPT_FILL_VOCAB,
#         "format": FillInVocabFormat,
#         "adaptor": Adaptor.fill_in_vocab,
#     },
#     AIQuestionType.FILL_IN_SENTENCE: {
#         "list_type": FillInSentenceList,
#         "prompt": PROMPT_FILL_SENTENCE,
#         "format": FillInSentenceFormat,
#         "adaptor": Adaptor.fill_in_sentence,
#     },
#     AIQuestionType.PAIRING_CARDS: {
#         "list_type": PairingCardsList,
#         "prompt": PROMPT_PAIRING_CARDS,
#         "format": PairingCardsFormat,
#         "adaptor": Adaptor.pairing_cards,
#     },
# }


class AIQuestionGenerator:
    def __init__(self, client: LLMService = LLMService()) -> None:
        """
        Initialize the AIQuestionGenerator with a client for generating questions.
        """
        self.client = client

    def _extract_questions(
        self, response: Union[Dict[str, Any], List[Dict[str, Any]], None]
    ) -> List[Dict[str, Any]]:
        if isinstance(response, dict):
            return response.get("questions", [])
        elif isinstance(response, list):
            return response
        else:
            logger.warning(
                f"Unexpected response type: {type(response)}. Expected dict or list."
            )
            # Return an empty list if the response is not as expected
            return []

    # Clearly define the return type for the methods
    async def batch_genq_fill_in_vocab(
        self,
        chars: List[ChineseChar],
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> List[FillInVocabQuestion]:
        """
        Generate a batch of fill-in-the-blank vocabulary questions based on a list of Chinese characters.

        :param chars: List of Chinese characters to generate questions from.
        :param max_tokens: Maximum number of tokens for the response.
        :param model: The LLM model to use for generation.
        :return: List of FillInVocabFormat questions.
        """
        user_prompt = ", ".join(chars) if isinstance(chars, list) else chars

        questions: List[Dict[str, Any]] = []
        response_dict = await self.client.generate_text_with_structured_outputs(
            system_prompt=PROMPT_FILL_VOCAB,
            user_prompt=user_prompt,
            response_model=FillInvocabList,
            max_tokens=max_tokens,
            model=model,
        )
        logger.debug(f"Response from LLM: {response_dict}")

        questions = self._extract_questions(response_dict)
        return [
            Adaptor.fill_in_vocab(FillInVocabFormat.model_validate(q))
            for q in questions
        ]

    async def batch_genq_fill_in_sentence(
        self,
        chars: List[ChineseChar],
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> List[FillInSentenceQuestion]:
        """
        Generate a batch of fill-in-the-blank sentence questions based on a list of Chinese characters.

        :param chars: List of Chinese characters to generate questions from.
        :param max_tokens: Maximum number of tokens for the response.
        :param model: The LLM model to use for generation.
        :return: List of FillInSentenceFormat questions.
        """
        user_prompt = ", ".join(chars) if isinstance(chars, list) else chars

        questions: List[Dict[str, Any]] = []
        response_dict = await self.client.generate_text_with_structured_outputs(
            system_prompt=PROMPT_FILL_SENTENCE,
            user_prompt=user_prompt,
            response_model=FillInSentenceList,
            max_tokens=max_tokens,
            model=model,
        )

        logger.debug(f"Response from LLM: {response_dict}")
        questions = self._extract_questions(response_dict)

        return [
            Adaptor.fill_in_sentence(FillInSentenceFormat.model_validate(q))
            for q in questions
        ]

    async def batch_genq_pairing_cards(
        self,
        chars: List[ChineseChar],
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> List[PairingCardsQuestion]:
        """
        Generate a batch of pairing cards questions based on a list of Chinese characters.

        :param chars: List of Chinese characters to generate questions from.
        :param max_tokens: Maximum number of tokens for the response.
        :param model: The LLM model to use for generation.
        :return: List of PairingCardsFormat questions.
        """
        user_prompt = ", ".join(f"({char}, n=2, k=4)" for char in chars)
        questions: List[Dict[str, Any]] = []
        response_dict = await self.client.generate_text_with_structured_outputs(
            system_prompt=PROMPT_PAIRING_CARDS,
            user_prompt=user_prompt,
            response_model=PairingCardsList,
            max_tokens=max_tokens,
            model=model,
        )

        questions = self._extract_questions(response_dict)

        return [
            Adaptor.pairing_cards(PairingCardsFormat.model_validate(q))
            for q in questions
        ]

    async def batch_genq_fill_in_radical(
        self,
        chars: list[ChineseChar],
        max_tokens: int = config.get("QuestionGenerator.Batch.MaxTokens", 300),
        model: LLMModels = LLMModels.DEEPSEEK_V3,
    ) -> None:
        """
        Generate a batch of fill-in-the-blank radical questions based on a list of Chinese characters.

        :param chars: List of Chinese characters to generate questions from.
        :param max_tokens: Maximum number of tokens for the response.
        :param model: The LLM model to use for generation.
        :return: List of FillInRadicalFormat questions.
        """
        user_prompt = ", ".join(chars) if isinstance(chars, list) else chars

        questions: List[Dict[str, Any]] = []
        response_dict = await self.client.generate_text_with_structured_outputs(
            system_prompt=PROMPT_FILL_IN_RADICAL,
            user_prompt=user_prompt,
            response_model=FillInRadicalList,
            max_tokens=max_tokens,
            model=model,
        )

        questions = self._extract_questions(response_dict)
        print(f"Generated questions: {questions}")
        # return [
        #     Adaptor.fill_in_radical(FillInRadicalFormat.model_validate(q))
        #     for q in questions
        # ]


# Run the main function to generate questions
if __name__ == "__main__":
    import asyncio
    import random

    characters = [
        "晴",
        "銀",
        "店",
        # "行",
        # "吃",
        "馬",
        "鳥",
        "書",
        "學",
        "問",
        "說",
        "走",
        "跑",
        "飛",
    ]

    picked_words = random.sample(characters, 4)
    picked_word = random.choice(characters)
    # picked_q_type = random.choice(list(AIQuestionType))
    picked_q_type = AIQuestionType.PAIRING_CARDS
    logger.info(f"Picked words: {picked_words}")
    logger.info(f"Picked word: {picked_word}")
    logger.info(f"Picked question type: {picked_q_type}")

    # Test
    generator = AIQuestionGenerator()
    questions = asyncio.run(
        generator.batch_genq_pairing_cards(
            chars=picked_words,
            max_tokens=config.get("QuestionGenerator.Batch.MaxTokens", 300),
            model=LLMModels.DEEPSEEK_V3,
        )
    )

    # questions: List[QuestionBase] = asyncio.run(
    #     generator.batch_generate_questions(
    #         chars=picked_words,
    #         question_type=picked_q_type,
    #         max_tokens=config.get("QuestionGenerator.Batch.MaxTokens", 300),
    #         model=LLMModels.DEEPSEEK_V3,
    #     )
    # )


# # Example JSON output
# json_data = '''
# {
#   "question": "？求",
#   "choices": ["情", "清", "精", "請"],
#   "answer": "請"
# }
# '''

# # Parse the JSON data
# data = json.loads(json_data)

# # Extract the values
# question = data["question"]
# choices = data["choices"]
# answer = data["answer"]

# # Print the extracted data
# print(f"Question: {question}")
# print("Choices:")
# for i, choice in enumerate(choices, start=1):
#     print(f"{i}. {choice}")
# print(f"Correct Answer: {answer}")


# MC_PROMPT = """
# Given a Chinese character,
# create a word-matching question by replacing one character in a word that contains the given character with "?",
# and provide 4 different choices as possible answers,
# where only one is correct.
# The return should be in a structured and easy-to-extract format.
# There must be only **one correct answer** .

# Example Input:
# Character: 請
# Example Output:

# {
#   "question": "？求",
#   "choices": ["情", "清", "精", "請"],
#   "answer": "請"
# }

# ## Character: {character}

# """
