const assert = require("assert");
const fs = require("fs");
const path = require("path");
const r = require("../dist/rating.js");
const v = JSON.parse(fs.readFileSync(path.join(__dirname, "rating_vectors.json"), "utf8"));
for (const c of v.rating) assert.strictEqual(r.delta(c.a, c.b, c.won, c.games), c.delta, JSON.stringify(c));
for (const w of v.windows) assert.strictEqual(r.window(w.seconds), w.window);
for (const l of v.leagues) { const got = r.league(l.rating); assert.strictEqual(got.name, l.name, String(l.rating)); assert.strictEqual(got.division, l.division, String(l.rating)); }
for (const m of v.matchmaking) assert.deepStrictEqual(r.pairs(v.queue, m.now), m.pairs, "pairs at " + m.now);
assert.strictEqual(r.after(100, 1500, false, 50), 100, "rating never drops below the floor");
assert.strictEqual(r.shouldOfferGhost(19), false);
assert.strictEqual(r.shouldOfferGhost(20), true);
console.log("rating tests passed");
