class_name PlayerData
extends RefCounted

## Display name entered at character select.
## Defaults to "Traveller" if left blank.
var player_name: String = ""

## "boy" or "girl".
## Cosmetic only in MVP. Future use: gate gender-specific dialogue variants.
var gender: String = "boy"

## Protagonist age stage index.
## 0 = Child (only stage in MVP).
## Advances by 1 when a StoryEvent with advances_player_age = true fires.
## Future stages: 0 = Child, 1 = Teen, 2 = Young Adult.
var age_stage: int = 0

## Flat item store: item_id → count.
## Holds food, evolution items, and key items in one dict.
## Do not access directly — use InventorySystem helpers.
var inventory: Dictionary = {}

## List of equipped clothing item IDs (max 2):
##   index 0 = protagonist outfit  (ClothingDef.is_creature_accessory == false)
##   index 1 = creature accessory  (ClothingDef.is_creature_accessory == true)
## Empty slots are simply absent from the array.
## Managed by EquipSystem (post-MVP). In MVP, populated via story grants.
var equipped_clothing: Array = []

## Cached sum of stat bonuses from all equipped clothing.
## Keys match creature stat keys: "speed", "resilience", "forage".
## Recalculated by InventorySystem.recalc_clothing_bonuses() on any equip change.
## Read by ExpSystem and ExploreScene when applying forage bonuses.
var clothing_bonuses: Dictionary = {}

# ── Inventory helpers ─────────────────────────────────────────────────────────

func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + amount

func remove_item(item_id: String, amount: int = 1) -> bool:
	if not has_item(item_id, amount):
		return false
	inventory[item_id] -= amount
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount

func item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

# ── Serialisation ─────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"name":             player_name,
		"gender":           gender,
		"age_stage":        age_stage,
		"inventory":        inventory.duplicate(),
		"equipped_clothing": equipped_clothing.duplicate(),
		"clothing_bonuses": clothing_bonuses.duplicate(),
	}

static func from_dict(data: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.player_name       = data.get("name", "")
	p.gender            = data.get("gender", "boy")
	p.age_stage         = data.get("age_stage", 0)
	p.inventory         = data.get("inventory", {}).duplicate()
	p.equipped_clothing = data.get("equipped_clothing", []).duplicate()
	p.clothing_bonuses  = data.get("clothing_bonuses", {}).duplicate()
	return p
