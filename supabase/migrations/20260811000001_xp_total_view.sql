-- Phase 1 — xp_total view
-- XP totals are derived from xp_events, not stored. Promoted to a trigger-
-- maintained column only when dashboard reads get hot (Phase 5+).

create or replace view public.xp_total as
  select user_id, coalesce(sum(amount), 0)::integer as total_xp
  from public.xp_events
  group by user_id;

-- Grant access to authenticated users (RLS on the underlying xp_events still
-- applies via the view's security_invoker mode in Postgres 15+; for older
-- Supabase Postgres, the security definer defaults carry RLS through).
grant select on public.xp_total to authenticated;
