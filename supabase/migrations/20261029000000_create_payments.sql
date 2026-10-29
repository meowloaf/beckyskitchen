create table if not exists public.payments (
  order_id text primary key,
  provider text not null default 'xendit',
  invoice_id text unique,
  amount numeric not null default 0,
  currency text not null default 'PHP',
  status text not null check (status in ('pending', 'paid', 'expired', 'refunded')),
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payments enable row level security;

create policy "Allow public payment status reads"
  on public.payments for select
  using (true);

create policy "No direct payment writes"
  on public.payments for insert
  with check (false);

create policy "No direct payment updates"
  on public.payments for update
  using (false)
  with check (false);
