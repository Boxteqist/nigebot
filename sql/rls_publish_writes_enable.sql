-- TEMPORARY — run in Supabase SQL Editor before publishing from Man Cave (browser uses anon key).
-- Symptom: new row violates row-level security policy for table "results" | "scores" | "published_log"
--
-- After publishing, run sql/rls_publish_writes_disable.sql to drop these policies again.

DROP POLICY IF EXISTS results_insert_public_tmp ON public.results;
DROP POLICY IF EXISTS results_update_public_tmp ON public.results;
DROP POLICY IF EXISTS scores_insert_public_tmp ON public.scores;
DROP POLICY IF EXISTS scores_update_public_tmp ON public.scores;
DROP POLICY IF EXISTS published_log_insert_public_tmp ON public.published_log;
DROP POLICY IF EXISTS published_log_update_public_tmp ON public.published_log;

CREATE POLICY results_insert_public_tmp
  ON public.results FOR INSERT TO public WITH CHECK (true);

CREATE POLICY results_update_public_tmp
  ON public.results FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY scores_insert_public_tmp
  ON public.scores FOR INSERT TO public WITH CHECK (true);

CREATE POLICY scores_update_public_tmp
  ON public.scores FOR UPDATE TO public USING (true) WITH CHECK (true);

CREATE POLICY published_log_insert_public_tmp
  ON public.published_log FOR INSERT TO public WITH CHECK (true);

CREATE POLICY published_log_update_public_tmp
  ON public.published_log FOR UPDATE TO public USING (true) WITH CHECK (true);
