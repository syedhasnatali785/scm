-- ==============================================================================
-- 71 International Import & Container Engine - Phase 1 Schema & RLS
-- Multi-Tenant Organizations, Memberships, Shipments, and Shipment Items
-- ==============================================================================

-- 1. Organizations Table
create table if not exists public.organizations (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    slug text unique not null,
    base_currency text not null default 'PKR',
    default_origin_currency text not null default 'RMB',
    workflow_preset text not null default 'SKD Assembly', -- 'Finished Goods' or 'SKD Assembly'
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 2. Organization Memberships (User to Org Mapping & Roles)
create table if not exists public.org_memberships (
    id uuid primary key default gen_random_uuid(),
    org_id uuid not null references public.organizations(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role text not null check (role in ('owner', 'operator')),
    created_at timestamptz not null default now(),
    unique(org_id, user_id)
);

-- 3. Security Helper Function for RLS
create or replace function public.get_user_org_ids(user_uuid uuid)
returns setof uuid
language sql
security definer
stable
as $$
    select org_id from public.org_memberships where user_id = user_uuid;
$$;

-- 4. Shipments Table
create table if not exists public.shipments (
    id uuid primary key default gen_random_uuid(),
    org_id uuid not null references public.organizations(id) on delete cascade,
    name text not null,
    reference_no text,
    status text not null default 'draft' check (status in ('draft', 'sourcing', 'locked', 'shipped', 'customs_cleared', 'warehouse_received')),
    container_preset text not null default 'fortyHC',
    container_specs jsonb not null default '{}'::jsonb,
    cost_pipeline jsonb not null default '[]'::jsonb,
    fx_rates jsonb not null default '{}'::jsonb,
    apportionment_mode text not null default 'targetCapacity' check (apportionment_mode in ('targetCapacity', 'actualLoad')),
    created_by uuid references auth.users(id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 5. Shipment Items Table
create table if not exists public.shipment_items (
    id uuid primary key default gen_random_uuid(),
    shipment_id uuid not null references public.shipments(id) on delete cascade,
    org_id uuid not null references public.organizations(id) on delete cascade,
    name text not null,
    model_number text not null,
    supplier_name text,
    carton_length numeric not null default 60,
    carton_width numeric not null default 40,
    carton_height numeric not null default 40,
    dimension_unit text not null default 'cm',
    manual_cbm_override numeric,
    ordered_cartons int not null default 1,
    pieces_per_carton int not null default 1,
    nw_per_carton_kg numeric not null default 0,
    gw_per_carton_kg numeric not null default 0,
    unit_price_origin numeric not null default 0,
    origin_currency text not null default 'RMB',
    duty_spec jsonb not null default '{}'::jsonb,
    assembly_spec jsonb not null default '{}'::jsonb,
    target_markup_pct numeric not null default 25,
    market_selling_price numeric,
    box_color text default '#3B82F6',
    photo_url text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Indexes for high-speed multi-tenant queries
create index if exists idx_org_memberships_user on public.org_memberships(user_id);
create index if exists idx_org_memberships_org on public.org_memberships(org_id);
create index if exists idx_shipments_org on public.shipments(org_id);
create index if exists idx_shipment_items_shipment on public.shipment_items(shipment_id);
create index if exists idx_shipment_items_org on public.shipment_items(org_id);

-- ==============================================================================
-- Row-Level Security (RLS) Policies
-- ==============================================================================

alter table public.organizations enable row level security;
alter table public.org_memberships enable row level security;
alter table public.shipments enable row level security;
alter table public.shipment_items enable row level security;

-- Organizations Policies
create policy "Users can view organizations they belong to"
    on public.organizations for select
    using (id in (select public.get_user_org_ids(auth.uid())));

create policy "Authenticated users can create organizations"
    on public.organizations for insert
    with check (auth.uid() is not null);

create policy "Owners can update their organization"
    on public.organizations for update
    using (id in (
        select org_id from public.org_memberships
        where user_id = auth.uid() and role = 'owner'
    ));

-- Org Memberships Policies
create policy "Users can view memberships of their orgs"
    on public.org_memberships for select
    using (user_id = auth.uid() or org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Owners can manage memberships"
    on public.org_memberships for all
    using (org_id in (
        select org_id from public.org_memberships
        where user_id = auth.uid() and role = 'owner'
    ));

-- Shipments Policies
create policy "Users can view shipments belonging to their orgs"
    on public.shipments for select
    using (org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Users can insert shipments in their orgs"
    on public.shipments for insert
    with check (org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Users can update shipments in their orgs"
    on public.shipments for update
    using (org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Owners can delete shipments in their orgs"
    on public.shipments for delete
    using (org_id in (
        select org_id from public.org_memberships
        where user_id = auth.uid() and role = 'owner'
    ));

-- Shipment Items Policies
create policy "Users can view items in their org shipments"
    on public.shipment_items for select
    using (org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Users can insert items in their org shipments"
    on public.shipment_items for insert
    with check (org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Users can update items in their org shipments"
    on public.shipment_items for update
    using (org_id in (select public.get_user_org_ids(auth.uid())));

create policy "Users can delete items in their org shipments"
    on public.shipment_items for delete
    using (org_id in (select public.get_user_org_ids(auth.uid())));

