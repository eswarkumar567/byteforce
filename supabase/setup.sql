-- PrepPilot Supabase setup. Run this entire script in Supabase SQL Editor.
-- Row Level Security ensures users can access only their own records.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  daily_streak integer not null default 0,
  last_active_date date,
  created_at timestamptz not null default now()
);
create table if not exists public.mock_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null check (score >= 0),
  total integer not null check (total > 0 and score <= total),
  percentage integer not null check (percentage between 0 and 100),
  created_at timestamptz not null default now()
);
create table if not exists public.resume_analyses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  target_role text not null default '',
  score integer not null check (score between 0 and 100),
  feedback jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
create table if not exists public.user_tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  done boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.mock_results enable row level security;
alter table public.resume_analyses enable row level security;
alter table public.user_tasks enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles for select to authenticated using ((select auth.uid()) = id);
drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "Users read own mock results" on public.mock_results;
create policy "Users read own mock results" on public.mock_results for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Users insert own mock results" on public.mock_results;
create policy "Users insert own mock results" on public.mock_results for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "Users read own resume analyses" on public.resume_analyses;
create policy "Users read own resume analyses" on public.resume_analyses for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Users insert own resume analyses" on public.resume_analyses;
create policy "Users insert own resume analyses" on public.resume_analyses for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "Users read own tasks" on public.user_tasks;
create policy "Users read own tasks" on public.user_tasks for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Users update own tasks" on public.user_tasks;
create policy "Users update own tasks" on public.user_tasks for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "Users insert own tasks" on public.user_tasks;
create policy "Users insert own tasks" on public.user_tasks for insert to authenticated with check ((select auth.uid()) = user_id);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  insert into public.user_tasks (user_id, title, sort_order) values
    (new.id, 'Complete one aptitude mock test', 1),
    (new.id, 'Improve two resume bullet points', 2),
    (new.id, 'Practise Tell me about yourself', 3),
    (new.id, 'Review yesterday''s mistakes', 4);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Records a daily visit and updates a consecutive-day streak.
create or replace function public.touch_daily_streak()
returns integer language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  today date := (now() at time zone 'utc')::date;
  prior date;
  current_streak integer;
begin
  if uid is null then raise exception 'Not authenticated'; end if;
  select last_active_date, daily_streak into prior, current_streak
  from public.profiles where id = uid for update;
  if prior is null then current_streak := 1;
  elsif prior = today then current_streak := coalesce(current_streak, 1);
  elsif prior = today - 1 then current_streak := coalesce(current_streak, 0) + 1;
  else current_streak := 1;
  end if;
  update public.profiles set last_active_date = today, daily_streak = current_streak where id = uid;
  return current_streak;
end;
$$;
revoke all on function public.touch_daily_streak() from public;
grant execute on function public.touch_daily_streak() to authenticated;
