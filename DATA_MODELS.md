# Data Models

All game data lives in `data/*.json`. These files are read-only at runtime.
Runtime state lives in `GameState` (autoload) and is persisted to `save/save.json`.

---

## 1. Player

Stored in `GameState.player` (runtime) and serialised to save file.

```json
{
  "name": "Kael",
  "gender": "boy",
  "age_stage": 0,
  "inventory": {
    "berrysprig": 3,
    "sunmoss": 1,
    "moonstone_shard": 1
  }
}
```

| Field | Type | Notes |
|---|---|---|
| `name` | string | entered by player at character select |
| `gender` | string | `"boy"` or `"girl"`, cosmetic only |
| `age_stage` | int | always `0` in MVP |
| `inventory` | dict | item_id → count |

---

## 2. Creature (runtime instance)

Stored in `GameState.creature`. Initialised from `data/creatures.json` on selection.

```json
{
  "id": "frogling",
  "stage": 1,
  "level": 1,
  "exp": 0,
  "evolved": false
}
```

| Field | Type | Notes |
|---|---|---|
| `id` | string | links to creatures.json definition |
| `stage` | int | `1` or `2` |
| `level` | int | 1–10 in MVP |
| `exp` | int | current EXP within this level |
| `evolved` | bool | true after evolution scene |

---

## 3. Creature Definition (`data/creatures.json`)

Static config. Never modified at runtime.

```json
[
  {
    "id": "frogling",
    "display_name": "Frogling",
    "description": "A calm, damp creature that thrives near mossy pools.",
    "stage": 1,
    "evolution_level": 10,
    "evolution_item_id": "moonstone_shard",
    "evolved_form_id": "marshwarden",
    "base_stats": {
      "speed": 3,
      "resilience": 4,
      "forage": 5
    }
  },
  {
    "id": "marshwarden",
    "display_name": "Marshwarden",
    "description": "Ancient and still. Its presence calms the forest.",
    "stage": 2,
    "evolution_level": null,
    "evolution_item_id": null,
    "evolved_form_id": null,
    "base_stats": {
      "speed": 4,
      "resilience": 7,
      "forage": 8
    }
  },
  {
    "id": "embkit",
    "display_name": "Embkit",
    "description": "A restless spark that singes the grass it runs across.",
    "stage": 1,
    "evolution_level": 10,
    "evolution_item_id": "moonstone_shard",
    "evolved_form_id": "cinderhorn",
    "base_stats": {
      "speed": 6,
      "resilience": 2,
      "forage": 4
    }
  },
  {
    "id": "cinderhorn",
    "display_name": "Cinderhorn",
    "description": "Swift and bold. Its horns glow when excited.",
    "stage": 2,
    "evolution_level": null,
    "evolution_item_id": null,
    "evolved_form_id": null,
    "base_stats": {
      "speed": 9,
      "resilience": 4,
      "forage": 5
    }
  },
  {
    "id": "puffmote",
    "display_name": "Puffmote",
    "description": "Round, floaty, and unexpectedly resilient.",
    "stage": 1,
    "evolution_level": 10,
    "evolution_item_id": "moonstone_shard",
    "evolved_form_id": "galehallow",
    "base_stats": {
      "speed": 4,
      "resilience": 5,
      "forage": 3
    }
  },
  {
    "id": "galehallow",
    "display_name": "Galehallow",
    "description": "Drifts silently through the canopy, scattering seeds.",
    "stage": 2,
    "evolution_level": null,
    "evolution_item_id": null,
    "evolved_form_id": null,
    "base_stats": {
      "speed": 6,
      "resilience": 7,
      "forage": 6
    }
  }
]
```

---

## 4. Food (`data/foods.json`)

```json
[
  {
    "id": "berrysprig",
    "display_name": "Berry Sprig",
    "description": "Small red berries on a thin branch.",
    "exp_value": 30,
    "rarity": "common"
  },
  {
    "id": "sunmoss",
    "display_name": "Sun Moss",
    "description": "Warm, golden moss that grows on sunlit stones.",
    "exp_value": 60,
    "rarity": "uncommon"
  },
  {
    "id": "dewdrop_vial",
    "display_name": "Dewdrop Vial",
    "description": "A tiny glass vial of morning dew. Potent.",
    "exp_value": 100,
    "rarity": "rare"
  }
]
```

---

## 5. Evolution Items (`data/evolution_items.json`)

```json
[
  {
    "id": "moonstone_shard",
    "display_name": "Moonstone Shard",
    "description": "A fragment of pale stone that pulses faintly in the dark.",
    "found_in_area": "whispering_grove"
  }
]
```

---

## 6. Area (`data/areas.json`)

```json
[
  {
    "id": "whispering_grove",
    "display_name": "Whispering Grove",
    "description": "A dense forest of silver-barked trees. Quiet, but watching.",
    "unlock_condition": null,
    "food_nodes": [
      { "food_id": "berrysprig", "count": 4 },
      { "food_id": "sunmoss",    "count": 2 },
      { "food_id": "dewdrop_vial", "count": 1 }
    ],
    "evolution_item_node": "moonstone_shard",
    "story_event_trigger": "story_event_1"
  }
]
```

---

## 7. Story Events (`data/story_events.json`)

```json
[
  {
    "id": "story_event_1",
    "trigger_condition": {
      "creature_evolved": true
    },
    "dialogue": [
      "The Grove stirs. The trees lean inward.",
      "An elder figure emerges from the mist.",
      "\"You have cared well. Your companion has answered.\"",
      "\"The wilds beyond await — when you are ready.\"",
      "The path forward shimmers, then fades.",
      "[ To be continued... ]"
    ],
    "grants_item": null,
    "unlocks_area": null,
    "advances_player_age": false
  }
]
```

---

## 8. Save File (`save/save.json`)

Written by `SaveSystem.gd`. Contains full runtime state.

```json
{
  "version": 1,
  "player": {
    "name": "Kael",
    "gender": "boy",
    "age_stage": 0,
    "inventory": {
      "berrysprig": 1
    }
  },
  "creature": {
    "id": "frogling",
    "stage": 1,
    "level": 6,
    "exp": 90,
    "evolved": false
  },
  "world": {
    "current_area": "whispering_grove",
    "collected_nodes": ["food_node_0", "food_node_2"],
    "story_events_seen": []
  }
}
```

---

## EXP Curve (MVP)

Flat curve for simplicity. Easy to replace later.

```
exp_required_for_next_level = 150
total_exp_to_reach_level_10 = 150 * 9 = 1350
```

Food values against this curve:

| Food | EXP | Feeds to max |
|---|---|---|
| Berry Sprig (×4) | 30 | 4 × 30 = 120 |
| Sun Moss (×2) | 60 | 2 × 60 = 120 |
| Dewdrop Vial (×1) | 100 | 1 × 100 = 100 |
| **Total available** | | **340 EXP** |

340 EXP covers ~2.3 levels per full map sweep. Player needs ~4 sweeps to reach level 10.
Food nodes respawn after the player exits and re-enters the area (one respawn allowed in MVP).
