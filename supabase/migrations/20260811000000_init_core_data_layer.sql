-- Phase 1 — Core Data Layer
-- Source of truth: docs/PRD.md Sections 4 & 12, agreed in plan review.
-- Stack: Supabase Postgres. RLS enforced on every business table.

-- =====================================================================
-- 0. Shared trigger function: tg_set_updated_at
-- =====================================================================
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- =====================================================================
-- 1. users (public profile mirroring auth.users, 1:1)
-- =====================================================================
create table public.users (
  id                    uuid primary key references auth.users(id) on delete cascade,
  name                  text,
  university            text,
  degree                text,
  start_year            integer,
  expected_graduation   date,
  target_cgpa           numeric(4,3),
  current_cgpa          numeric(4,3),
  current_semester_gpa  numeric(4,3),
  timezone              text not null default 'UTC',
  theme                 text not null default 'system' check (theme in ('light','dark','system')),
  settings              jsonb not null default '{}'::jsonb,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

create trigger users_set_updated_at
  before update on public.users
  for each row execute function public.tg_set_updated_at();

-- Auto-create a public.users row when a new auth.users row is created.
create or replace function public.tg_handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.tg_handle_new_auth_user();

-- =====================================================================
-- 2. semesters
-- =====================================================================
create table public.semesters (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  start_date  date not null,
  end_date    date not null,
  target_gpa  numeric(4,3),
  credits     integer,
  status      text not null default 'upcoming' check (status in ('upcoming','active','completed')),
  is_current  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create unique index semesters_one_current_per_user
  on public.semesters (user_id) where is_current;

create trigger semesters_set_updated_at
  before update on public.semesters
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 3. courses
-- =====================================================================
create table public.courses (
  id                     uuid primary key default gen_random_uuid(),
  user_id                uuid not null references auth.users(id) on delete cascade,
  semester_id            uuid not null references public.semesters(id) on delete cascade,
  name                   text not null,
  code                   text,
  professor              text,
  ta                     text,
  credits                numeric(4,1),
  color                  text,
  target_grade_percent   numeric(5,2),
  grading_scale          text not null default 'unknown'
                           check (grading_scale in ('absolute','relative','unknown')),
  attendance_total       integer not null default 0,
  attendance_attended    integer not null default 0,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create index courses_user_semester_idx on public.courses (user_id, semester_id);

create trigger courses_set_updated_at
  before update on public.courses
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 4. lectures
-- =====================================================================
create table public.lectures (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  course_id           uuid not null references public.courses(id) on delete cascade,
  lecture_number      integer,
  date                date,
  topic               text,
  slides_url          text,
  recording_url       text,
  notes               text,
  summary             text,
  key_concepts        text[] not null default '{}',
  difficult_concepts  text[] not null default '{}',
  status              text not null default 'not_started'
                        check (status in ('not_started','attended','notes_complete','reviewed','mastered')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index lectures_course_date_idx on public.lectures (course_id, date desc);

create trigger lectures_set_updated_at
  before update on public.lectures
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 5. assignments
-- =====================================================================
create table public.assignments (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  course_id           uuid not null references public.courses(id) on delete cascade,
  title               text not null,
  description         text,
  due_date            timestamptz,
  weight_percent      numeric(5,2),
  difficulty          smallint check (difficulty between 1 and 5),
  estimated_hours     numeric(5,1),
  actual_hours        numeric(5,1) not null default 0,
  priority            smallint check (priority between 1 and 5),
  status              text not null default 'not_started'
                        check (status in ('not_started','in_progress','submitted','graded','late','missed')),
  feedback            text,
  submission_link     text,
  what_went_well      text,
  what_to_improve     text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index assignments_course_due_idx on public.assignments (course_id, due_date);
create index assignments_user_status_idx on public.assignments (user_id, status);
create index assignments_user_upcoming_idx on public.assignments (user_id, due_date)
  where status not in ('graded','missed');

create trigger assignments_set_updated_at
  before update on public.assignments
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 6. assignment_subtasks
-- =====================================================================
create table public.assignment_subtasks (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  assignment_id       uuid not null references public.assignments(id) on delete cascade,
  kind                text not null
                        check (kind in ('research','outline','draft','revision','proofreading','submission','reflection')),
  completed           boolean not null default false,
  completed_at        timestamptz,
  time_spent_minutes  integer not null default 0,
  notes               text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  unique (assignment_id, kind)
);

create trigger assignment_subtasks_set_updated_at
  before update on public.assignment_subtasks
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 7. exams
-- =====================================================================
create table public.exams (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  course_id         uuid not null references public.courses(id) on delete cascade,
  title             text not null,
  date              timestamptz,
  weight_percent    numeric(5,2),
  topics            text[] not null default '{}',
  confidence        smallint check (confidence between 1 and 5),
  hours_studied     numeric(6,1) not null default 0,
  revision_status   text not null default 'not_started'
                      check (revision_status in ('not_started','planning','revising','ready','confident')),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index exams_course_date_idx on public.exams (course_id, date);

create trigger exams_set_updated_at
  before update on public.exams
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 8. grades (typed FK split per agreed plan)
-- =====================================================================
create table public.grades (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  course_id         uuid not null references public.courses(id) on delete cascade,
  assessment_type   text not null
                      check (assessment_type in ('assignment','exam','quiz','lab','project','other')),
  assignment_id     uuid references public.assignments(id) on delete cascade,
  exam_id           uuid references public.exams(id) on delete cascade,
  title             text not null,
  marks             numeric(7,2),
  max_marks         numeric(7,2) not null,
  weight_percent    numeric(5,2),
  letter_grade      text,
  percentage        numeric(5,2) generated always as
                      (case when max_marks > 0 then marks / max_marks * 100 else null end) stored,
  date_received     date,
  reflection        text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  -- Exactly one typed link must be set.
  check ((assignment_id is not null)::int + (exam_id is not null)::int = 1)
);

create index grades_course_idx on public.grades (course_id);
create index grades_assignment_idx on public.grades (assignment_id) where assignment_id is not null;
create index grades_exam_idx on public.grades (exam_id) where exam_id is not null;

create trigger grades_set_updated_at
  before update on public.grades
  for each row execute function public.tg_set_updated_at();

-- Option 3: status-sync trigger. When a grade is logged for an assignment,
-- flip the assignment's status to 'graded' so the database guarantees the
-- invariant. Prevents the app from forgetting to keep two things in sync.
create or replace function public.tg_grade_sync_assignment_status()
returns trigger
language plpgsql
as $$
begin
  if new.assignment_id is not null then
    update public.assignments
       set status = 'graded'
     where id = new.assignment_id
       and user_id = new.user_id
       and status <> 'graded';
  end if;
  return new;
end;
$$;

create trigger grades_sync_assignment_status
  after insert on public.grades
  for each row execute function public.tg_grade_sync_assignment_status();

-- =====================================================================
-- 9. study_sessions
-- =====================================================================
create table public.study_sessions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  course_id           uuid references public.courses(id) on delete set null,
  started_at          timestamptz not null,
  ended_at            timestamptz,
  duration_minutes    integer generated always as
                        (case when ended_at is not null
                              then extract(epoch from (ended_at - started_at))::integer / 60
                              else null end) stored,
  topic               text,
  location            text,
  session_type        text not null default 'reading'
                        check (session_type in ('reading','problem_solving','revision','lecture','essay','lab','flashcards','practice_questions','other')),
  focus_rating        smallint check (focus_rating between 1 and 5),
  enjoyment           smallint check (enjoyment between 1 and 5),
  difficulty          smallint check (difficulty between 1 and 5),
  energy_before       smallint check (energy_before between 1 and 5),
  energy_after        smallint check (energy_after between 1 and 5),
  notes               text,
  concepts_covered    text[] not null default '{}',
  flashcards_created  integer not null default 0,
  questions_raised    text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index study_sessions_user_recent_idx on public.study_sessions (user_id, started_at desc);
create index study_sessions_course_recent_idx on public.study_sessions (course_id, started_at desc);

create trigger study_sessions_set_updated_at
  before update on public.study_sessions
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 10. xp_events
-- =====================================================================
create table public.xp_events (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users(id) on delete cascade,
  amount                integer not null,
  category              text not null
                          check (category in ('academic','productivity','personal','social','consistency','penalty')),
  source                text not null,
  reason                text,
  related_entity_type   text,
  related_entity_id     uuid,
  skill_tree            text,
  occurred_at           timestamptz not null default now(),
  created_at            timestamptz not null default now()
);

create index xp_events_user_recent_idx on public.xp_events (user_id, occurred_at desc);
create index xp_events_related_entity_idx on public.xp_events (related_entity_type, related_entity_id);

-- =====================================================================
-- 11. goals
-- =====================================================================
create table public.goals (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  category          text not null
                      check (category in ('academic','fitness','music','reading','cycling','personal','other')),
  title             text not null,
  description       text,
  target            text,
  target_metric     numeric(10,2),
  current_metric    numeric(10,2) not null default 0,
  deadline          date,
  status            text not null default 'active'
                      check (status in ('active','completed','abandoned')),
  progress_percent  numeric(5,2) generated always as
                      (case when target_metric > 0
                            then least(100, current_metric / target_metric * 100)
                            else null end) stored,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create trigger goals_set_updated_at
  before update on public.goals
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 12. habits
-- =====================================================================
create table public.habits (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references auth.users(id) on delete cascade,
  title               text not null,
  description         text,
  frequency           text not null default 'daily'
                        check (frequency in ('daily','weekdays','weekly','custom')),
  custom_days         smallint[],
  current_streak      integer not null default 0,
  longest_streak      integer not null default 0,
  total_completions   integer not null default 0,
  started_at          date not null default current_date,
  archived_at         timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create trigger habits_set_updated_at
  before update on public.habits
  for each row execute function public.tg_set_updated_at();

-- =====================================================================
-- 13. habit_completions
-- =====================================================================
create table public.habit_completions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  habit_id      uuid not null references public.habits(id) on delete cascade,
  completed_on  date not null,
  created_at    timestamptz not null default now(),
  unique (habit_id, completed_on)
);

create index habit_completions_habit_date_idx on public.habit_completions (habit_id, completed_on desc);

-- =====================================================================
-- 14. RLS — enable + one owner policy per table
-- =====================================================================
alter table public.users                enable row level security;
alter table public.semesters            enable row level security;
alter table public.courses              enable row level security;
alter table public.lectures             enable row level security;
alter table public.assignments          enable row level security;
alter table public.assignment_subtasks  enable row level security;
alter table public.exams                enable row level security;
alter table public.grades               enable row level security;
alter table public.study_sessions       enable row level security;
alter table public.xp_events            enable row level security;
alter table public.goals                enable row level security;
alter table public.habits               enable row level security;
alter table public.habit_completions    enable row level security;

create policy users_owner               on public.users               for all using (id = auth.uid())                  with check (id = auth.uid());
create policy semesters_owner           on public.semesters           for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy courses_owner             on public.courses             for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy lectures_owner            on public.lectures            for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy assignments_owner         on public.assignments         for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy assignment_subtasks_owner on public.assignment_subtasks for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy exams_owner               on public.exams               for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy grades_owner              on public.grades              for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy study_sessions_owner      on public.study_sessions      for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy xp_events_owner           on public.xp_events           for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy goals_owner               on public.goals               for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy habits_owner              on public.habits              for all using (user_id = auth.uid())            with check (user_id = auth.uid());
create policy habit_completions_owner   on public.habit_completions   for all using (user_id = auth.uid())            with check (user_id = auth.uid());
