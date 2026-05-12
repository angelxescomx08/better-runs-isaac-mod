# Better Runs

A quality-of-life mod for **The Binding of Isaac: Repentance+** that improves the run experience.

## Features

- [x] **Guaranteed angel room after skipping devil room** — if a devil room door appears and you ignore it, the next deal room on any subsequent floor is guaranteed to be an angel room (provided the normal no-red-heart-damage condition is met).

## Changelog

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
