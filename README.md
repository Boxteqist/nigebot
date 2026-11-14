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
| `test.html` | Man Cave — admin tools, test suite, results publishing, **Copy for Claude** |
| `shared.js` | Shared players, driver codes, points tables, `norm()` / `calcScore()`, lock and publish checks (used by both pages) |
| `sql/one_time_setup.sql` | Full schema and one-time setup. Paste once into the Supabase SQL editor. Safe to re-run on the live database. Does not delete rows. |
| `sql/rls_publish_writes_enable.sql` | Retired. It refuses to run. Do not use it. |
| `sql/rls_publish_writes_disable.sql` | Drops the old temporary publish policies if they are still there. The setup script does this too. |
| `sql/rls_predictions_public_writes.sql` | Repair only, if prediction saves fail with a row-level security error and the setup script has not been run |
| `sql/add_nigebot_player.sql` | Backfill NigeBot’s scores (Australia) and predictions (China); run in Supabase SQL Editor |
| `sql/remove_cancelled_2026_bahrain_saudi.sql` | Optional: delete `races` (and related rows) for cancelled 2026 Bahrain / Saudi Arabian GPs if they exist |
| `sql/sync_2026_race_names.sql` | Optional: correct all 2026 `races.name` values to match Jolpica (22 rounds) |
| `sql/maintenance_checklist.sql` | Optional: verify queries — policies, orphan races, duplicate GP names |
| `sql/fix_2026_race_names.sql` | Pointer only — use `sync_2026_race_names.sql` instead |
| `.github/workflows/supabase-heartbeat.yml` | Daily ping so the Free-tier Supabase project is not paused for inactivity |

---

## How It Works

### For Players
1. Open NigeBot — the most recently published race loads automatically  
2. Enter your top 3 predictions for **qualifying** and the **Grand Prix** using 3-letter driver codes (e.g. `VER`, `HAM`, `NOR`)  
3. On Sprint weekends, also enter your top 3 for the **Sprint Race**, and pick the **fastest lap** driver for the Grand Prix. On sprint weekends the Predictions tab shows sections in order: Sprint Race, Qualifying, Race, Fastest Lap.  
4. Hit **Save** under your name (each player has their own Save button at the bottom of their column). On a sprint weekend, sprint picks lock when the sprint starts. Qualifying, race, and fastest-lap picks lock when qualifying starts. The same driver cannot be picked in all three places. The database enforces both rules.  
5. Check back after the race weekend — results and scores will be published here. On the **Results** tab, **Actual Results** are shown in four columns (on sprint weekends): Sprint, Qualifying, Race, Fastest Lap. Per-player score cards use the same order.

### For Admins (Tim & Ollie)
1. Open Man Cave after the race weekend
2. Go to **Tests** tab and run all tests — confirm Jolpica API is green and current round has full results
3. Go to **Results** tab — select the season and round. The **Actual Results** card shows four columns (on sprint weekends): Sprint, Qualifying, Race, Fastest Lap
4. Hit **Fetch Results** and review the score preview for all players (sorted highest to lowest). Jolpica results are matched by **Grand Prix name**, not only the DB round number — so the correct weekend is fetched even if `races.round` in Supabase is out of date.
5. On a sprint weekend the publish button stays grey until the sprint results are in Jolpica, as well as qualifying, the race, and (from round 2) fastest lap.
6. Type the admin password and hit **Publish Results to NigeBot**. Nothing in Supabase needs to be opened, and no SQL is run on race weekend.
7. Button turns green with a timestamp once published — "Last published" also updates with race name and time
8. **WhatsApp via Claude** — **Fetch** first for race weekends, then **Copy for Claude**. You get high-level facts (podiums, round + season scores, talking points, app URL) to paste into Claude — not full prediction grids. Optional notes for reminders, birthdays, etc.

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

- **Season standings**: cumulative qualifying, sprint, race, fastest lap, and total points per player, plus a **Delta** column (points behind the leader; leader shows —).
- **Key stats** (3×3 grid, ties shown as combined names):
  - **Current Leader** — season points leader(s)
  - **Rounds Scored** — published rounds vs full season calendar from Jolpica (e.g. `6 / 22`)
  - **Lead over 2nd** — leader’s name and points gap to 2nd place
  - **Clean Sweeps** — perfect quali top 3 (29 pts) or perfect race top 3 (58 pts) in a round
  - **Best Single Round** — highest one-weekend score
  - **Best Avg / Round** — highest average per scored round
  - **Fewest Missed** — fewest rounds without predictions (all tied players listed)
  - **Last Round Top** — top scorer in the most recently published round
  - **Most Pole Calls** — most correct pole predictions
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

## One-time setup

Run this once in **Supabase → SQL Editor**. No Supabase CLI and no Edge Function.

