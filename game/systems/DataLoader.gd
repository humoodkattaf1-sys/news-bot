class_name DataLoader

const _PATHS: Dictionary = {
	"creatures":        "res://data/creatures.json",
	"foods":            "res://data/foods.json",
	"evolution_items":  "res://data/evolution_items.json",
	"areas":            "res://data/areas.json",
	"story_events":     "res://data/story_events.json",
}

static var _cache: Dictionary = {}

# ── Public getters ────────────────────────────────────────────────────────────

static func get_creature(id: String) -> Dictionary:
	return _find(_load("creatures"), id)

static func get_food(id: String) -> Dictionary:
	return _find(_load("foods"), id)

static func get_evolution_item(id: String) -> Dictionary:
	return _find(_load("evolution_items"), id)

static func get_area(id: String) -> Dictionary:
	return _find(_load("areas"), id)

static func get_story_event(id: String) -> Dictionary:
	return _find(_load("story_events"), id)

static func get_all_creatures() -> Array:
	return _load("creatures")

static func get_starter_creatures() -> Array:
	return _load("creatures").filter(
		func(c: Dictionary) -> bool:
			return c.get("stage", 1) == 1 and c.get("evolution_level") != null
	)

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
