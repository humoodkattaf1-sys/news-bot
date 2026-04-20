# Core Loop

## Primary Loop (per session)

```
LAUNCH
  │
  ├─ Save exists?
  │     YES → Load save → go to Explore Scene
  │     NO  → Title Screen → Character Select → Creature Select
  │
  ▼
EXPLORE SCENE  ←─────────────────────────┐
  │                                       │
  ├─ Walk around region                   │
  ├─ Collect food nodes (auto on contact) │
  ├─ Open inventory (I key)               │
  │     └─ Select food → Feed creature    │
  │           └─ Creature gains EXP       │
  │                 └─ EXP bar fills      │
  │                       └─ Level up?    │
  │                             YES → Level Up message shown
  │                             NO  → continue exploring ──┘
  │
  ├─ Reached level 10?
  │     NO  → keep exploring
  │     YES → evolution item collected?
  │               NO  → hint text: "Find the evolution stone"
  │               YES → walk to Evolution Stone node
  │                       └─ EVOLUTION SCENE
  │                             └─ Creature evolves (stage 1 → 2)
  │                                   └─ Stats update shown
  │                                         └─ STORY SCENE
  │                                               └─ Dialogue plays
  │                                                     └─ END SCREEN
  │                                                         "To be continued"
  │
  └─ AUTO-SAVE on every scene transition
```

---

## Secondary Loop (within Explore Scene)

```
Player enters region
  │
  ├─ Food nodes visible on map (sprite icons)
  │     Walk into node → collected → removed from map → added to inventory
  │
  ├─ Evolution item node visible but unreachable until level 10
  │     (or: visible always but evolution trigger blocked by gate check)
  │
  └─ Creature companion
        Follows player at offset
        HUD shows: creature name | level | EXP bar
```

---

## Feed Loop (within Explore Scene)

```
Player presses I → Inventory panel opens
  │
  ├─ Shows: item name | count | EXP value
  │
  └─ Player selects food item
        │
        └─ ExpSystem.apply_exp(creature, food.exp_value)
              │
              ├─ EXP added
              ├─ Level up check
              │     YES → creature.level += 1, show message
              └─ Inventory count decremented
                    └─ Panel refreshes
```

---

## Evolution Gate Logic

```
EvolutionSystem.can_evolve(creature, inventory):
  return (
    creature.level >= creature.evolution_level        # level gate
    AND inventory.has(creature.evolution_item_id)     # item gate
  )
```

Evolution is only triggered when the player walks to the Evolution Stone node.
The stone node runs `can_evolve()` on contact and either triggers the scene or
shows a "not ready" message.

---

## Story Trigger Logic

```
StorySystem.check_trigger(event_id, game_state):
  event = load story_events.json[event_id]
  return all conditions in event.trigger_condition are met in game_state
```

For MVP: story_event_1 triggers when `creature_evolved == true`.
Triggered automatically at the end of the Evolution Scene.

---

## Scene Flow

```
TitleScene
  └─ CharacterSelectScene
        └─ CreatureSelectScene
              └─ ExploreScene  ←── main gameplay, looping
                    └─ EvolutionScene
                          └─ StoryScene
                                └─ EndScreen
```

Each scene transition auto-saves GameState to save/save.json.
