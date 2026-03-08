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
1. Open NigeBot before qualifying starts
2. Enter your top 3 predictions for qualifying and the race using 3-letter driver codes (e.g. `VER`, `HAM`, `NOR`)
3. Hit **Save All Predictions** — predictions lock automatically when qualifying begins
4. Check back after the race weekend — results and scores will be published here and shared on WhatsApp

### For Admins (Tim & Ollie)
1. Open Man Cave after the race weekend
2. Go to **Tests** tab and run all tests — confirm Jolpica API is green and current round has full results
3. Go to **Results** tab — select the season and round
4. Hit **Fetch Results** and review the score preview for all players (sorted highest to lowest)
5. When ready, the **Publish Results to NigeBot** button turns amber — hit it to push scores live
6. Button turns green with a timestamp once published — "Last published" also updates with race name and time
7. Generate the WhatsApp message using the section below the score preview — edit if needed, copy and send

---

## Scoring

Points are awarded for predicting the top 3 in qualifying and the race.

| Session | Position | Exact | One Position Off |
|---------|----------|-------|-----------------|
| Qualifying | P1 | 12.5 pts | 6.25 pts |
| Qualifying | P2 | 9 pts | 4.5 pts |
| Qualifying | P3 | 7.5 pts | 3.75 pts |
| Race | P1 | 25 pts | 12.5 pts |
| Race | P2 | 18 pts | 9 pts |
| Race | P3 | 15 pts | 7.5 pts |

**One position off** means the driver finished one place away from where you predicted — you get half the points for where they actually finished.

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
| `races` | Race calendar entries (season, round, name, dates) |
| `predictions` | Player predictions per race |
| `results` | Official top 3 results per race |
| `scores` | Calculated scores per player per race |
| `published_log` | Timestamp log of when results were published |

> `published_log` requires a unique constraint on `race_id`. If not present, run: `ALTER TABLE published_log ADD CONSTRAINT published_log_race_id_key UNIQUE (race_id);`

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
