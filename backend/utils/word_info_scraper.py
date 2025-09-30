MP3_SAVE_DIR = ""

if __name__ == "__main__":
    import sys
    import os

    # Add the workspace root to sys.path
    MP3_SAVE_PATH = os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "scraped_mp3"
    )
    sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from models.word_info import WordInfo, PhraseInfoList, CharPingyinEntry, language
import requests
from time import time
from bs4 import BeautifulSoup, Tag
from typing import Optional


class WordInfoScraper:
    def __init__(self, api_base: Optional[str] = None):
        # Initialize any necessary attributes or configurations
        self.api_base = (
            api_base
            if api_base
            else "https://www.secmenu.com/apps/words/www/words.json.web.php"
        )
        self.api_word_search = "https://chineselearning.omghomework.com/search/{word}/1"
        self.session = requests.Session()  # Use a session for persistent connections
        self.session.headers.update(
            {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36"
            }
        )

    def _sanitise_response(self, response):
        """
        Sanitizes the response content by removing unwanted prefixes and suffixes.

        Args:
            response (str): The raw response content.

        Returns:
            str: Sanitized response content.
        """
        output = response.strip()
        if output.startswith("wordCallBack("):
            output = output[len("wordCallBack(") : -1]
        elif output.startswith("phraseCallBack("):
            output = output[len("phraseCallBack(") : -1]
        elif output.endswith(")"):
            output = output[:-1]

        return output

    def get_word_info(self, word) -> WordInfo:
        """
        Retrieves the ID associated with the given word.

        Args:
            word (str): The word to look up.

        Returns:
            str: The ID of the word.
        """
        # Implementation logic for retrieving the word ID
        wordParams = {
            "action": "downloadWord",
            "word": word,
            "callback": "wordCallBack",
            "_": int(time() * 1000),  # Current timestamp in milliseconds
        }

        # example: https://www.secmenu.com/apps/words/www/words.json.web.php?action=downloadWord&word=%E4%BD%A0&callback=wordCallBack&_=1749220317841
        response = self.session.get(self.api_base, params=wordParams, timeout=10)
        response.raise_for_status()  # Raise an error for bad responses
        # check response length, raise error if response is empty
        if len(response.text) < 20:
            raise ValueError(
                f"Response for word '{word}' is empty or too short: {response.text}; Word not found?"
            )
        # Sanitize the response content
        sanitized_response = self._sanitise_response(response.text)

        return WordInfo.model_validate_json(sanitized_response)

    def get_word_phrase(self, word_info: WordInfo) -> PhraseInfoList:
        """
        Retrieves the phrase associated with the given word.

        Args:
            word (str): The word to look up.

        Returns:
            str: The phrase associated with the word.
        """
        # Implementation logic for retrieving the phrase
        phraseParams = {
            "action": "phrase",
            "callback": "phraseCallBack",
            "word": str(
                word_info.word
            ),  # word is actually not necessary, but included to match original API call
            # Ensure the ID is always 4 digits
            "id": f"{int(word_info.id):04}",
            "_": int(time() * 1000),  # Current timestamp in milliseconds
        }
        #  https://www.secmenu.com/apps/words/www/words.json.web.php?action=phrase&word=%E4%BD%A0&id=0124&callback=phraseCallBack&_=1749223374788
        response = self.session.get(self.api_base, params=phraseParams, timeout=10)
        response.raise_for_status()
        # check response length, raise error if response is empty
        if len(response.text) < 20:
            raise ValueError(
                f"Response for word '{word_info.word}' is empty or too short: {response.text}"
            )
        # Sanitize the response content
        sanitized_response = (
            '{ "phrases": ' + self._sanitise_response(response.text) + "}"
        )
        # Parse the JSON response
        try:
            phrase_info = PhraseInfoList.model_validate_json(sanitized_response)
        except Exception as e:
            raise ValueError(
                f"Failed to parse phrase info for word '{word_info.word}': {e}"
            )
        return phrase_info

    def get_word_stroke_image(self, word_info: WordInfo):
        """
        Retrieves the stroke image for the given word ID.

        Args:
            word_id (str): The ID of the word.

        Returns:
            str: URL or path to the stroke image.
        """
        return word_info.stroke_gif

    def get_word_big_image(self, word) -> str:
        """
        Retrieves the high-res image URL for the given word by downloading and parsing the entire HTML of the webpage.
        **Warning:** This function downloads the entire HTML content of the webpage, which can be slow and resource-intensive.
        Use this function only when absolutely necessary.
        Raises:
            ValueError: If the response is empty, too short, or the big image URL cannot be found.
            requests.exceptions.RequestException: If there is an issue with the HTTP request.
        Retrieves the big image for the given word.

        Args:
            word (str): The word to look up.

        Returns:
            str: URL of the big image.
        """
        # Example: https://chineselearning.omghomework.com/search/%E4%BD%A0/1
        response = self.session.get(self.api_word_search.format(word=word), timeout=10)
        response.raise_for_status()

        # Check response length, raise error if response is empty
        if len(response.text) < 20:
            raise ValueError(
                f"Response for word '{word}' is empty or too short: {response.text}; Word not found?"
            )

        # Parse the HTML response to extract the big image URL
        soup = BeautifulSoup(response.text, "html.parser")
        meta_tag = soup.find("meta", {"property": "og:image"})

        if (
            not meta_tag
            or not isinstance(meta_tag, Tag)
            or "content" not in meta_tag.attrs
        ):
            raise ValueError(
                f"Failed to find big image URL for word '{word}' in the response."
            )

        return str(meta_tag["content"])

    def get_pronunciation_url(self, pinyin: CharPingyinEntry, lang: language) -> str:
        """
        Retrieves the pronunciation MP3 URL for the given pinyin entry.

        Args:
            pinyin (CharPingyinEntry): The pinyin entry containing the display and code.

        Returns:
            str: URL of the pronunciation MP3.
        """
        pinyin = CharPingyinEntry.model_validate(pinyin)
        if not pinyin.code:
            raise ValueError("Pinyin code is required to fetch pronunciation.")
        # https://www.secmenu.com/apps/words/www/audio/cantonese/nei5.mp3
        if lang == language.PUTONGHUA:
            # Construct the URL for the Putonghua pronunciation MP3
            return str(
                f"https://www.secmenu.com/apps/words/www/audio/putonghua/{pinyin.code}.mp3"
            )

        elif lang == language.CANTONESE:
            # Construct the URL for the Cantonese pronunciation MP3
            return str(
                f"https://www.secmenu.com/apps/words/www/audio/cantonese/{pinyin.code}.mp3"
            )

        else:
            raise ValueError(f"Unsupported language: {lang}")

    def download_pronunciation_mp3(
        self, pinyin: CharPingyinEntry, lang: language, save_path: str
    ):
        """
        Downloads the pronunciation MP3 for the given pinyin entry and saves it to the specified path.

        Args:
            pinyin (CharPingyinEntry): The pinyin entry containing the display and code.
            lang (language): The language of the pronunciation (PUTONGHUA or CANTONESE).
            save_path (str): The path where the MP3 file will be saved.
        """
        mp3_url = self.get_pronunciation_url(pinyin, lang)
        response = self.session.get(str(mp3_url), timeout=10)
        response.raise_for_status()

        with open(save_path, "wb") as mp3_file:
            mp3_file.write(response.content)


