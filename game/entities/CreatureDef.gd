## Typed schema for one entry in data/creatures.json.
## Load via DataLoader.get_creature(id) — raw Dictionary — then wrap with from_dict()
## when you need typed access or computed helpers.
class_name CreatureDef
extends RefCounted

## Primary key. Must be unique across all entries (both stages).
## Stage-2 forms have their own IDs (e.g. "marshwarden" for frogling's evolved form).
var id: String = ""

## Name shown in UI — creature select card, HUD, evolution scene.
var display_name: String = ""

## Short flavour text (1–2 sentences) shown on the select card and in the inspect panel.
var description: String = ""

## 1 = base (starter) form. 2 = evolved form.
## DataLoader.get_starter_creatures() filters to stage == 1 and evolution_level != null.
var stage: int = 1

## Minimum level the creature must reach before evolution is possible.
## null in JSON → treated as 999 here (cannot evolve — already final form).
var evolution_level: int = 999

## ID of the EvolutionItemDef required alongside the level gate.
## Empty string when the creature cannot evolve.
var evolution_item_id: String = ""

## ID of the CreatureDef this form becomes after EvolutionSystem.do_evolve().
## Empty string when already at final stage.
var evolved_form_id: String = ""

## Base stats before any accessory bonuses.
##   speed      — tiles moved per second (used when tile movement is added).
##   resilience — toughness pool; affects future stamina / hazard systems.
##   forage     — bonus chance of finding rare items while exploring.
## All values are plain integers. Use CreatureData.get_stat() to include bonuses.
var base_stats: Dictionary = {}

# ── Factory ───────────────────────────────────────────────────────────────────

static func from_dict(d: Dictionary) -> CreatureDef:
	var c := CreatureDef.new()
	c.id               = d.get("id", "")
	c.display_name     = d.get("display_name", "")
	c.description      = d.get("description", "")
	c.stage            = d.get("stage", 1)
	c.evolution_level  = d.get("evolution_level", 999) if d.get("evolution_level") != null else 999
	c.evolution_item_id = d.get("evolution_item_id", "") if d.get("evolution_item_id") != null else ""
	c.evolved_form_id  = d.get("evolved_form_id", "") if d.get("evolved_form_id") != null else ""
	c.base_stats       = d.get("base_stats", {}).duplicate()
	return c

# ── Helpers ───────────────────────────────────────────────────────────────────

## True when this form can still evolve further.
func can_evolve() -> bool:
	return not evolved_form_id.is_empty()

## Raw base stat value. Prefer CreatureData.get_stat() for in-game reads.
func base_stat(name: String) -> int:
	return base_stats.get(name, 0)
