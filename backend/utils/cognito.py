# from pydantic import BaseModel, Field
# from typing import Optional
# from jose import jwt
# import boto3
# import os
# import hmac
# import hashlib
# import base64
# import requests
# from utils.config import config
# from fastapi import HTTPException


# class Cognito:
#     def __init__(self):
#         self.region = config.get("aws.cognito.region", "us-east-1")
#         self.user_pool_id = config.get("aws.cognito.user_pool_id")
#         self.client_id = config.get("aws.cognito.client_id")
#         self.client_secret = config.get("aws.cognito.client_secret")
#         self.client = boto3.client("cognito-idp", region_name=self.region)

#     def get_secret_hash(self, username: str) -> str:
#         """Generate the secret hash for Cognito."""
#         message = username + self.client_id
#         digest = hmac.new(
#             self.client_secret.encode("utf-8"),
#             message.encode("utf-8"),
#             hashlib.sha256,
#         ).digest()
#         return base64.b64encode(digest).decode()

#     def login(self, email: str, password: str) -> AuthTokens:
#         """Authenticate a user with email and password."""
#         try:
#             response = self.client.initiate_auth(
#                 AuthFlow="USER_PASSWORD_AUTH",
#                 AuthParameters={
#                     "USERNAME": email,
#                     "PASSWORD": password,
#                     "SECRET_HASH": self.get_secret_hash(email),
#                 },
#                 ClientId=self.client_id,
#             )
#             auth_result = response["AuthenticationResult"]
#             return AuthTokens(
#                 access_token=auth_result["AccessToken"],
#                 id_token=auth_result["IdToken"],
#                 refresh_token=auth_result["RefreshToken"],
#             )
#         except self.client.exceptions.NotAuthorizedException:
#             raise HTTPException(status_code=401, detail="Invalid credentials")
#         except self.client.exceptions.UserNotConfirmedException:
#             raise HTTPException(status_code=403, detail="User not confirmed")
#         except Exception as e:
#             raise HTTPException(status_code=500, detail=str(e))

#     def register(self, email: str, password: str, name: str) -> CognitoMessage:
#         """Register a new user in Cognito."""
#         try:
#             self.client.sign_up(
#                 ClientId=self.client_id,
#                 Username=email,
#                 Password=password,
#                 SecretHash=self.get_secret_hash(email),
#                 UserAttributes=[
#                     {"Name": "email", "Value": email},
#                     {"Name": "name", "Value": name},
#                 ],
#             )
#             return CognitoMessage(
#                 message="User registered successfully. Please confirm your email."
#             )
#         except self.client.exceptions.UsernameExistsException:
#             raise HTTPException(status_code=400, detail="User already exists")
#         except Exception as e:
#             raise HTTPException(status_code=500, detail=str(e))

#     def logout(self, token: str) -> CognitoMessage:
#         """Log out a user by invalidating their session."""
#         try:
#             self.client.global_sign_out(AccessToken=token)
#             return CognitoMessage(message="User logged out successfully.")
#         except self.client.exceptions.NotAuthorizedException:
#             raise HTTPException(status_code=401, detail="Invalid token")
#         except Exception as e:
#             raise HTTPException(status_code=500, detail=str(e))

#     def get_profile(self, token: str) -> UserProfile:
#         """Retrieve the user's profile information."""
#         try:
#             response = self.client.get_user(AccessToken=token)
#             user_attributes = {
#                 attr["Name"]: attr["Value"] for attr in response["UserAttributes"]
#             }
#             return UserProfile(
#                 email=user_attributes.get("email"),
#                 name=user_attributes.get("name"),
#                 additional_attributes=user_attributes,
#             )
#         except self.client.exceptions.NotAuthorizedException:
#             raise HTTPException(status_code=401, detail="Invalid token")
#         except Exception as e:
#             raise HTTPException(status_code=500, detail=str(e))

#     def social_login(self, provider: str, token: str) -> SocialLoginResponse:
#         """Authenticate a user using social login (Google/Facebook)."""

#         def verify_social_token(provider: str, token: str):
#             """Verify access token from Google or Facebook."""
#             if provider == "google":
#                 response = requests.get(
#                     f"https://www.googleapis.com/oauth2/v3/tokeninfo?id_token={token}"
#                 )
#             elif provider == "facebook":
#                 response = requests.get(
#                     f"https://graph.facebook.com/me?fields=id,name,email&access_token={token}"
#                 )
#             else:
#                 raise HTTPException(status_code=400, detail="Unsupported provider")

#             if response.status_code != 200:
#                 raise HTTPException(status_code=401, detail="Invalid social token")

#             return response.json()

#         # Verify the token with the provider
#         social_user = verify_social_token(provider, token)
#         email = social_user.get("email")
#         if not email:
#             raise HTTPException(
#                 status_code=400, detail="Email not found in social account"
#             )

#         # Check if the user exists in Cognito; if not, register them
#         try:
#             self.client.admin_get_user(
#                 UserPoolId=self.user_pool_id,
#                 Username=email,
#             )
#         except self.client.exceptions.UserNotFoundException:
#             # Register user
#             self.client.admin_create_user(
#                 UserPoolId=self.user_pool_id,
#                 Username=email,
#                 UserAttributes=[{"Name": "email", "Value": email}],
#                 DesiredDeliveryMediums=["EMAIL"],
#             )

#         # Authenticate the user
#         auth_tokens = self.login(email, "SocialLoginPlaceholder")
#         return SocialLoginResponse(
#             provider=provider,
#             access_token=auth_tokens.access_token,
#             id_token=auth_tokens.id_token,
#             refresh_token=auth_tokens.refresh_token,
#         )
