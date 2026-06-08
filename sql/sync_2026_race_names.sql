-- Sync 2026 `races.name` to the Jolpica calendar (22 rounds). Safe to re-run.
-- Run in Supabase → SQL Editor after calendar changes or if Man Cave shows the wrong GP at a round.
-- Does not delete rows — only renames existing (season, round) slots. Orphan duplicates: run
-- sql/remove_cancelled_2026_bahrain_saudi.sql and inspect the verify query at the bottom.

UPDATE public.races AS r
SET name = v.canonical_name
FROM (VALUES
  (2026, 1, 'Australian Grand Prix'),
  (2026, 2, 'Chinese Grand Prix'),
  (2026, 3, 'Japanese Grand Prix'),
  (2026, 4, 'Miami Grand Prix'),
  (2026, 5, 'Canadian Grand Prix'),
  (2026, 6, 'Monaco Grand Prix'),
  (2026, 7, 'Barcelona Grand Prix'),
  (2026, 8, 'Austrian Grand Prix'),
  (2026, 9, 'British Grand Prix'),
  (2026, 10, 'Belgian Grand Prix'),
  (2026, 11, 'Hungarian Grand Prix'),
  (2026, 12, 'Dutch Grand Prix'),
  (2026, 13, 'Italian Grand Prix'),
  (2026, 14, 'Spanish Grand Prix'),
  (2026, 15, 'Azerbaijan Grand Prix'),
  (2026, 16, 'Singapore Grand Prix'),
  (2026, 17, 'United States Grand Prix'),
  (2026, 18, 'Mexico City Grand Prix'),
  (2026, 19, 'Brazilian Grand Prix'),
  (2026, 20, 'Las Vegas Grand Prix'),
  (2026, 21, 'Qatar Grand Prix'),
  (2026, 22, 'Abu Dhabi Grand Prix')
) AS v(season, round, canonical_name)
WHERE r.season = v.season
  AND r.round = v.round
  AND r.name IS DISTINCT FROM v.canonical_name;

-- Duplicate GP names in the same season (should return no rows):
SELECT season, name, COUNT(*) AS n, array_agg(round ORDER BY round) AS rounds
FROM public.races
WHERE season = 2026
GROUP BY season, name
HAVING COUNT(*) > 1;

-- Current 2026 calendar in DB:
SELECT season, round, name
FROM public.races
WHERE season = 2026
ORDER BY round;
