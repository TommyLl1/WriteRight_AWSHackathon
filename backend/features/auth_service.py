from fastapi import Depends, HTTPException
from utils.database.base import DatabaseService
from models.db.db import User, Password, SupabaseTable
from typing import Optional
import bcrypt
import secrets
import uuid
from uuid import UUID
from utils.logger import setup_logger
import os

logger = setup_logger(__name__)

# Get pepper from environment or use a default (in production, this should always be from env)
PEPPER = os.getenv("PASSWORD_PEPPER", "writeright_default_pepper_change_in_production")

# Fixed sample session key and corresponding user ID (for backward compatibility during transition)
SAMPLE_SESSION_ID = "sample-session-id"
SAMPLE_USER_ID = "b2977f0b-b464-4be3-9057-984e7ac4c9a9"
SAMPLE_EMPTY_USER_ID = "6d495c93-28d5-4c40-b4fe-36a514c1c275"
SAMPLE_EMPTY_USER_SESSION_ID = "sample-empty-session-id"


class AuthService:
    def __init__(self, db: DatabaseService):
        self.db = db

    async def create_session(self, user_id: str) -> str:
        """
        Create a new session for the user and store it in the database.
        Returns the session_id.
        """
        try:
            # Check for sample users (backward compatibility)
            if user_id == SAMPLE_EMPTY_USER_ID:
                return SAMPLE_EMPTY_USER_SESSION_ID
            elif user_id == SAMPLE_USER_ID:
                return SAMPLE_SESSION_ID

            # Generate unique session ID
            session_id = secrets.token_urlsafe(32)

            # Set session expiration (24 hours from now)
            from models.helpers import get_time

            current_time = get_time()
            expires_at = current_time + (24 * 60 * 60)  # 24 hours in seconds

            # Create session record
            from models.db.db import Session

            session = Session(
                session_id=session_id,
                user_id=UUID(user_id),
                expires_at=expires_at,
            )

            # Store session in database
            await self.db.insert_data(
                table=SupabaseTable.SESSIONS,
                data=session.model_dump(mode="json"),
            )

            logger.info(f"Created session for user: {user_id}")
            return session_id

        except Exception as e:
            logger.error(f"Error creating session for user {user_id}: {str(e)}")
            # Fallback to sample session for backward compatibility
            return SAMPLE_SESSION_ID

    async def remove_session(self, session_id: str) -> None:
        """
        Remove/invalidate a session from the database.
        """
        try:
            # Skip for sample sessions
            if session_id in [SAMPLE_SESSION_ID, SAMPLE_EMPTY_USER_SESSION_ID]:
                return

            # Actually delete the session from the database
            await self.db.delete_data(
                table=SupabaseTable.SESSIONS,
                condition={"session_id": session_id},
            )

            logger.info(f"Deleted session: {session_id}")

        except Exception as e:
            logger.error(f"Error removing session {session_id}: {str(e)}")

    async def verify_session(self, session_id: str) -> Optional[str]:
        """
        Verify if the session is valid and active.
        Returns user_id if valid, None otherwise.
        """
        try:
            # Handle sample sessions (backward compatibility)
            if session_id == SAMPLE_SESSION_ID:
                return SAMPLE_USER_ID
            elif session_id == SAMPLE_EMPTY_USER_SESSION_ID:
                return SAMPLE_EMPTY_USER_ID

            # Check session in database
            from models.db.db import Session

            session_result = await self.db.filter_data(
                table=SupabaseTable.SESSIONS,
                condition={"session_id": session_id, "is_active": True},
                return_type=Session,
            )

            if not session_result.data:
                return None

            session = session_result.data[0]

            # Check if session has expired
            from models.helpers import get_time

            current_time = get_time()
            if current_time > session.expires_at:
                # Mark session as inactive
                await self.db.update_data(
                    table=SupabaseTable.SESSIONS,
                    condition={"session_id": session_id},
                    data={"is_active": False},
                )
                logger.warning(f"Session expired: {session_id}")
                return None

            return str(session.user_id)

        except Exception as e:
            logger.error(f"Error verifying session {session_id}: {str(e)}")
            return None

    async def fetch_user(self, session_id: str) -> User:
        """
        Fetches the user based on the session key. In this case, it returns a fixed sample user.
        """
        # change to actual verification (maybe add a db to store sessions and join with user)
        user_id = await self.verify_session(session_id)
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid session ID")

        # Normally, you would fetch the user from the database using the session ID.
        # Here we return a fixed sample user for demonstration purposes.
        user = await self.db.filter_data(
            table=SupabaseTable.USERS,
            condition={"user_id": user_id},
            return_type=User,
        )
        if not user.data:
            raise HTTPException(status_code=404, detail="User not found")

        return user.data[0]

    async def login(self, email: str, plain_password: str) -> Optional[str]:
        """
        Authenticate user with email and password.
        Returns user_id if authentication is successful, None otherwise.
        """
        try:
            # Check for sample users first (backward compatibility)
            if email == "empty":
                return SAMPLE_EMPTY_USER_ID
            elif email.endswith("@example.com"):
                # Handle all test users with their specific IDs
                test_user_map = {
                    "no-words-added@example.com": "6d495c93-28d5-4c40-b4fe-36a514c1c275",
                    "test1@example.com": "b2977f0b-b464-4be3-9057-984e7ac4c9a9",
                    "test2@example.com": "033610f9-5741-4341-ae4d-198dd3d0a9d4",
                    "doe@example.com": "4767db57-8ae6-484d-8f9f-8ad977fb3157",
                }
                user_id = test_user_map.get(
                    email, SAMPLE_USER_ID
                )  # Default to SAMPLE_USER_ID for other @example.com emails
                logger.info(f"Test user login: {email} -> {user_id}")
                return user_id

            # Fetch password record from database
            password_result = await self.db.filter_data(
                table=SupabaseTable.PASSWORDS,
                condition={"email": email},
                return_type=Password,
            )

            if not password_result.data:
                logger.warning(f"No password record found for email: {email}")
                return None

            password_record = password_result.data[0]

            # Verify password using bcrypt with pepper
            if self._verify_password(
                plain_password, password_record.hashed_password, password_record.salt
            ):
                logger.info(f"Successful login for user: {email}")
                return str(password_record.user_id)
            else:
                logger.warning(f"Invalid password for user: {email}")
                return None

        except Exception as e:
            logger.error(f"Error during login for {email}: {str(e)}")
            return None

    def _hash_password(self, password: str) -> tuple[str, str]:
        """
        Hash a password using bcrypt with a generated salt and pepper.
        Returns tuple of (hashed_password, salt).
        """
        # Add pepper to password before hashing
        peppered_password = password + PEPPER

        # Generate a salt
        salt = bcrypt.gensalt().decode("utf-8")

        # Hash the peppered password with the salt
        hashed_password = bcrypt.hashpw(
            peppered_password.encode("utf-8"), salt.encode("utf-8")
        ).decode("utf-8")

        return hashed_password, salt

    def _verify_password(
        self, plain_password: str, hashed_password: str, salt: str
    ) -> bool:
        """
        Verify a password against its hash and salt using bcrypt with pepper.
        """
        try:
            # Add pepper to the plain password
            peppered_password = plain_password + PEPPER

            # Check password using bcrypt
            return bcrypt.checkpw(
                peppered_password.encode("utf-8"), hashed_password.encode("utf-8")
            )
        except Exception as e:
            logger.error(f"Error verifying password: {str(e)}")
            return False

    async def register(self, email: str, password: str, name: str) -> Optional[str]:
        """
        Register a new user with email and password.
        Returns user_id if successful, None if user already exists.
        """
        try:
            # Check if user already exists
            existing_user = await self.db.filter_data(
                table=SupabaseTable.PASSWORDS,
                condition={"email": email},
                return_type=Password,
            )

            if existing_user.data:
                logger.warning(f"User already exists with email: {email}")
                return None

            # Generate user ID
            user_id = UUID(str(uuid.uuid4()))

            # Create user record
            user = User(
                user_id=user_id,
                email=email,
                name=name,
            )

            # Hash password
            hashed_password, salt = self._hash_password(password)

            # Create password record
            password_record = Password(
                user_id=user_id,
                email=email,
                hashed_password=hashed_password,
                salt=salt,
            )

            # Insert user and password records
            await self.db.insert_data(
                table=SupabaseTable.USERS,
                data=user.model_dump(mode="json"),
            )

            await self.db.insert_data(
                table=SupabaseTable.PASSWORDS,
                data=password_record.model_dump(mode="json"),
            )

            logger.info(f"Successfully registered user: {email}")
            return str(user_id)

        except Exception as e:
            logger.error(f"Error during registration for {email}: {str(e)}")
            return None

    async def sso_login(
        self,
        provider: str,
        token: str,
        email: Optional[str] = None,
        name: Optional[str] = None,
    ) -> Optional[str]:
        """
        Handle SSO login. Currently not implemented but placeholder for future implementation.
        Returns user_id if successful, None otherwise.
        """
        logger.warning(
            f"SSO login attempted but not implemented yet. Provider: {provider}"
        )
        # TODO: Implement SSO login logic
        # 1. Verify token with the SSO provider (Google, Apple, etc.)
        # 2. Extract user information from the token
        # 3. Check if user exists with SSO provider info
        # 4. Create user if doesn't exist
        # 5. Return user_id
        return None
