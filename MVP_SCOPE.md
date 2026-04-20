# MVP Scope

## Goal
A playable vertical slice: one region, one creature arc (select → raise → evolve), one story beat.
Completable in 15–20 minutes. Demonstrates every system in the core loop.

---

## IN SCOPE

### Protagonist
- [ ] Choose gender (boy / girl) — cosmetic only for MVP
- [ ] Enter a name (text input)
- [ ] Single age stage: Child (no progression in MVP)

### Creatures
- [ ] 3 starter creatures to choose from
- [ ] Each has a display name, flavour description, and 3 base stats: `speed`, `resilience`, `forage`
- [ ] Creature shown as companion in explore scene (follows player)
- [ ] Level 1–10 range for MVP
- [ ] 1 evolution per creature (stage 1 → stage 2) at level 10 + evolution item

### Region
- [ ] 1 region: Whispering Grove
- [ ] Simple tile-based map (placeholder tiles acceptable)
- [ ] 5–8 food resource nodes scattered across the map
- [ ] 1 hidden evolution item node

### Food & Inventory
- [ ] 3 food types in this region, different EXP values
- [ ] Walk into node to collect (no interaction prompt needed)
- [ ] Inventory panel (toggle key) shows held items and counts
- [ ] Feed action: open inventory → select food → creature gains EXP

### EXP & Leveling
- [ ] EXP bar visible in HUD at all times
- [ ] Level-up message shown on screen
- [ ] EXP curve: flat for MVP (150 EXP per level)

### Evolution
- [ ] Evolution available when: level >= 10 AND evolution item in inventory
- [ ] Player must walk to a designated Evolution Stone in the map to trigger
- [ ] Evolution scene: short text + visual change (sprite swap)
- [ ] Stats increase shown before/after

### Story
- [ ] 1 story event: triggered after evolution
- [ ] Displayed as a dialogue cutscene (text panels, press to advance)
- [ ] Ends with "To be continued…" screen

### Save System
- [ ] Auto-save to a single JSON file on scene transitions
- [ ] Load save on boot if file exists
- [ ] New Game option clears save

---

## OUT OF SCOPE (MVP)

| Feature | Deferred to |
|---|---|
| Multiple regions | Post-MVP |
| Protagonist age stages | Post-MVP |
| Clothing / accessories | Post-MVP |
| Combat system | Post-MVP |
| Multiple save slots | Post-MVP |
| Sound and music | Post-MVP |
| Animated sprites | Post-MVP |
| Creature abilities | Post-MVP |
| Multiple evolutions per creature | Post-MVP |
| Day/night cycle | Post-MVP |

---

## Done Definition
MVP is complete when a player can:
1. Start a new game
2. Choose protagonist and starter creature
3. Explore the region and collect food
4. Feed the creature to reach level 10
5. Find and collect the evolution item
6. Evolve the creature
7. See the story cutscene
8. Reach the "To be continued" screen
9. Quit and reload with progress intact
