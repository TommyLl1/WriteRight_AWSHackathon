# Database Configuration Guide

This project now supports multiple database backends:

## Supabase (Default)
Set `DATABASE_TYPE=supabase` in your `.env` file and provide:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`

## PostgreSQL
Set `DATABASE_TYPE=postgresql` in your `.env` file and provide:
- `POSTGRES_HOST` (default: localhost)
- `POSTGRES_PORT` (default: 5432)
- `POSTGRES_DB` (default: writeright)
- `POSTGRES_USER` (default: postgres)
- `POSTGRES_PASSWORD`

## Architecture

The project uses an abstract `DatabaseService` interface that both `SupabaseService` and `PgDatabaseService` implement. This allows for seamless switching between backends.

### Key Components:
- `utils/database/base.py` - Abstract base class
- `utils/database/supabase_service.py` - Supabase implementation
- `utils/database/pgdb.py` - PostgreSQL implementation
- `utils/database/factory.py` - Factory to create database instances

### Migration Notes:
- RPC functions in `RPCService` are database-agnostic
- The system automatically falls back to Supabase for RPC operations when using PostgreSQL
- All CRUD operations use the abstract interface and work with both backends

## Security
Both implementations use parameterized queries to prevent SQL injection. The PostgreSQL implementation uses `asyncpg` with proper parameter binding.
