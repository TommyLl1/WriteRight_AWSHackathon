# API documentation

## Authentication

The API uses session-based authentication with bcrypt password hashing for security.

### Registration
- **POST** `/auth/register`
  - **Body**: `{ "email": "user@example.com", "password": "securepassword", "name": "User Name" }`
  - **Response**: `{ "user_id": "uuid", "email": "user@example.com", "name": "User Name", "message": "User registered successfully" }`
  - **Status Codes**: 
    - 201: User created successfully
    - 409: User already exists
    - 422: Validation error (password too short, invalid email, etc.)

### Login
- **POST** `/auth/login`
  - **Body**: `{ "email": "user@example.com", "password": "securepassword" }`
  - **Response**: `{ "user_id": "uuid", "email": "user@example.com", "name": "User Name", "level": 1, "exp": 0, "session_id": "session_token" }`
  - **Headers**: Sets `Authorization: Bearer <session_id>` header
  - **Status Codes**:
    - 200: Login successful
    - 401: Invalid email or password

### Logout
- **GET** `/auth/logout`
  - **Headers**: Requires `Authorization: Bearer <session_id>`
  - **Response**: `{ "message": "User logged out successfully" }`
  - **Status Codes**:
    - 200: Logout successful
    - 401: Missing or invalid session

### SSO Login (Placeholder)
- **POST** `/auth/sso-login`
  - **Body**: `{ "provider": "google", "token": "oauth_token", "email": "user@example.com", "name": "User Name" }`
  - **Status Codes**: 
    - 501: Not implemented yet

### Authentication Headers
All protected endpoints require the `Authorization` header:
```
Authorization: Bearer <session_id>
```

### Session Management
- Sessions expire after 24 hours
- Expired sessions are automatically cleaned up
- Session cleanup runs periodically to remove old/inactive sessions

### Security Features
- Passwords are hashed using bcrypt with salt and pepper
- Session IDs are cryptographically secure random tokens
- Password minimum length: 8 characters
- Email validation using Pydantic EmailStr
- Pepper adds an additional layer of security to password hashing

### Test Users
The following test users are available for development and testing:
- `no-words-added@example.com` → User ID: `6d495c93-28d5-4c40-b4fe-36a514c1c275`
- `test1@example.com` → User ID: `b2977f0b-b464-4be3-9057-984e7ac4c9a9` 
- `test2@example.com` → User ID: `033610f9-5741-4341-ae4d-198dd3d0a9d4`
- `doe@example.com` → User ID: `4767db57-8ae6-484d-8f9f-8ad977fb3157`
- Any other `@example.com` email defaults to the `test1` user ID
- Special case: `empty` email returns the "no words added" user ID

All test users accept any password for login.

## User related
Auth shall be implemented later, users should only be able to access their own
But currently userID is a uuid, guessing is likely impossible
Hence not implemented in first version

- /user/status
  - method: get
  - parm: userID
  - return: `userObject`
    - username: str
    - level: int
    - exp: int
- /user/dictionary
  - method: get
  - parm: userID
  - return: `list[DictionaryItem]`
  - DictionaryItem: 
    - dict_id: ? (can we just use unicode number)
    - text: ChineseChar
    - image: url
    - pronounce: `PronounceObject`
    - explain: str
    - strokes: url (to strokes video)
  - `PronounceObject`: 
    - canton: _cantonese pinyin_
    - mandarin: (optional) _hanyu pinyin_
- /user/dictionary
  - paging
  - method: post
  - parm: userID, jobID
  - return: `list[status]`
  - status: int (0=ok, >0 = fail, different for each reason)
  - payload: `list[PostDictionaryItem]`
  - PostDictionaryItem: 
    - text: ChineseChar
    - image: url
- /user/dictionary-from-htr
  - method: post
  - parm: userID, jobID
  - return: `list[status]`
  - status: int (0=ok, >0 = fail, different for each reason)
  - payload: `list[outCharID]` (jobID may expire)
  - task: (Jeff): To get the running htr status? 
- /user/gameHistory
  - method: get
  - param: userID, year, month, limit < 500
  - output: `list[gameObject]` in that month, maximum `limit` entries
  - task: 
    1. verify year and month, clamp limit to 500
    2. query database 
  - Note: 
    - get condensed history first. Details: use query param
    - limit is page? max entry get each time?


## Handwritten Text Recognision
- /htr/upload
  - method: post
  - parm: job=`single`/`passage`, userID
  - payload: image
  - return:
    - jobID: uuid
    - eta: int (seconds until expected completion)
  - task:
    1. store image, rename to `uuid.png`/`uuid.jpg`/etc
    2. store userID and jobID in database
    3. calculate eta (hardcode for now, but can be based on system load+image size later)
    4. htr model runs in separate process, use rpc? or it just monitors the db and see if it was changed? (Jeff): Seperate process (fastapi have background job itself), monitor db change
- /htr/result
  - method: get
  - parm: jobID: UUID, userID
  - return: `list[htrOutputChar]`
  - htrOutputChar: 
    - cords: [x1, y1, x2, y2]
    - expectedChar: ChineseChar
    - outCharID: int (just unique to this jobID)
    - mistakeType: TODO: Filled by backend
  - task: 
    - lookup database and see if completed, if so return results

## Games
Auth shall be implemented later, users should only be able to access their own
But currently userID is a uuid, guessing is likely impossible
Hence not implemented in first version

- /game/questions
  - method: get
  - param: userID, qCount
  - qCount: int (num of questions)
  - return: gameObject
  - gameObject: 
    - `list[questions]`
    - generated_at: unix timestamps
    - gameID: uuid
  - task:
    1. mark current time
    2. dispatch generator and return result
- /game/submitResults
  - method: post
  - param: userID
  - payload: gameObject
  - return: http code
  - task: 
    1. store gameObject

- /game/check-handwrite
  - post
  - param: chinese char, uploaded url, game_id, (any format for strokes recognition later)
  - Flow:
    1. Client upload to pre-signed url
    2. Client post to this endpoint of the word and the url
    3. return True or False to client

