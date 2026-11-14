-- NigeBot full schema and one-time setup.
-- Paste this whole file into Supabase → SQL Editor and run it once.
-- Written for the live project (Postgres 17): races, predictions, results,
-- scores, published_log, and an unused players table that has a pin column.
--
-- Safe to re-run on that database. It does not DELETE, TRUNCATE, or DROP
-- any of those tables, and it does not rewrite existing picks, results, or
-- scores. CREATE TABLE is skipped when the table is already there.
--
-- Before the FIRST run, replace __SET_ME_BEFORE_RUNNING__ near the bottom
-- with an admin password of at least 10 characters. Do not commit that password.
-- Later re-runs leave an existing password alone.
--
-- What this gives you:
--   * results, scores, and published_log stay read-only for the public website key
--   * Man Cave publishes by calling publish_results with the admin password
--   * the password is stored only as a hash in schema private (not exposed as an API)
--   * sprint picks lock at sprint start; qualifying, race, and fastest lap lock at qualifying start
--   * three identical drivers in one podium are rejected
--
-- Do not add schema "private" to Exposed schemas in the Supabase API settings.
-- There is no Edge Function to deploy.

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO postgres;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO postgres, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Tables. CREATE is skipped when the live database already has the table.
-- Missing columns used by the app are added afterwards.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.races (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  season integer NOT NULL,
  round integer NOT NULL,
  name text NOT NULL,
  qualifying_at timestamptz,
  race_at timestamptz,
  sprint_at timestamptz,
  is_sprint boolean NOT NULL DEFAULT false,
  UNIQUE (season, round)
);

CREATE TABLE IF NOT EXISTS public.predictions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id uuid NOT NULL,
  player_name text NOT NULL,
  quali_p1 text,
  quali_p2 text,
  quali_p3 text,
  sprint_p1 text,
  sprint_p2 text,
  sprint_p3 text,
  race_p1 text,
  race_p2 text,
  race_p3 text,
  fastest_lap text,
  submitted_at timestamptz,
  admin_entered boolean NOT NULL DEFAULT false,
  UNIQUE (player_name, race_id)
);

CREATE TABLE IF NOT EXISTS public.results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id uuid NOT NULL,
  quali_p1 text,
  quali_p2 text,
  quali_p3 text,
  sprint_p1 text,
  sprint_p2 text,
  sprint_p3 text,
  race_p1 text,
  race_p2 text,
  race_p3 text,
  fastest_lap text,
  fetched_at timestamptz,
  UNIQUE (race_id)
);

CREATE TABLE IF NOT EXISTS public.scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id uuid NOT NULL,
  player_name text NOT NULL,
  quali_score numeric NOT NULL DEFAULT 0,
  race_score numeric NOT NULL DEFAULT 0,
  sprint_score numeric NOT NULL DEFAULT 0,
  fastest_lap_score numeric NOT NULL DEFAULT 0,
  total_score numeric NOT NULL DEFAULT 0,
  calculated_at timestamptz,
  UNIQUE (player_name, race_id)
);

CREATE TABLE IF NOT EXISTS public.published_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  race_id uuid NOT NULL,
  race_name text,
  published_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (race_id)
);

-- Unused on the live project (0 rows) and it has a pin column.
-- CREATE is skipped when the table already exists, so the live pin column
-- is not altered. The grants below close it to the website key.
CREATE TABLE IF NOT EXISTS public.players (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  pin text
);

ALTER TABLE public.races ADD COLUMN IF NOT EXISTS qualifying_at timestamptz;
ALTER TABLE public.races ADD COLUMN IF NOT EXISTS race_at timestamptz;
ALTER TABLE public.races ADD COLUMN IF NOT EXISTS sprint_at timestamptz;
ALTER TABLE public.races ADD COLUMN IF NOT EXISTS is_sprint boolean NOT NULL DEFAULT false;

ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS quali_p1 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS quali_p2 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS quali_p3 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS sprint_p1 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS sprint_p2 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS sprint_p3 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS race_p1 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS race_p2 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS race_p3 text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS fastest_lap text;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS submitted_at timestamptz;
ALTER TABLE public.predictions ADD COLUMN IF NOT EXISTS admin_entered boolean NOT NULL DEFAULT false;

