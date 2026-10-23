-- AI 에이전트 마스터클래스 수강 신청 저장소
-- Supabase 관리 화면 > SQL Editor 에 전체를 붙여 넣고 [Run] 을 누르세요.

-- 1. 수강 신청 테이블
create table if not exists public.registrations (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  name       text not null check (char_length(name) between 1 and 50),
  phone      text not null check (char_length(phone) between 9 and 20),
  email      text check (email is null or char_length(email) <= 100),
  interest   text check (interest is null or char_length(interest) <= 100),
  message    text check (message is null or char_length(message) <= 2000),
  status     text not null default '신규'
             check (status in ('신규', '연락 완료', '등록 확정', '취소'))
);

-- 2. 관리자 명단 (여기에 등록된 계정만 신청 내역을 볼 수 있습니다)
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

alter table public.registrations enable row level security;
alter table public.admins enable row level security;

-- 3. 권한: 방문자는 신청 등록만, 관리자는 조회와 상태 변경만
revoke all on public.registrations from anon, authenticated;
grant insert (name, phone, email, interest, message) on public.registrations to anon, authenticated;
grant select, update (status) on public.registrations to authenticated;

revoke all on public.admins from anon, authenticated;
grant select on public.admins to authenticated;

drop policy if exists "누구나 수강 신청 등록" on public.registrations;
create policy "누구나 수강 신청 등록" on public.registrations
  for insert to anon, authenticated
  with check (status = '신규');

drop policy if exists "관리자만 신청 조회" on public.registrations;
create policy "관리자만 신청 조회" on public.registrations
  for select to authenticated
  using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

drop policy if exists "관리자만 상태 변경" on public.registrations;
create policy "관리자만 상태 변경" on public.registrations
  for update to authenticated
  using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

drop policy if exists "본인 관리자 여부 확인" on public.admins;
create policy "본인 관리자 여부 확인" on public.admins
  for select to authenticated
  using (user_id = (select auth.uid()));

-- 4. 관리자 지정
-- Authentication > Users 에서 관리자 계정을 먼저 만든 뒤, 이메일을 바꿔 아래 한 줄만 다시 실행하세요.
insert into public.admins (user_id)
select id from auth.users where email = 'rlatnrska0316@gmail.com'
on conflict do nothing;