1. Choose an admin password of at least 10 characters. It is not stored in git or in the website. Only a hash is saved, in a private table the public API cannot read.
2. Open `sql/one_time_setup.sql`. Replace `__SET_ME_BEFORE_RUNNING__` with that password.
3. Paste the whole file into the SQL editor and run it once.
4. Leave **Exposed schemas** as `public` (and `graphql_public` if it is already there). Do not add `private`.

The file is the full schema: tables, columns, policies, grants, the publish function, and the lock triggers. On the live database it keeps existing races, predictions, results, scores, and published rows. It does not `DELETE`, `TRUNCATE`, or `DROP` those tables. It removes the temporary `*_insert_public_tmp` and `*_update_public_tmp` policies and revokes `TRUNCATE` (and the other extra grants) from `anon` and `authenticated`. The unused `players` table, including its `pin` column, is left in place and closed to the website key.

Re-running the file is safe. It will not change a password that is already saved. To change the password later, run only this in the SQL editor:

```sql
SELECT private.set_admin_password('the-new-password');
```

There is nothing to deploy for an Edge Function. Publishing goes through the `publish_results` database function. The service role key is not used and must not be put in the repo or the pages.

### 2027 season checklist

- The season dropdown already includes 2027. No SQL toggle before or after publishing.
- The admin password carries over. Set a new one only if it has been shared.
- The first time someone opens a round in NigeBot, that round’s qualifying time and sprint time are saved. After that, the website cannot move them. If the FIA reschedules a session, correct `qualifying_at`, `sprint_at`, or `race_at` in the SQL editor (that path is allowed). The app cannot do it.
- If the 2027 grid changes, update `DRIVER_CODES` in `shared.js`.
- If a player joins or leaves, update `PLAYERS` in `shared.js`.
- Confirm **Actions → Supabase heartbeat** still has a green run. If GitHub has disabled it, open the workflow and click **Enable workflow**, or use the backup monitor in the heartbeat section below.
- NigeBot’s “0 points for round 1, 0 sprint points” rule lives in the app. Change it there if 2027 should score him differently.

## Database maintenance (occasional)

Run in **Supabase → SQL Editor** only when something on this list is actually wrong. Publishing does not use these.

| When | Script |
|------|--------|
| Wrong GP name at a round (e.g. Miami at R6) | `sql/sync_2026_race_names.sql` |
| Old cancelled Bahrain / Saudi rows still listed | `sql/remove_cancelled_2026_bahrain_saudi.sql` |
| Prediction saves blocked by RLS and the setup script was never applied | `sql/rls_predictions_public_writes.sql` |
| General health check | `sql/maintenance_checklist.sql` (inspect results; delete orphan races manually if needed) |

Re-run **sync** after FIA calendar changes. Man Cave **Fetch** also resolves Jolpica by GP name.

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Frontend | Vanilla HTML/CSS/JavaScript |
| Database | Supabase (PostgreSQL) |
| F1 Data | Jolpica API (`api.jolpi.ca/ergast/`) — the race dropdown for **every season, including 2026**, is loaded from this API so it stays aligned with Man Cave’s schedule checks |
| Charts | Chart.js |
| Hosting | GitHub Pages |

### Versioning

The version shown in the NigeBot and Man Cave headers comes from `window.NIGEBOT_VERSION` in `version.js`. On each push to `main`, the GitHub Actions workflow rewrites this file with:

- A base version from `BASE_VERSION` in `.github/workflows/deploy.yml` (for example, `1.6.0`)
- An auto-incrementing build number: `1.6.0+build.<GitHub run number>`

To bump the major/minor version, update `BASE_VERSION` in the workflow and push to `main`.

### Database Tables

| Table | Description |
|-------|-------------|
| `races` | Race calendar entries (season, round, name, dates, sprint weekends) |
| `predictions` | Player predictions per race (qualifying top 3, sprint race top 3 where applicable, Grand Prix top 3, fastest lap) |
| `results` | Official top 3 results per race (qualifying, sprint race where applicable, Grand Prix top 3, fastest lap driver) |
| `scores` | Calculated scores per player per race (qualifying, sprint race, Grand Prix, fastest lap, totals) |
| `published_log` | Timestamp log of when results were published |

`sql/one_time_setup.sql` adds any missing columns and the unique keys the app expects (`race_id` on results and published_log, `player_name, race_id` on predictions and scores, `season, round` on races). It does not drop or rewrite rows that are already there.

`players` is unused by the app. It has a `pin` column. The setup script leaves the table as it is and removes website-key access, so the pin is not readable from NigeBot or Man Cave.

### Who can write what

Players stay logged-out. The publishable key in `shared.js` is the public anon key.

- `results`, `scores`, `published_log`: **SELECT only**. No insert, update, delete, or truncate for `anon` or `authenticated`.
- `predictions`: **SELECT, INSERT, UPDATE**. A trigger rejects changes after the session has started, and rejects three identical drivers. Delete and truncate are revoked.
- `races`: **SELECT, INSERT, UPDATE**, so opening a round can store its name and session times. Once a session time is saved, the website cannot move it. Delete and truncate are revoked.
- `players`: no privileges for the website key, and no row policy, so nothing in that table is exposed.

