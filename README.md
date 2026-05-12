# Better Runs

A quality-of-life mod for **The Binding of Isaac: Repentance+** that improves the run experience.

## Features

- [x] **Guaranteed angel room after skipping devil room** — if a devil room door appears and you ignore it, the next deal room on any subsequent floor is guaranteed to be an angel room (provided the normal no-red-heart-damage condition is met).
- [x] **Item quality filter for Tainted Lost** — tier 0 and tier 1 items never appear on pedestals for Tainted Lost. If Tainted Lost holds item 691, tier 2 items are also blocked. When a disqualified item would appear, it is rerolled from the same pool for a qualifying replacement.
- [x] **Price discount** — items priced at 30 or 99 coins (Greed mode shops, The Stairway angel shops) are reduced to 15 coins. Applies to items like Sacred Heart, R Key, and other high-tier shop items.
- [x] **Shop pool expansion** — adds Breakfast (3), Jesus Juice (25), ID 197, 20/20 (245), Spoon Bender (444), Consolation Prize (586), Sausage (669), and Stapler (708) to the shop item pool.
- [x] **Secret room improvements** — adds 9 items to the secret room pool (Rosary, The Halo, Ouija Board, Polyphemus, Abaddon, Jacob's Ladder, Little Horn, Immaculate Heart, C Section) and raises the chance of secret rooms containing an item pedestal from ~21% to ~50% via 16 additional room layouts.

## Changelog

### [0.5.0] — 2026-05-11

- **Secret room improvements:** added 9 items to the secret room pool via `content/itempools.xml`. Added 16 new secret room layouts with item pedestals via `resources/rooms/00.special rooms.stb`, raising the item-pedestal probability from ~21% to ~50%. Variant IDs 2000–2015 to avoid collision with vanilla (0–38) and other mods.

### [0.4.0] — 2026-05-11

- **Shop pool expansion:** added 8 items to the shop pool via `content/itempools.xml`.

### [0.3.0] — 2026-05-11

- **Price discount:** collectibles priced at 30 or 99 coins are automatically reduced to 15. Covers Greed mode shops and The Stairway (item 586) angel shops.

### [0.2.0] — 2026-05-11

- Refactored into a modular feature system (`features/` directory).
- **Item quality filter:** Tainted Lost cannot receive items below quality 2 (tiers 0-1). Holding item 691 raises the floor to quality 3 (tiers 0-2 also blocked). Rerolls from the same pool on pedestal spawn.

### [0.1.0] — 2026-05-11

- Initial release.
- **Guaranteed angel room:** skipping a devil room sets a persistent flag that converts the next devil room door into an angel room door. The guarantee carries across floors until a deal room actually appears, and resets on death, victory, or a new run.

### [Unreleased]

_Nothing yet._

---

## How "guaranteed angel room" works

| Situation | Result |
|---|---|
| Devil room door appears, you skip it | Next deal room is guaranteed angel |
| You enter the devil room (any item or not) | Guarantee is **not** triggered |
| No deal room this floor (red heart damage taken) | Guarantee carries to the next floor |
| Angel room appears naturally | Guarantee is consumed, no change |
| You die or win | Guarantee resets |

The no-red-heart-damage condition for deal rooms still applies as normal. This mod only changes **which type** (devil vs angel) appears, not **whether** it appears.

---

## Installation

1. Copy the `better-runs` folder into your mods directory:
   ```
   C:\Program Files (x86)\Steam\steamapps\common\The Binding of Isaac Rebirth\mods\
   ```
2. Launch the game and enable the mod from the **Mods** menu.

## Development

- **Language:** Lua 5.3
- **Target DLC:** Repentance / Repentance+
- **API docs:** https://wofsauge.github.io/IsaacDocs/rep/

Enable the in-game debug console by adding `debug=1` to `options.ini`, then press `~` in-game.
