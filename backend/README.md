# README for WriteRight-Backend

## Installing Dependencies

To install the required dependencies for this project, run the following command:

```bash
pip install -r requirements.txt
```

### Optional: Type Hinting for aioboto3

If you need type hinting for the custom `aioboto3` package, follow these steps:

```bash
pip install vendored/types_aioboto3_custom-14.3.0-py3-none-any.whl
```

Alternatively, build a custom one from scratch

```bash
pip install boto3-stubs
mypy-boto3-builder
# Choose required package
pip install vendored/types_aioboto3_custom-14.3.0-py3-none-any.whl
```

Note: Only install the `aioboto3` type hinting tools when auth is needed

## Environment variables

See `dotenv_template.txt` to create a new `.env` file

- tried using anon key, but need to set Auth Policy
- have problem getting env keys? find small jeff

## Deployment
Assume writeright-admin is current user

```bash Deployment
# Create backend user
sudo useradd --system --no-create-home --shell /usr/sbin/nologin writeright-backend
sudo addgroup writeright-shared
sudo adduser writeright-admin writeright-shared

# logout and log back in

# Create the backend directory
sudo mkdir -p /opt/writeright-backend
sudo chown writeright-backend:writeright-shared /opt/writeright-backend

# Make uploads dir, and set perms
sudo mkdir -p /var/lib/writeright/uploads
sudo chown writeright-backend:writeright-shared /var/lib/writeright/uploads
sudo chmod 2775 /var/lib/writeright/uploads

# Clone repository
cd /opt
sudo -u writeright-backend git clone --recursive https://github.com/WriteRight-HK/writeright-backend

# Set correct ownership and permissions for the backend directory
sudo chown -R writeright-backend:writeright-shared /opt/writeright-backend
sudo chmod -R 2770 /opt/writeright-backend
sudo chown writeright-backend:writeright-shared /var/lib/writeright/uploads

# Set up environment file
cd /opt/writeright-backend
sudo -u writeright-backend cp dotenv_template.txt .env

# Edit .env file with appropriate values
sudo nano .env
sudo mkdir -p AI_text_recognition/env
sudo cp .env AI_text_recognition/env/.env
# And remember to fill the env folder with the required jsons.


# Set to group writable first, to activate venv
# Ensure python > 3.11
sudo -u writeright-backend python3.11 -m venv /opt/writeright-backend/.venv
sudo -u writeright-backend /opt/writeright-backend/.venv/bin/pip install -r /opt/writeright-backend/requirements.txt

# Set final permissions (remove group write access for security)
# (2750: rwxr-s---, group inheritance, no world access)
sudo chmod -R 2750 /opt/writeright-backend
# Upload dir needs to be written by group, webserver needs rx
sudo chmod 2775 /var/lib/writeright/uploads


# Set up automatic cleanup of old uploads (run as writeright-backend user):
sudo -u writeright-backend crontab -e
# Add the following line to the crontab to delete files older than 6 hours every hour:
# 0 * * * * find /var/lib/writeright/uploads -type f -mmin +360 -delete


# Install and enable systemd service
sudo cp /opt/writeright-backend/deployment/writeright-backend.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable writeright-backend
sudo systemctl start writeright-backend

# Check service status
sudo systemctl status writeright-backend


# Install caddy (see https://caddyserver.com/docs/install for latest)
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# Install caddyfile, remember to change domain example.com
sudo mv /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak
sudo cp /opt/writeright-backend/deployment/Caddyfile /etc/caddy/


# Check firewall settings, allow 80/TCP, 443/TCP, 443/UDP
sudo systemctl restart caddy
```

## submodule

```bash
git submodule add https://github.com/WriteRight-HK/AI-text-recognition.git
```



## TODO: 

- [x] User Auth w/ session & headers, password, etc
- [ ] SSO / oauth2 user creation (placeholder implemented)
- [x] Handle existing user
- [x] Proper response code for all endpoints (auth endpoints)
- [x] Documentation for all endpoints (auth endpoints)
- [x] Fix the requirement.txt
- [x] Validate user email properly, not just using simple regex (using Pydantic EmailStr)
- [ ] Rate limiting
- [ ] Proper DB auth policies

## Authentication System

The WriteRight backend now includes a complete authentication system with the following features:

### ✅ Implemented Features
- **User Registration**: Email/password registration with validation
- **User Login**: Secure login with bcrypt password hashing
- **Session Management**: Secure session tokens with expiration (24 hours)
- **Password Security**: Bcrypt hashing with salt generation
- **Session Cleanup**: Automatic cleanup of expired sessions
- **Backward Compatibility**: Sample users still work for testing
- **Input Validation**: Email validation and password requirements (min 8 characters)

### 🚧 Placeholder Features (Not Yet Implemented)
- **SSO Login**: Google, Apple, etc. (endpoint exists but returns 501)

### 📊 Database Tables
- `passwords`: Stores user authentication data with bcrypt hashes
- `sessions`: Manages active user sessions with expiration
- Both tables include proper foreign key relationships and indexes

### 🔐 Security Features
- Passwords hashed with bcrypt using unique salts and pepper
- Session IDs are cryptographically secure random tokens
- Sessions expire after 24 hours
- Automatic cleanup of expired sessions (runs every 12 hours)
- Protected endpoints require valid session tokens
- Pepper provides additional security layer for password hashing


## Test users

All test users have email ending with `@example.com`:

| **Name**       | **UUID**                             | **Email**                  |
| -------------- | ------------------------------------ | -------------------------- |
| No words added | 6d495c93-28d5-4c40-b4fe-36a514c1c275 | no-words-added@example.com |
| Testing1       | b2977f0b-b464-4be3-9057-984e7ac4c9a9 | test1@example.com          |
| Testing2       | 033610f9-5741-4341-ae4d-198dd3d0a9d4 | test2@example.com          |
| John Doe       | 4767db57-8ae6-484d-8f9f-8ad977fb3157 | doe@example.com            |
