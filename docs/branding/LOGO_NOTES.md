# MemDoping — Logo & Brand Palette

Status: **`logo-official.png` is the official logo**, supplied by the project owner and wired in as the app icon. The three machine-generated concepts further down are archive only — not in use.

## Official logo

`docs/branding/logo-official.png` — a smiling pink brain mascot pressing a blue barbell overhead, yellow burst rays around it. The mascot is delivered on a plain white background, with no frame or backdrop of its own.

It reads as "training your memory" literally rather than by metaphor, and stays clear of anything drug-like, which is the constraint the master brief puts on the name (§1: the name must not imply drugs, medical treatment, or biological enhancement).

### How it was prepared for the app icon

iOS masks app icons itself and rejects alpha, so the icon has to be a full opaque square:

1. Measured the mascot's bounding box (content is off-white pixels) and cropped to it.
2. Scaled it to 86% of the canvas, so nothing important sits where iOS rounds the corners.
3. Keyed only near-pure white to the background colour. Kept deliberately tight: the artwork's own whites (shoe soles, eye whites, highlights) sit inside dark outlines and must survive.
4. Centred it on a flat cream canvas at 1024×1024, saved as RGB — no alpha channel.
5. Generated the macOS sizes (512/256/128/64/32/16) with `sips`.

**Why cream and not the brand blue.** The artwork is composited on white, so its anti-aliased edges are blended with white. On a dark or saturated background those edge pixels read as a white halo around every shape. A light, warm background absorbs them invisibly. Cream also keeps the blue barbell readable, which a blue backdrop would have flattened.

Verified on the simulator: mascot balanced in frame, no halo, no white artifacts at the rounded edge.

### Known behaviour: dark mode

On iOS 26 the system applies its own dark-appearance treatment to app icons. Tested previously on the earlier artwork: it happens identically whether the catalog declares no appearance variants or an explicit dark variant, both with a cleared asset cache — so it's platform behaviour, not an asset bug. Controlling it needs purpose-made dark artwork (mascot on transparent, so the system draws its own backdrop). The catalog is kept at the simplest correct configuration: one icon, no appearance variants.

## Brand palette

Sampled from the finished icon's pixels, grouped by colour family (median plus the light and dark ends), not eyeballed:

| Role | Hex | Share | Notes |
|---|---|---|---|
| Background cream | `#F7F2E8` | 65% | The icon's flat backdrop — the brand's neutral ground |
| Primary blue | `#0452C3` | 12% | Barbell plates; the brand's core accent colour |
| Primary blue, light | `#00AFFD` | — | Plate highlights |
| Primary blue, deep | `#02217B` | — | Plate shadow side |
| Navy | `#011049` | 5% | Outlines, limbs — the near-black of the artwork |
| Mascot pink | `#FD7789` | 11% | The brain body |
| Mascot pink, saturated | `#D122AF` | — | Brain outline and deepest folds |
| Accent yellow | `#FEBC05` | 3% | Burst rays — the attention/energy accent |

**The in-app palette does not match this yet.** `Brand` in `Views/Components.swift` still uses an indigo primary (`#5C3DDB`) with an orange accent (`#FA873D`) and a dark indigo background gradient, left over from the first generated concept. Aligning the app to this logo (cream/light surfaces, blue primary, yellow accent, pink for reward moments) is a follow-up — and a bigger job than swapping constants, since the whole UI is currently designed for a dark background.

## Archived concepts (not in use)

Generated before the official logo arrived. Kept for reference; delete whenever.

- `concept-a-brain-bolt.svg` / `.png` — brain cloud with a lightning bolt
- `concept-b-m-bolt.svg` / `.png` — "M" monogram with a bolt-shaped middle stroke
- `concept-c-neuron-spark.svg` / `.png` — neuron network badge with a central spark

## Replacing the icon later

1. Drop the new artwork in and note its path.
2. Produce a 1024×1024, alpha-free PNG. If it arrives on white or transparent, the recipe above applies; if it arrives with its own baked-in rounded frame, the corners need filling instead (see this file's git history for that variant).
3. Overwrite `appicon-1024.png` in the appiconset, then regenerate the smaller sizes:
   ```
   ICONSET=MemDoping/MemDoping/Assets.xcassets/AppIcon.appiconset
   for s in 512 256 128 64 32 16; do
     sips -z $s $s "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-$s.png"
   done
   ```
   `Contents.json` needs no edit as long as the filenames stay the same.
4. Uninstall the app from the simulator before reinstalling — Springboard caches icons.

## Open items

- Trademark clearance still pending (master brief §1).
- No dark-mode or tinted icon artwork.
- Store listing assets (screenshots, feature graphics) not produced.
- In-app palette still needs aligning to this logo.