Man Cave publishes by calling `publish_results` with the admin password. That function checks the hash in `private.admin_config`, then writes results, scores, and the publish log as the database owner. A wrong password writes nothing.

---

## Man Cave Test Suite

The Tests tab runs a suite of checks across four groups:

- **F1 API — Jolpica** — confirms the API is reachable using a known historical race, checks the season schedule, and checks whether the current round (most recent with predictions) has full results. On a sprint weekend it also requires sprint results before it calls the round ready to publish.
- **Scoring Logic** — unit tests for exact matches, near-misses, driver code resolution, and full prediction scenarios
- **Supabase Connection** — confirms read access to all five database tables
- **Prediction Save & Update** — writes, updates, reads back, and cleans up a test prediction row

## Score Preview

The score preview in the Results tab shows all eight players sorted by score, highest first. On sprint weekends, each player’s card shows sections in order: **Sprint**, **Qualifying**, **Race**, **Fastest Lap**. Each prediction is colour-coded with a symbol:

- `✓` green — exact match
- `~` amber — one position off (half points)
- `✗` grey — miss or driver not in top 3

## Supabase Free plan — “project will be paused” emails

Supabase is **not** complaining that you use too little database storage. On the **Free** plan, projects are **paused after about 7 days of inactivity** so shared infrastructure isn’t kept warm for unused apps. That’s the opposite of “we want you to use more data” — it’s **“we want some sign the project is still in use.”**

**What counts as activity:** REST/API requests that reach Postgres (reads or writes). Opening the static GitHub Pages site alone does **not** count unless the page actually calls Supabase (predictions save, load races, publish, etc.). Quiet weeks between race weekends can trigger the warning email.

**When paused:** Data is usually still on disk; restore from the [Supabase dashboard](https://supabase.com/dashboard). Free projects can be restored for **90 days** after pause (see [Supabase changelog](https://supabase.com/changelog/27497-paused-free-plan-projects-are-restorable-for-90-days)). **Pro** ($25/mo) projects are not paused for inactivity.

**What we do in this repo:** GitHub Actions workflow [`.github/workflows/supabase-heartbeat.yml`](.github/workflows/supabase-heartbeat.yml) runs **daily** at 09:17 UTC and runs a simple `GET` on the `races` table. That resets the Supabase inactivity timer. You can also run it manually under **Actions → Supabase heartbeat → Run workflow**.

GitHub turns **scheduled** workflows off on a public repository after **60 days with no commit on the default branch**. A successful heartbeat run does not count as that commit. The same workflow, when the last commit on `main` is 30 days old or more, pushes an empty commit (`chore: keep scheduled workflows enabled`). That push uses the built-in `GITHUB_TOKEN`, which does not start the Pages deploy, so the site is not rebuilt just to stay awake. If `main` is protected and the push is rejected, the database ping still counts as a successful run.

If the workflow still shows **disabled** (Actions → Supabase heartbeat), click **Enable workflow**. The missed days are not replayed.

**Backup if Actions schedules are off:** a free [cron-job.org](https://cron-job.org) or UptimeRobot monitor, daily, `GET`

`https://qkmukcuqosvlumsrqyay.supabase.co/rest/v1/races?select=id&limit=1`

with headers `apikey` and `Authorization: Bearer`, both set to the publishable key in `shared.js`. That key is already public in the website. No heartbeat table is required.

## Publish Button States

| State | Colour | Meaning |
|-------|--------|---------|
| 🔒 Publish Results to NigeBot | Grey | Results not yet available, or a sprint weekend is still missing the sprint |
| ⚠️ Publish Results to NigeBot | Amber | Ready to publish |
| ✅ Published — date, time | Green | Published successfully |

> Re-publishing is allowed and will overwrite scores and update the timestamp.

---

## Players

The app supports eight players: Ollie, Tom, Tim, Ralph, Herbie, Dave, Jason, and **NigeBot**. NigeBot receives **0 points for Australia** (Round 1) and **0 sprint points** on sprint weekends; his quali, race, and fastest-lap scores are calculated normally.

**Adding NigeBot (backfill):** NigeBot has no predictions for Australia and no sprint predictions for China. The script `sql/add_nigebot_player.sql` inserts his Australia scores (all zeros) and his China predictions (quali, race, fastest lap only). Run the script in the Supabase Dashboard → SQL Editor (paste and run); then re-publish China from Man Cave so his China score (with 0 sprint) is calculated.

## Driver Codes

Predictions must be entered as 3-letter codes:

`VER` `NOR` `LEC` `PIA` `HAM` `RUS` `ANT` `ALO` `STR` `GAS` `HUL` `TSU` `LAW` `ALB` `BEA` `HAD` `DOO` `BOR` `COL`

> For reserve drivers not in the standard list, use the driver's full surname instead of a code.
