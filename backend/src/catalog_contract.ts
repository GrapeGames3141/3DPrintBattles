declare const require: (moduleName: string) => unknown;
declare const __dirname: string;

type FileSystem = { readFileSync(path: string, encoding: string): string };
type Path = { resolve(...parts: string[]): string };

export type SharedCatalogCard = {
  id: string;
  name: string;
  type: "creature" | "equipment" | "filament" | "spell" | "trap" | "upgrade";
  rarity: string;
  filament_cost: number;
  print_turns: number;
  equipment_slot?: "armor" | "gem" | "battle_effect";
  [key: string]: unknown;
};

export type SharedCatalogDocument = {
  schema: string;
  version: number;
  cards: SharedCatalogCard[];
};

const fs = require("fs") as FileSystem;
const path = require("path") as Path;
const CATALOG_PATH = path.resolve(__dirname, "../../data/v3/catalog.json");
const TYPES = new Set(["creature", "equipment", "filament", "spell", "trap", "upgrade"]);
const ELEMENTS = new Set(["Fire", "Water", "Lightning", "Nature", "Ice", "Stone", "Wind", "Arcane"]);
const TARGETS = new Set(["self", "foe", "field", "printer", "forge", "team", "any"]);
const SUPPORT_ART_ATLASES = new Set(["resources", "defense", "offense", "utility"]);

/** The server seam reads the exact source file that Godot loads at runtime. */
export function sharedCatalogDocument(): SharedCatalogDocument {
  return JSON.parse(fs.readFileSync(CATALOG_PATH, "utf8")) as SharedCatalogDocument;
}

export function validateSharedCatalog(document = sharedCatalogDocument()): string[] {
  const failures: string[] = [];
  if (document.schema !== "printforge.v3.catalog" || document.version !== 1) {
    failures.push("catalog schema/version is invalid");
  }
  if (!Array.isArray(document.cards) || document.cards.length === 0) {
    failures.push("catalog has no cards");
    return failures;
  }
  const ids = new Set<string>();
  const visibleArt = new Set<string>();
  for (const card of document.cards) {
    if (!card || typeof card !== "object") { failures.push("catalog card is not an object"); continue; }
    if (typeof card.id !== "string" || card.id.length === 0 || ids.has(card.id)) failures.push(`invalid card id ${String(card.id)}`);
    ids.add(card.id);
    if (!TYPES.has(card.type)) failures.push(`invalid type ${card.id}`);
    if (!Number.isInteger(card.filament_cost) || card.filament_cost < 0 || !Number.isInteger(card.print_turns) || card.print_turns < 0) {
      failures.push(`invalid core numeric field ${card.id}`);
    }
    if (card.type === "equipment" && !["armor", "gem", "battle_effect"].includes(String(card.equipment_slot))) {
      failures.push(`invalid equipment slot ${card.id}`);
    }
    if (card.type === "creature") {
      if (!Number.isInteger(card.bend_score) || Number(card.bend_score) <= 0 || !Number.isInteger(card.hp) || Number(card.hp) <= 0 || !ELEMENTS.has(String(card.element)) || !Number.isInteger(card.ability_cooldown) || Number(card.ability_cooldown) < 0 || !Number.isInteger(card.ability_damage_bonus)) {
        failures.push(`invalid creature fields ${card.id}`);
      }
      if (!card.presentation || typeof card.presentation !== "object") failures.push(`missing creature presentation ${card.id}`);
    } else {
      const art = card.art;
      const isArtObject = !!art && typeof art === "object" && !Array.isArray(art);
      const atlas = isArtObject && typeof (art as { atlas?: unknown }).atlas === "string" ? (art as { atlas: string }).atlas : "";
      const cell = isArtObject ? (art as { cell?: unknown }).cell : undefined;
      const directPath = isArtObject && typeof (art as { path?: unknown }).path === "string" ? (art as { path: string }).path : "";
      const hasAtlas = atlas.length > 0 || cell !== undefined;
      const hasPath = directPath.length > 0;
      let artIdentity = "";
      if (hasAtlas === hasPath) {
        failures.push(`non-creature art must use exactly one source ${card.id}`);
      } else if (hasAtlas) {
        if (!SUPPORT_ART_ATLASES.has(atlas) || !Number.isInteger(cell) || Number(cell) < 0 || Number(cell) > 7) failures.push(`invalid non-creature atlas art ${card.id}`);
        artIdentity = `atlas:${atlas}:${String(cell)}`;
      } else {
        if (!directPath.startsWith("res://")) failures.push(`invalid non-creature direct art ${card.id}`);
        artIdentity = `path:${directPath}`;
      }
      if (artIdentity.length > 0) {
        if (visibleArt.has(artIdentity)) failures.push(`duplicate non-creature art ${artIdentity}`);
        visibleArt.add(artIdentity);
      }
    }
    if (Array.isArray(card.effects) && card.effects.some((effect) => !effect || typeof effect !== "object" || !TARGETS.has(String(effect.target)))) failures.push(`invalid effect target ${card.id}`);
  }
  return failures;
}
