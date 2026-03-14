# NigeBot — Full Repo Code Review

**Date:** March 2025  
**Scope:** Entire repository (index.html, test.html, version.js, deploy.yml, sql/, README.md)

---

## 1. Summary

The repo is a small, focused F1 predictions app: vanilla HTML/CSS/JS, Supabase, Jolpica API, GitHub Pages. Structure is clear and README is strong. One **critical bug** was found and fixed (sprint data missing when publishing from Man Cave). Below: security, consistency, maintainability, and minor improvements.

---

## 2. Critical bug (fixed)

### Man Cave: `publishResults()` used `sTop3` and `hasSprint` without including them in `previewData`

- **Issue:** `previewData` was set in `fetchPreview()` with `qTop3`, `rTop3`, `preds`, `hasQual`, `hasRace`, `fastestLapDriver` but **not** `sTop3` or `hasSprint`. In `publishResults()` the code used:
  - `sTop3` for `results.sprint_p1/p2/p3` → effectively always `null`
  - `hasSprint` and `sTop3` for sprint score → `hasSprint` undefined (falsy) so everyone got **0 sprint points** on sprint weekends
- **Fix applied:** `previewData` now includes `sTop3` and `hasSprint`; `publishResults()` destructures them from `previewData`. Sprint results and sprint scores now publish correctly on sprint weekends.

---

## 3. Security

### 3.1 Supabase key in frontend

- **Current:** `SB_URL` and `SB_KEY` (publishable key) are in both `index.html` and `test.html`.
- **Assessment:** Supabase anon/publishable keys are intended for client-side use; RLS should protect data. Key is in the repo and in deployed HTML, which is normal for a public client app.
- **Recommendation:** Ensure Supabase RLS is strict (no public write to sensitive tables; Man Cave-only flows could use a separate key or backend if you ever need to restrict who can publish). No change required for current design.

### 3.2 No sensitive data in version.js

- `version.js` only sets `window.NIGEBOT_VERSION`. Safe.

---

## 4. Duplication and single source of truth

### 4.1 Shared constants

- **PLAYERS:** Identical in `index.html` and `test.html`. Same for **QUALI_PTS**, **RACE_PTS**, **SPRINT_PTS**, **FASTEST_LAP_PTS**.
- **DRIVER_CODES:** Slightly different between the two files (index has SAI, SAR, BOT, ZHO; test has different set). Predictions and scoring can diverge if one list is updated and not the other.
- **Recommendation:** Prefer a single shared script (e.g. `shared.js` or `config.js`) loaded by both pages with PLAYERS, points arrays, and DRIVER_CODES. Failing that, document “canonical” list (e.g. index.html) and keep test.html in sync.

### 4.2 Supabase helpers

- `sbGet` / `sbUpsert` and URL/header construction are duplicated in index and test. Extracting to a small `supabase.js` would reduce drift and bugs (e.g. test has `published_log` conflict param, index doesn’t upsert published_log).

### 4.3 Scoring and `norm()`

- `norm()` and `calcScore()` are duplicated. Same suggestion: shared module or file so logic and driver handling stay consistent.

---

## 5. Error handling and robustness

### 5.1 index.html

- **sbGet:** Returns `r.json()` even when `!r.ok`, so callers can receive a JSON error body instead of an array and may not check. Prefer: if `!r.ok` throw or return a structured `{ error }` and handle it in callers.
- **sbUpsert:** Returns `{ error: err }` on failure; some callers check `res.error`, which is good. Consistent use of this pattern elsewhere would help.
- **loadRaces:** On 2027/2028, failure to load from API leaves dropdown as “Failed to load” with no retry. Optional: retry or message like “Check connection and try again.”

### 5.2 test.html

- **sbGet:** Throws on `!r.ok`, which is consistent with the rest of the file.
- **fetchPreview:** Try/catch surfaces a generic message. Optional: log `e` (or send to logging) for debugging.

### 5.3 API usage

- Jolpica endpoints are called with no timeout or abort. For slow networks, consider `AbortController` + timeout so the UI doesn’t hang indefinitely.

---

## 6. Consistency and UX

### 6.1 Race section label (test.html)

- In the score preview card, Race section uses lowercase `'pending'`:  
  `Race (${rScore!==null?rScore:'pending'})`.  
  Elsewhere “Pending” is capitalized and amber. Consider: `rScore !== null ? rScore : 'Pending'` and, if desired, same amber styling for that label.

### 6.2 index.html — empty prediction save

- Saving with all fields empty still upserts a row (all nulls). Functionally fine; consider whether you want to block “Save” when there’s no input or show a different message.

### 6.3 Season leaderboard (index.html)

- Leaderboard table shows Quali and Race but not Sprint or Fast Lap columns. README and “Crofty’s Split” mention sprint and fast lap; adding optional Sprint/Fast Lap columns could improve consistency with the rest of the app.

---

## 7. Accessibility and markup

- **Tabs:** Implemented with buttons and `onclick`; no `role="tablist"`, `role="tab"`, or `aria-selected`. Adding ARIA and keyboard support (e.g. Arrow keys, Enter/Space) would help keyboard and screen-reader users.
- **Forms:** Prediction inputs use `list="driverList"` and labels are implicit (placeholder only). Adding `<label for="...">` (or aria-label) would improve a11y.
- **Status messages:** Success/error messages could use `role="status"` or `role="alert"` and `aria-live` so they’re announced.

---

## 8. Performance and size

- **index.html:** Single ~940-line file with inline CSS and JS; Chart.js from CDN. For this app size, this is acceptable. If it grows, splitting CSS/JS and lazy-loading the chart for the Season tab would help.
- **test.html:** Same idea; no major concerns.

---

## 9. Deployment and versioning

- **deploy.yml:** Rewrites `version.js` with `BASE_VERSION+build.${GITHUB_RUN_NUMBER}`. Clear and correct.
- **version.js in repo:** Contains a static version; overwritten on deploy. README’s versioning section is accurate.

---

## 10. SQL and data

- **add_nigebot_player.sql:** Clear, idempotent (ON CONFLICT), and documented. Relies on `races` existing for 2026 rounds 1 and 2.
- **published_log:** Man Cave expects `race_name` on `published_log` (for “Last published” and possibly elsewhere). If the table was created without it, add the column and ensure it’s set on publish (already done in `publishResults()`).

---

## 11. Recommendations summary

| Priority | Item |
|----------|------|
| Done | Fix Man Cave publish using `sTop3`/`hasSprint` from `previewData` (sprint results and sprint scores). |
| High | Align DRIVER_CODES (and PLAYERS/points) between index and test, or move to shared script. |
| Medium | Harden sbGet/sbUpsert: explicit handling of `!r.ok` in index, consistent error shape. |
| Low | Shared JS for Supabase + scoring + constants to avoid drift. |
| Low | A11y: tab roles, labels, live regions for status messages. |
| Low | Optional: Race section label “Pending” and styling consistency in Man Cave. |

---

*End of code review.*
