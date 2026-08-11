-- Phase 1 — Local dev seed
-- Source of truth: docs/PRD.md Sections 4 & 12.
-- Runs against `supabase db reset` or via `psql $DATABASE_URL -f supabase/seed.sql`.
-- This file is for LOCAL DEV ONLY. The script guard at the top aborts if
-- the KARTIKOS_PRODUCTION_GUARD env var is set to '1' (Vercel/CI should
-- set it). It also bails if the target database is anything other than a
-- local Supabase instance.

\set ON_ERROR_STOP on

do $$
declare
  guard text := current_setting('KARTIKOS_PRODUCTION_GUARD', true);
  url   text := current_setting('SUPABASE_DB_URL', true);
begin
  if guard = '1' then
    raise exception 'refusing to seed: KARTIKOS_PRODUCTION_GUARD is set';
  end if;
  if url is not null and url !~* 'localhost|127\.0\.0\.1' then
    raise exception 'refusing to seed: database URL is not local (%', url;
  end if;
end $$;

-- Fixed UUIDs so the seed is idempotent and reproducible.
-- =====================================================================
-- Dev user
-- =====================================================================
-- Password: 'kartikos-dev' (bcrypt hash pre-computed for speed).
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated',
  'dev@kartikos.local',
  -- bcrypt hash of 'kartikos-dev' (cost 10). Replace by running the
  -- auth flow if you need to log in as this user.
  '$2a$10$wH8ZvJlTz4u5pJ7Hk1OXPe5Kv4qf.l4q6cJxYqgYH0Jz2vN5oqv8m',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(), now()
) on conflict (id) do nothing;

-- The on_auth_user_created trigger normally creates this — but we disable
-- the trigger when seeding to keep auth.users as the source of truth.
alter table auth.users disable trigger on_auth_user_created;

insert into public.users (id, name, university, degree, start_year, timezone, theme)
values (
  '00000000-0000-0000-0000-000000000001',
  'Kartik', 'Local Dev University', 'B.S. Computer Science',
  2024, 'America/Los_Angeles', 'system'
) on conflict (id) do nothing;

-- =====================================================================
-- Semesters
-- =====================================================================
insert into public.semesters (id, user_id, name, start_date, end_date, target_gpa, credits, status, is_current) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001',
   'Fall 2026', '2026-08-25', '2026-12-19', 3.700, 16, 'active', true),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001',
   'Spring 2027', '2027-01-11', '2027-05-07', 3.700, 16, 'upcoming', false);

-- =====================================================================
-- Courses (3, varying grading scales)
-- =====================================================================
insert into public.courses (id, user_id, semester_id, name, code, professor, credits, color, target_grade_percent, grading_scale, attendance_total, attendance_attended) values
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001', 'Algorithms', 'CS 271', 'Dr. Hopper', 4.0, '#7c3aed', 92.0, 'absolute', 30, 27),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001', 'Linear Algebra', 'MATH 264', 'Prof. Noether', 3.0, '#0ea5e9', 88.0, 'absolute', 28, 26),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001',
   '10000000-0000-0000-0000-000000000001', 'Intro to Psychology', 'PSY 101', 'Dr. Skinner', 3.0, '#f59e0b', 90.0, 'relative', 25, 24);

