-- Password table for authentication
-- Salt should be generated using a secure random generator (e.g., gen_salt('bf') for bcrypt)
create table public.passwords (
  user_id uuid not null primary key references users(user_id) on delete cascade,
  email text not null unique,
  hashed_password text not null,
  salt text not null, -- Salt generated securely, e.g., gen_salt('bf')
  sso_provider text null, -- For SSO, e.g., 'google', 'apple', etc.
  sso_token text null, -- Store SSO token or identifier if needed
  created_at bigint not null default (EXTRACT(epoch from now()))::bigint,
  updated_at bigint not null default (EXTRACT(epoch from now()))::bigint
) TABLESPACE pg_default;

-- Best practice: Store only hashed passwords and salts, never plaintext. For SSO, store provider and token/identifier as needed.
