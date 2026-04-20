## Typed schema for one entry in data/foods.json.
## Food is collected by walking into pickup nodes in ExploreScene
## and consumed via the InventoryPanel to grant EXP to the creature.
class_name FoodDef
extends RefCounted

## Primary key. Used as the dictionary key in PlayerData.inventory.
var id: String = ""

## Name shown in the inventory panel list and any tooltip.
var display_name: String = ""

## One-line flavour description. Shown when the item row is selected/hovered.
var description: String = ""

## EXP granted to the creature when this food is fed via InventoryPanel.
## Calibrated against the flat curve in ExpSystem (150 EXP per level):
##   common   → 30  EXP  (~5 feeds per level)
##   uncommon → 60  EXP  (~2–3 feeds per level)
##   rare     → 100 EXP  (~1–2 feeds per level)
var exp_value: int = 0

## Spawn weight category for map node placement.
## "common"   — 4 nodes per map sweep
## "uncommon" — 2 nodes per map sweep
## "rare"     — 1 node per map sweep
## ExploreScene reads this to place nodes; DataLoader does not filter by it.
var rarity: String = "common"

# ── Factory ───────────────────────────────────────────────────────────────────

static func from_dict(d: Dictionary) -> FoodDef:
	var f := FoodDef.new()
	f.id           = d.get("id", "")
	f.display_name = d.get("display_name", "")
	f.description  = d.get("description", "")
	f.exp_value    = d.get("exp_value", 0)
	f.rarity       = d.get("rarity", "common")
	return f

# ── Helpers ───────────────────────────────────────────────────────────────────

## True for the most impactful tier — used to show a "rare!" badge in UI.
func is_rare() -> bool:
	return rarity == "rare"
