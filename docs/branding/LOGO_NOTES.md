# MemDoping — Logo & Brand Palette

Status: **`logo-official.png` is the official logo**, supplied by the project owner and wired in as the app icon. The three earlier machine-generated concepts are kept below as archive only — they are not in use.

## Official logo

`docs/branding/logo-official.png` — a smiling pink brain mascot pressing a barbell overhead, yellow burst rays around it, on a blue gradient rounded square.

It reads as "training your memory" literally rather than by metaphor, and stays clear of anything drug-like, which is the constraint the master brief puts on the name (§1: the name must not imply drugs, medical treatment, or biological enhancement).

### How it was prepared for the app icon

The supplied file is 1254×1254 with the artwork's own rounded corners and white outside them. iOS masks app icons itself and requires a full square with no alpha, so:

1. Trimmed the flat white margin (3px left/right, 13px bottom).
2. Squared to 1241×1241.
3. Filled the four corner arcs — the white outside the rounded shape — using a flood fill from each corner. Flood fill rather than a "replace all near-white pixels" pass on purpose: the artwork has its own near-white highlights (the glossy top-left sheen, the shoe soles, the eye whites) that a global threshold would have eaten. Flood fill only reaches white connected to the outside, which the blue border ring seals off.
4. Filled those corners with a zoomed, heavily blurred copy of the artwork itself, so each corner picks up the gradient tone next to it instead of a flat patch.
5. Resized to 1024×1024, saved as RGB (no alpha channel — iOS rejects icons with alpha).
6. Generated the macOS sizes (512/256/128/64/32/16) with `sips`.

Verified on the simulator: no white slivers at the rounded edge, and iOS's own mask produces the rounded shape.

### Known behaviour: dark mode

On iOS 26 the system applies its own dark-appearance treatment to the icon — the blue background renders much darker while the brain and rays stay bright. This is **not** an asset problem: it happens identically whether the catalog declares no appearance variants, or declares an explicit dark variant pointing at the same bright artwork. Both were tested on the simulator with a cleared asset cache.

Controlling the dark appearance properly needs purpose-made dark artwork (typically the mascot on a transparent background, so the system draws its own dark backdrop). That's a design task, not a code one. The current single-icon setup is the simplest correct configuration until that art exists.

## Brand palette

Sampled from the official logo's actual pixels, grouped by colour family (median plus the light and dark ends of each family), not eyeballed:

| Role | Hex | Share of icon | Notes |
|---|---|---|---|
| Primary blue | `#0178F9` | 44% | The dominant background blue — the brand's core colour |
| Primary blue, light | `#02C0FE` | — | Top-left sheen, highlight end of the gradient |
| Primary blue, deep | `#0154DB` | — | Shadowed end of the same gradient |
| Deep blue | `#0128A5` | 17% | Outer border ring; good for surfaces behind the primary |
| Deep blue, darkest | `#001D82` | — | Border shadow |
| Navy | `#010C48` | 6% | Outlines, limbs — the near-black in the artwork |
| Cyan | `#4DEFFD` | 8% | Centre glow behind the mascot; use sparingly as a highlight |
| Mascot pink | `#FD7C91` | 15% | The brain body |
| Mascot pink, saturated | `#D729B3` | — | Brain outline / deepest fold |
| Accent yellow | `#FDCE11` | 3% | Burst rays — the attention/energy accent |
| White | `#F9FCFD` | 3% | Eye whites, shoe soles, specular highlights |

**How this differs from what's in the app today.** `Brand` in `Views/Components.swift` currently uses an indigo primary (`#5C3DDB`) with an orange accent (`#FA873D`) — the palette from the earlier generated concept. The official logo is blue with a yellow accent, so the in-app palette does not match the icon yet. Aligning it (blue primary, yellow accent, pink as the reward/celebration colour) is a follow-up.

## Archived concepts (not in use)

These were generated before the official logo arrived. Kept for reference; delete whenever.

- `concept-a-brain-bolt.svg` / `.png` — brain cloud with a lightning bolt
- `concept-b-m-bolt.svg` / `.png` — "M" monogram with a bolt-shaped middle stroke
- `concept-c-neuron-spark.svg` / `.png` — neuron network badge with a central spark

## Replacing the icon later

1. Put the new square artwork somewhere and note its path.
2. Produce a 1024×1024, alpha-free PNG. If it has its own rounded corners with white outside them, repeat the corner treatment above (the flood-fill approach is in this file's history and in the commit that introduced it).
3. Overwrite `MemDoping/MemDoping/Assets.xcassets/AppIcon.appiconset/appicon-1024.png`, then regenerate the smaller sizes:
   ```
   ICONSET=MemDoping/MemDoping/Assets.xcassets/AppIcon.appiconset
   for s in 512 256 128 64 32 16; do
     sips -z $s $s "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-$s.png"
   done
   ```
   `Contents.json` needs no edit as long as the filenames stay the same.
4. Uninstall the app from the simulator before reinstalling — Springboard caches icons.

## Open items

- Trademark clearance is still pending (master brief §1) — unchanged by this logo.
- No dark-mode or tinted icon artwork yet (see above).
- App Store / Play Store listing assets (screenshots, feature graphics) not produced.
- In-app palette still needs to be aligned to this logo.
