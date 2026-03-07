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
2. Go to **Tests** tab and run all tests — confirm Jolpica API is green
3. Go to **Results** tab — select the season and round
4. Hit **Fetch Results** and review the score preview for all players
5. If everything looks correct, hit **Publish** — scores go live in NigeBot instantly
6. Share the leaderboard link in the WhatsApp group

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

---

## Driver Codes

Predictions must be entered as 3-letter codes:

`VER` `NOR` `LEC` `PIA` `HAM` `RUS` `ANT` `ALO` `STR` `GAS` `HUL` `TSU` `LAW` `ALB` `BEA` `HAD` `DOO` `BOR` `COL`