def main():
    scraper = WordInfoScraper()
    word = "床"  # Example word

    try:
        word_info = scraper.get_word_info(word)
        # The ID in this word_info is not the same as the ID we are using in the database
        print("Word Info:", word_info.model_dump())
        print("-" * 40)
        stroke_image = scraper.get_word_stroke_image(word_info)
        print("Stroke Image URL:", stroke_image)
        print("-" * 40)

        vocab_details = scraper.get_word_phrase(word_info)
        print("Vocabulary Details:", vocab_details.model_dump())
        print("-" * 40)

        # print(
        #     "If you want to get the big image or pronounciation, comment out the return below"
        # )
        # return
        big_image = scraper.get_word_big_image(word)
        print("Big Image URL:", big_image)
        print("-" * 40)

        for pronounciation in word_info.pingyin.cantonese:
            print(
                "Cantonese Pronunciation:", pronounciation.display, pronounciation.code
            )
            try:
                # ensure os exists
                import os

                mp3_filename = os.path.join(
                    MP3_SAVE_PATH,
                    f"{word_info.word}_cantonese_{pronounciation.code}.mp3",
                )
                scraper.download_pronunciation_mp3(
                    pronounciation, language.CANTONESE, mp3_filename
                )
                print(f"MP3 downloaded successfully: {mp3_filename}")
            except Exception as e:
                print(f"Failed to download MP3: {e}")

    except Exception as e:
        print("An error occurred:", e)


if __name__ == "__main__":
    main()
