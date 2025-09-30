-- Sessions table for managing user authentication sessions
CREATE TABLE public.sessions (
    session_id text NOT NULL PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at bigint NOT NULL DEFAULT (EXTRACT(epoch FROM now()))::bigint,
    expires_at bigint NOT NULL,
    is_active boolean NOT NULL DEFAULT true
) TABLESPACE pg_default;

-- Create index for faster lookups
CREATE INDEX idx_sessions_user_id ON public.sessions(user_id);
CREATE INDEX idx_sessions_active ON public.sessions(is_active);
CREATE INDEX idx_sessions_expires_at ON public.sessions(expires_at);

-- Best practice: Clean up expired sessions periodically
COMMENT ON TABLE public.sessions IS 'Table for managing user authentication sessions with expiration';
