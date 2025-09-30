# from AI_text_recognition.google_ocr_2 import GoogleVisionOCR, OCRCharItem
# from AI_text_recognition.wrong_word import WrongWordRecognitionService, WrongWordEntry
# from word_service import WordService
# from PIL import Image
# from models.helpers import to_unicodeInt_from_char
# from models.db.db import Word, PastWrongWord
# from features.word_service import WordService
# from features.user_service import UserService
# import asyncio
# from typing import List, Awaitable
# from models.helpers import UUIDStr
# from utils.logger import setup_logger
# import os

# logger = setup_logger(__name__)

# class TextRecognitionService:
#     """
#     Service for recognizing text in images, identifying wrong words, and managing user-specific word data.
#     """

#     def __init__(self, ocr: GoogleVisionOCR, word_service: WordService, wrong_word_service: WrongWordRecognitionService, user_service: UserService):
#         """
#         Initialize the TextRecognitionService with required dependencies.

#         :param ocr: OCR service for text recognition.
#         :param word_service: Service for managing word-related operations.
#         :param wrong_word_service: Service for recognizing wrong words.
#         :param user_service: Service for managing user-specific data.
#         """
#         self.ocr = ocr
#         self.word_service = word_service
#         self.user_service = user_service  
#         self.wrong_word_service = wrong_word_service
#         self.llm_batch_size = 10  # Set the batch size for LLM requests

#     async def get_wrong_words(self, image_url: str, user_id: UUIDStr):
#         """
#         Process an image to identify wrong words and update the user's wrong word dictionary.

#         :param image_url: URL of the image to process.
#         :param user_id: ID of the user for whom the wrong words are being identified.
#         :return: List of added wrong words.
#         """
#         logger.info(f"Starting wrong word detection for user {user_id} with image {image_url}.")

#         # Load the image from the URL
#         try:
#             image = Image.open(image_url)
#         except Exception as e:
#             logger.error(f"Failed to load image from {image_url}: {e}")
#             raise ValueError("Image could not be loaded from the provided URL.")

#         # Use the OCR service to recognize text in the image
#         logger.info("Running OCR on the image.")
#         ocr_results = await self.ocr.detect_text([image], output_path=f'uploads/{user_id}/wrong_chars')
#         ocr_result = ocr_results[0]

#         # Extract recognized characters and their IDs
#         chars = [item.char for item in ocr_result.items]
#         char_ids = [to_unicodeInt_from_char(item.char) for item in ocr_result.items]
#         logger.debug(f"Recognized characters: {chars}")

#         # Get existing words from the database
#         logger.info("Fetching existing words from the database.")
#         correct_chars = await self.word_service.get_existing_words(char_ids)

#         # Identify characters not in the existing words
#         not_existing_chars = [
#             char for char in chars if char not in [word.word for word in correct_chars]
#         ]
#         logger.debug(f"Characters not in the database: {not_existing_chars}")

#         # Create new word entries for non-existing characters
#         logger.info("Creating new word entries for non-existing characters.")
#         tasks = [self.word_service.create_new_word_db_entry(char) for char in not_existing_chars]
#         new_added_words = await asyncio.gather(*tasks)

#         # Combine existing and newly added words
#         all_words = {word.word: word for word in correct_chars + new_added_words}
#         ordered_words = [all_words[char] for char in chars]
#         ordered_word_urls = [word.image_url for word in ordered_words]

#         # Filter out words with missing image URLs
#         logger.info("Filtering out words with missing image URLs.")
#         filtered_ordered_words, filtered_ordered_word_urls, filtered_ocr_items = [], [], []
#         for word, url, ocr_item in zip(ordered_words, ordered_word_urls, ocr_result.items):
#             if url:
#                 filtered_ordered_words.append(word)
#                 filtered_ordered_word_urls.append(url)
#                 filtered_ocr_items.append(ocr_item)
#             else:
#                 logger.warning(f"Word {word.word} has no image URL, removing it from the list.")

#         # Update the lists with filtered values
#         ordered_words = filtered_ordered_words
#         ordered_word_urls = filtered_ordered_word_urls
#         ocr_result.items = filtered_ocr_items

#         # Process words in batches for wrong word recognition
#         logger.info("Processing words in batches for wrong word recognition.")
#         total_words = len(ordered_words)
#         llm_tasks = []
#         for i in range(0, total_words, self.llm_batch_size):
#             batch_input_urls = [item.url for item in ocr_result.items[i:i + self.llm_batch_size]]
#             batch_chars = [item.char for item in ocr_result.items[i:i + self.llm_batch_size]]
#             batch_word_urls = ordered_word_urls[i:i + self.llm_batch_size]

#             llm_tasks.append(
#                 self.wrong_word_service.batch_recognize_wrong_words_urls(
#                     batch_input_urls, batch_word_urls, batch_chars
#                 )
#             )

#         llm_results = await asyncio.gather(*llm_tasks)

#         # Process wrong word results
#         logger.info("Processing wrong word results.")
#         items_to_add = []
#         wrong_words = [item for sublist in llm_results for item in sublist]
#         for word, entry, upload_url in zip(ordered_words, wrong_words, ordered_word_urls):
#             if entry.is_correct:
#                 ## TODO: remove file
#                 pass
#             else:
#                 past_wrong_word = PastWrongWord(
#                     word_id=word.word_id,
#                     user_id=user_id,
#                     wrong_count=1,
#                     wrong_image_url=upload_url,
#                 )
#                 items_to_add.append(past_wrong_word)

#         # Add wrong words to the user's dictionary
#         result = []
#         if items_to_add:
#             logger.info(f"Adding {len(items_to_add)} wrong words for user {user_id}.")
#             result = await self.user_service.batch_add_wrong_words_raw(user_id, items_to_add)

#         if not result:
#             logger.info(f"No wrong words to add for user {user_id}.")

#         logger.info(f"Completed wrong word detection for user {user_id}.")
#         return result

#     async def check_handwrite_answer(self):
#         """
#         Placeholder for handwriting answer checking functionality.
#         """
#         logger.info("Handwriting answer checking is not yet implemented.")
#         pass