ALTER TABLE public.results ADD COLUMN IF NOT EXISTS sprint_p1 text;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS sprint_p2 text;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS sprint_p3 text;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS fastest_lap text;
ALTER TABLE public.results ADD COLUMN IF NOT EXISTS fetched_at timestamptz;

ALTER TABLE public.scores ADD COLUMN IF NOT EXISTS sprint_score numeric NOT NULL DEFAULT 0;
ALTER TABLE public.scores ADD COLUMN IF NOT EXISTS fastest_lap_score numeric NOT NULL DEFAULT 0;

ALTER TABLE public.published_log ADD COLUMN IF NOT EXISTS race_name text;
ALTER TABLE public.published_log ADD COLUMN IF NOT EXISTS published_at timestamptz NOT NULL DEFAULT now();

-- Stop before adding a unique index if the live rows are not unique.
-- This only reads. It does not delete the duplicates.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.races GROUP BY season, round HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'races has duplicate (season, round) rows. Nothing was deleted. Fix those rows by hand, then run this file again.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.predictions GROUP BY player_name, race_id HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'predictions has duplicate (player_name, race_id) rows. Nothing was deleted. Fix those rows by hand, then run this file again.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.results GROUP BY race_id HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'results has duplicate race_id rows. Nothing was deleted. Fix those rows by hand, then run this file again.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.scores GROUP BY player_name, race_id HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'scores has duplicate (player_name, race_id) rows. Nothing was deleted. Fix those rows by hand, then run this file again.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.published_log GROUP BY race_id HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'published_log has duplicate race_id rows. Nothing was deleted. Fix those rows by hand, then run this file again.';
  END IF;
END $$;

-- Add a unique index only when those columns are not already unique.
-- A second index on the same columns makes ON CONFLICT fail, and this does
-- not delete rows to force the index through.
DO $$
DECLARE
  spec record;
  already boolean;
BEGIN
  FOR spec IN
    SELECT *
    FROM (VALUES
      ('races_season_round_uidx', 'public.races'::regclass, ARRAY['season','round']::text[]),
      ('predictions_player_race_uidx', 'public.predictions'::regclass, ARRAY['player_name','race_id']::text[]),
      ('results_race_id_uidx', 'public.results'::regclass, ARRAY['race_id']::text[]),
      ('scores_player_race_uidx', 'public.scores'::regclass, ARRAY['player_name','race_id']::text[]),
      ('published_log_race_id_uidx', 'public.published_log'::regclass, ARRAY['race_id']::text[])
    ) AS v(index_name, tbl, cols)
  LOOP
    SELECT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_index i
      WHERE i.indrelid = spec.tbl
        AND i.indisunique
        AND i.indpred IS NULL
        AND (
          SELECT pg_catalog.array_agg(a.attname::text ORDER BY k.ord)
          FROM pg_catalog.unnest(i.indkey) WITH ORDINALITY AS k(attnum, ord)
          JOIN pg_catalog.pg_attribute a
            ON a.attrelid = i.indrelid AND a.attnum = k.attnum
          WHERE k.attnum > 0
        ) = spec.cols
    ) INTO already;

    IF already THEN
      CONTINUE;
    END IF;

    EXECUTE format(
      'CREATE UNIQUE INDEX %I ON %s (%s)',
      spec.index_name,
      spec.tbl,
      (SELECT pg_catalog.string_agg(pg_catalog.quote_ident(c), ', ') FROM pg_catalog.unnest(spec.cols) AS c)
    );
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- Lock official tables. The public website key can read them and nothing else.
-- Writes happen only inside private.publish_results, which runs as the owner.
--
-- The live project granted anon and authenticated ALL privileges, including
-- TRUNCATE, on every public table, and left the temporary publish policies
-- (*_insert_public_tmp / *_update_public_tmp) in place. Both are removed here.
-- service_role is not changed.
-- ---------------------------------------------------------------------------

