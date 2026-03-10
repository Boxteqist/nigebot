# NigeBot 🏁
**Park Estate F1 Predictions Tracker**

NigeBot is a lightweight F1 prediction game for the Park Estate group. Each race weekend, players predict the top 3 in qualifying and the top 3 in the race. Points are awarded for exact and near-miss predictions. Results are published after the race by an admin.

---

## Live URLs

| App | URL |
|-----|-----|
| NigeBot (main app) | `boxteqist.github.io/nigebot` |
| Man Cave (admin only) | `boxteqist.github.io/nigebot/test.html` |

---

## Files

| File | Description |
|------|-------------|
| `index.html` | Main NigeBot app — predictions, leaderboard, stats, scoring guide |
| `test.html` | Man Cave — admin tools, test suite, results publishing |

---

## How It Works

### For Players
1. Open NigeBot — the most recently published race loads automatically  
2. Enter your top 3 predictions for **qualifying** and the **Grand Prix** using 3-letter driver codes (e.g. `VER`, `HAM`, `NOR`)  
3. On Sprint weekends, also enter your top 3 for the **Sprint Race**, and pick the **fastest lap** driver for the Grand Prix  
4. Hit **Save All Predictions** — predictions lock automatically when qualifying begins  
5. Check back after the race weekend — results and scores will be published here. On the **Results** tab, the Race column shows Grand Prix P1–P3, Sprint P1–P3 where applicable, plus the fastest lap

### For Admins (Tim & Ollie)
1. Open Man Cave after the race weekend
2. Go to **Tests** tab and run all tests — confirm Jolpica API is green and current round has full results
3. Go to **Results** tab — select the season and round. The “Actual Results” card shows qualifying P1–P3, Grand Prix P1–P3, Sprint P1–P3 where applicable, plus fastest lap
4. Hit **Fetch Results** and review the score preview for all players (sorted highest to lowest)
5. When ready, the **Publish Results to NigeBot** button turns amber — hit it to push scores live
6. Button turns green with a timestamp once published — "Last published" also updates with race name and time

---

## Scoring

Points are awarded for predicting the top 3 in qualifying, the Sprint Race (on Sprint weekends), and the Grand Prix, plus fastest lap.

| Session      | Position | Exact    | One Position Off |
|-------------|----------|----------|------------------|
| Qualifying  | P1       | 12.5 pts | 6.25 pts         |
| Qualifying  | P2       | 9 pts    | 4.5 pts          |
| Qualifying  | P3       | 7.5 pts  | 3.75 pts         |
| Sprint Race | P1       | 12.5 pts | 6.25 pts         |
| Sprint Race | P2       | 9 pts    | 4.5 pts          |
| Sprint Race | P3       | 7.5 pts  | 3.75 pts         |
| Grand Prix  | P1       | 25 pts   | 12.5 pts         |
| Grand Prix  | P2       | 18 pts   | 9 pts            |
| Grand Prix  | P3       | 15 pts   | 7.5 pts          |
| Fastest Lap | —        | 10 pts   | n/a              |

**One position off** means the driver finished one place away from where you predicted — you get **half the points for where they actually finished**. Fastest lap is all‑or‑nothing: 10 points if you name the fastest-lap driver correctly, 0 otherwise.

---

## Season Stats & Awards

On the **Season** tab the app shows:

- **Season standings**: cumulative qualifying, sprint, race, and total points per player.
- **Key stats**: including Most Pole Calls, Most Win Calls, Sprint Specialist, Most Fast Laps, Fewest Missed, and Best Avg / Round.
- **Awards**:
  - **Most Pole Calls** — most correctly called poles.
  - **Most Win Calls** — most correctly called Grand Prix winners.
  - **Sprint Specialist** — highest total sprint race points.
  - **Hot Lap Hero** — most correctly called fastest laps across the season.
  - **Mr Saturday** — highest total qualifying points.
  - **Sunday Merchant** — highest total race (Grand Prix) points.
  - **Volatility King** — biggest swing between best and worst race scores.
  - **Consistency King** — lowest variance in race scores.

There is also **Crofty’s Split — Points Breakdown**, which shows, for each player, what percentage of their season points comes from qualifying, sprint races, the Grand Prix, and fastest lap.

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Vanilla HTML/CSS/JavaScript |
| Database | Supabase (PostgreSQL) |
| F1 Data | Jolpica API (`api.jolpi.ca/ergast/`) |
| Charts | Chart.js |
| Hosting | GitHub Pages |

### Database Tables

| Table | Description |
|-------|-------------|
| `races` | Race calendar entries (season, round, name, dates, sprint weekends) |
| `predictions` | Player predictions per race (qualifying top 3, sprint race top 3 where applicable, Grand Prix top 3, fastest lap) |
| `results` | Official top 3 results per race (qualifying, sprint race where applicable, Grand Prix top 3, fastest lap driver) |
| `scores` | Calculated scores per player per race (qualifying, sprint race, Grand Prix, fastest lap, totals) |
| `published_log` | Timestamp log of when results were published |

> `published_log` requires a unique constraint on `race_id`. If not present, run: `ALTER TABLE public.published_log ADD CONSTRAINT published_log_race_id_key UNIQUE (race_id);`

Additional columns expected by the app:

```sql
ALTER TABLE public.predictions
  ADD COLUMN IF NOT EXISTS fastest_lap text,
  ADD COLUMN IF NOT EXISTS sprint_p1 text,
  ADD COLUMN IF NOT EXISTS sprint_p2 text,
  ADD COLUMN IF NOT EXISTS sprint_p3 text;

ALTER TABLE public.results
  ADD COLUMN IF NOT EXISTS fastest_lap text,
  ADD COLUMN IF NOT EXISTS sprint_p1 text,
  ADD COLUMN IF NOT EXISTS sprint_p2 text,
  ADD COLUMN IF NOT EXISTS sprint_p3 text;

ALTER TABLE public.scores
  ADD COLUMN IF NOT EXISTS fastest_lap_score numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sprint_score numeric DEFAULT 0;
```

---

## Man Cave Test Suite

The Tests tab runs a suite of checks across four groups:

- **F1 API — Jolpica** — confirms the API is reachable using a known historical race, checks the season schedule, and checks whether the current round (most recent with predictions) has full results, qualifying only, or nothing yet
- **Scoring Logic** — unit tests for exact matches, near-misses, driver code resolution, and full prediction scenarios
- **Supabase Connection** — confirms read access to all five database tables
- **Prediction Save & Update** — writes, updates, reads back, and cleans up a test prediction row

## Score Preview

The score preview in the Results tab shows all seven players sorted by score, highest first. Each prediction is colour-coded with a symbol:

- `✓` green — exact match
- `~` amber — one position off (half points)
- `✗` grey — miss or driver not in top 3

## Publish Button States

| State | Colour | Meaning |
|-------|--------|---------|
| 🔒 Publish Results to NigeBot | Grey | Results not yet available |
| ⚠️ Publish Results to NigeBot | Amber | Ready to publish |
| ✅ Published — date, time | Green | Published successfully |

> Re-publishing is allowed and will overwrite scores and update the timestamp.

---

## Driver Codes

Predictions must be entered as 3-letter codes:

`VER` `NOR` `LEC` `PIA` `HAM` `RUS` `ANT` `ALO` `STR` `GAS` `HUL` `TSU` `LAW` `ALB` `BEA` `HAD` `DOO` `BOR` `COL`

> For reserve drivers not in the standard list, use the driver's full surname instead of a code.
