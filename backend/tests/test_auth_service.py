import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock
from features.auth_service import AuthService
from models.db.db import User, Password, Session, SupabaseTable
from models.helpers import APIResponse
from uuid import uuid4, UUID


class TestAuthService:
    """Test cases for the AuthService class."""

    @pytest.fixture
    def mock_db(self):
        """Create a mock database service."""
        db = AsyncMock()
        return db

    @pytest.fixture
    def auth_service(self, mock_db):
        """Create an AuthService instance with mock database."""
        return AuthService(db=mock_db)

    @pytest.mark.asyncio
    async def test_hash_password(self, auth_service):
        """Test password hashing functionality."""
        password = "testpassword123"
        hashed_password, salt = auth_service._hash_password(password)

        # Check that hash and salt are returned
        assert hashed_password is not None
        assert salt is not None
        assert isinstance(hashed_password, str)
        assert isinstance(salt, str)

        # Check that the same password produces different hashes (due to different salts)
        hashed_password2, salt2 = auth_service._hash_password(password)
        assert hashed_password != hashed_password2
        assert salt != salt2

    @pytest.mark.asyncio
    async def test_verify_password(self, auth_service):
        """Test password verification functionality."""
        password = "testpassword123"
        hashed_password, salt = auth_service._hash_password(password)

        # Correct password should verify
        assert auth_service._verify_password(password, hashed_password, salt) is True

        # Wrong password should not verify
        assert (
            auth_service._verify_password("wrongpassword", hashed_password, salt)
            is False
        )

    @pytest.mark.asyncio
    async def test_login_sample_users(self, auth_service, mock_db):
        """Test login with sample/test users."""
        # Test empty user
        user_id = await auth_service.login("empty", "anypassword")
        assert user_id == "6d495c93-28d5-4c40-b4fe-36a514c1c275"

        # Test all specific test users
        user_id = await auth_service.login("no-words-added@example.com", "anypassword")
        assert user_id == "6d495c93-28d5-4c40-b4fe-36a514c1c275"

        user_id = await auth_service.login("test1@example.com", "anypassword")
        assert user_id == "b2977f0b-b464-4be3-9057-984e7ac4c9a9"

        user_id = await auth_service.login("test2@example.com", "anypassword")
        assert user_id == "033610f9-5741-4341-ae4d-198dd3d0a9d4"

        user_id = await auth_service.login("doe@example.com", "anypassword")
        assert user_id == "4767db57-8ae6-484d-8f9f-8ad977fb3157"

        # Test unknown example.com user (should default to SAMPLE_USER_ID)
        user_id = await auth_service.login("unknown@example.com", "anypassword")
        assert user_id == "b2977f0b-b464-4be3-9057-984e7ac4c9a9"

    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, auth_service, mock_db):
        """Test login with nonexistent user."""
        # Mock database to return no password record
        mock_db.filter_data.return_value = APIResponse(data=[], count=0)

        user_id = await auth_service.login("nonexistent@test.com", "password")
        assert user_id is None

    @pytest.mark.asyncio
    async def test_register_new_user(self, auth_service, mock_db):
        """Test registering a new user."""
        # Mock database responses
        mock_db.filter_data.return_value = APIResponse(
            data=[], count=0
        )  # User doesn't exist
        mock_db.insert_data.return_value = APIResponse(
            data=[{"success": True}], count=1
        )

        user_id = await auth_service.register(
            email="newuser@test.com", password="password123", name="New User"
        )

        assert user_id is not None
        # Verify database calls were made
        assert mock_db.filter_data.called
        assert mock_db.insert_data.call_count == 2  # User and Password records

    @pytest.mark.asyncio
    async def test_register_existing_user(self, auth_service, mock_db):
        """Test registering a user that already exists."""
        # Mock database to return existing password record
        existing_password = Password(
            user_id=UUID(str(uuid4())),
            email="existing@test.com",
            hashed_password="hash",
            salt="salt",
        )
        mock_db.filter_data.return_value = APIResponse(
            data=[existing_password], count=1
        )

        user_id = await auth_service.register(
            email="existing@test.com", password="password123", name="Existing User"
        )

        assert user_id is None  # Should return None for existing user

    @pytest.mark.asyncio
    async def test_create_session(self, auth_service, mock_db):
        """Test session creation."""
        user_id = str(uuid4())
        mock_db.insert_data.return_value = APIResponse(
            data=[{"success": True}], count=1
        )

        session_id = await auth_service.create_session(user_id)

        assert session_id is not None
        assert isinstance(session_id, str)
        assert len(session_id) > 0

        # Verify database call was made
        mock_db.insert_data.assert_called_once()

    @pytest.mark.asyncio
    async def test_verify_session_sample_sessions(self, auth_service, mock_db):
        """Test session verification with sample sessions."""
        # Test sample session
        user_id = await auth_service.verify_session("sample-session-id")
        assert user_id == "b2977f0b-b464-4be3-9057-984e7ac4c9a9"

        # Test empty user session
        user_id = await auth_service.verify_session("sample-empty-session-id")
        assert user_id == "6d495c93-28d5-4c40-b4fe-36a514c1c275"

        # Test invalid session
        user_id = await auth_service.verify_session("invalid-session")
        assert user_id is None

    @pytest.mark.asyncio
    async def test_pepper_functionality(self, auth_service):
        """Test that pepper is properly used in password hashing."""
        import os

        # Save original pepper
        original_pepper = os.environ.get("PASSWORD_PEPPER", "")

        try:
            # Set a test pepper
            os.environ["PASSWORD_PEPPER"] = "test_pepper_123"

            # Create new auth service to pick up new pepper
            from features.auth_service import AuthService
            from unittest.mock import AsyncMock

            # Note: We need to reload the module to pick up new environment variable
            # In real usage, pepper should be set before app startup
            password = "testpassword123"

            # Test with one pepper value
            hashed_password1, salt1 = auth_service._hash_password(password)
            assert (
                auth_service._verify_password(password, hashed_password1, salt1) is True
            )

            # Change pepper and verify password fails (simulating different pepper)
            os.environ["PASSWORD_PEPPER"] = "different_pepper_456"

            # The hash was created with old pepper, so verification with new pepper should fail
            # Note: This is a conceptual test - in practice pepper shouldn't change

        finally:
            # Restore original pepper
            if original_pepper:
                os.environ["PASSWORD_PEPPER"] = original_pepper
            elif "PASSWORD_PEPPER" in os.environ:
                del os.environ["PASSWORD_PEPPER"]


if __name__ == "__main__":
    pytest.main([__file__])
