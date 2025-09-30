from pydantic import BaseModel, Field
from typing import List, Optional, Any, Annotated, Literal
from enum import Enum


class CharPingyinEntry(BaseModel):
    display: str
    code: Annotated[
        str, Field(pattern=r"^[a-zA-Z]+[0-9](\-[a-zA-Z])*$")
    ]  # Ensures the code is valid pinyin format
    sound: Optional[str] = None


class language(str, Enum):
    PUTONGHUA = Literal["putonghua"]
    CANTONESE = Literal["cantonese"]


class CharPingyin(BaseModel):
    putonghua: List[CharPingyinEntry]
    cantonese: List[CharPingyinEntry]


def get_stroke_image_url(fieldInfo: dict[str, Any]) -> Optional[str]:
    """
    Returns the URL for the stroke image.
    """
    # Changed to return optional value, can change to throw exception if needed
    url_prefix = "https://www.secmenu.com/apps/words/www/img/word/"
    word_id = fieldInfo.get("id", None)
    if fieldInfo.get("imgs"):
        fname = fieldInfo["imgs"][0]
        return str(f"{url_prefix}{fname}")
    elif word_id:
        # Fallback to word_id if no imgs are provided
        fname = f"{word_id}.gif"
        return str(f"{url_prefix}{fname}")
    else:
        # If no imgs and no word_id, return None
        return None

    # fname = (
    #     fieldInfo["imgs"][0]
    #     if fieldInfo.get("imgs") else word_id + ".gif"
    #     # and len(fieldInfo.get("imgs")) >= 1
    # )
    # return (
    #     str(f"https://www.secmenu.com/apps/words/www/img/word/{fname}")
    #     if fname
    #     else None
    # )


class WordInfo(BaseModel):
    id: int  # Changed from str to int
    word: str
    radical: str
    stroke: int  # Changed from str to int
    english: str
    imgs: List[str]  # Updated to use Filename model
    # Default value will be set dynamically
    stroke_gif: Optional[str] = Field(default_factory=get_stroke_image_url)
    ishd: bool
    hres_imgs: Optional[List[str]] = None  # Updated to use Filename model
    pingyin: CharPingyin
    cj_code: str
    cj_root: str
    ytz: List[str]
    # Removed as it was not used, and might cause buggy behavior
    # seems like alternative method of writing the word
    # zx_rmk: List[str]


class VocabPingyinEntry(BaseModel):
    """
    May contain multiple chars
    """

    display: str
    code: Annotated[
        str,
        Field(
            description="The pinyin code for the vocabulary entry. A singular 'P' indicates a pause."
        ),
    ]
    sound: Optional[str] = None


class VocabPingyin(BaseModel):
    putonghua: VocabPingyinEntry
    cantonese: VocabPingyinEntry


class PhraseInfo(BaseModel):
    phrase: str
    english: str
    pingyin: VocabPingyin = Field(
        default_factory=lambda: VocabPingyin(
            putonghua=VocabPingyinEntry(display="", code="", sound=None),
            cantonese=VocabPingyinEntry(display="", code="", sound=None),
        ),
        description="Pingyin information for the phrase, defaults to empty values if missing.",
    )
    sentences: str = Field(default="", description="Sentences using the phrase")


class PhraseInfoList(BaseModel):
    phrases: List[PhraseInfo]

    def __getitem__(self, item: int) -> PhraseInfo:
        return self.phrases[item]

    def __len__(self) -> int:
        return len(self.phrases)
