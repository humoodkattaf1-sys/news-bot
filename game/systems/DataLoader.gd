class_name DataLoader

const _PATHS: Dictionary = {
	"creatures":        "res://data/creatures.json",
	"foods":            "res://data/foods.json",
	"evolution_items":  "res://data/evolution_items.json",
	"clothing":         "res://data/clothing.json",
	"areas":            "res://data/areas.json",
	"story_events":     "res://data/story_events.json",
	"growth_stages":    "res://data/growth_stages.json",
}

static var _cache: Dictionary = {}

# ── Creature ──────────────────────────────────────────────────────────────────

static func get_creature(id: String) -> Dictionary:
	return _find(_load("creatures"), id)

static func get_all_creatures() -> Array:
	return _load("creatures")

## Returns only stage-1 creatures that have an evolution path.
## Used by CreatureSelectScene to populate the starter list.
static func get_starter_creatures() -> Array:
	return _load("creatures").filter(
		func(c: Dictionary) -> bool:
			return c.get("stage", 1) == 1 and c.get("evolution_level") != null
	)

# ── Food ──────────────────────────────────────────────────────────────────────

static func get_food(id: String) -> Dictionary:
	return _find(_load("foods"), id)

static func get_all_foods() -> Array:
	return _load("foods")

# ── Evolution items ───────────────────────────────────────────────────────────

static func get_evolution_item(id: String) -> Dictionary:
	return _find(_load("evolution_items"), id)

# ── Clothing ──────────────────────────────────────────────────────────────────

static func get_clothing(id: String) -> Dictionary:
	return _find(_load("clothing"), id)

static func get_all_clothing() -> Array:
	return _load("clothing")

## Returns clothing available to the protagonist (not creature accessories).
static func get_protagonist_clothing() -> Array:
	return _load("clothing").filter(
		func(c: Dictionary) -> bool: return not c.get("is_creature_accessory", false)
	)

## Returns clothing wearable by the creature.
static func get_creature_accessories() -> Array:
	return _load("clothing").filter(
		func(c: Dictionary) -> bool: return c.get("is_creature_accessory", false)
	)

# ── Areas ─────────────────────────────────────────────────────────────────────

static func get_area(id: String) -> Dictionary:
	return _find(_load("areas"), id)

# ── Story events ──────────────────────────────────────────────────────────────

static func get_story_event(id: String) -> Dictionary:
	return _find(_load("story_events"), id)

# ── Growth stages ─────────────────────────────────────────────────────────────

## Returns the stage definition whose "stage" integer matches the given index.
static func get_growth_stage(stage: int) -> Dictionary:
	for entry: Dictionary in _load("growth_stages"):
		if entry.get("stage") == stage:
			return entry
	push_warning("DataLoader: growth stage %d not found" % stage)
	return {}

static func get_all_growth_stages() -> Array:
	return _load("growth_stages")

# ── Internal ──────────────────────────────────────────────────────────────────

static func _load(key: String) -> Array:
	if _cache.has(key):
		return _cache[key]
	var path: String = _PATHS.get(key, "")
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DataLoader: cannot open '%s'" % path)
		return []
	var parsed := JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not parsed is Array:
		push_error("DataLoader: invalid JSON in '%s'" % path)
		return []
	_cache[key] = parsed
	return parsed

static func _find(arr: Array, id: String) -> Dictionary:
	for entry: Dictionary in arr:
		if entry.get("id", "") == id:
			return entry
	push_warning("DataLoader: id '%s' not found" % id)
	return {}
