from typing import Annotated, Any, Optional, TypeVar, Union, List, Generic
from pydantic import PlainSerializer, Field
from uuid import UUID
import unicodedata
from datetime import datetime, timezone
from pydantic import BaseModel


# ------ Helper Types ----------------------------
# Custom UUID type that always serializes to a string
UUIDStr = Annotated[
    UUID,
    PlainSerializer(lambda v: str(v) if isinstance(v, UUID) else v, return_type=str),
]

# Custom type aliases
QuestionTypeStr = str
AnswerTypeStr = str
ChineseChar = str
ID = int
TimeStamp = Annotated[str, Field(description="ISO 8601 formatted timestamp")]
UnixTimestamp = Annotated[int, Field(description="Unix timestamp in seconds")]
UnicodeInt = Annotated[
    int,
    Field(
        description="Unicode code point of a character",
    ),
]

_TableT = TypeVar("_TableT")


class APIResponse(BaseModel, Generic[_TableT]):
    """Supabase API response model."""

    data: List[_TableT]  # A list of items of type _TableT
    count: Optional[int]


# ------ Helper Functions -------------------------
def get_time():
    """UNIX timestamp in seconds"""
    return int(datetime.now(timezone.utc).timestamp())


def is_Chinese_char(char: ChineseChar | str) -> bool:
    """
    Check if the character is a valid Chinese character.
    :param char: Character to check.
    :return: True if the character is a valid Chinese character, False otherwise.
    """
    return len(char) == 1 and (0x4E00 <= ord(char) <= 0x9FFF)


def is_Chinese_char_unicode(char: UnicodeInt | int) -> bool:
    """
    Check if the Unicode code point corresponds to a valid Chinese character.
    :param char: Unicode code point to check.
    :return: True if the code point is a valid Chinese character, False otherwise.
    """
    return isinstance(char, int) and (0x4E00 <= char <= 0x9FFF)


def is_Chinese_char_factory(fieldInfo: dict[str, Any]) -> bool:
    """
    Factory function to validate if a given field contains a valid Chinese character.

    This function is designed to be used in conjunction with Pydantic models to ensure
    that a specific field always contains a valid Chinese character. It retrieves the
    value of the "word" key from the provided field information dictionary and checks
    its validity.

    Args:
        fieldInfo (dict[str, Any]): A dictionary containing field information, where
            the "word" key is expected to hold the string to be validated.

    Returns:
        bool: True if the "word" value is a valid Chinese character, False otherwise.
    """
    return is_Chinese_char(fieldInfo.get("word", ""))


def is_Chinese_String(s: str) -> bool:
    """
    Check if the string contains only valid Chinese characters.
    :param s: String to check.
    :return: True if the string contains only valid Chinese characters, False otherwise.
    """
    return all(is_Chinese_char(char) for char in s)


def is_Chinese_String_factory(fieldInfo: dict[str, Any]) -> bool:
    """
    Factory function to validate if a given field contains a valid Chinese string.

    This function is designed to be used in conjunction with Pydantic models to ensure
    that a specific field always contains a valid Chinese string. It retrieves the
    value of the "word" key from the provided field information dictionary and checks
    its validity.

    Args:
        fieldInfo (dict[str, Any]): A dictionary containing field information, where
            the "word" key is expected to hold the string to be validated.

    Returns:
        bool: True if the "word" value is a valid Chinese string, False otherwise.
    """
    return is_Chinese_String(fieldInfo.get("word", ""))


def to_unicodeInt_from_char(char: ChineseChar | str) -> UnicodeInt:
    # Check if the character is a single Chinese character
    # Normalize the character to NFC form
    # e.g. example: 'n\u0303' (n with tilde) will be normalized to 'ñ'
    normalized_char = unicodedata.normalize("NFC", char)

    if not is_Chinese_char(normalized_char):
        raise ValueError("Input must be a single Chinese character.")

    # Return the Unicode code point of the character
    return ord(normalized_char)


def get_char_unicode_factory(fieldInfo: dict[str, Any]) -> UnicodeInt:
    """
    Factory function to create a UnicodeInt field with a custom validator.
    This is useful for Pydantic models to ensure the field is always a valid Unicode code point.
    """
    # invalid will trigger value error in get_char_unicode
    return to_unicodeInt_from_char(fieldInfo.get("word", "invalid"))


def to_char_from_unicode(unicode_int: Union[UnicodeInt, int]) -> ChineseChar:
    """
    Convert a Unicode code point to a Chinese character.
    :param unicode_int: Unicode code point of the character.
    :return: The corresponding Chinese character.
    """
    unicode_int = int(unicode_int)  # Explicitly cast to int
    if not (0x4E00 <= unicode_int <= 0x9FFF):
        raise ValueError("Unicode integer must be in the range of Chinese characters.")

    return chr(unicode_int)
