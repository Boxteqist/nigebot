-- Cancelled 2026 events (Bahrain, Saudi Arabia): remove DB rows if they exist from the old embedded calendar.
-- Safe to run multiple times. Optional — only needed if those races were ever opened in NigeBot (creating `races` rows).
--
-- Note: Jolpica’s 2026 calendar was revised (22 rounds, different order/dates than the old hardcoded list).
-- Opening a weekend in Enter Predictions upserts `races` from the API. Orphan rows from the old numbering may
-- still appear in Man Cave’s round list until removed or superseded.

DELETE FROM public.published_log
WHERE race_id IN (
  SELECT id FROM public.races
  WHERE season = 2026 AND name IN ('Bahrain Grand Prix', 'Saudi Arabian Grand Prix')
);

DELETE FROM public.results
WHERE race_id IN (
  SELECT id FROM public.races
  WHERE season = 2026 AND name IN ('Bahrain Grand Prix', 'Saudi Arabian Grand Prix')
);

DELETE FROM public.scores
WHERE race_id IN (
  SELECT id FROM public.races
  WHERE season = 2026 AND name IN ('Bahrain Grand Prix', 'Saudi Arabian Grand Prix')
);

DELETE FROM public.predictions
WHERE race_id IN (
  SELECT id FROM public.races
  WHERE season = 2026 AND name IN ('Bahrain Grand Prix', 'Saudi Arabian Grand Prix')
);

DELETE FROM public.races
WHERE season = 2026 AND name IN ('Bahrain Grand Prix', 'Saudi Arabian Grand Prix');
