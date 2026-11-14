-- Occasional database hygiene — run sections in Supabase SQL Editor as needed.
-- No CLI required. "Success. No rows returned" on UPDATE/DELETE is normal.

-- 1) Remove cancelled 2026 Bahrain / Saudi rows (if they exist from the old calendar)
--    Full script: sql/remove_cancelled_2026_bahrain_saudi.sql

-- 2) Rename 2026 rounds to match Jolpica (wrong GP at a round number)
--    Full script: sql/sync_2026_race_names.sql  (replaces the older R1–R6-only fix)

-- 3) Policies and grants (read-only).
--    results, scores, published_log: SELECT only. No *_public_tmp policies.
--    anon/authenticated must not have TRUNCATE or DELETE on those tables.
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('players', 'predictions', 'published_log', 'races', 'results', 'scores')
ORDER BY tablename, policyname;

SELECT table_name, privilege_type, grantee
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('anon', 'authenticated')
  AND table_name IN ('players', 'predictions', 'published_log', 'races', 'results', 'scores')
ORDER BY table_name, grantee, privilege_type;

-- 4) Orphan check: races with no predictions, results, or scores (candidates to delete manually)
SELECT r.season, r.round, r.name, r.id
FROM public.races r
WHERE NOT EXISTS (SELECT 1 FROM public.predictions p WHERE p.race_id = r.id)
  AND NOT EXISTS (SELECT 1 FROM public.results res WHERE res.race_id = r.id)
  AND NOT EXISTS (SELECT 1 FROM public.scores s WHERE s.race_id = r.id)
ORDER BY r.season, r.round;
