-- ═══════════════════════════════════════════════════════════
--  VIDEOARTE NET — Schema completo v3
--  Ejecuta en: Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════════


-- ─── 1. PIEZAS ───────────────────────────────────────────────
create table if not exists pieces (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  author      text not null,
  tags        text[] not null default '{}',
  vimeo_url   text not null,
  vimeo_thumb text,
  year        int,
  description text,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);
create index if not exists pieces_tags_idx on pieces using gin(tags);
alter table pieces enable row level security;
create policy "pieces_public_read"    on pieces for select using (active = true);
create policy "pieces_service_write"  on pieces for insert with check (true);
create policy "pieces_service_update" on pieces for update using (true);
create policy "pieces_service_delete" on pieces for delete using (true);


-- ─── 2. PERFILES ─────────────────────────────────────────────
create table if not exists profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at   timestamptz not null default now()
);
alter table profiles enable row level security;
create policy "profiles_public_read" on profiles for select using (true);
create policy "profiles_own_update"  on profiles for update using (auth.uid() = id);


-- ─── 3. AJUSTES DE USUARIO ───────────────────────────────────
create table if not exists user_settings (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  maps_public  boolean not null default false,  -- si sus mapas de favoritos/watchlist son públicos
  created_at   timestamptz not null default now()
);
alter table user_settings enable row level security;
create policy "settings_own_read"   on user_settings for select using (auth.uid() = user_id);
create policy "settings_own_insert" on user_settings for insert with check (auth.uid() = user_id);
create policy "settings_own_update" on user_settings for update using (auth.uid() = user_id);
-- lectura pública solo del campo maps_public (para ver perfiles compartidos)
create policy "settings_public_read" on user_settings for select using (maps_public = true);


-- ─── 4. TAGS DE USUARIO ──────────────────────────────────────
create table if not exists user_tags (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  piece_id   uuid not null references pieces(id) on delete cascade,
  tag        text not null,
  public     boolean not null default false,
  created_at timestamptz not null default now(),
  unique(user_id, piece_id, tag)
);
create index if not exists user_tags_piece_idx  on user_tags(piece_id);
create index if not exists user_tags_user_idx   on user_tags(user_id);
create index if not exists user_tags_public_idx on user_tags(public) where public = true;
alter table user_tags enable row level security;
create policy "user_tags_read_own"    on user_tags for select using (auth.uid() = user_id);
create policy "user_tags_read_public" on user_tags for select using (public = true);
create policy "user_tags_insert"      on user_tags for insert with check (auth.uid() = user_id);
create policy "user_tags_update"      on user_tags for update using (auth.uid() = user_id);
create policy "user_tags_delete"      on user_tags for delete using (auth.uid() = user_id);


-- ─── 5. GUARDADOS (favoritos + watchlist) ────────────────────
create table if not exists user_saves (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  piece_id   uuid not null references pieces(id) on delete cascade,
  type       text not null check (type in ('favorite', 'watchlist')),
  created_at timestamptz not null default now(),
  unique(user_id, piece_id, type)
);
create index if not exists user_saves_user_idx  on user_saves(user_id);
create index if not exists user_saves_piece_idx on user_saves(piece_id);
alter table user_saves enable row level security;
create policy "saves_own_read"   on user_saves for select using (auth.uid() = user_id);
create policy "saves_own_insert" on user_saves for insert with check (auth.uid() = user_id);
create policy "saves_own_delete" on user_saves for delete using (auth.uid() = user_id);
-- lectura pública cuando el perfil es público
create policy "saves_public_read" on user_saves for select
  using (
    exists (
      select 1 from user_settings s
      where s.user_id = user_saves.user_id and s.maps_public = true
    )
  );


-- ─── 6. PREGUNTAS ────────────────────────────────────────────
-- Las crea el equipo admin. Pueden ser globales (piece_id = null)
-- o específicas de una pieza.
create table if not exists questions (
  id         uuid primary key default gen_random_uuid(),
  piece_id   uuid references pieces(id) on delete cascade,  -- null = global
  text       text not null,
  order_idx  int not null default 0,
  active     boolean not null default true,
  created_at timestamptz not null default now()
);
alter table questions enable row level security;
create policy "questions_public_read"   on questions for select using (active = true);
create policy "questions_service_write" on questions for insert with check (true);
create policy "questions_service_update"on questions for update using (true);
create policy "questions_service_delete"on questions for delete using (true);


