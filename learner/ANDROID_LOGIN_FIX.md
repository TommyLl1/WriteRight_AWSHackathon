# Android Login Fix Summary

## Problem
Android login was failing with connection errors while web login worked fine. The error was:
```
SocketException: Connection refused (OS Error: Connection refused, errno = 111), address = localhost, port = 59098
```

## Root Causes
1. **Missing INTERNET permission** - Android apps require explicit permission to access the internet
2. **Localhost URL issue** - On Android, `localhost` refers to the device itself, not the host machine
3. **Network Security Configuration** - Android blocks HTTP traffic by default (requires HTTPS or explicit configuration)

## Solutions Applied

### 1. Added INTERNET Permission
**File:** `android/app/src/main/AndroidManifest.xml`
- Added `<uses-permission android:name="android.permission.INTERNET" />` to allow network access

### 2. Platform-Specific Base URL
**File:** `lib/utils/constants.dart`
- Modified to use platform-specific URLs:
  - Web: `http://localhost:8000`
  - Android: `http://10.0.2.2:8000` (Android emulator's host machine mapping)
  - iOS: `http://localhost:8000`
- Can be replaced when we have the real API

### 3. Network Security Configuration
**Files:** 
- `android/app/src/main/AndroidManifest.xml` - Added `android:networkSecurityConfig="@xml/network_security_config"`
- `android/app/src/main/res/xml/network_security_config.xml` - Created configuration to allow HTTP traffic to:
  - localhost
  - 10.0.2.2 (Android emulator)
  - 10.0.3.2 (Genymotion emulator) 
  - Local network ranges (192.168.x.x, 172.16.x.x)

### 4. Enhanced Error Handling
**File:** `lib/backend/services/auth_service.dart`
- Added specific handling for `DioException` types
- Better error messages for network issues
- Added logging for base URL to help debug

### 5. Improved Dio Configuration
**File:** `lib/utils/dio.dart`
- Increased timeout for Android (30 seconds vs 15 seconds)
- Added `sendTimeout` configuration
- Enhanced logging for debugging

## Testing
After applying these fixes:
1. Clean and rebuild the Android app: `flutter clean && flutter build apk`
2. Make sure your backend server is running on `localhost:8000`
3. Test on Android emulator - login should now work

## Notes
- For physical Android devices, you'll need to use your computer's actual IP address instead of `10.0.2.2`
- For production, consider using HTTPS and removing the cleartext traffic permissions
- The network security configuration is only needed for development with HTTP localhost
