import requests
from bs4 import BeautifulSoup
from logging import debug
from typing import Optional
import os


class VoiceScraper:

    # Apparently i can just use other better websites (like i just found https://ondoku3.com/zh-hant/)
    # Or https://www.edbchinese.hk/EmbziciwebRes/jyutping/{pronounce}.mp3

    def download_pronunciation_mp3(self, word: str, save_dir: str) -> Optional[str]:
        """
        Downloads the MP3 file for a given pronunciation from the Lexi-Can website.

        :param pronunciation: The pronunciation string (e.g., "juk1").
        :param save_dir: The directory where the MP3 file will be saved.
        :return: The full path of the saved MP3 file, or None if the download fails.
        """

        pronunciation = self.get_word_pronuntiation(word)
        if not pronunciation:
            print(f"No pronunciation found for word '{word}'.")
            return None

        # Base URL for the MP3 file
        base_url = (
            f"https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/sound/{pronunciation}.wav"
        )

        try:
            print(f"Downloading MP3 from: {base_url}")

            # Send a GET request to the server
            response = requests.get(base_url, timeout=10)
            response.raise_for_status()  # Raise an error for HTTP status codes 4xx/5xx

            # Ensure the save directory exists
            os.makedirs(save_dir, exist_ok=True)

            # Construct the full file path for the MP3
            file_path = os.path.join(save_dir, f"{word}_{pronunciation}.mp3")

            # Save the MP3 file locally
            with open(file_path, "wb") as file:
                file.write(response.content)

            print(f"MP3 saved to: {file_path}")
            return file_path

        except requests.exceptions.RequestException as e:
            print(f"Error downloading MP3 for pronunciation '{pronunciation}': {e}")
            return None
        except Exception as e:
            print(f"An unexpected error occurred: {e}")
            return None

    def encode_big5(self, word: str) -> str:
        """
        Encodes a given text to Big5 encoding.
        """
        try:
            big5_bytes = word.encode("big5")
            encoded_string = "".join([f"%{byte:02X}" for byte in big5_bytes])
            return encoded_string
        except UnicodeEncodeError as e:
            print(f"Encoding error: {e}")
            return word

    def get_word_pronuntiation(self, word: str) -> Optional[str]:
        """
        Fetches details of a given word from the Lexi-Can website.
        """
        try:
            encoded = self.encode_big5(word)
            url = f"https://humanum.arts.cuhk.edu.hk/Lexis/lexi-can/search.php?q={encoded}"
            print(encoded)
            print(url)
            response = requests.get(url)
            response.raise_for_status()  # Raise an error for bad responses

            print("status code:", response.status_code)
            # Parse the HTML response
            soup = BeautifulSoup(response.text, "html.parser")

            # Save the HTML content to a file
            # with open(f"{word}.html", "w", encoding="utf-8") as file:
            #     file.write(str(soup))

            # Locate the <td> element containing the phonetics
            phonetics_td = soup.find("td", align="center", nowrap=True)

            # Extract the phonetics text from the nested <font> tags
            if not isinstance(phonetics_td, BeautifulSoup):
                print(f"No phonetics found for word '{word}'.")
                return None
            phonetics = "".join(font.text for font in phonetics_td.find_all("font"))

            print(f"pronunciation: {phonetics}")
            return phonetics
        except requests.RequestException as e:
            print(f"Error fetching data for word '{word}': {e}")
            return None
        except Exception as e:
            print(f"An unexpected error occurred for word '{word}': {e}")
            return None


# Usage Examples
if __name__ == "__main__":
    characters = ["俞", "晨", "旭", "行"]
    download_path = os.path.join(os.getcwd(), "scraped_mp3")

    # Scraper Instance
    scraper = VoiceScraper()
    for word in characters:
        scraper.download_pronunciation_mp3(word, save_dir=download_path)
