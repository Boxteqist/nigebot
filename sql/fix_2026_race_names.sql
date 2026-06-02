-- Fix `races.name` drift after the 2026 calendar dropped Bahrain/Saudi and renumbered rounds.
-- Symptom in Man Cave: round 6 shows "Miami Grand Prix" again (old slot) while Jolpica has Monaco at R6.
-- Safe to run multiple times.

UPDATE public.races AS r
SET name = v.canonical_name
FROM (VALUES
  (2026, 1, 'Australian Grand Prix'),
  (2026, 2, 'Chinese Grand Prix'),
  (2026, 3, 'Japanese Grand Prix'),
  (2026, 4, 'Miami Grand Prix'),
  (2026, 5, 'Canadian Grand Prix'),
  (2026, 6, 'Monaco Grand Prix')
) AS v(season, round, canonical_name)
WHERE r.season = v.season
  AND r.round = v.round
  AND r.name IS DISTINCT FROM v.canonical_name;

-- Inspect anything still off (should return no rows for 2026 R1–R6):
SELECT season, round, name
FROM public.races
WHERE season = 2026
ORDER BY round;
