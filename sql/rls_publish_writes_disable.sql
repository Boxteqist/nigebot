-- Run after publishing — removes temporary publish policies (re-lock).

DROP POLICY IF EXISTS results_insert_public_tmp ON public.results;
DROP POLICY IF EXISTS results_update_public_tmp ON public.results;
DROP POLICY IF EXISTS scores_insert_public_tmp ON public.scores;
DROP POLICY IF EXISTS scores_update_public_tmp ON public.scores;
DROP POLICY IF EXISTS published_log_insert_public_tmp ON public.published_log;
DROP POLICY IF EXISTS published_log_update_public_tmp ON public.published_log;
