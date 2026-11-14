const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const test = require('node:test');

const context = {};
vm.createContext(context);
vm.runInContext(
  fs.readFileSync(require('node:path').join(__dirname, '..', 'shared.js'), 'utf8') +
    '\nglobalThis.__api = { threeIdentical, sessionStarted, publishReady, calcScore, norm };',
  context
);
const { threeIdentical, sessionStarted, publishReady, calcScore, norm } = context.__api;

test('three identical drivers', () => {
  assert.equal(threeIdentical('VER', 'VER', 'VER'), true);
  assert.equal(threeIdentical(' ver ', 'VER', 'Ver'), true);
  assert.equal(threeIdentical('VER', 'VER', 'NOR'), false);
  assert.equal(threeIdentical('VER', '', ''), false);
  assert.equal(threeIdentical('', '', ''), false);
  assert.equal(threeIdentical(null, null, null), false);
});

test('session lock uses the session start', () => {
  const start = '2026-03-14T07:00:00Z';
  assert.equal(sessionStarted(start, Date.parse('2026-03-14T06:59:59Z')), false);
  assert.equal(sessionStarted(start, Date.parse('2026-03-14T07:00:00Z')), true);
  assert.equal(sessionStarted(null, Date.parse(start)), false);
  assert.equal(sessionStarted('', Date.parse(start)), false);
});

test('publish waits for sprint results on a sprint weekend', () => {
  const base = { hasQual: true, hasRace: true, round: 5, fastestLapDriver: 'Norris', hasSprint: false };
  assert.equal(publishReady({ ...base, sprintWeekend: true }), false);
  assert.equal(publishReady({ ...base, sprintWeekend: true, hasSprint: true }), true);
  assert.equal(publishReady({ ...base, sprintWeekend: false }), true);
  assert.equal(publishReady({ ...base, sprintWeekend: false, round: 4, fastestLapDriver: null }), false);
  assert.equal(publishReady({ hasQual: true, hasRace: true, round: 1, fastestLapDriver: null, sprintWeekend: false, hasSprint: false }), true);
});

test('scoring still maps driver codes', () => {
  assert.equal(norm('VER'), 'verstappen');
  assert.equal(calcScore(['VER', 'NOR', 'LEC'], ['Verstappen', 'Norris', 'Leclerc'], [25, 18, 15]), 58);
});
