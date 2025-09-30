create or replace function public.get_past_wrong_words_by_user(
    p_user_id uuid,
    p_limit int,
    p_offset int
) -- Basically is join 2 tables: past_wrong_words and words with pagination
returns table (
    word_id bigint,
    word text,
    description text,
    image_url text,
    pronunciation_url text,
    strokes_url text,
    wrong_count bigint,
    wrong_image_url text,
    last_wrong_at bigint,
    created_at bigint
) as $$
begin
    return query
    select
        w.word_id,
        w.word,
        w.description,
        w.image_url,
        w.pronunciation_url,
        w.strokes_url,
        pww.wrong_count,
        pww.wrong_image_url,
        pww.last_wrong_at,
        pww.created_at

    -- Foreign key join
    from
        public.past_wrong_words pww
    join
        public.words w
    on
        pww.word_id = w.word_id
    where
        pww.user_id = p_user_id

    -- Pagination
    order by
        pww.last_wrong_at desc
    limit p_limit
    offset p_offset;
end;
$$ language plpgsql;




create or replace function public.increment_wrong_count_for_user(
    p_user_id uuid,
    p_word_ids bigint[]
)
returns void as $$
begin
    update public.past_wrong_words
    set
        wrong_count = coalesce(wrong_count, 0) + 1, -- Increase wrong count by 1
        last_wrong_at = EXTRACT(epoch FROM now()) -- Update last wrong time as current time
    where
        user_id = p_user_id
        and word_id = any(p_word_ids);
end;
$$ language plpgsql;




create or replace function public.update_question_stats(
    p_answered_questions uuid[], -- List of question IDs answered
    p_wrong_questions uuid[]     -- List of question IDs answered incorrectly
)
returns table (
    answered_count int, -- Number of rows updated for answered questions
    wrong_count int     -- Number of rows updated for wrong questions
) as $$
declare
    rows_answered int;
    rows_wrong int;
begin
    -- Increment the use_count for all answered questions
    update public.questions
    set
        use_count = coalesce(use_count, 0) + 1
    where
        question_id = any(p_answered_questions)
    returning count(*) into rows_answered;

    -- Increment the wrong_count for all wrong questions
    update public.questions
    set
        wrong_count = coalesce(wrong_count, 0) + 1
    where
        question_id = any(p_wrong_questions)
    returning count(*) into rows_wrong;

    -- Return the counts
    return query select rows_answered, rows_wrong;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION public.add_new_user(
    p_name text,
    p_email text
) RETURNS jsonb AS $$
DECLARE
    v_user jsonb;
    v_result jsonb;
BEGIN
    -- Check if the user already exists
    SELECT to_jsonb(u) INTO v_user FROM public.users u WHERE email = p_email;

    IF v_user IS NOT NULL THEN
        -- Add 'existing_user' flag to the returned JSON
        v_result := jsonb_set(v_user, '{existing_user}', 'true');
        RETURN v_result;
    ELSE
        -- Insert new user
        INSERT INTO public.users (user_id, created_at, name, exp, level, email)
        VALUES (gen_random_uuid(), extract(epoch from now())::bigint, p_name, 0, 1, p_email)
        RETURNING to_jsonb(users.*) INTO v_user;
        
        -- Add 'existing_user' flag to the returned JSON
        v_result := jsonb_set(v_user, '{existing_user}', 'false');
        RETURN v_result;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_utc8_start_day_unix()
RETURNS bigint
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    -- Somehow needs UTC-8, none of the AI figured this out.
    -- Claude 4 gave this along with another incorrect ans, still think both right
    -- Don't question, just use is fine
    RETURN EXTRACT(EPOCH FROM DATE_TRUNC('day', NOW() AT TIME ZONE 'UTC-8') AT TIME ZONE 'UTC-8')::bigint;
END;
$$;

create or replace function get_or_create_today_tasks(p_user_id uuid)
returns setof tasks
language plpgsql
as $$
declare
    -- get_utc8_start_day_unix() just works, dont ask why
    today_start bigint := get_utc8_start_day_unix();
    -- start + 1d - 1s
    today_end bigint := today_start + 86399; 
    existing_task_id uuid;
begin
    -- Check if today's daily task exists
    select task_id into existing_task_id
    from tasks
    where user_id = p_user_id
      and task_class = 'daily'
      and until between today_start and today_end
    limit 1;

    -- If not, insert today's daily task
    if existing_task_id is null then
        insert into tasks (
            task_id, user_id, task_class, type, created_at, until, status, title, content, priority, completed_at, exp, target, progress
        ) values (
            gen_random_uuid(),
            p_user_id,
            'daily',
            'daily_adventure',
            extract(epoch from now()),
            today_end,
            'ongoing',
            '每日任務: 完成一次冒險探索',
            json_build_object(
                'description', '每日任務: 完成一次冒險探索'
            ),
            100,
            null,
            10, -- exp default to 10
            1,  -- target (e.g., required_count)
            0   -- progress
        );
    end if;

    -- Return all valid tasks (until in the future), max 100, order by priority desc
    return query
    select *
    from tasks
    where user_id = p_user_id
      and (until is null or until > extract(epoch from now()))
    order by priority desc nulls last, until asc
    limit 100;

