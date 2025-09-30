from typing import Type, Optional, TypeVar, Dict, Any, Iterable
from openai import AsyncOpenAI
import asyncio
from os import getenv
import json
from json import loads, JSONDecodeError
from openai.types.chat import ChatCompletion
from pydantic import BaseModel
from utils.config import config
from utils.logger import setup_logger
from models.LLM import LLMModels
from logging import DEBUG
import base64
from PIL import Image
from io import BytesIO


logger = setup_logger(__name__, level=DEBUG)

T = TypeVar("T", bound=BaseModel)
TEMPERATURE = 0.5  # Default temperature for LLM responses
MODEL = "gpt-4.1-mini-ca"  # Default model for LLM responses


class LLMService:
    def __init__(
        self,
        api_key: str = getenv("OPENAI_API_KEY") or "",
        client_url: str = getenv("OPENAI_API_PATH") or "",
    ) -> None:
        """
        Initialize the OpenAI client with the provided API key.
        :param api_key: Your OpenAI API key. If not provided, it will be loaded from environment variables.
        """
        self.api_key = api_key
        self.path = client_url
        assert self.api_key, "API key is required for OpenAI client."
        assert self.path, "API path is required for OpenAI client."

        # Initialize OpenAI client
        # We uses ChatAnywhere platform with OpenAI client
        # self.client = OpenAI(api_key=self.api_key, base_url=self.path)
        self.client = AsyncOpenAI(
            api_key=self.api_key,
            base_url=self.path,
        )

    # async def generate_text(
    #     self,
    #     system_prompt: str,
    #     user_prompt: str,
    #     model: LLMModels = LLMModels.GPT_3_5_TURBO,
    #     max_tokens: int = int(str(config.get("LLMService.MaxTokens", 100))),
    # ) -> str:
    #     """
    #     Generate text based on given prompts using the specified model.
    #     :param prompt: The input prompt for text generation.
    #     :param model: The model to use for generation (default is "gpt-3.5-turbo").
    #     :param max_tokens: The maximum number of tokens to generate (default is 100).
    #     :return: The generated text.
    #     """
    #     try:
    #         response = self.client.chat.completions.create(
    #             model=model,
    #             messages=[
    #                 {"role": "system", "content": system_prompt},
    #                 {"role": "user", "content": user_prompt},
    #             ],
    #             max_tokens=max_tokens,
    #         )
    #         return (
    #             response.choices[0].message.content.strip()
    #             if response.choices and response.choices[0].message.content is not None
    #             else ""
    #         )
    #     except Exception as e:
    #         print(f"Error generating text: {e}")
    #         return ""

    def is_response_complete(self, response: ChatCompletion) -> bool:
        """
        Determines if a ChatCompletion response is complete based on various conditions.

        This method evaluates the `finish_reason` and the content of the response to
        determine if it is complete. It raises specific exceptions for incomplete or
        invalid responses.

        :param response: An instance of `ChatCompletion` containing the generated response.
        :type response: ChatCompletion

        :raises ValueError: If the response does not contain any choices.
        :raises ValueError: If the response was cut off due to length limits.
        :raises ValueError: If the response was filtered due to content policies.
        :raises ValueError: If the response was cut off due to tool calls.
        :raises ValueError: If the response was cut off due to function calls.
        :raises ValueError: If the response does not contain a valid message or content.
        :raises ValueError: If the response is not complete or valid due to an unknown error.

        :return: True if the response is complete and the `finish_reason` is "stop".
        :rtype: bool
        """
        # A simple heuristic to check for incomplete responses
        if not response.choices:
            raise ValueError(
                "Incomplete Response: The response does not contain any choices."
            )
        if response.choices[0].finish_reason == "length":
            raise ValueError(
                "Incomplete Response: The response was cut off due to length limits."
            )
        if response.choices[0].finish_reason == "content_filter":
            raise ValueError(
                "Incomplete Response: The response was filtered due to content policies."
            )
        if response.choices[0].finish_reason == "tool_calls":
            raise ValueError(
                "Incomplete Response: The response was cut off due to tool calls."
            )
        if response.choices[0].finish_reason == "function_call":
            raise ValueError(
                "Incomplete Response: The response was cut off due to function calls."
            )
        if (
            not response.choices[0].message
            or not response.choices[0].message.content
            or len(response.choices[0].message.content.strip()) == 0
        ):
            raise ValueError(
                "Incomplete Response: The response does not contain a valid message or content."
            )
        if response.choices[0].finish_reason == "stop":
            return True
        raise ValueError("Unknown Error: The response is not complete or valid.")

    def output_sanitizer(self, response: ChatCompletion) -> str:
        """
        Sanitize the output from the response.
        :param response: The generated response text.
        :return: The sanitized output.
        """
        if (
            response.choices is None
            or len(response.choices) == 0
            or response.choices[0].message.content is None
        ):
            return ""
        response_content = response.choices[0].message.content.strip()
        if response_content.startswith("```json\n"):
            response_content = response_content.strip()[len("```json\n") :].strip()
        if response_content.endswith("```"):
            response_content = response_content[: -len("\n```")].strip()
        response_content.replace("<think></think>", "").strip()
        return response_content

    async def generate_text_with_structured_outputs(
        self,
        system_prompt: str,
        user_prompt: str,
        response_model: Type[BaseModel],
        model: LLMModels = LLMModels.DEEPSEEK_V3,
        max_tokens: int = int(str(config.get("LLMService.MaxTokens", 100))),
    ) -> Optional[Dict[str, Any]]:
        """
        Generate **Structured** text based on given prompts using the specified model.
        """
        logger.info(f"Using {model}...")

        # Only gpt-4o and DeepSeek LLMModels support structured outputs
        response_formats = {
            "type": "json_object",
        }
        if model == LLMModels.DEEPSEEK_V3:
            response_formats = {
                "type": "json_schema",
                "properties": json.dumps(response_model.model_json_schema(), indent=2),
            }
            # logger.debug(
            #     f"Using structured output format for model {model}: {response_formats}"
            # )
            try:
                response = await self.client.chat.completions.create(
                    model=model.value,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    max_tokens=max_tokens,
                    n=1,
                    # Cannot get the correct type hint for response_format
                    response_format=response_formats,  # type: ignore
                    temperature=0.9,
                )
            except Exception as e:
                logger.error(f"Error generating structured text: {e}")
                return None
        elif model in [LLMModels.GPT_4O_MINI]:
            # logger.debug(
            #     f"Using structured output format for model {model}: {response_formats}"
            # )
            try:
                response = await self.client.beta.chat.completions.parse(
                    model=model.value,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    max_tokens=max_tokens,
                    n=1,
                    # Cannot get the correct type hint for response_format
                    response_format=response_model,  # type: ignore
                    temperature=0.9,
                )
            except Exception as e:
                logger.error(f"Error generating structured text: {e}")
                return None

        else:
            logger.warning(
                f"Model {model} does not support structured outputs. Using default response format."
            )
            # Fallback to default response format
            try:
                response = await self.client.chat.completions.create(
                    model=model.value,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt},
                    ],
                    max_tokens=max_tokens,
                    n=1,
                    # Cannot get the correct type hint for response_format
                    response_format=response_formats,  # type: ignore
                    temperature=0.9,
                )
            except Exception as e:
                logger.error(f"Error generating structured text: {e}")
                return None

        if not response:
            logger.error("No response received from the LLM.")
            return None

        # Logging
        if response.usage is not None:
            logger.debug("Tokens used:")
            logger.debug(f"- prompt: {response.usage.prompt_tokens}")
            logger.debug(f"- completion: {response.usage.completion_tokens}")
            logger.debug(f"- total: {response.usage.total_tokens}")
        else:
            logger.warning("No usage information available in the response.")
        logger.debug(response)
        # Check if the response is complete and has choices
        if not self.is_response_complete(response) and response.choices:
            logger.error("Response is not complete or has no choices.")
            return None

        # Sanitize the output
        # logger.debug("Response is complete and has choices.")
        sanitized_output = self.output_sanitizer(response)
        # logger.debug(f"Sanitized output: {sanitized_output}")
        loaded_object = loads(sanitized_output)
        # logger.debug(f"Loaded object: {loaded_object}")
        return loaded_object

    async def generate_structured_output_with_urls(
        self,
        system_prompt: str,
        image_urls: list[Iterable[str]],
        response_model: Type[BaseModel],
        user_prompt: Optional[str] = None,
    ) -> Optional[list[Dict[str, Any]]]:
        """
        Generate structured output with image URLs.
        :param system_prompt: The system prompt to guide the LLM.
        :param image_urls: A list of lists of image URLs.
        :return: A list of dictionaries with structured output.

        NOTE: only gpt 4o mini model is used for now.
        NOTE: This function is designed to handle pairs of images.
        """
        logger.info("Generating structured output with image URLs...")

        content = []
        # If a user prompt is provided, add it to the content
        if user_prompt:
            content.append({"type": "text", "text": user_prompt})

        # Add each pair of image URLs to the content
        for idx, url_set in enumerate(image_urls):
            # Append to content with labels for clarity
            content.append({"type": "text", "text": f"Pair {idx + 1}:"})
            for i, url in enumerate(url_set):
                content.append(
                    {
                        "type": "image_url",
                        "image_url": {"url": url},
                        "label": f"Image {i + 1} of Pair {idx + 1}",
                    }
                )

        # Serialize content into JSON for the user message
        logger.debug(content)
        user_message = json.dumps(content)

        try:
            response = await self.client.chat.completions.create(
                model=MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                n=1,
                response_format={
                    "type": "json_schema",
                    "json_schema": {
                        "name": response_model.__name__,
                        "schema": response_model.model_json_schema(),
                    },
                },  # type: ignore
                temperature=TEMPERATURE,
            )
        except Exception as e:
            # Log the error and return None
            error_message = f"{type(e).__name__}: {str(e)}"
            logger.error(
                f"Error generating structured output with image URLs. Details: {error_message}"
            )
            return None

        if not response:
            logger.error("No response received from the LLM.")
            return None

        logger.debug(response)
        # Logging token usage
        if response.usage is not None:
            logger.debug("Tokens used:")
            logger.debug(f"- prompt: {response.usage.prompt_tokens}")
            logger.debug(f"- completion: {response.usage.completion_tokens}")
            logger.debug(f"- total: {response.usage.total_tokens}")
        else:
            logger.warning("No usage information available in the response.")

        if not response.choices[0].message.content:
            logger.error("No content in the response message.")
            return None

        return json.loads(response.choices[0].message.content)

    async def generate_structured_output_with_image_lists(
        self,
        system_prompt: str,
        image_lists: list[list[Image.Image]],
        response_model: Type[BaseModel],
    ) -> Optional[list[Dict[str, Any]]]:
        """
        Generate structured output with images.
        :param system_prompt: The system prompt to guide the LLM.
        :param images: A list of images as numpy arrays.
        :return: A list of dictionaries with structured output.

        NOTE: only gpt 4o mini model is used for now.
        NOTE: This function is designed to handle pairs of images.
        """
        logger.info("Generating structured output with images...")

        content = []
        # Add each pair of images to the content
        for idx, image_set in enumerate(image_lists):
            # Ensure pair contains exactly two images
            image_urls = []
            for image in image_set:
                buffer = BytesIO()
                image.save(buffer, format="PNG")  # Save image to buffer in PNG format
                buffer.seek(0)
                encoded_image = base64.b64encode(buffer.read()).decode(
                    "utf-8"
                )  # Encode Base64
                image_urls.append(f"data:image/png;base64,{encoded_image}")

            # Append to content with labels for clarity
            content.append({"type": "text", "text": f"Pair {idx + 1}:"})
            for i, image_url in enumerate(image_urls):
                content.append(
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_url
                        },  # Correctly structured image_url
                        "label": f"Image {i + 1} of Pair {idx + 1}",
                    }
                )

        # Serialize content into JSON for the user message
        user_message = json.dumps(content)

        try:
            response = await self.client.chat.completions.create(
                model=MODEL,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                n=1,
                # response_format={
                #     "type": "json_object",
                #     "properties": {
                #         "pair_index": {"type": "integer"},
                #         "char": {"type": "string"},
                #         "is_correct": {"type": "boolean"}
                #     },
                #     "required": ["pair_index", "char", "is_correct"]
                # }, # type: ignore
                response_format={
                    "type": "json_schema",
                    "json_schema": {
                        "name": response_model.__name__,
                        "schema": response_model.model_json_schema(),
                    },
                },  # type: ignore
                temperature=TEMPERATURE,
            )
        except Exception as e:
            # Log the error and return None
            # logger.error(f"Error generating structured output with images: {e}")
            error_message = f"{type(e).__name__}: {str(e)}"
            logger.error(
                f"Error generating structured output with images. Details: {error_message}"
            )
            return None

        if not response:
            logger.error("No response received from the LLM.")
            return None

        # Logging token usage
        if response.usage is not None:
            logger.debug("Tokens used:")
            logger.debug(f"- prompt: {response.usage.prompt_tokens}")
            logger.debug(f"- completion: {response.usage.completion_tokens}")
            logger.debug(f"- total: {response.usage.total_tokens}")
        else:
            logger.warning("No usage information available in the response.")

        # Check if the response is complete
        if not self.is_response_complete(response):
            logger.error("Response is not complete.")
            return None

        # Sanitize and parse the output
        sanitized_output = self.output_sanitizer(response)
        try:
            structured_output = loads(sanitized_output)
            return structured_output
        except JSONDecodeError as e:
            logger.error(f"Error decoding JSON from response: {e}")
            return None


if __name__ == "__main__":

    async def main():
        # avoid accidential run of this script
        print("Are you sure you want to run this script?")

        return
        client = LLMService()
        result = await client.generate_text(
            system_prompt="You are a pirate. Speak like a pirate.",
            user_prompt="What is the capital of France?",
        )
        print(result)

    asyncio.run(main())
