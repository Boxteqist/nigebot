-- INSERT + UPDATE on predictions for anonymous clients (publishable key).
-- Needed for index.html saves and Man Cave "Prediction Save & Update" tests.
--
-- Symptom in browser or curl: HTTP 401 / PostgreSQL 42501 —
--   new row violates row-level security policy for table "predictions"
--
-- Run in Supabase → SQL Editor (project owner). Does not enable RLS or change SELECT;
-- use only when predictions already readable but writes fail.

DROP POLICY IF EXISTS predictions_insert_public ON public.predictions;
DROP POLICY IF EXISTS predictions_update_public ON public.predictions;

CREATE POLICY predictions_insert_public
  ON public.predictions
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY predictions_update_public
  ON public.predictions
  FOR UPDATE
  TO public
  USING (true)
  WITH CHECK (true);
