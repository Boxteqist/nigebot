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
