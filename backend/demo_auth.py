#!/usr/bin/env python3
"""
Demo script showing how to use the new authentication system.
This script demonstrates registration, login, and session management.

Usage:
    python demo_auth.py
"""

import asyncio
import httpx
import json
from typing import Optional


class AuthDemo:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.session_id: Optional[str] = None

    async def register_user(self, email: str, password: str, name: str) -> dict:
        """Register a new user."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/auth/register",
                json={"email": email, "password": password, "name": name},
            )
            if response.status_code == 201:
                print(f"✅ User registered successfully: {email}")
                return response.json()
            elif response.status_code == 409:
                print(f"⚠️  User already exists: {email}")
                return {"error": "User already exists"}
            else:
                print(f"❌ Registration failed: {response.status_code} {response.text}")
                return {"error": response.text}

    async def login_user(self, email: str, password: str) -> dict:
        """Login a user and store session."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.base_url}/auth/login",
                json={"email": email, "password": password},
            )
            if response.status_code == 200:
                data = response.json()
                # Extract session from Authorization header
                auth_header = response.headers.get("authorization", "")
                if auth_header.startswith("Bearer "):
                    self.session_id = auth_header[7:]  # Remove "Bearer " prefix
                    print(f"✅ Login successful for: {email}")
                    if self.session_id:
                        print(f"   Session ID: {self.session_id[:20]}...")
                    print(f"   User Level: {data.get('level')}, EXP: {data.get('exp')}")
                    return data
                else:
                    print("⚠️  Login successful but no session in response")
                    return data
            else:
                print(f"❌ Login failed: {response.status_code} {response.text}")
                return {"error": response.text}

    async def logout_user(self) -> dict:
        """Logout the current user."""
        if not self.session_id:
            print("❌ No active session to logout")
            return {"error": "No session"}

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/auth/logout",
                headers={"Authorization": f"Bearer {self.session_id}"},
            )
            if response.status_code == 200:
                print("✅ Logout successful")
                self.session_id = None
                return response.json()
            else:
                print(f"❌ Logout failed: {response.status_code} {response.text}")
                return {"error": response.text}

    async def test_protected_endpoint(self) -> dict:
        """Test accessing a protected endpoint with the session."""
        if not self.session_id:
            print("❌ No active session for protected endpoint test")
            return {"error": "No session"}

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/testing/auth-template",
                headers={"Authorization": f"Bearer {self.session_id}"},
            )
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Protected endpoint access successful: {data.get('message')}")
                return data
            else:
                print(
                    f"❌ Protected endpoint access failed: {response.status_code} {response.text}"
                )
                return {"error": response.text}


async def main():
    """Main demo function."""
    print("🔐 WriteRight Authentication Demo")
    print("=" * 40)

    demo = AuthDemo()

    # Test user credentials
    test_email = "demo@test.com"
    test_password = "demopassword123"
    test_name = "Demo User"

    print("\n1. Testing User Registration...")
    await demo.register_user(test_email, test_password, test_name)

    print("\n2. Testing User Login...")
    await demo.login_user(test_email, test_password)

    print("\n3. Testing Protected Endpoint Access...")
    await demo.test_protected_endpoint()

    print("\n4. Testing User Logout...")
    await demo.logout_user()

    print("\n5. Testing Access After Logout...")
    await demo.test_protected_endpoint()

    print("\n6. Testing Login with Wrong Password...")
    await demo.login_user(test_email, "wrongpassword")

    print("\n7. Testing Sample User Login (Backward Compatibility)...")
    await demo.login_user("test1@example.com", "anypassword")

    print("\n8. Testing All Test Users...")
    test_users = [
        ("no-words-added@example.com", "6d495c93-28d5-4c40-b4fe-36a514c1c275"),
        ("test1@example.com", "b2977f0b-b464-4be3-9057-984e7ac4c9a9"),
        ("test2@example.com", "033610f9-5741-4341-ae4d-198dd3d0a9d4"),
        ("doe@example.com", "4767db57-8ae6-484d-8f9f-8ad977fb3157"),
    ]

    for email, expected_user_id in test_users:
        print(f"   Testing {email}...")
        result = await demo.login_user(email, "anypassword")
        if result.get("user_id") == expected_user_id:
            print(f"   ✅ {email} -> {expected_user_id}")
        else:
            print(
                f"   ❌ {email} -> Expected {expected_user_id}, got {result.get('user_id')}"
            )
        await demo.logout_user()

    print("\n✅ Demo completed!")
    print(
        "\nNote: Make sure the WriteRight backend server is running on localhost:8000"
    )
    print("You can start it with: uvicorn app:app --reload")


if __name__ == "__main__":
    asyncio.run(main())
