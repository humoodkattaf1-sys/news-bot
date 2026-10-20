## Typed schema for one entry in data/evolution_items.json.
## One evolution item is hidden per region. Collecting it satisfies the item gate
## in EvolutionSystem.can_evolve(), alongside the level gate.
class_name EvolutionItemDef
extends RefCounted

## Primary key. Must match the "evolution_item_id" field of the creature(s) it unlocks.
## Multiple creatures in a region can share the same evolution item (MVP: all share
## "moonstone_shard"), keeping the gather loop simple.
var id: String = ""

## Name shown in the inventory panel.
## Should feel rare and meaningful — it is a one-per-region, non-stackable item.
var display_name: String = ""

## Atmospheric description shown when the item is inspected.
## Hints at the transformation without spelling it out.
var description: String = ""

## Area ID where this item's pickup node is placed.
## Constrains evolution to the correct region — a player cannot evolve early
## by carrying the item across areas (future: area-locked flag on the node).
var found_in_area: String = ""

# ── Factory ───────────────────────────────────────────────────────────────────

static func from_dict(d: Dictionary) -> EvolutionItemDef:
	var e := EvolutionItemDef.new()
	e.id            = d.get("id", "")
	e.display_name  = d.get("display_name", "")
	e.description   = d.get("description", "")
	e.found_in_area = d.get("found_in_area", "")
	return e
