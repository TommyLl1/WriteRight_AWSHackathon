from fastapi import FastAPI, Request, Depends
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi.responses import JSONResponse
from features.auth_service import AuthService
from routers.dependencies import get_auth_service
from utils.logger import setup_logger
logger = setup_logger(__name__, level="INFO")

# Fixed sample session ID
SAMPLE_SESSION_ID = "sample-session-id"

class AuthMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: FastAPI, auth_service: AuthService = Depends(get_auth_service)):
        """
        Middleware to verify session keys for incoming requests (except excluded paths).
        """
        super().__init__(app)
        self.excluded_paths = [
            "/auth/login",
            "/auth/register",
            "/auth/verify",
            "/auth/refresh",
            "/auth/logout",
            "/health",
            "/openapi.json",
            "/docs",
            "ping"
        ]
        self.auth_service = auth_service

    async def dispatch(self, request: Request, call_next):
        # Skip verification for excluded paths
        if request.url.path in self.excluded_paths:
            logger.info(f"Skipping auth verification for path: {request.url.path}")
            return await call_next(request)

        # Extract session key from headers
        session_id = request.headers.get("Authorization")
        if not session_id:
            return JSONResponse(
                status_code=401,
                content={"detail": "Authorization header missing"}
            )

        # Verify session key
        is_valid = await self.auth_service.verify_session(session_id)
        if not is_valid:
            return JSONResponse(
                status_code=401,
                content={"detail": "Invalid session key"}
            )

        # Proceed with the request
        return await call_next(request)