ALTER TABLE public.races ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.published_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.results FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.scores FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.published_log FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.predictions FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.races FROM PUBLIC, anon, authenticated;
REVOKE ALL ON TABLE public.players FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.results, public.scores, public.published_log TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.predictions TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.races TO anon, authenticated;

-- Identity/serial inserts still need nextval. setval stays revoked.
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC, anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Future tables created by the SQL editor should not inherit TRUNCATE/writes.
DO $$
DECLARE
  role_name text;
BEGIN
  FOREACH role_name IN ARRAY ARRAY['postgres', 'supabase_admin']
  LOOP
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
      BEGIN
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLES FROM anon, authenticated',
          role_name
        );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE NOTICE 'Could not adjust default privileges for %: %', role_name, SQLERRM;
      END;
    END IF;
  END LOOP;
END $$;

-- players: no policies, so the pin column is not readable through the API.
DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'players'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.players', pol.policyname);
  END LOOP;
END $$;

-- Named policies that were still enabled on the live project, then any other
-- write policy on the official tables.
DROP POLICY IF EXISTS results_insert_public_tmp ON public.results;
DROP POLICY IF EXISTS results_update_public_tmp ON public.results;
DROP POLICY IF EXISTS scores_insert_public_tmp ON public.scores;
DROP POLICY IF EXISTS scores_update_public_tmp ON public.scores;
DROP POLICY IF EXISTS published_log_insert_public_tmp ON public.published_log;
DROP POLICY IF EXISTS published_log_update_public_tmp ON public.published_log;

DO $$
DECLARE
  pol record;
BEGIN
  FOR pol IN
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('results', 'scores', 'published_log')
      AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

DROP POLICY IF EXISTS results_select_public ON public.results;
DROP POLICY IF EXISTS scores_select_public ON public.scores;
DROP POLICY IF EXISTS published_log_select_public ON public.published_log;
DROP POLICY IF EXISTS predictions_select_public ON public.predictions;
DROP POLICY IF EXISTS predictions_insert_public ON public.predictions;
DROP POLICY IF EXISTS predictions_update_public ON public.predictions;
DROP POLICY IF EXISTS races_select_public ON public.races;
DROP POLICY IF EXISTS races_insert_public ON public.races;
DROP POLICY IF EXISTS races_update_public ON public.races;

CREATE POLICY results_select_public ON public.results
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY scores_select_public ON public.scores
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY published_log_select_public ON public.published_log
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY predictions_select_public ON public.predictions
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY predictions_insert_public ON public.predictions
  FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY predictions_update_public ON public.predictions
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

CREATE POLICY races_select_public ON public.races
  FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY races_insert_public ON public.races
  FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY races_update_public ON public.races
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- Admin password. Hash only. No API access.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS private.admin_config (
  id integer PRIMARY KEY CHECK (id = 1),
  password_hash text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now()
);

