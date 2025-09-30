from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional
from models.helpers import UUIDStr
from uuid import UUID


# TODO: This is a workaround for development purposes.
# In production, remove the EmailStrWrapper and use EmailStr directly for LoginRequest.
# Currently this allows us to use @example.com for testing without validation errors.
class EmailStrWrapper(BaseModel):
    email: EmailStr


class LoginRequest(BaseModel):
    email: str  # Accept any string, custom validation below
    password: str = Field(
        min_length=8, description="Password must be at least 8 characters"
    )

    @field_validator("email")
    @classmethod
    def allow_test_or_valid_email(cls, value):
        if value.endswith("@example.com"):
            return value
        # Simple regex for email validation
        if EmailStrWrapper(email=value).email:
            return value
        raise ValueError("Invalid email format (except for @example.com test accounts)")


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(
        min_length=8, description="Password must be at least 8 characters"
    )
    name: str = Field(max_length=100, description="User's name, up to 100 characters")


class LoginResponse(BaseModel):
    user_id: str  # Changed to str to handle both UUID and string user IDs
    email: str
    name: str
    level: int
    exp: int
    session_id: str
    created_at: int  # Timestamp in seconds


class RegisterResponse(BaseModel):
    user_id: str  # Changed to str to handle both UUID and string user IDs
    email: str
    name: str
    message: str = "User registered successfully"


class AuthError(BaseModel):
    detail: str


class SSOLoginRequest(BaseModel):
    provider: str = Field(description="SSO provider (e.g., 'google', 'apple')")
    token: str = Field(description="SSO access token")
    email: Optional[EmailStr] = None
    name: Optional[str] = None
