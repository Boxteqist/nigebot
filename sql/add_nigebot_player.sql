-- Add NigeBot as a player: no predictions for Australia; China quali/race/fastest lap only (no sprint).
-- NigeBot receives 0 points for Australia and 0 sprint points for China (handled in app when publishing).

-- 1) Australia (Round 1): no predictions; insert scores only (all zeros)
INSERT INTO public.scores (
  race_id,
  player_name,
  quali_score,
  race_score,
  sprint_score,
  fastest_lap_score,
  total_score,
  calculated_at
)
SELECT
  r.id,
  'NigeBot',
  0, 0, 0, 0, 0,
  NOW()
FROM public.races r
WHERE r.season = 2026 AND r.round = 1
ON CONFLICT (player_name, race_id) DO UPDATE SET
  quali_score = 0,
  race_score = 0,
  sprint_score = 0,
  fastest_lap_score = 0,
  total_score = 0,
  calculated_at = NOW();

-- 2) China (Round 2): insert predictions — Quali RUS, NOR, HAM; Race RUS, LEC, NOR; Fastest lap NOR; no sprint
INSERT INTO public.predictions (
  race_id,
  player_name,
  quali_p1, quali_p2, quali_p3,
  sprint_p1, sprint_p2, sprint_p3,
  race_p1, race_p2, race_p3,
  fastest_lap,
  submitted_at,
  admin_entered
)
SELECT
  r.id,
  'NigeBot',
  'RUS',  'NOR',  'HAM',
  NULL,   NULL,   NULL,
  'RUS',  'LEC',  'NOR',
  'NOR',
  NOW(),
  true
FROM public.races r
WHERE r.season = 2026 AND r.round = 2
ON CONFLICT (player_name, race_id) DO UPDATE SET
  quali_p1 = EXCLUDED.quali_p1,
  quali_p2 = EXCLUDED.quali_p2,
  quali_p3 = EXCLUDED.quali_p3,
  sprint_p1 = EXCLUDED.sprint_p1,
  sprint_p2 = EXCLUDED.sprint_p2,
  sprint_p3 = EXCLUDED.sprint_p3,
  race_p1  = EXCLUDED.race_p1,
  race_p2  = EXCLUDED.race_p2,
  race_p3  = EXCLUDED.race_p3,
  fastest_lap = EXCLUDED.fastest_lap,
  submitted_at = EXCLUDED.submitted_at,
  admin_entered = true;

-- 3) China scores: re-publish China from Man Cave (Results tab → Fetch → Publish) so NigeBot gets
--    quali/race/fastest-lap points calculated; the app will set his sprint_score to 0 automatically.
