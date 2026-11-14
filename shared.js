/** Shared config and scoring — loaded by index.html and test.html */
const SB_URL = 'https://qkmukcuqosvlumsrqyay.supabase.co';
const SB_KEY = 'sb_publishable_dkJN0bxvkkW7JHXAvZ62XQ_tpxexARU';

const QUALI_PTS = [12.5, 9, 7.5];
const RACE_PTS  = [25, 18, 15];
const SPRINT_PTS = [12.5, 9, 7.5];
const FASTEST_LAP_PTS = 10;
const QUALI_MAX = QUALI_PTS.reduce((a, b) => a + b, 0);
const RACE_MAX  = RACE_PTS.reduce((a, b) => a + b, 0);

const PLAYERS = ['Ollie', 'Tom', 'Tim', 'Ralph', 'Herbie', 'Dave', 'Jason', 'NigeBot'];

const DRIVER_CODES = {
  VER: 'Verstappen', NOR: 'Norris', LEC: 'Leclerc', PIA: 'Piastri',
  SAI: 'Sainz', HAM: 'Hamilton', RUS: 'Russell', ANT: 'Antonelli',
  ALO: 'Alonso', STR: 'Stroll', GAS: 'Gasly', OCO: 'Ocon',
  HUL: 'Hulkenberg', MAG: 'Magnussen', TSU: 'Tsunoda', LAW: 'Lawson',
  ALB: 'Albon', SAR: 'Sargeant', BOT: 'Bottas', ZHO: 'Zhou',
  BEA: 'Bearman', HAD: 'Hadjar', DOO: 'Doohan', BOR: 'Bortoleto', COL: 'Colapinto'
};

function norm(s) {
  if (!s) return '';
  const up = s.trim().toUpperCase();
  if (DRIVER_CODES[up]) return DRIVER_CODES[up].toLowerCase();
  return s.trim().toLowerCase();
}

function calcScore(preds, results, pts) {
  let total = 0;
  preds.forEach((pred, pi) => {
    if (!pred) return;
    const ei = results.findIndex(r => norm(r) === norm(pred));
    if (ei === pi) total += pts[pi];
    else if (ei !== -1 && Math.abs(ei - pi) === 1) total += pts[ei] / 2;
  });
  return total;
}

function blankPick(s) {
  if (s == null) return '';
  return String(s).trim();
}

/** True when all three podium slots are filled with the same driver. */
function threeIdentical(a, b, c) {
  const x = blankPick(a).toUpperCase();
  const y = blankPick(b).toUpperCase();
  const z = blankPick(c).toUpperCase();
  return x !== '' && x === y && y === z;
}

/** True once the session start time has been reached. Missing time means not locked. */
function sessionStarted(iso, nowMs) {
  if (!iso) return false;
  const t = new Date(iso).getTime();
  if (Number.isNaN(t)) return false;
  const now = nowMs == null ? Date.now() : nowMs;
  return now >= t;
}

/**
 * Publish stays off until qualifying, the race, and (from round 2) fastest lap
 * are in, and until sprint results are in on a sprint weekend.
 */
function publishReady(o) {
  const roundNum = parseInt(o.round, 10);
  if (!o.hasQual || !o.hasRace) return false;
  if (!(roundNum === 1 || o.fastestLapDriver)) return false;
  if (o.sprintWeekend && !o.hasSprint) return false;
  return true;
}
