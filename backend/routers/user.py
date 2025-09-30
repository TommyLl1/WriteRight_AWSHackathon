from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, UUID4
from routers.dependencies import (
    get_database,
    get_rpc_service,
)
from models.db.db import (
    User,
    SupabaseTable,
)
from models.api_response import condensedUser
from utils.database.base import DatabaseService
from utils.logger import setup_logger
from utils.rpc_service import RPCService
from routers.user_tasks import router as user_tasks_router
from routers.user_wrong_words import router as user_wrong_words_router
from typing import Optional, Dict, Any
from models.helpers import get_time
from models.helpers import UUIDStr

logger = setup_logger(__name__)

router = APIRouter(prefix="/user", tags=["User"])
router.include_router(user_tasks_router)
router.include_router(user_wrong_words_router)


# TODO: replace with actual authentication logic
@router.get("/profile", response_model=User)
async def get_user_profile(
    user_id: UUID4,
    db: DatabaseService = Depends(get_database),
):
    """
    Fetches the user profile by user ID.
    Supposed to be more detailed than the condensed version.
    May include extra things e.g. user settings, preferences, etc. later on.
    """

    # Default a tester user first
    user = await db.filter_data(
        table=SupabaseTable.USERS, condition={"user_id": user_id}
    )

    if not user.data:
        raise HTTPException(status_code=404, detail="User not found")

    return user.data[0]


class RegisterUserRequest(BaseModel):
    username: str
    email: str


@router.post(
    "/register",
    response_model=User,
    status_code=status.HTTP_201_CREATED,
    responses={
        409: {"description": "User already exists"},
    },
)
async def register_user(
    register_request: RegisterUserRequest,
    rpc_service: RPCService = Depends(get_rpc_service),
) -> User:
    """
    Registers a new user in the system.
    """
    try:
        # For now, treat name as username, later on we may separate them
        # Verify if the name and email are valid, not actually creating a user yet
        User(
            # username=register_request.username,
            email=register_request.email,
            name=register_request.username,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error registering user: {str(e)}")

    logger.debug(f"User data syntax validated")
    # Call the RPC to add a new user
    new_user = await rpc_service.add_new_user_handle_exist(
        name=register_request.username, email=register_request.email
    )
    if new_user is None or not isinstance(new_user, tuple):
        raise HTTPException(
            status_code=500, detail="Failed to register user, Database error"
        )
    user, exist = new_user
    user = User.model_validate(user)  # Validate the user data
    if not exist:
        logger.info(f"New user registered: {user}")
    else:
        # User already exists w/ the same email
        # For security reasons, we do not return the user data, or the user ID could be leaked
        raise HTTPException(status_code=409, detail="User already exists")
    return user


@router.get("/status", response_model=condensedUser)
async def get_user_status(user_id: UUID4, db: DatabaseService = Depends(get_database)):
    """
    Fetches the user's status including level and experience points.
    This is a condensed version of the user profile.
    """
    try:
        userQuery = await db.filter_data(
            table=SupabaseTable.USERS, condition={"user_id": user_id}
        )
    except Exception as e:
        logger.error(f"Error fetching user status: {str(e)}")
        raise HTTPException(
            status_code=500, detail=f"Error fetching user status: {str(e)}"
        )
    if not userQuery.data:
        raise HTTPException(status_code=404, detail="User not found")
    user: condensedUser = condensedUser.model_validate(userQuery.data[0])
    logger.debug(f"Fetched user data: {user}")
    # Condense user data to return only necessary fields
    return user


class UserSettings(BaseModel):
    user_id: UUIDStr
    updated_at: int
    language: str = "zh-hk"
    theme: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


class UpdateUserSettingsRequest(BaseModel):
    language: Optional[str] = None
    theme: Optional[str] = None
    settings: Optional[Dict[str, Any]] = None


# TODO: restrict what fields are in the settings, e.g. only allow certain keys to be updated
# currently it allows any key-value pairs in the settings dict
@router.get("/settings", response_model=UserSettings)
async def get_user_settings(
    user_id: UUIDStr, db: DatabaseService = Depends(get_database)
):
    """
    Retrieves the user's settings from the user_settings table.
    """
    result = await db.filter_data(
        table=SupabaseTable.USER_SETTINGS, condition={"user_id": str(user_id)}
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="User settings not found")
    return UserSettings(**result.data[0])


@router.post("/settings", response_model=UserSettings)
async def update_user_settings(
    user_id: UUIDStr,
    update: UpdateUserSettingsRequest,
    db: DatabaseService = Depends(get_database),
):
    """
    Updates the user's settings in the user_settings table.
    """
    # Fetch current settings
    result = await db.filter_data(
        table=SupabaseTable.USER_SETTINGS, condition={"user_id": str(user_id)}
    )
    if not result.data:
        new_settings = UserSettings(
            user_id=user_id,
            updated_at=get_time(),
            language=update.language or "zh-hk",
            theme=update.theme,
            settings=update.settings,
        )
        try:
            await db.insert_data(
                table=SupabaseTable.USER_SETTINGS, data=new_settings.model_dump()
            )
        except Exception as e:
            raise HTTPException(
                status_code=500, detail=f"Failed to create user settings: {str(e)}"
            )
        return new_settings
    else:
        current = result.data[0]
        # Prepare update fields
        update_fields = {}
        if update.language is not None:
            update_fields["language"] = update.language
        if update.theme is not None:
            update_fields["theme"] = update.theme
        if update.settings is not None:
            update_fields["settings"] = update.settings
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields to update")
        update_fields["updated_at"] = get_time()
        # Update in DB
        updated = await db.update_data(
            table=SupabaseTable.USER_SETTINGS,
            condition={"user_id": str(user_id)},
            data=update_fields,
        )
        if not updated.data:
            raise HTTPException(status_code=500, detail="Failed to update user settings")
        return UserSettings(**updated.data[0])