end;
$$;

create or replace function maintain_tasks()
returns table (abandoned_count integer, deleted_abandoned_count integer, deleted_old_count integer)
language plpgsql
as $$
declare
    abandoned_count integer := 0;
    deleted_abandoned_count integer := 0;
    deleted_old_count integer := 0;
begin
    -- Mark overdue ongoing tasks as abandoned
    update tasks
    set status = 'abandoned',
        completed_at = extract(epoch from now())
    where status = 'ongoing'
      and until is not null
      and until < extract(epoch from now());
    get diagnostics abandoned_count = row_count;

    -- Delete abandoned tasks more than 7 days past due
    delete from tasks
    where status = 'abandoned'
      and until is not null
      and until < (extract(epoch from now()) - 7 * 24 * 60 * 60);
    get diagnostics deleted_abandoned_count = row_count;

    -- Delete any tasks older than 90 days (by created_at)
    delete from tasks
    where created_at is not null
      and created_at < (extract(epoch from now()) - 90 * 24 * 60 * 60);
    get diagnostics deleted_old_count = row_count;

    return query select abandoned_count, deleted_abandoned_count, deleted_old_count;
end;
$$;



create or replace function set_task_progress(p_user_id uuid, p_task_id uuid, p_progress integer)
returns table (
    updated boolean,
    granted_exp bigint
)
language plpgsql
as $$
declare
    v_exp bigint := 0;
    v_completed boolean := false;
    v_new_exp bigint;
    v_new_level bigint;
    v_target integer;
begin
    -- Get the target for the task
    select target into v_target from tasks where task_id = p_task_id and user_id = p_user_id;

    -- Update progress
    update tasks
    set progress = p_progress
    where task_id = p_task_id
      and user_id = p_user_id;

    -- Always return true if found
    if found then
        v_completed := true;
    end if;

    -- If progress meets or exceeds target, mark as completed
    if v_target is not null and p_progress >= v_target then
        -- Get task provided xp
        update tasks
        set status = 'completed',
            completed_at = extract(epoch from now())
        where task_id = p_task_id
          and user_id = p_user_id
          and status = 'ongoing'
        returning exp into v_exp;

        -- If a task is completed, grant exp to the user using update_user_experience
        if found then
            select new_exp, new_level into v_new_exp, v_new_level
            from update_user_experience(p_user_id, coalesce(v_exp, 0));
            v_completed := true;
        end if;
    else
        v_completed := true;
    end if;

    return query select v_completed, coalesce(v_exp, 0);
end;
$$;

create or replace function update_user_experience(
    p_user_id uuid,
    p_gained_exp bigint,
    p_growth_rate float default 1.5
)
returns table (
    new_exp bigint,
    new_level bigint
) as $$
declare
    v_exp bigint;
    v_level bigint;
begin
    -- Fetch current exp, add gained exp
    select coalesce(exp, 0) + p_gained_exp into v_exp
    from users
    where user_id = p_user_id;

    -- Calculate new level
    v_level := floor(power(v_exp / 10.0, 1.0 / p_growth_rate));

    -- Ensure minimum level is 1
    if v_level < 1 then
        v_level := 1;
    end if;

    -- Update user
    update users
    set exp = v_exp, level = v_level
    where user_id = p_user_id;

    return query select v_exp, v_level;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION cleanup_game_sessions()
RETURNS TABLE (abandoned_count integer, deleted_count integer) AS $$
DECLARE
    abandoned_count integer := 0;
    deleted_count integer := 0;
BEGIN
    -- Mark sessions as abandoned if older than 24 hours and not already abandoned
    UPDATE public.game_sessions
    SET status = 'abandoned'
    WHERE status IS DISTINCT FROM 'abandoned'
      AND start_time < (EXTRACT(EPOCH FROM NOW())::bigint - 24 * 60 * 60);

    GET DIAGNOSTICS abandoned_count = ROW_COUNT;

    -- Delete sessions older than 7 days, including those just marked as abandoned
    DELETE FROM public.game_sessions
    WHERE start_time < (EXTRACT(EPOCH FROM NOW())::bigint - 7 * 24 * 60 * 60);

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN QUERY SELECT abandoned_count, deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Session cleanup function for authentication sessions
CREATE OR REPLACE FUNCTION cleanup_auth_sessions()
RETURNS TABLE (expired_count integer, deleted_count integer) AS $$
DECLARE
    expired_count integer := 0;
    deleted_count integer := 0;
BEGIN
    -- Mark expired sessions as inactive
    UPDATE public.sessions
    SET is_active = false
    WHERE is_active = true
      AND expires_at < EXTRACT(EPOCH FROM NOW())::bigint;

    GET DIAGNOSTICS expired_count = ROW_COUNT;

    -- Delete inactive sessions older than 7 days
    DELETE FROM public.sessions
    WHERE expires_at < (EXTRACT(EPOCH FROM NOW())::bigint - 7 * 24 * 60 * 60);

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN QUERY SELECT expired_count, deleted_count;
END;
$$ LANGUAGE plpgsql;