if __name__ == "__main__":
    import sys
    import os

    sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from PIL import Image
import requests
import io
import aiohttp
from pydantic import BaseModel

class FileUploadResponse(BaseModel):
    file_id: str
    original_filename: str
    stored_filename: str
    content_type: str
    size: int
    message: str

class StorageController():
    def __init__(self):
        self.base_url = "https://writeright-1.eastasia.cloudapp.azure.com/api-9687094a"

    async def upload_image(self, image: Image.Image, filename: str) -> FileUploadResponse:
        """
        Uploads an image to the storage service and returns the URL of the uploaded image.
        
        :param image: The image to upload.
        :param filename: The name of the file to save the image as.
        :return: URL of the uploaded image.
        """

        ## Check if file is larger than 2 KiB
        if image.size[0] * image.size[1] > 2048 * 2048:  # Assuming image.size returns (width, height)
            raise ValueError("Image size exceeds the maximum allowed size of 2 KiB.")

        # Convert PIL Image to bytes
        img_byte_arr = io.BytesIO()
        image.save(img_byte_arr, format='PNG')
        img_byte_arr.seek(0)

        # Use FormData to properly format the file upload
        form_data = aiohttp.FormData()
        form_data.add_field(
            name="file",
            value=img_byte_arr,
            filename=filename,
            content_type="image/png"
        )

        # Upload the image asynchronously
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/files/upload",
                data=form_data
            ) as response:
                if response.status == 200:
                    response_data = await response.json()
                    return FileUploadResponse.model_validate(response_data)
                else:
                    raise Exception(f"Failed to upload image: {await response.text()}")
                
    def get_submit_url(self, user_id) -> str:
        return self.base_url + "/files/upload"
    
        
if __name__ == "__main__":
    import asyncio
    # Example usage
    controller = StorageController()
    try:
        # Load an image from a file or URL
        image = Image.open("AI_text_recognition/img_database/tori.jpg")  # Replace with your image path
        filename = "tori.jpg"  # The name you want to save the image as
        uploaded_url = asyncio.run(controller.upload_image(image, filename))
        print(f"Image uploaded successfully: {uploaded_url}")
    except Exception as e:
        print(f"Error uploading image: {e}")