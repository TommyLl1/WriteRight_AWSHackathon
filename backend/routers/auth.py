from fastapi import APIRouter, Depends, HTTPException, Response, Request
from pydantic import BaseModel
from features.auth_service import AuthService
from routers.dependencies import get_auth_service
from models.db.db import User
from models.auth import (
    LoginRequest,
    RegisterRequest,
    LoginResponse,
    RegisterResponse,
    SSOLoginRequest,
)

from utils.logger import setup_logger

logger = setup_logger(__name__)

# Define the router
router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=LoginResponse)
async def login(
    request: LoginRequest,
    response: Response,
    auth_service: AuthService = Depends(get_auth_service),
):
    """Login with email and password."""
    logger.debug(f"Attempting to login with email: {request.email}")
    user_id = await auth_service.login(request.email, request.password)
    logger.debug(f"User ID after login attempt: {user_id}")

    if not user_id:
        logger.debug(f"Login failed for email: {request.email}")
        raise HTTPException(status_code=401, detail="Invalid email or password")

    session_id = await auth_service.create_session(user_id)
    user: User = await auth_service.fetch_user(session_id)

    response.headers["Authorization"] = f"Bearer {session_id}"

    return LoginResponse(
        user_id=str(user.user_id) if user.user_id else user_id,
        email=user.email,
        name=user.name,
        level=user.level,
        exp=user.exp,
        session_id=session_id,
        created_at=user.created_at,
    )


@router.post("/register", response_model=RegisterResponse)
async def register(
    request: RegisterRequest,
    auth_service: AuthService = Depends(get_auth_service),
):
    """Register a new user with email and password."""
    logger.debug(f"Attempting to register user with email: {request.email}")

    user_id = await auth_service.register(request.email, request.password, request.name)

    if not user_id:
        raise HTTPException(status_code=409, detail="User already exists")

    logger.info(f"Successfully registered user: {request.email}")

    return RegisterResponse(
        user_id=user_id,
        email=request.email,
        name=request.name,
    )


@router.get("/logout")
async def logout(
    request: Request, auth_service: AuthService = Depends(get_auth_service)
):
    """Logout the user by invalidating the session."""
    # In this example, we simply clear the session ID from the response.
    # In a real application, you might want to delete the session from the database.
    session_id = request.headers.get("Authorization")
    if not session_id:
        raise HTTPException(status_code=401, detail="Authorization header missing")
    await auth_service.remove_session(session_id)
    return {"message": "User logged out successfully"}


@router.post("/sso-login", response_model=LoginResponse)
async def sso_login(
    request: SSOLoginRequest,
    response: Response,
    auth_service: AuthService = Depends(get_auth_service),
):
    """SSO login with Google, Apple, etc. (Currently not implemented)."""
    logger.debug(f"Attempting SSO login with provider: {request.provider}")

    user_id = await auth_service.sso_login(
        provider=request.provider,
        token=request.token,
        email=request.email,
        name=request.name,
    )

    if not user_id:
        raise HTTPException(status_code=501, detail="SSO login not implemented yet")

    session_id = await auth_service.create_session(user_id)
    user: User = await auth_service.fetch_user(session_id)

    response.headers["Authorization"] = f"Bearer {session_id}"

    return LoginResponse(
        user_id=str(user.user_id) if user.user_id else user_id,
        email=user.email,
        name=user.name,
        level=user.level,
        exp=user.exp,
        session_id=session_id,
        created_at=user.created_at,
    )


# class RegisterRequest(BaseModel):
#     email: str
#     password: str
#     name: str


# class SocialLoginRequest(BaseModel):
#     provider: str  # "google" or "facebook"
#     token: str  # Access token from Google/Facebook


# # Helper Functions
# def get_secret_hash(username: str) -> str:
#     """Generate the secret hash for Cognito."""
#     import hmac
#     import hashlib
#     import base64