ALTER TABLE private.admin_config ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.admin_config FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.trimmed(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p IS NULL THEN NULL
    WHEN pg_catalog.btrim(p) = '' THEN NULL
    ELSE pg_catalog.btrim(p)
  END;
$$;

CREATE OR REPLACE FUNCTION private.clean_pick(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p IS NULL THEN NULL
    WHEN pg_catalog.btrim(p) = '' THEN NULL
    ELSE pg_catalog.upper(pg_catalog.btrim(p))
  END;
$$;

CREATE OR REPLACE FUNCTION private.same_pick(a text, b text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT private.clean_pick(a) IS NOT DISTINCT FROM private.clean_pick(b);
$$;

CREATE OR REPLACE FUNCTION private.assert_distinct_podium(a text, b text, c text, label text)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  x text := private.clean_pick(a);
  y text := private.clean_pick(b);
  z text := private.clean_pick(c);
BEGIN
  IF x IS NOT NULL AND x = y AND y = z THEN
    RAISE EXCEPTION '% picks cannot be three identical drivers', label
      USING ERRCODE = '23514';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION private.assert_schedule_window(p_season integer, p_at timestamptz, p_label text)
RETURNS void
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_start timestamptz;
  v_end timestamptz;
BEGIN
  IF p_at IS NULL OR p_season IS NULL THEN
    RETURN;
  END IF;
  v_start := pg_catalog.make_timestamptz(p_season, 1, 1, 0, 0, 0, 'UTC') - interval '14 days';
  v_end := pg_catalog.make_timestamptz(p_season, 12, 31, 23, 59, 59, 'UTC') + interval '120 days';
  IF p_at < v_start OR p_at > v_end THEN
    RAISE EXCEPTION '% is outside the % season window', p_label, p_season
      USING ERRCODE = '22023';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION private.set_admin_password(p_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  chosen text := pg_catalog.btrim(coalesce(p_password, ''));
BEGIN
  -- The placeholder is detected without repeating it as one string, so a
  -- replace-all of that token does not turn the check into the real password.
  IF char_length(chosen) < 10
     OR (position('SET_ME_BEFORE' in chosen) > 0 AND position('RUNNING__' in chosen) > 0) THEN
    RAISE EXCEPTION 'Admin password must be at least 10 characters and must not be the placeholder'
      USING ERRCODE = '22023';
  END IF;
  INSERT INTO private.admin_config (id, password_hash, updated_at)
  VALUES (
    1,
    extensions.crypt(chosen, extensions.gen_salt('bf', 10)),
    pg_catalog.now()
  )
  ON CONFLICT (id) DO UPDATE
    SET password_hash = EXCLUDED.password_hash,
        updated_at = pg_catalog.now();
END;
$$;

-- The website calls public.publish_results. That runs as the visitor and only
-- forwards into this function. This function checks the password, then writes.
CREATE OR REPLACE FUNCTION private.publish_results(p_password text, p_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_hash text;
  v_race public.races%ROWTYPE;
  v_results jsonb;
  v_score jsonb;
  v_player text;
  v_quali numeric;
  v_race_score numeric;
  v_sprint numeric;
  v_fl numeric;
  v_total numeric;
  v_sprint_required boolean;
  v_name text;
  v_count integer := 0;
BEGIN
  IF p_password IS NULL OR pg_catalog.btrim(p_password) = '' THEN
    RAISE EXCEPTION 'Admin password required' USING ERRCODE = '28000';
  END IF;

  SELECT password_hash INTO v_hash FROM private.admin_config WHERE id = 1;
  IF v_hash IS NULL THEN
    RAISE EXCEPTION 'Admin password is not set' USING ERRCODE = '28000';
  END IF;
  IF extensions.crypt(pg_catalog.btrim(p_password), v_hash) IS DISTINCT FROM v_hash THEN
    RAISE EXCEPTION 'Invalid admin password' USING ERRCODE = '28000';
  END IF;

  IF p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN
    RAISE EXCEPTION 'Publish payload is missing' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO v_race
  FROM public.races
  WHERE id::text = p_payload->>'race_id';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unknown race. Open the round in NigeBot once so it is on the calendar.'
      USING ERRCODE = '22023';
  END IF;

  v_results := p_payload->'results';
  IF v_results IS NULL OR jsonb_typeof(v_results) <> 'object' THEN
    RAISE EXCEPTION 'Results are missing' USING ERRCODE = '22023';
  END IF;

  IF private.trimmed(v_results->>'quali_p1') IS NULL
     OR private.trimmed(v_results->>'quali_p2') IS NULL
     OR private.trimmed(v_results->>'quali_p3') IS NULL
     OR private.trimmed(v_results->>'race_p1') IS NULL
     OR private.trimmed(v_results->>'race_p2') IS NULL
     OR private.trimmed(v_results->>'race_p3') IS NULL THEN
    RAISE EXCEPTION 'Qualifying and race podiums are required before publish'
      USING ERRCODE = '22023';
  END IF;

  IF v_race.round > 1 AND private.trimmed(v_results->>'fastest_lap') IS NULL THEN
    RAISE EXCEPTION 'Fastest lap is required from round 2' USING ERRCODE = '22023';
  END IF;

  v_sprint_required :=
    coalesce(v_race.is_sprint, false)
    OR v_race.sprint_at IS NOT NULL
    OR coalesce((p_payload->>'sprint_weekend')::boolean, false);

  IF v_sprint_required AND (
    private.trimmed(v_results->>'sprint_p1') IS NULL
    OR private.trimmed(v_results->>'sprint_p2') IS NULL
    OR private.trimmed(v_results->>'sprint_p3') IS NULL
  ) THEN
    RAISE EXCEPTION 'Sprint results are required before publishing a sprint weekend'
      USING ERRCODE = '22023';
  END IF;

  IF jsonb_typeof(p_payload->'scores') IS DISTINCT FROM 'array'
     OR jsonb_array_length(p_payload->'scores') < 1 THEN
    RAISE EXCEPTION 'At least one score row is required' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.results (
    race_id,
    quali_p1, quali_p2, quali_p3,
    sprint_p1, sprint_p2, sprint_p3,
    race_p1, race_p2, race_p3,
    fastest_lap,
    fetched_at
  ) VALUES (
    v_race.id,
    private.trimmed(v_results->>'quali_p1'),
    private.trimmed(v_results->>'quali_p2'),
    private.trimmed(v_results->>'quali_p3'),
    private.trimmed(v_results->>'sprint_p1'),
    private.trimmed(v_results->>'sprint_p2'),
    private.trimmed(v_results->>'sprint_p3'),
    private.trimmed(v_results->>'race_p1'),
    private.trimmed(v_results->>'race_p2'),
    private.trimmed(v_results->>'race_p3'),
    CASE WHEN v_race.round > 1 THEN private.trimmed(v_results->>'fastest_lap') ELSE NULL END,
    pg_catalog.now()
  )
  ON CONFLICT (race_id) DO UPDATE SET
    quali_p1 = EXCLUDED.quali_p1,
    quali_p2 = EXCLUDED.quali_p2,
    quali_p3 = EXCLUDED.quali_p3,
    sprint_p1 = EXCLUDED.sprint_p1,
    sprint_p2 = EXCLUDED.sprint_p2,
    sprint_p3 = EXCLUDED.sprint_p3,
    race_p1 = EXCLUDED.race_p1,
    race_p2 = EXCLUDED.race_p2,
    race_p3 = EXCLUDED.race_p3,
    fastest_lap = EXCLUDED.fastest_lap,
    fetched_at = pg_catalog.now();

  FOR v_score IN
    SELECT value FROM jsonb_array_elements(p_payload->'scores')
  LOOP
    v_player := pg_catalog.btrim(coalesce(v_score->>'player_name', ''));
    IF v_player = '' OR char_length(v_player) > 40 THEN
      RAISE EXCEPTION 'Each score needs a player name' USING ERRCODE = '22023';
    END IF;
    v_quali := coalesce((v_score->>'quali_score')::numeric, 0);
    v_race_score := coalesce((v_score->>'race_score')::numeric, 0);
    v_sprint := coalesce((v_score->>'sprint_score')::numeric, 0);
    v_fl := coalesce((v_score->>'fastest_lap_score')::numeric, 0);
    v_total := coalesce((v_score->>'total_score')::numeric, 0);
    IF v_quali < 0 OR v_race_score < 0 OR v_sprint < 0 OR v_fl < 0 OR v_total < 0
       OR v_quali > 200 OR v_race_score > 200 OR v_sprint > 200 OR v_fl > 200 OR v_total > 200 THEN
      RAISE EXCEPTION 'Score for % is out of range', v_player USING ERRCODE = '22023';
    END IF;
    IF abs(v_total - (v_quali + v_race_score + v_sprint + v_fl)) > 0.001 THEN
      RAISE EXCEPTION 'total_score does not match the section scores for %', v_player
        USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.scores (
      race_id, player_name,
      quali_score, race_score, sprint_score, fastest_lap_score, total_score,
      calculated_at
    ) VALUES (
      v_race.id, v_player,
      v_quali, v_race_score, v_sprint, v_fl, v_total,
      pg_catalog.now()
    )
    ON CONFLICT (player_name, race_id) DO UPDATE SET
      quali_score = EXCLUDED.quali_score,
      race_score = EXCLUDED.race_score,
      sprint_score = EXCLUDED.sprint_score,
      fastest_lap_score = EXCLUDED.fastest_lap_score,
      total_score = EXCLUDED.total_score,
      calculated_at = pg_catalog.now();
    v_count := v_count + 1;
  END LOOP;

  IF v_sprint_required AND coalesce(v_race.is_sprint, false) IS NOT TRUE THEN
    UPDATE public.races SET is_sprint = true WHERE id = v_race.id;
  END IF;

  v_name := coalesce(private.trimmed(p_payload->>'race_name'), v_race.name);

  INSERT INTO public.published_log (race_id, race_name, published_at)
  VALUES (v_race.id, v_name, pg_catalog.now())
  ON CONFLICT (race_id) DO UPDATE SET
    race_name = EXCLUDED.race_name,
    published_at = pg_catalog.now();

  RETURN jsonb_build_object(
    'ok', true,
    'race_id', v_race.id::text,
    'scores', v_count
  );
END;
$$;

-- Public wrapper. Not SECURITY DEFINER: it cannot write tables itself.
-- PostgREST exposes this because it lives in schema public.
CREATE OR REPLACE FUNCTION public.publish_results(p_password text, p_payload jsonb)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.publish_results(p_password, p_payload);
$$;

COMMENT ON FUNCTION public.publish_results(text, jsonb) IS
  'Publish one weekend. Requires the admin password. Visitors cannot write results, scores, or published_log directly.';

-- ---------------------------------------------------------------------------
-- Prediction locks and calendar protection.
-- These run as the visitor (anon). They only read races and reject bad writes.
-- The database owner (SQL editor) can still correct a rescheduled session.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.enforce_prediction_rules()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_quali_at timestamptz;
  v_sprint_at timestamptz;
  v_sprint_locked boolean;
  v_quali_locked boolean;
BEGIN
  NEW.quali_p1 := private.clean_pick(NEW.quali_p1);
  NEW.quali_p2 := private.clean_pick(NEW.quali_p2);
  NEW.quali_p3 := private.clean_pick(NEW.quali_p3);
  NEW.sprint_p1 := private.clean_pick(NEW.sprint_p1);
  NEW.sprint_p2 := private.clean_pick(NEW.sprint_p2);
  NEW.sprint_p3 := private.clean_pick(NEW.sprint_p3);
  NEW.race_p1 := private.clean_pick(NEW.race_p1);
  NEW.race_p2 := private.clean_pick(NEW.race_p2);
  NEW.race_p3 := private.clean_pick(NEW.race_p3);
  NEW.fastest_lap := private.clean_pick(NEW.fastest_lap);
  NEW.player_name := pg_catalog.btrim(coalesce(NEW.player_name, ''));

  IF NEW.player_name = '' THEN
    RAISE EXCEPTION 'Player name is required' USING ERRCODE = '23514';
  END IF;

  PERFORM private.assert_distinct_podium(NEW.quali_p1, NEW.quali_p2, NEW.quali_p3, 'Qualifying');
  PERFORM private.assert_distinct_podium(NEW.sprint_p1, NEW.sprint_p2, NEW.sprint_p3, 'Sprint');
  PERFORM private.assert_distinct_podium(NEW.race_p1, NEW.race_p2, NEW.race_p3, 'Race');

  IF CURRENT_USER IN ('anon', 'authenticated') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.admin_entered := false;
    ELSE
      NEW.admin_entered := OLD.admin_entered;
      IF NEW.player_name IS DISTINCT FROM pg_catalog.btrim(OLD.player_name)
         OR NEW.race_id IS DISTINCT FROM OLD.race_id THEN
        RAISE EXCEPTION 'Player and race on a prediction cannot be changed'
          USING ERRCODE = '42501';
      END IF;
    END IF;

    SELECT qualifying_at, sprint_at
      INTO v_quali_at, v_sprint_at
    FROM public.races
    WHERE id = NEW.race_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Unknown race' USING ERRCODE = '23503';
    END IF;

    v_sprint_locked := v_sprint_at IS NOT NULL AND pg_catalog.now() >= v_sprint_at;
    v_quali_locked := v_quali_at IS NOT NULL AND pg_catalog.now() >= v_quali_at;

    IF TG_OP = 'INSERT' THEN
      IF v_sprint_locked AND (
        NEW.sprint_p1 IS NOT NULL OR NEW.sprint_p2 IS NOT NULL OR NEW.sprint_p3 IS NOT NULL
      ) THEN
        RAISE EXCEPTION 'Sprint predictions are locked (the sprint has started)'
          USING ERRCODE = '42501';
      END IF;
      IF v_quali_locked AND (
        NEW.quali_p1 IS NOT NULL OR NEW.quali_p2 IS NOT NULL OR NEW.quali_p3 IS NOT NULL
        OR NEW.race_p1 IS NOT NULL OR NEW.race_p2 IS NOT NULL OR NEW.race_p3 IS NOT NULL
        OR NEW.fastest_lap IS NOT NULL
      ) THEN
        RAISE EXCEPTION 'Qualifying and race predictions are locked (qualifying has started)'
          USING ERRCODE = '42501';
      END IF;
    ELSE
      IF v_sprint_locked AND (
        NOT private.same_pick(NEW.sprint_p1, OLD.sprint_p1)
        OR NOT private.same_pick(NEW.sprint_p2, OLD.sprint_p2)
        OR NOT private.same_pick(NEW.sprint_p3, OLD.sprint_p3)
      ) THEN
        RAISE EXCEPTION 'Sprint predictions are locked (the sprint has started)'
          USING ERRCODE = '42501';
      END IF;
      IF v_quali_locked AND (
        NOT private.same_pick(NEW.quali_p1, OLD.quali_p1)
        OR NOT private.same_pick(NEW.quali_p2, OLD.quali_p2)
        OR NOT private.same_pick(NEW.quali_p3, OLD.quali_p3)
        OR NOT private.same_pick(NEW.race_p1, OLD.race_p1)
        OR NOT private.same_pick(NEW.race_p2, OLD.race_p2)
        OR NOT private.same_pick(NEW.race_p3, OLD.race_p3)
        OR NOT private.same_pick(NEW.fastest_lap, OLD.fastest_lap)
      ) THEN
        RAISE EXCEPTION 'Qualifying and race predictions are locked (qualifying has started)'
          USING ERRCODE = '42501';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.protect_race_schedule()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  -- SQL editor (postgres) and the publish function may correct the calendar.
  -- The public website key may not move a lock time once it has been saved.
  IF CURRENT_USER IN ('anon', 'authenticated') THEN
    IF TG_OP = 'UPDATE' THEN
      IF NEW.season IS DISTINCT FROM OLD.season OR NEW.round IS DISTINCT FROM OLD.round THEN
        RAISE EXCEPTION 'Season and round cannot be changed from the app'
          USING ERRCODE = '42501';
      END IF;
      IF OLD.qualifying_at IS NOT NULL AND NEW.qualifying_at IS DISTINCT FROM OLD.qualifying_at THEN
        RAISE EXCEPTION 'qualifying_at is locked once set. A reschedule has to be fixed in the Supabase SQL editor.'
          USING ERRCODE = '42501';
      END IF;
      IF OLD.race_at IS NOT NULL AND NEW.race_at IS DISTINCT FROM OLD.race_at THEN
        RAISE EXCEPTION 'race_at is locked once set. A reschedule has to be fixed in the Supabase SQL editor.'
          USING ERRCODE = '42501';
      END IF;
      IF OLD.sprint_at IS NOT NULL AND NEW.sprint_at IS DISTINCT FROM OLD.sprint_at THEN
        RAISE EXCEPTION 'sprint_at is locked once set. A reschedule has to be fixed in the Supabase SQL editor.'
          USING ERRCODE = '42501';
      END IF;
      IF OLD.is_sprint IS TRUE AND coalesce(NEW.is_sprint, false) IS NOT TRUE THEN
        RAISE EXCEPTION 'A sprint weekend cannot be unmarked from the app'
          USING ERRCODE = '42501';
      END IF;
    END IF;

    IF TG_OP = 'INSERT' AND NEW.qualifying_at IS NULL THEN
      RAISE EXCEPTION 'qualifying_at is required' USING ERRCODE = '23502';
    END IF;

    PERFORM private.assert_schedule_window(NEW.season, NEW.qualifying_at, 'qualifying_at');
    PERFORM private.assert_schedule_window(NEW.season, NEW.race_at, 'race_at');
    PERFORM private.assert_schedule_window(NEW.season, NEW.sprint_at, 'sprint_at');
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS predictions_enforce_rules ON public.predictions;
CREATE TRIGGER predictions_enforce_rules
  BEFORE INSERT OR UPDATE ON public.predictions
  FOR EACH ROW
  EXECUTE FUNCTION private.enforce_prediction_rules();

DROP TRIGGER IF EXISTS races_protect_schedule ON public.races;
CREATE TRIGGER races_protect_schedule
  BEFORE INSERT OR UPDATE ON public.races
  FOR EACH ROW
  EXECUTE FUNCTION private.protect_race_schedule();

-- Weekends that already have sprint picks or sprint results stay sprint
-- weekends. Only is_sprint is updated, and only from false to true.
UPDATE public.races AS r
SET is_sprint = true
WHERE coalesce(r.is_sprint, false) = false
  AND (
    r.sprint_at IS NOT NULL
    OR EXISTS (
      SELECT 1 FROM public.results res
      WHERE res.race_id = r.id
        AND nullif(btrim(res.sprint_p1), '') IS NOT NULL
    )
    OR EXISTS (
      SELECT 1 FROM public.predictions p
      WHERE p.race_id = r.id
        AND nullif(btrim(p.sprint_p1), '') IS NOT NULL
    )
  );

-- Default privileges would let anon call every new function. Close that, then
-- open only the functions the website actually needs.
REVOKE ALL ON FUNCTION private.trimmed(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.clean_pick(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.same_pick(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.assert_distinct_podium(text, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.assert_schedule_window(integer, timestamptz, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.set_admin_password(text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.publish_results(text, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.enforce_prediction_rules() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.protect_race_schedule() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.publish_results(text, jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION private.trimmed(text) TO postgres;
GRANT EXECUTE ON FUNCTION private.clean_pick(text) TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.same_pick(text, text) TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.assert_distinct_podium(text, text, text, text) TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.assert_schedule_window(integer, timestamptz, text) TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.set_admin_password(text) TO postgres;
GRANT EXECUTE ON FUNCTION private.enforce_prediction_rules() TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.protect_race_schedule() TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.publish_results(text, jsonb) TO postgres, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.publish_results(text, jsonb) TO postgres, anon, authenticated;

-- set_admin_password stays owner-only. Run it from the SQL editor, never from the website.

-- ---------------------------------------------------------------------------
-- Password. First run: edit the quoted password (10+ characters) and run this
-- file. Re-runs do not change a password that is already saved.
-- To rotate later, run only:
--   SELECT private.set_admin_password('the-new-password');
-- ---------------------------------------------------------------------------

DO $setup_pw$
DECLARE
  chosen text := '__SET_ME_BEFORE_RUNNING__';
BEGIN
  IF EXISTS (SELECT 1 FROM private.admin_config WHERE id = 1) THEN
    RAISE NOTICE 'Admin password already set. Leaving it unchanged.';
    RETURN;
  END IF;
  IF char_length(pg_catalog.btrim(chosen)) < 10
     OR (position('SET_ME_BEFORE' in chosen) > 0 AND position('RUNNING__' in chosen) > 0) THEN
    RAISE EXCEPTION 'Choose an admin password of at least 10 characters on the chosen-text line near the bottom of sql/one_time_setup.sql, then run this file again. Do not commit the password.'
      USING ERRCODE = '22023';
  END IF;
  PERFORM private.set_admin_password(chosen);
  RAISE NOTICE 'Admin password saved.';
END
$setup_pw$;

NOTIFY pgrst, 'reload schema';