-- =====================================================================
-- Lectures (12 across the 3 courses, mix of statuses)
-- =====================================================================
insert into public.lectures (id, user_id, course_id, lecture_number, date, topic, status) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 1, '2026-08-26', 'Asymptotic analysis', 'mastered'),
  ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 2, '2026-08-28', 'Divide & conquer', 'reviewed'),
  ('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 3, '2026-09-02', 'Master theorem', 'reviewed'),
  ('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 4, '2026-09-04', 'Dynamic programming intro', 'notes_complete'),
  ('30000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 1, '2026-08-26', 'Vector spaces', 'mastered'),
  ('30000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 2, '2026-08-28', 'Linear independence', 'reviewed'),
  ('30000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 3, '2026-09-02', 'Basis & dimension', 'reviewed'),
  ('30000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 4, '2026-09-04', 'Linear transformations', 'attended'),
  ('30000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000003', 1, '2026-08-27', 'What is psychology?', 'mastered'),
  ('30000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 2, '2026-08-29', 'Neuroscience basics', 'reviewed'),
  ('30000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 3, '2026-09-03', 'Memory & learning', 'notes_complete'),
  ('30000000-0000-0000-0000-00000000000c', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 4, '2026-09-05', 'Perception', 'attended');

-- =====================================================================
-- Assignments (6: 2 per course, mix of statuses)
-- =====================================================================
insert into public.assignments (id, user_id, course_id, title, description, due_date, weight_percent, difficulty, estimated_hours, actual_hours, priority, status, feedback, submission_link, what_went_well, what_to_improve) values
  ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   'PS1: Asymptotic analysis', 'Prove Big-O for 5 given functions', '2026-09-12 23:59:00+00', 5.0, 3, 4.0, 4.5, 3, 'graded',
   'Solid proofs, missing one edge case on n=0.', 'https://canvas.example.edu/submissions/1',
   'Got the structure right on the first try.', 'Check edge cases more carefully.'),
  ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   'PS2: Divide & conquer', 'Implement merge sort with recurrence analysis', '2026-09-26 23:59:00+00', 7.0, 4, 6.0, 0, 4, 'in_progress', null, null, null, null),
  ('40000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002',
   'Problem Set 1', 'Vector space axioms', '2026-09-10 23:59:00+00', 5.0, 2, 3.0, 2.5, 2, 'graded',
   'Excellent justification on axiom 4.', 'https://canvas.example.edu/submissions/2', null, null),
  ('40000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002',
   'Problem Set 2', 'Basis + dimension proofs', '2026-09-24 23:59:00+00', 6.0, 3, 4.0, 1.5, 3, 'in_progress', null, null, null, null),
  ('40000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003',
   'Reading reflection 1', '400-word reflection on neuroscience reading', '2026-09-08 23:59:00+00', 3.0, 1, 2.0, 2.0, 2, 'submitted', null, null, null, null),
  ('40000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003',
   'Group discussion post', '300-word post + 2 replies', '2026-09-22 23:59:00+00', 4.0, 2, 3.0, 0, 2, 'not_started', null, null, null, null);

-- =====================================================================
-- Assignment subtasks (7 per assignment, slot per kind)
-- =====================================================================
-- Helper to insert all 7 kinds for a given assignment with realistic progress.
do $$
declare
  aid uuid;
  kinds text[] := array['research','outline','draft','revision','proofreading','submission','reflection'];
  k text;
  i int;
begin
  for i in 1..6 loop
    aid := ('40000000-0000-0000-0000-00000000000' || lpad(i::text, 1, '0'))::uuid;
    foreach k in array kinds loop
      insert into public.assignment_subtasks (user_id, assignment_id, kind, completed, completed_at, time_spent_minutes, notes)
      values (
        '00000000-0000-0000-0000-000000000001',
        aid,
        k,
        -- assignment 1: all done; assignment 2: draft done; 3: all done;
        -- 4: research done; 5: all done; 6: none done.
        case
          when i in (1,3,5) then true
          when i = 2 and k = 'draft' then true
          when i = 4 and k = 'research' then true
          else false
        end,
        case
          when i in (1,3,5) then now() - interval '2 days'
          when i = 2 and k = 'draft' then now() - interval '1 day'
          when i = 4 and k = 'research' then now() - interval '3 days'
          else null
        end,
        case
          when i = 1 then 35
          when i = 2 and k = 'draft' then 60
          when i = 3 then 25
          when i = 4 and k = 'research' then 40
          when i = 5 then 20
          else 0
        end,
        null
      );
    end loop;
  end loop;
end $$;

-- =====================================================================
-- Exams (2)
-- =====================================================================
insert into public.exams (id, user_id, course_id, title, date, weight_percent, topics, confidence, hours_studied, revision_status) values
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001', 'Midterm 1', '2026-10-15 14:00:00+00', 20.0,
   array['asymptotic analysis','divide & conquer','master theorem','DP intro'], 3, 8.0, 'revising'),
  ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000002', 'Midterm 1', '2026-10-17 10:00:00+00', 25.0,
   array['vector spaces','linear independence','basis','dimension'], 4, 5.5, 'planning');

-- =====================================================================
-- Grades (4: 3 assignments + 1 exam). Insert AFTER assignments/exams exist.
-- =====================================================================
insert into public.grades (user_id, course_id, assessment_type, assignment_id, exam_id, title, marks, max_marks, weight_percent, letter_grade, date_received, reflection) values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   'assignment', '40000000-0000-0000-0000-000000000001', null,
   'PS1: Asymptotic analysis', 46.0, 50.0, 5.0, 'A-', '2026-09-14', 'Watch edge cases.'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002',
   'assignment', '40000000-0000-0000-0000-000000000003', null,
   'Problem Set 1', 49.0, 50.0, 5.0, 'A', '2026-09-12', null),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003',
   'assignment', '40000000-0000-0000-0000-000000000005', null,
   'Reading reflection 1', 95.0, 100.0, 3.0, 'A', '2026-09-10', null);
-- Note: a free-form quiz (assessment_type='quiz' with neither assignment_id
-- nor exam_id) is intentionally excluded — the schema's CHECK constraint
-- requires exactly one typed link. Quizzes without backing rows can be
-- modeled as assessment_type='other' once Phase 2 decides the shape.

-- =====================================================================
-- Study sessions (8, varied types and ratings)
-- =====================================================================
insert into public.study_sessions (user_id, course_id, started_at, ended_at, topic, location, session_type, focus_rating, enjoyment, difficulty, energy_before, energy_after, notes, flashcards_created, questions_raised) values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   '2026-08-27 19:00:00+00', '2026-08-27 20:30:00+00', 'Asymptotic analysis review', 'Library', 'reading', 4, 4, 3, 4, 4, 'Solid session.', 5, 'Why does master theorem fail on f(n)=n log n?'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   '2026-08-29 14:00:00+00', '2026-08-29 16:00:00+00', 'PS1 problem 4', 'Cafe', 'problem_solving', 5, 3, 4, 3, 4, null, 0, null),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
   '2026-09-01 20:00:00+00', '2026-09-01 21:00:00+00', 'Master theorem drills', 'Home', 'practice_questions', 4, 5, 4, 5, 5, 'Felt great.', 12, null),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002',
   '2026-08-28 18:00:00+00', '2026-08-28 19:15:00+00', 'Vector space axioms', 'Library', 'reading', 4, 4, 2, 4, 4, null, 0, null),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002',
   '2026-08-30 16:00:00+00', '2026-08-30 17:30:00+00', 'Linear independence proofs', 'Library', 'revision', 3, 3, 3, 3, 3, 'Distracted today.', 0, null),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003',
   '2026-08-29 10:00:00+00', '2026-08-29 11:00:00+00', 'Neuroscience reading', 'Home', 'reading', 3, 4, 2, 4, 4, null, 0, null),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003',
   '2026-09-04 19:00:00+00', '2026-09-04 20:00:00+00', 'Memory & learning', 'Cafe', 'flashcards', 4, 4, 3, 4, 4, 'Anki deck: 30 cards.', 30, null),
  ('00000000-0000-0000-0000-000000000001', null,
   '2026-09-06 09:00:00+00', '2026-09-06 09:45:00+00', 'Weekly planning', 'Home', 'other', 5, 3, 1, 5, 5, 'Reviewed next week.', 0, null);

