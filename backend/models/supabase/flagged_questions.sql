create table public.flagged_questions (
  flag_id uuid not null default gen_random_uuid(),
  question_id uuid not null,
  user_id uuid not null,
  flagged_at bigint not null default (EXTRACT(epoch from now()))::bigint,
  reason text null,
  status text null default 'pending',
  notes text null,
  constraint flagged_questions_pkey primary key (flag_id),
  constraint flagged_questions_question_id_fkey foreign key (question_id) references questions (question_id) on delete cascade,
  constraint flagged_questions_user_id_fkey foreign key (user_id) references users (user_id) on delete cascade
) TABLESPACE pg_default;
