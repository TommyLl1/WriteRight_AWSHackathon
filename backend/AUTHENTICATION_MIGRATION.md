# Authentication Migration Guide

This guide explains how to migrate from the old sample-based authentication to the new real authentication system.

## Database Setup

You'll need to create the new database tables for authentication. Run these SQL commands on your database:

### 1. Environment Configuration
First, add the pepper configuration to your `.env` file:
```env
# Authentication Configuration
# Pepper for password hashing - MUST be kept secret and consistent
# Generate a strong, random value and store securely
PASSWORD_PEPPER="your_secret_pepper_change_this_in_production"
```

**Important**: The pepper value must remain consistent across deployments, or existing password hashes will become invalid.

### 2. Create the passwords table:
```sql
-- Execute the contents of models/supabase/password.sql
```

### 3. Create the sessions table:
```sql
-- Execute the contents of models/supabase/sessions.sql  
```

### 4. Add the new RPC functions:
```sql
-- Add the cleanup_auth_sessions function from models/supabase/rpc.sql
```

## Code Migration

### For Frontend/Client Applications:

#### Old Way (Sample Authentication):
```javascript
// Login always returned the same sample user
const response = await fetch('/auth/login', {
  method: 'POST',
  body: JSON.stringify({
    email: 'any@example.com',
    password: 'anypassword'
  })
});
```

#### New Way (Real Authentication):
```javascript
// 1. Register a new user first
const registerResponse = await fetch('/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'securepassword123',  // Min 8 characters
    name: 'User Name'
  })
});

// 2. Login with real credentials
const loginResponse = await fetch('/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'securepassword123'
  })
});

// 3. Extract session from Authorization header
const sessionId = loginResponse.headers.get('authorization')?.replace('Bearer ', '');

// 4. Use session for authenticated requests
const protectedResponse = await fetch('/some/protected/endpoint', {
  headers: {
    'Authorization': `Bearer ${sessionId}`
  }
});
```

### Backward Compatibility

The system maintains backward compatibility with existing test users:

- Users with emails ending in `@example.com` still work with any password
- The "empty" email still returns the empty user
- Sample session IDs still work for these test users

### Session Management

#### Key Changes:
- **Real sessions**: Sessions are now stored in the database with expiration
- **Session expiry**: Sessions expire after 24 hours
- **Automatic cleanup**: Expired sessions are cleaned up every 12 hours
- **Secure tokens**: Session IDs are cryptographically secure

#### Session Lifecycle:
1. **Login**: Creates a new session with 24-hour expiration
2. **Use**: Session is validated on each protected endpoint call
3. **Expiry**: Sessions expire automatically after 24 hours
4. **Logout**: Explicitly invalidates the session
5. **Cleanup**: Expired sessions are removed from database

## Error Handling

### New Error Responses:

#### Registration Errors:
- `409 Conflict`: User already exists
- `422 Validation Error`: Invalid email or password too short

#### Login Errors:
- `401 Unauthorized`: Invalid email or password
- `422 Validation Error`: Invalid email format

#### Session Errors:
- `401 Unauthorized`: Missing or invalid session
- `401 Unauthorized`: Session expired

## Security Considerations

### Password Security:
- Minimum 8 characters required
- Passwords are hashed with bcrypt and pepper
- Unique salt generated for each password
- Pepper provides additional security layer
- Plaintext passwords are never stored

### Session Security:
- Session IDs are 32-byte cryptographically secure tokens
- Sessions stored in database with expiration timestamps
- Sessions can be invalidated server-side
- Automatic cleanup prevents session accumulation

### Best Practices:
1. **Always use HTTPS in production**
2. **Implement proper password policies on frontend**
3. **Handle session expiry gracefully in client applications**
4. **Implement session refresh if needed for long-running applications**
5. **Use proper CORS settings in production**

## Testing

Use the provided demo script to test the new authentication:

```bash
python demo_auth.py
```

Or run the test suite:

```bash
pytest tests/test_auth_service.py -v
```

## Troubleshooting

### Common Issues:

1. **"User already exists" on registration**
   - Check if user was previously registered
   - Use login instead of register

2. **"Invalid email or password" on login**
   - Verify email format is correct
   - Ensure password meets minimum requirements
   - Check if user was registered successfully

3. **"Session expired" errors**
   - Sessions expire after 24 hours
   - Re-login to get a new session

4. **Database connection errors**
   - Ensure database tables were created
   - Check database connection settings
   - Verify database permissions

For more help, check the API documentation in `api.md` or the README file.
