class_name CreatureData
extends RefCounted

## Matches "id" in data/creatures.json.
## Swapped to the definition's evolved_form_id when EvolutionSystem.do_evolve() runs.
var creature_id: String = ""

## Evolution stage. 1 = base form, 2 = evolved form.
## Maximum is 2 in MVP. Extend the JSON and this cap for post-MVP chains.
var stage: int = 1

## Current level within this stage. Range 1–10 in MVP.
## Resets to 1 when evolving to a new stage (creature_id swap means fresh start).
var level: int = 1

## EXP accumulated toward the next level.
## Resets to 0 after each level-up via ExpSystem.apply_exp().
## Never stored above ExpSystem.exp_to_next(level) — any overflow carries forward.
var exp: int = 0

## Set to true by EvolutionSystem.do_evolve() after the evolution scene plays.
## Guards the Evolution Stone trigger so it cannot fire a second time.
var evolved: bool = false

## Flat bonus stats from the creature's equipped accessory (ClothingDef.is_creature_accessory).
## Keys match base_stats keys in the definition: "speed", "resilience", "forage".
## Recalculated by InventorySystem.recalc_clothing_bonuses() on equip change.
## In MVP populated via story grants (post-MVP: equip screen).
var bonus_stats: Dictionary = {}

# ── Computed stat access ──────────────────────────────────────────────────────

## Returns base stat from the JSON definition plus any active accessory bonus.
## Use this everywhere stats are displayed or evaluated — never read base_stats raw.
func get_stat(stat_name: String) -> int:
	var def  := DataLoader.get_creature(creature_id)
	var base := def.get("base_stats", {}).get(stat_name, 0) as int
	return base + bonus_stats.get(stat_name, 0)

# ── Serialisation ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"id":          creature_id,
		"stage":       stage,
		"level":       level,
		"exp":         exp,
		"evolved":     evolved,
		"bonus_stats": bonus_stats.duplicate(),
	}

static func from_dict(data: Dictionary) -> CreatureData:
	var c := CreatureData.new()
	c.creature_id = data.get("id", "")
	c.stage       = data.get("stage", 1)
	c.level       = data.get("level", 1)
	c.exp         = data.get("exp", 0)
	c.evolved     = data.get("evolved", false)
	c.bonus_stats = data.get("bonus_stats", {}).duplicate()
	return c
