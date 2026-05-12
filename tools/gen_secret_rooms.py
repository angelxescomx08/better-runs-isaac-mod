"""
Generates additional secret room layouts with item pedestals and writes them
to the mod's resources/rooms folder as 00.special rooms.stb.

The game merges the mod's STB with vanilla — our file only adds NEW rooms.
Vanilla secret rooms have ~21% item-pedestal probability; we add weight-1.0
rooms until the combined pool reaches TARGET_PROBABILITY.

Vanilla baseline (measured from community data):
  ~35 total secret rooms, 11 with item pedestals
  item_weight ≈ 5.95, total_weight ≈ 27.80, current prob ≈ 21.4%

STB1 format (Afterbirth / Repentance):
  Header  : "<4sI"   → magic b"STB1", room_count (uint32)
  Room hdr: "<IIIBH" → type, variant, subtype, difficulty, name_len
  name    : name_len bytes UTF-8
  Room end: "<fBBBBH" → weight, width, height, shape, door_count, spawn_count
  Door    : "<hh?"   → x, y, exists (bool, 1 byte)
  Spawn   : "<hhB"   → x, y, entity_count
  Entity  : "<HHHf"  → type, variant, subtype, weight

Entity types:
  EntityType 5 = pickup
  PickupVariant 100 = collectible (item pedestal), subtype 0 = pool-chosen
"""

import struct
import os

GAME_DIR      = r"C:\Program Files (x86)\Steam\steamapps\common\The Binding of Isaac Rebirth"
MOD_ROOMS_DIR = os.path.join(GAME_DIR, "mods", "better-runs", "resources", "rooms")
OUT_STB       = os.path.join(MOD_ROOMS_DIR, "00.special rooms.stb")

# Vanilla baseline (cannot read rooms.a directly — it is compressed).
# Derived from community-documented room counts and weights.
VANILLA_ITEM_WEIGHT  = 5.95
VANILLA_TOTAL_WEIGHT = 27.80
TARGET_PROBABILITY   = 0.50

# Variant IDs 0–38: vanilla secret rooms.
# 39–999: "rare secret rooms" workshop mod.
# 2000+: reserved for this mod to avoid any collision.
FIRST_VARIANT = 2000

# Standard 1×1 secret room geometry (confirmed by parsing live STB files).
# Shape 1 = rectangle 13×7. Door slots at the four cardinal midpoints;
# all marked exists=True so the game can open whichever connects.
ROOM_WIDTH  = 13
ROOM_HEIGHT = 7
ROOM_SHAPE  = 1   # standard rectangle
ROOM_DOORS  = [
    (-1,           ROOM_HEIGHT // 2, True),   # left
    (ROOM_WIDTH,   ROOM_HEIGHT // 2, True),   # right
    (ROOM_WIDTH // 2, -1,            True),   # top
    (ROOM_WIDTH // 2, ROOM_HEIGHT,   True),   # bottom
]
PEDESTAL_X  = ROOM_WIDTH  // 2   # 6
PEDESTAL_Y  = ROOM_HEIGHT // 2   # 3


# ── STB1 writer ───────────────────────────────────────────────────────────────

HDR_FMT      = struct.Struct("<4sI")
ROOM_HDR_FMT = struct.Struct("<IIIBH")
ROOM_END_FMT = struct.Struct("<fBBBBH")
DOOR_FMT     = struct.Struct("<hh?")
SPAWN_FMT    = struct.Struct("<hhB")
ENTITY_FMT   = struct.Struct("<HHHf")


def write_stb(rooms):
    out = bytearray()
    out += HDR_FMT.pack(b"STB1", len(rooms))
    for r in rooms:
        name_enc = r["name"].encode("utf-8")
        out += ROOM_HDR_FMT.pack(r["type"], r["variant"], r["subtype"],
                                  r["difficulty"], len(name_enc))
        out += name_enc
        out += ROOM_END_FMT.pack(r["weight"], r["width"], r["height"],
                                  r["shape"], len(r["doors"]), len(r["spawns"]))
        for dx, dy, exists in r["doors"]:
            out += DOOR_FMT.pack(dx, dy, exists)
        for sx, sy, entities in r["spawns"]:
            out += SPAWN_FMT.pack(sx, sy, len(entities))
            for etype, evariant, esubtype, eweight in entities:
                out += ENTITY_FMT.pack(etype, evariant, esubtype, eweight)
    return bytes(out)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    # Solve for N: (item_weight + N) / (total_weight + N) = TARGET
    other_weight = VANILLA_TOTAL_WEIGHT - VANILLA_ITEM_WEIGHT
    N = (TARGET_PROBABILITY * other_weight
         - VANILLA_ITEM_WEIGHT * (1 - TARGET_PROBABILITY)) \
        / (1 - TARGET_PROBABILITY)
    copies_needed = max(0, round(N))

    combined_total = VANILLA_TOTAL_WEIGHT + copies_needed
    final_prob = (VANILLA_ITEM_WEIGHT + copies_needed) / combined_total

    print(f"Vanilla baseline   : {len([])or'~35'} secret rooms, "
          f"item weight {VANILLA_ITEM_WEIGHT}, total {VANILLA_TOTAL_WEIGHT}")
    print(f"Current probability: {VANILLA_ITEM_WEIGHT/VANILLA_TOTAL_WEIGHT:.1%}")
    print(f"Target probability : {TARGET_PROBABILITY:.0%}")
    print(f"Copies to add      : {copies_needed}")
    print(f"Final probability  : {final_prob:.1%}")

    new_rooms = []
    for i in range(copies_needed):
        new_rooms.append({
            "type":       7,                      # RoomType.ROOM_SECRET
            "variant":    FIRST_VARIANT + i,
            "subtype":    0,
            "difficulty": 0,                      # all difficulties
            "name":       f"BetterRuns Secret {i + 1}",
            "weight":     1.0,
            "width":      ROOM_WIDTH,
            "height":     ROOM_HEIGHT,
            "shape":      ROOM_SHAPE,
            "doors":      list(ROOM_DOORS),
            "spawns": [
                (PEDESTAL_X, PEDESTAL_Y, [
                    (5, 100, 0, 1.0),             # EntityType.PICKUP, PICKUP_COLLECTIBLE, pool-chosen
                ]),
            ],
        })

    os.makedirs(MOD_ROOMS_DIR, exist_ok=True)
    stb_bytes = write_stb(new_rooms)
    with open(OUT_STB, "wb") as f:
        f.write(stb_bytes)
    print(f"\nWritten: {OUT_STB}")
    print(f"  {len(stb_bytes):,} bytes, {len(new_rooms)} rooms")


if __name__ == "__main__":
    main()