-- ─── 7. COMENTARIOS ──────────────────────────────────────────
create table if not exists comments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  piece_id    uuid not null references pieces(id) on delete cascade,
  question_id uuid references questions(id) on delete set null,  -- null = comentario libre
  text        text not null,
  anonymous   boolean not null default false,
  approved    boolean not null default false,  -- moderación por el equipo
  created_at  timestamptz not null default now()
);
create index if not exists comments_piece_idx    on comments(piece_id);
create index if not exists comments_user_idx     on comments(user_id);
create index if not exists comments_question_idx on comments(question_id);
create index if not exists comments_approved_idx on comments(approved) where approved = true;
alter table comments enable row level security;
-- Lectura pública: solo comentarios aprobados
create policy "comments_public_read" on comments for select using (approved = true);
-- El autor ve también los suyos pendientes
create policy "comments_own_read"    on comments for select using (auth.uid() = user_id);
-- Solo usuarios autenticados pueden insertar
create policy "comments_insert"      on comments for insert with check (auth.uid() = user_id);
-- El autor puede borrar el suyo
create policy "comments_own_delete"  on comments for delete using (auth.uid() = user_id);
-- El equipo (service_role) puede aprobar/borrar cualquiera
create policy "comments_service_update" on comments for update using (true);
create policy "comments_service_delete" on comments for delete using (true);


-- ─── 8. TRIGGER: crear perfil y ajustes al registrarse ───────
drop trigger if exists on_auth_user_created on auth.users;

create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, display_name)
  values (new.id, split_part(new.email, '@', 1))
  on conflict (id) do nothing;

  insert into public.user_settings(user_id, maps_public)
  values (new.id, false)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();


-- ─── 9. AUTENTICACIÓN ────────────────────────────────────────
-- En Supabase → Authentication → Providers → Email:
--   - Email/Password: activado
--   - Confirm email: según prefieras (desactivar para desarrollo)
-- En Authentication → URL Configuration:
--   - Site URL: https://tu-dominio.netlify.app
--   - Redirect URLs: https://tu-dominio.netlify.app


-- ─── 10. DATOS DE EJEMPLO ────────────────────────────────────
-- Piezas (descomenta y ajusta las URLs de Vimeo):
-- insert into pieces (title, author, tags, vimeo_url, year) values
--   ('Cuerpo sin órganos', 'Elena Vidal',  array['cuerpo','fragmento','loop'],     'https://player.vimeo.com/video/XXXXXXX', 2023),
--   ('Glitch Memoria',     'Takashi N.',   array['glitch','tiempo','ruido'],       'https://player.vimeo.com/video/XXXXXXX', 2024),
--   ('Paisaje Dato',       'Mar Solà',     array['datos','espacio','paisaje'],     'https://player.vimeo.com/video/XXXXXXX', 2022),
--   ('Loop Silencio',      'Diego A.',     array['loop','silencio','tiempo'],      'https://player.vimeo.com/video/XXXXXXX', 2024),
--   ('Ruido Blanco',       'Lena Ko',      array['ruido','glitch','cuerpo'],       'https://player.vimeo.com/video/XXXXXXX', 2023),
--   ('Espejo Roto',        'Ivan Pérez',   array['fragmento','espejo','silencio'], 'https://player.vimeo.com/video/XXXXXXX', 2022),
--   ('Tiempo Muerto',      'Sofía R.',     array['tiempo','espacio','loop'],       'https://player.vimeo.com/video/XXXXXXX', 2024);

-- Preguntas globales de ejemplo (descomenta para añadirlas):
-- insert into questions (piece_id, text, order_idx) values
--   (null, '¿Qué sensación o recuerdo te evoca esta pieza?', 1),
--   (null, '¿Qué relación ves entre el tiempo y el cuerpo en este trabajo?', 2),
--   (null, '¿Qué pregunta te deja abierta esta obra?', 3);
