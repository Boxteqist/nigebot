-- RETIRED. Do not run.
--
-- Publishing no longer opens results, scores, or published_log to the website key.
-- Man Cave calls publish_results with the admin password.
-- Setup is sql/one_time_setup.sql (once). Re-running this old enable script
-- would put the temporary public write policies back, so it now refuses.

DO $$
BEGIN
  RAISE EXCEPTION
    'Retired. Do not re-enable public writes on results, scores, or published_log. See sql/one_time_setup.sql.';
END $$;