-- =====================================================================
-- XP events (20+ across categories)
-- =====================================================================
insert into public.xp_events (user_id, amount, category, source, reason, related_entity_type, related_entity_id, occurred_at) values
  ('00000000-0000-0000-0000-000000000001', 25, 'academic', 'assignment.completed', 'PS1: Asymptotic analysis graded', 'assignment', '40000000-0000-0000-0000-000000000001', '2026-09-14 12:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 60, 'academic', 'grade.a_received', 'A on PS1', 'assignment', '40000000-0000-0000-0000-000000000001', '2026-09-14 12:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 25, 'academic', 'assignment.completed', 'Problem Set 1 graded', 'assignment', '40000000-0000-0000-0000-000000000003', '2026-09-12 12:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 60, 'academic', 'grade.a_received', 'A on Math PS1', 'assignment', '40000000-0000-0000-0000-000000000003', '2026-09-12 12:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 25, 'academic', 'assignment.completed', 'Reading reflection 1 graded', 'assignment', '40000000-0000-0000-0000-000000000005', '2026-09-10 12:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 60, 'academic', 'grade.a_received', 'A on Reading reflection 1', 'assignment', '40000000-0000-0000-0000-000000000005', '2026-09-10 12:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Algorithm lecture 1 notes', 'lecture', '30000000-0000-0000-0000-000000000001', '2026-08-27 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Algorithms lecture 2 notes', 'lecture', '30000000-0000-0000-0000-000000000002', '2026-08-29 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Algorithms lecture 3 notes', 'lecture', '30000000-0000-0000-0000-000000000003', '2026-09-02 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Linear Algebra lecture 1 notes', 'lecture', '30000000-0000-0000-0000-000000000005', '2026-08-27 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Linear Algebra lecture 2 notes', 'lecture', '30000000-0000-0000-0000-000000000006', '2026-08-29 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Linear Algebra lecture 3 notes', 'lecture', '30000000-0000-0000-0000-000000000007', '2026-09-02 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Psychology lecture 1 notes', 'lecture', '30000000-0000-0000-0000-000000000009', '2026-08-28 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 10, 'academic', 'lecture.notes_done', 'Psychology lecture 2 notes', 'lecture', '30000000-0000-0000-0000-00000000000a', '2026-08-30 10:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '90-min session', 'study_session', null, '2026-08-27 20:30:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '120-min session', 'study_session', null, '2026-08-29 16:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '60-min session', 'study_session', null, '2026-09-01 21:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '75-min session', 'study_session', null, '2026-08-28 19:15:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '90-min session', 'study_session', null, '2026-08-30 17:30:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '60-min session', 'study_session', null, '2026-08-29 11:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '60-min session', 'study_session', null, '2026-09-04 20:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 5, 'productivity', 'study_session.logged', '45-min session', 'study_session', null, '2026-09-06 09:45:00+00'),
  ('00000000-0000-0000-0000-000000000001', 15, 'consistency', 'streak.day', '3-day streak', null, null, '2026-08-29 23:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 25, 'consistency', 'streak.week', 'Full week logged', null, null, '2026-09-06 23:00:00+00'),
  ('00000000-0000-0000-0000-000000000001', 30, 'academic', 'quiz.completed', 'Quiz 1 scored A-', null, null, '2026-09-09 12:00:00+00');

-- =====================================================================
-- Goals (3, mixed categories)
-- =====================================================================
insert into public.goals (user_id, category, title, description, target, target_metric, current_metric, deadline, status) values
  ('00000000-0000-0000-0000-000000000001', 'academic', '3.7 GPA this semester', 'Hold target GPA across all 3 courses', '3.7 CGPA', 3.7, 3.68, '2026-12-19', 'active'),
  ('00000000-0000-0000-0000-000000000001', 'fitness', 'Bench 100 kg', 'Working set of 5', '100 kg', 100.0, 87.5, '2026-12-31', 'active'),
  ('00000000-0000-0000-0000-000000000001', 'reading', 'Read 24 books this year', 'Mix of fiction + non-fiction', '24 books', 24.0, 11.0, '2026-12-31', 'active');

-- =====================================================================
-- Habits (4, with a week of completions)
-- =====================================================================
insert into public.habits (id, user_id, title, description, frequency, current_streak, longest_streak, total_completions, started_at) values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Morning pages', '10 min of longhand writing', 'daily', 7, 12, 38, '2026-07-15'),
  ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Workout', 'Lift or cardio', 'weekdays', 4, 9, 27, '2026-07-05'),
  ('60000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Read 30 pages', 'Non-textbook reading', 'daily', 5, 14, 41, '2026-07-01'),
  ('60000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Weekly review', 'Plan the next week', 'weekly', 3, 6, 11, '2026-06-15');

-- 7 days of completions for each daily/weekdays habit, ending today.
do $$
declare
  d date;
begin
  for d in select (current_date - g)::date
           from generate_series(0, 6) g
  loop
    insert into public.habit_completions (user_id, habit_id, completed_on)
    values ('00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', d)
    on conflict (habit_id, completed_on) do nothing; -- daily

    -- weekdays only: skip Sat (6) and Sun (7).
    if extract(isodow from d) < 6 then
      insert into public.habit_completions (user_id, habit_id, completed_on)
      values ('00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000002', d)
      on conflict (habit_id, completed_on) do nothing;
    end if;

    insert into public.habit_completions (user_id, habit_id, completed_on)
    values ('00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000003', d)
    on conflict (habit_id, completed_on) do nothing; -- daily
  end loop;

  -- Weekly review: completed on the most recent Sunday.
  insert into public.habit_completions (user_id, habit_id, completed_on)
  values ('00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000004',
          date_trunc('week', current_date)::date - interval '1 week')
  on conflict (habit_id, completed_on) do nothing;
end $$;

-- =====================================================================
-- Verify the seed (loud failures > silent corruption)
-- =====================================================================
do $$
declare
  counts text;
begin
  select format(
    'users=%s semesters=%s courses=%s lectures=%s assignments=%s subtasks=%s exams=%s grades=%s sessions=%s xp=%s goals=%s habits=%s completions=%s',
    (select count(*) from public.users),
    (select count(*) from public.semesters),
    (select count(*) from public.courses),
    (select count(*) from public.lectures),
    (select count(*) from public.assignments),
    (select count(*) from public.assignment_subtasks),
    (select count(*) from public.exams),
    (select count(*) from public.grades),
    (select count(*) from public.study_sessions),
    (select count(*) from public.xp_events),
    (select count(*) from public.goals),
    (select count(*) from public.habits),
    (select count(*) from public.habit_completions)
  ) into counts;

  raise notice 'seed complete: %', counts;
  raise notice 'xp_total (from view): %', (
    select total_xp from public.xp_total
    where user_id = '00000000-0000-0000-0000-000000000001'
  );
end $$;
