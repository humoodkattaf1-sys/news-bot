## Typed schema for one entry in data/clothing.json.
## Clothing provides flat stat bonuses while equipped.
## Two slots exist: one protagonist outfit, one creature accessory.
## In MVP, items are granted by story events. Post-MVP: discoverable in the world.
class_name ClothingDef
extends RefCounted

## Primary key. Stored in PlayerData.equipped_clothing and StoryState.unlocked_clothing.
var id: String = ""

## Name shown in the equipment menu and inventory.
var display_name: String = ""

## Flavour text describing the item's look or origin.
var description: String = ""

## Determines which equipment slot this item occupies.
##   false → protagonist outfit slot (affects forage via clothing_bonuses)
##   true  → creature accessory slot (affects speed / resilience / forage via bonus_stats)
## Only one item of each type can be equipped at a time.
var is_creature_accessory: bool = false

## Flat bonuses applied while this item is equipped.
## Keys must match CreatureDef.base_stats keys: "speed", "resilience", "forage".
## Protagonist clothing bonuses go into PlayerData.clothing_bonuses.
## Creature accessory bonuses go into CreatureData.bonus_stats.
## Both are recalculated by InventorySystem.recalc_clothing_bonuses().
var stat_bonus: Dictionary = {}

## Story event ID that must have fired before this item is available to the player.
## Empty string = available from the start (no restriction).
## Checked by StorySystem when processing a StoryEventDef.unlocks_clothing list.
var unlock_condition: String = ""

# ── Factory ───────────────────────────────────────────────────────────────────

static func from_dict(d: Dictionary) -> ClothingDef:
	var c := ClothingDef.new()
	c.id                    = d.get("id", "")
	c.display_name          = d.get("display_name", "")
	c.description           = d.get("description", "")
	c.is_creature_accessory = d.get("is_creature_accessory", false)
	c.stat_bonus            = d.get("stat_bonus", {}).duplicate()
	c.unlock_condition      = d.get("unlock_condition", "")
	return c

# ── Helpers ───────────────────────────────────────────────────────────────────

## Returns the bonus for a named stat, or 0 if this item does not affect it.
func bonus_for(stat_name: String) -> int:
	return stat_bonus.get(stat_name, 0)
