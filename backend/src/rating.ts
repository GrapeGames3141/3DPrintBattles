/** Maker Rating and ranked matchmaking. Mirrors scripts/core/rating.gd and
 * scripts/core/matchmaker.gd; backend/test/rating_vectors.json holds the cases
 * both implementations must agree on. The server owns ratings: clients send the
 * result of a verified match, never a rating. */
export const START = 1000;
export const FLOOR = 100;
export const LEAGUES = [
  { name: "Spool", floor: 0 }, { name: "Filament", floor: 900 }, { name: "Nozzle", floor: 1050 },
  { name: "Hotend", floor: 1200 }, { name: "Extruder", floor: 1400 }, { name: "Gantry", floor: 1600 },
  { name: "Print Master", floor: 1850 },
];
export function kFactor(games: number): number { return games < 10 ? 40 : games < 30 ? 28 : 20; }
export function expected(a: number, b: number): number { return 1 / (1 + Math.pow(10, (b - a) / 400)); }
/** Round half away from zero, like Godot's roundi. */
function roundHalf(x: number): number { return x >= 0 ? Math.floor(x + 0.5) : -Math.floor(-x + 0.5); }
export function delta(a: number, b: number, won: boolean, games: number): number {
  return roundHalf(kFactor(games) * ((won ? 1 : 0) - expected(a, b)));
}
export function after(a: number, b: number, won: boolean, games: number): number { return Math.max(FLOOR, a + delta(a, b, won, games)); }
export function league(rating: number): { name: string; division: number; index: number } {
  let idx = 0;
  for (let i = 0; i < LEAGUES.length; i++) if (rating >= LEAGUES[i].floor) idx = i;
  const last = idx === LEAGUES.length - 1;
  let division = 0;
  if (!last) {
    const span = LEAGUES[idx + 1].floor - LEAGUES[idx].floor;
    division = 3 - Math.max(0, Math.min(2, Math.trunc((3 * (rating - LEAGUES[idx].floor)) / span)));
  }
  return { name: LEAGUES[idx].name, division, index: idx };
}

export const BASE_WINDOW = 100;
export const GROWTH_PER_SECOND = 15;
export const MAX_WINDOW = 700;
export const GHOST_AFTER = 20;
export type QueueEntry = { id: string; rating: number; joined: number; recent: string[] };
export function window(seconds: number): number { return Math.min(BASE_WINDOW + GROWTH_PER_SECOND * Math.max(seconds, 0), MAX_WINDOW); }
export function partnerFor(entry: QueueEntry, queue: QueueEntry[], now: number): [string, string] | null {
  let best: QueueEntry | null = null;
  let bestGap = Number.MAX_SAFE_INTEGER;
  const mine = window(now - entry.joined);
  for (const other of queue) {
    if (other.id === entry.id) continue;
    if (entry.recent.includes(other.id) || other.recent.includes(entry.id)) continue;
    const gap = Math.abs(other.rating - entry.rating);
    const reach = Math.max(mine, window(now - other.joined));
    if (gap > reach) continue;
    if (gap < bestGap || (gap === bestGap && best !== null && other.id < best.id)) { best = other; bestGap = gap; }
  }
  return best ? [entry.id, best.id] : null;
}
export function pairs(queue: QueueEntry[], now: number): [string, string][] {
  let waiting = [...queue].sort((a, b) => a.joined - b.joined || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  const out: [string, string][] = [];
  let i = 0;
  while (i < waiting.length) {
    const found = partnerFor(waiting[i], waiting, now);
    if (!found) { i++; continue; }
    out.push(found);
    waiting = waiting.filter((e) => e.id !== found[0] && e.id !== found[1]);
    i = 0;
  }
  return out;
}
export function shouldOfferGhost(waitedSeconds: number): boolean { return waitedSeconds >= GHOST_AFTER; }
