-- Repair only. Prefer sql/one_time_setup.sql, which creates these policies and
-- also installs the lock trigger.
--
-- INSERT + UPDATE on predictions for anonymous clients (publishable key).
-- Needed for index.html saves and Man Cave "Prediction Save & Update" tests.
--
-- Symptom in browser or curl: HTTP 401 / PostgreSQL 42501 —
--   new row violates row-level security policy for table "predictions"
--
-- Does not grant DELETE or TRUNCATE. Session locks are enforced by a trigger,
-- not by removing these policies.

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
