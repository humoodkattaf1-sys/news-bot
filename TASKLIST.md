# Task List

Status key: `[ ]` todo · `[~]` in progress · `[x]` done

---

## Step 1 — Project Scaffold & Engine Core
- [ ] Create Godot 4 project (`project.godot`)
- [ ] Set up folder structure: `scenes/`, `systems/`, `entities/`, `data/`, `autoloads/`, `save/`, `assets/`
- [ ] Create `autoloads/SceneManager.gd` — push/pop scene stack, `change_scene(path)`
- [ ] Create `autoloads/GameState.gd` — holds player + creature runtime data
- [ ] Create `autoloads/SaveSystem.gd` — `save()`, `load()`, `clear()`
- [ ] Register all three autoloads in `project.godot`
- [ ] Create `engine/InputHandler.gd` (if needed, or rely on Godot Input map)
- [ ] Define Input Map actions: `move_up/down/left/right`, `open_inventory`, `interact`, `confirm`, `back`
- [ ] Confirm project runs to a blank window

## Step 2 — Data Files
- [ ] Write `data/creatures.json` (6 entries: 3 stage-1 + 3 stage-2)
- [ ] Write `data/foods.json` (3 entries)
- [ ] Write `data/evolution_items.json` (1 entry)
- [ ] Write `data/areas.json` (1 entry)
- [ ] Write `data/story_events.json` (1 entry)
- [ ] Create `systems/DataLoader.gd` — `get_creature(id)`, `get_food(id)`, `get_area(id)`, `get_story_event(id)`
- [ ] Test DataLoader returns correct dicts in a test scene

## Step 3 — Entities
- [ ] Create `entities/PlayerData.gd` (plain class, no Node): name, gender, age_stage, inventory dict
- [ ] Create `entities/CreatureData.gd` (plain class, no Node): id, stage, level, exp, evolved
- [ ] Add `to_dict()` and `from_dict()` methods to both for save/load
- [ ] Wire PlayerData and CreatureData into GameState

## Step 4 — Title & Character Select Scenes
- [ ] Create `scenes/TitleScene.tscn` — game title, Start button, Load button (if save exists)
- [ ] Create `scenes/CharacterSelectScene.tscn` — gender toggle (Boy/Girl), name text input, Confirm button
- [ ] On confirm: write name + gender to `GameState.player`, transition to CreatureSelect
- [ ] New Game clears save file before starting

## Step 5 — Creature Select Scene
- [ ] Create `scenes/CreatureSelectScene.tscn`
- [ ] Show 3 starter creature cards: name, description, stats (speed / resilience / forage)
- [ ] Highlight selected card on click/arrow key
- [ ] Confirm button: write creature to `GameState.creature`, transition to ExploreScene
- [ ] Only show stage-1 creatures (filter by `stage == 1` and `evolution_level != null`)

## Step 6 — Explore Scene
- [ ] Create `scenes/ExploreScene.tscn`
- [ ] Place `TileMapLayer` node with placeholder tiles (floor + wall)
- [ ] Create `entities/Player.tscn` (CharacterBody2D) with 4-directional movement
- [ ] Create `entities/CreatureCompanion.tscn` (Node2D) — follows player at offset
- [ ] Spawn 4× Berry Sprig, 2× Sun Moss, 1× Dewdrop Vial as `Area2D` pickup nodes
- [ ] Spawn 1× Moonstone Shard as `Area2D` pickup node
- [ ] Spawn 1× Evolution Stone trigger node (Area2D, always present)
- [ ] On pickup contact: add item to `GameState.player.inventory`, remove node from scene
- [ ] Persist `collected_nodes` list so respawned map doesn't re-add collected items
- [ ] Allow one map respawn (reset `collected_nodes` after first full clear)
- [ ] HUD: creature name, level, EXP bar (ProgressBar node), inventory item count

## Step 7 — Inventory & Feed System
- [ ] Create `systems/InventorySystem.gd` — `add(item_id)`, `remove(item_id)`, `has(item_id)`, `count(item_id)`
- [ ] Create `scenes/InventoryPanel.tscn` (CanvasLayer) — list of items, EXP value shown, select to feed
- [ ] Toggle panel with `open_inventory` action
- [ ] On feed: call `ExpSystem.apply_exp(creature, food.exp_value)`, decrement inventory
- [ ] Panel refreshes after each feed
- [ ] Create `systems/ExpSystem.gd` — `apply_exp(creature, amount)`, `exp_to_next(level)`, `check_level_up(creature)`
- [ ] Level-up: increment level, reset exp, show on-screen "Level Up!" message for 2 seconds

## Step 8 — Evolution System
- [ ] Create `systems/EvolutionSystem.gd` — `can_evolve(creature, inventory)`, `do_evolve(creature)`
- [ ] `can_evolve`: returns true if level >= evolution_level AND item in inventory
- [ ] Evolution Stone node: on player contact, run `can_evolve()`
  - [ ] Not ready: show floating hint text ("Your creature is not ready yet")
  - [ ] Ready: transition to EvolutionScene
- [ ] Create `scenes/EvolutionScene.tscn`
  - [ ] Show stage-1 creature name + stats
  - [ ] Short pause / flash animation (Tween)
  - [ ] Swap to stage-2 creature data via `do_evolve()`
  - [ ] Show stage-2 creature name + updated stats
  - [ ] Press confirm → transition to StoryScene
- [ ] `do_evolve`: update `GameState.creature` id to `evolved_form_id`, set `stage = 2`, set `evolved = true`, remove evolution item from inventory

## Step 9 — Story Scene & End Screen
- [ ] Create `scenes/StoryScene.tscn`
  - [ ] CanvasLayer with dark background
  - [ ] RichTextLabel for dialogue lines
  - [ ] Press confirm to advance to next line
  - [ ] Last line advances to EndScreen
- [ ] Load dialogue from `story_events.json` via `StorySystem.get_event("story_event_1")`
- [ ] Create `systems/StorySystem.gd` — `get_event(id)`, `mark_seen(id)`
- [ ] Create `scenes/EndScreen.tscn` — "To be continued…" text, Return to Title button

## Step 10 — Save & Load
- [ ] `SaveSystem.save()`: serialise `GameState.player.to_dict()`, `GameState.creature.to_dict()`, world state → write to `save/save.json`
- [ ] `SaveSystem.load()`: read file, deserialise, populate GameState
- [ ] `SaveSystem.exists()`: returns bool
- [ ] Auto-save on every scene transition (call from SceneManager)
- [ ] Title screen: show Load button only if `SaveSystem.exists()` is true
- [ ] New Game button: call `SaveSystem.clear()` then start fresh

---

## Milestone Summary

| Milestone | Steps | Status |
|---|---|---|
| M1 — Foundation | 1 | `[ ]` |
| M2 — Data & Entities | 2, 3 | `[ ]` |
| M3 — Select Screens | 4, 5 | `[ ]` |
| M4 — Explore Loop | 6, 7 | `[ ]` |
| M5 — Evolution | 8 | `[ ]` |
| M6 — Story & End | 9 | `[ ]` |
| M7 — Save / Load | 10 | `[ ]` |

---

## Post-MVP Backlog (do not implement now)

- Second region (Saltwind Coast)
- Protagonist age stage (Child → Teen) triggered by story flag
- Clothing items with `forage` / `speed` stat bonuses
- Creature accessories slot
- Sound effects and background music
- Animated creature sprites
- Multiple save slots
- Combat system (turn-based or real-time avoidance)
- Creature abilities unlocked at stage 2