#     message = username + COGNITO_CLIENT_ID
#     digest = hmac.new(
#         COGNITO_CLIENT_SECRET.encode("utf-8"),
#         message.encode("utf-8"),
#         hashlib.sha256,
#     ).digest()
#     return base64.b64encode(digest).decode()


# def verify_social_token(provider: str, token: str):
#     """Verify access token from Google or Facebook."""
#     if provider == "google":
#         # Verify token via Google API
#         response = requests.get(
#             f"https://www.googleapis.com/oauth2/v3/tokeninfo?id_token={token}"
#         )
#     elif provider == "facebook":
#         # Verify token via Facebook API
#         response = requests.get(
#             f"https://graph.facebook.com/me?fields=id,name,email&access_token={token}"
#         )
#     else:
#         raise HTTPException(status_code=400, detail="Unsupported provider")

#     if response.status_code != 200:
#         raise HTTPException(status_code=401, detail="Invalid social token")

#     return response.json()


# @router.post("/register")
# def register(request: RegisterRequest):
#     """Register a new user in Cognito."""
#     try:
#         cognito_client.sign_up(
#             ClientId=COGNITO_CLIENT_ID,
#             Username=request.email,
#             Password=request.password,
#             SecretHash=get_secret_hash(request.email),
#             UserAttributes=[
#                 {"Name": "email", "Value": request.email},
#                 {"Name": "name", "Value": request.name},
#             ],
#         )
#         return {"message": "User registered successfully. Please confirm your email."}
#     except cognito_client.exceptions.UsernameExistsException:
#         raise HTTPException(status_code=400, detail="User already exists")
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))


# @router.post("/logout")
# def logout(token: str):
#     """Log out a user by invalidating their session."""
#     try:
#         cognito_client.global_sign_out(AccessToken=token)
#         return {"message": "User logged out successfully"}
#     except cognito_client.exceptions.NotAuthorizedException:
#         raise HTTPException(status_code=401, detail="Invalid token")
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))


# @router.get("/profile")
# def get_profile(token: str):
#     """Retrieve the user's profile information."""
#     try:
#         response = cognito_client.get_user(AccessToken=token)
#         user_attributes = {
#             attr["Name"]: attr["Value"] for attr in response["UserAttributes"]
#         }
#         return {"profile": user_attributes}
#     except cognito_client.exceptions.NotAuthorizedException:
#         raise HTTPException(status_code=401, detail="Invalid token")
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))


# @router.post("/social-login")
# def social_login(request: SocialLoginRequest):
#     """Login with Google or Facebook."""
#     try:
#         # Verify the social token
#         social_user = verify_social_token(request.provider, request.token)
#         email = social_user.get("email")
#         if not email:
#             raise HTTPException(
#                 status_code=400, detail="Email not found in social account"
#             )

#         # Check if the user already exists in Cognito
#         try:
#             cognito_client.admin_get_user(
#                 UserPoolId=COGNITO_USER_POOL_ID,
#                 Username=email,
#             )
#         except cognito_client.exceptions.UserNotFoundException:
#             # If user does not exist, register them in Cognito
#             cognito_client.admin_create_user(
#                 UserPoolId=COGNITO_USER_POOL_ID,
#                 Username=email,
#                 UserAttributes=[{"Name": "email", "Value": email}],
#                 DesiredDeliveryMediums=["EMAIL"],
#             )

#         # Authenticate the user and return tokens
#         response = cognito_client.initiate_auth(
#             AuthFlow="USER_PASSWORD_AUTH",
#             AuthParameters={
#                 "USERNAME": email,
#                 "PASSWORD": "SocialLoginPlaceholder",  # Set a placeholder password
#                 "SECRET_HASH": get_secret_hash(email),
#             },
#             ClientId=COGNITO_CLIENT_ID,
#         )
#         return {
#             "message": f"Login successful via {request.provider}",
#             "access_token": response["AuthenticationResult"]["AccessToken"],
#             "id_token": response["AuthenticationResult"]["IdToken"],
#             "refresh_token": response["AuthenticationResult"]["RefreshToken"],
#         }

#     except HTTPException as e:
#         raise e
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
