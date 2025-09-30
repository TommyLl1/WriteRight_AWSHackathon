import os
import uuid
import tempfile
import platform
from pathlib import Path
from fastapi import APIRouter, File, UploadFile, HTTPException, status
from pydantic import BaseModel
from utils.logger import setup_logger
from models.helpers import UUIDStr

logger = setup_logger(__name__)

router = APIRouter(prefix="/files", tags=["File Upload"])


# Directory to store uploaded files
if platform.system() == "Linux":
    # Use persistent directory for uploads on Linux
    # Crontab cleans up /var/lib/writeright/uploads every 6 hours
    # 0 * * * * find /var/lib/writeright/uploads -type f -mmin +360 -delete
    # Ensure the directory exists

    UPLOAD_DIR = Path("/var/lib/writeright/uploads")
else:
    # Use local uploads directory on other systems (Windows, macOS)
    UPLOAD_DIR = Path("uploads")

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Log the upload directory being used
logger.info(f"Using upload directory: {UPLOAD_DIR.absolute()}")

# File upload constraints
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MiB in bytes
ALLOWED_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".webp",  # Images
}
BLOCKED_EXTENSIONS = {
    ".exe",
    ".bat",
    ".cmd",
    ".com",
    ".pif",
    ".scr",
    ".vbs",
    ".js",
    ".jar",
    ".sh",
    ".ps1",
    ".php",
    ".py",
    ".pl",
    ".rb",
    ".asp",
    ".aspx",
    ".jsp",
}


class FileUploadResponse(BaseModel):
    file_id: UUIDStr
    original_filename: str
    stored_filename: str
    content_type: str
    size: int
    message: str


@router.post("/upload", response_model=FileUploadResponse)
async def upload_file(file: UploadFile = File(...)):
    """
    Upload a file and store it with a random UUID filename.

    File size limit: 5 MiB
    Allowed file types: Images, Documents, Audio, Video, Archives
    Blocked file types: Executables and scripts for security

    Args:
        file: The uploaded file

    Returns:
        FileUploadResponse with file details
    """
    if not file:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="No file uploaded"
        )

    if not file.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="File must have a filename"
        )

    try:
        # Get file extension and validate
        original_filename = file.filename
        file_extension = Path(original_filename).suffix.lower()

        # Check for blocked extensions first
        if file_extension in BLOCKED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type '{file_extension}' is not allowed for security reasons",
            )

        # Check for allowed extensions
        if file_extension not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File type '{file_extension}' is not supported. Allowed types: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
            )

        # Read file content to check size
        file_content = await file.read()
        file_size = len(file_content)

        # Check file size
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File size ({file_size / (1024 * 1024):.2f} MiB) exceeds maximum allowed size of {MAX_FILE_SIZE / (1024 * 1024):.0f} MiB",
            )

        # Check for empty files
        if file_size == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="File is empty"
            )

        # Generate a random UUID for the filename
        file_uuid = uuid.uuid4()
        file_id = str(file_uuid)

        # Create the new filename with UUID and original extension
        stored_filename = f"{file_id}{file_extension}"
        file_path = UPLOAD_DIR / stored_filename

        # Save the file
        with open(file_path, "wb") as f:
            f.write(file_content)

        logger.info(
            f"File uploaded successfully: {original_filename} -> {stored_filename} ({file_size / (1024 * 1024):.2f} MiB)"
        )

        return FileUploadResponse(
            file_id=file_uuid,
            original_filename=original_filename,
            stored_filename=stored_filename,
            content_type=file.content_type or "unknown",
            size=file_size,
            message="File uploaded successfully",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error uploading file: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error uploading file: {str(e)}",
        )


@router.get("/info/{file_id}")
async def get_file_info(file_id: str):
    """
    Get information about an uploaded file by its UUID.

    Args:
        file_id: The UUID of the uploaded file

    Returns:
        File information if found
    """
    try:
        # Look for files that start with the given file_id
        matching_files = list(UPLOAD_DIR.glob(f"{file_id}.*"))

        if not matching_files:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="File not found"
            )

        file_path = matching_files[0]
        file_stats = file_path.stat()

        return {
            "file_id": file_id,
            "stored_filename": file_path.name,
            "size": file_stats.st_size,
            "created_at": file_stats.st_ctime,
            "modified_at": file_stats.st_mtime,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting file info: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error getting file info: {str(e)}",
        )


@router.delete("/{file_id}")
async def delete_file(file_id: str):
    """
    Delete an uploaded file by its UUID.

    Args:
        file_id: The UUID of the file to delete

    Returns:
        Success message
    """
    try:
        # Look for files that start with the given file_id
        matching_files = list(UPLOAD_DIR.glob(f"{file_id}.*"))

        if not matching_files:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="File not found"
            )

        file_path = matching_files[0]
        file_path.unlink()  # Delete the file

        logger.info(f"File deleted successfully: {file_path.name}")

        return {
            "message": "File deleted successfully",
            "file_id": file_id,
            "deleted_filename": file_path.name,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting file: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting file: {str(e)}",
        )


@router.get("/limits")
async def get_upload_limits():
    """
    Get file upload limits and allowed file types.

    Returns:
        Upload configuration information
    """
    return {
        "max_file_size_bytes": MAX_FILE_SIZE,
        "max_file_size_mb": MAX_FILE_SIZE / (1024 * 1024),
        "allowed_extensions": sorted(list(ALLOWED_EXTENSIONS)),
        "blocked_extensions": sorted(list(BLOCKED_EXTENSIONS)),
        "message": f"Maximum file size: {MAX_FILE_SIZE / (1024 * 1024):.0f} MiB",
    }
