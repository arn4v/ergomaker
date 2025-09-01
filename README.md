# ErgoMaker — Guided Split Keyboard Layout Finder

Design notes and product vision for a single-file HTML/JS app that helps a person discover an optimal split keyboard key layout for their specific hands and preferences.

## Project Status (Current Behavior)

The single-file app (`index.html`) runs locally with no network calls and guides users through: constraints → optional calibration → homing capture → per-finger sampling → candidate layout → export. It supports touch (Pointer Events + Touch Events fallback for iPad Safari) and a desktop mouse mode for anchors. State persists locally via `localStorage` and can be exported.

## Vision

A local, privacy-first, guided experience that:
- Captures each hand’s neutral posture and comfortable finger travel with multitouch.
- Asks a few high-impact questions (keys per hand, thumb cluster size, rows/columns, etc.).
- Generates one or more candidate layouts (key positions per hand) that minimize strain and movement for the user’s usage profile.
- Visualizes the result and exports to common formats (KLE JSON, QMK/VIA snippets) for easy iteration.

## Guided Flow (First Draft)

1) Welcome & Setup
- Choose dominant hand to measure first (left/right; measured separately; default to mirroring later).
- Device check: recommend phone/tablet for true multitouch; desktop works with pointer emulation.
- Optional DPI calibration by matching an on-screen ruler to a credit card (to convert pixels ↔ millimeters).

2) Constraints & Preferences
- Main-finger keys per hand and thumb-cluster keys per hand (separate), plus rows/columns target (e.g., main: 30/34/36/42; thumb: 2–5).
- Switch preset: Cherry MX (standard), Kailh Choc (low-profile), Gateron Low Profile, Redragon Low Profile, or Other.
- Keycap spacing preset (pitch): MX 1u (19.05 × 19.05 mm), Choc 1u (18.0 × 17.0 mm), Low-profile 1u (~18.8 × 18.0 mm), or Custom (edit mm).
- Switch footprint (keepout): preset body keepout dims with option to customize. Defaults: MX ≈ 14×14 mm body, Choc v1 ≈ 15×15 mm body, Gateron LP ≈ 14×14 mm. Note: plate cutout vs body keepout differ; we use body keepout to compute clearance; plate cutout is often ≈14×14 mm for both MX and Choc.
- Thumb cluster shape and placement: fan/arc/row; position relative to main grid.
- Column style: ortholinear vs column-staggered; allow per-column vertical offsets.
- Symmetry: default mirror dominant hand; allow per-hand differences if toggled off.
- Optional usage profile (writing/coding/gaming/mixed). V1 focuses on comfort only (uniform key weights); frequency weighting can come later.

3) Homing Posture Capture (Multitouch)
- Rest hand naturally on the canvas; place four fingertips and the thumb in a neutral homing posture.
- Stability timer (~2 seconds) snapshots contacts; you may lift your hand afterward — the capture persists.
- Auto-labeling algorithm:
  - Thumb: farthest point from the centroid of the captured contacts.
  - Others: x-order, respecting dominant hand (right: left→right = index→middle→ring→pinky; left mirrored).
- Anchors are saved immediately and used in later steps; desktop “Mouse mode” allows sequential clicks to set anchors.

4) Finger Travel Measurement
- For each finger (index, middle, ring, pinky, thumb), in order:
  - Keep the hand anchored; you can rest all fingertips on-screen.
  - Each touch-down adds a sample for the current finger only (others are ignored).
  - The app accumulates samples and computes up/down/lateral envelopes in mm.
  - The keycap overlay updates live: the column for the current finger shifts to an optimized home (centered between min/max vertical samples; median lateral), with bounded limits.
  - Status shows Up/Down/Lateral, sample count, detected style (ortholinear/stagger), and X/Y offset of the optimized home.

5) Candidate Generation & Scoring
- Generate grid candidates per constraints (rows/columns, staggers, column curves, thumb cluster shapes).
- Assign keys to fingers based on their home anchors and reach envelopes.
- Score candidates with a comfort model (distance/angle/extension costs × usage frequency weights).

6) Review & Export
- Show top N candidates with heatmaps (comfort, travel) and finger assignments.
- Allow quick tweaks (e.g., nudge a column, change thumb count) and live re-score.
- Export KLE JSON, JSON with key coordinates, and an outline image; copy QMK/VIA skeleton mappings.

## Measurements Collected

- Finger home positions (x,y) for index/middle/ring/pinky; thumb anchor and angle preference.
- Comfortable displacement ranges per finger (up/down; optional lateral).
- Hand scale (mm/px) and per-user key pitch preference.
- Inferred hand splay (index→pinky vector) and optional column rotation hints.
- Optional: usage frequency table from sample text or presets.
- Optimized anchors per finger (optAnchors) derived from samples; used by generation/export.

## Comfort Model (Initial Sketch)

- Base cost: distance from each finger’s home anchor to a candidate key center.
- Directional penalty: higher cost for extension vs flexion, and for ulnar vs radial deviation.
- Angle penalty: cost increases as finger travel deviates from the finger’s preferred column direction.
- Finger strength weights: index < middle < ring < pinky cost multipliers; customizable for injuries.
- Thumb model: separate arc/fan; penalize inward/outward rotation beyond neutral.
- Layout score: sum(cost(key) × usage_frequency(key)) over all keys in the target set.

## Output Formats

- KLE JSON (Keyboard Layout Editor) for visualization/import.
- Simple JSON: per-hand key coordinates and metadata (pitchXMM, pitchYMM, stagger, column rotations, switch/cap presets, switch body keepout dims, anchors + optAnchors, per-finger travel).
- QMK/VIA scaffolds: placeholders mapping physical positions to logical layers.
- Static PNG/SVG preview export of the candidate layout.

## UI & Interaction Notes

- Single-file app (HTML/CSS/JS) with no external network calls; all data stays local (localStorage export/import).
- Touch support: Pointer Events with Touch Events fallback (iPad Safari compatible); desktop mouse mode for anchor capture.
- Measurement UI: sample-based (tap to add samples), per-finger envelopes and “Redo” to clear current-finger samples.
- “Confidence bands” from accumulated samples; quick retakes refine data.
- Keyboard-agnostic: generate positions first; mapping to letters/layers is out of scope for the core flow (export helps).

## Assumptions & Non-Goals (for now)

- Not modeling tenting or forearm pronation/supination angles (may be inferred later).
- Not generating 3D case geometry; focus on key centroids and simple outlines.
- Not prescribing legends or layers; only physical positions and suggested finger assignments.

## Open Questions

- Are we optimizing only key positions, or also per-column rotation and splay angles?
- Fixed pitch per layout, or allow per-column pitch/curvature differences?
- Should lateral reach (inboard/outboard) be measured explicitly for each finger?
- Any injuries or finger-specific constraints to weight more heavily?
- Are the two hands mirrored by default, or can they diverge materially?
- Thumb cluster: arc vs row vs fan—any strong preference or constraints (e.g., vertical stack)?
- Target key set: include numbers/symbols, or assume layers for those?
- Usage profile: provide presets, user-pasted corpus, or both?
- Minimum and maximum keys per hand you want to support (e.g., 28–50)?
- Should we output ready-to-import KLE and VIA/QMK, or only raw JSON initially?
- Do we need a quick “sanity” test after generation (typing mini drill) to validate comfort?

## Ideas to Improve the Experience

- DPI calibration by matching a credit card or known coin for more accurate mm scaling.
- Optional “palm rest alignment” overlay to encourage a neutral wrist angle during measurement.
- Visualize per-finger reach envelopes (heatmaps/contours) before generating candidates.
- Confidence-driven prompts: if a measurement is noisy, ask for one more quick sample.
- Multi-candidate explorer: side-by-side comparison with deltas highlighted (stagger, pitch, thumb shape).
- Simple “pain map” input to bias the model against certain regions/directions.
- Preset profiles: writing/coding/gaming; import usage stats to refine weighting.
- Session history: keep previous measurements and layouts for easy A/B comparison.
- Offline help cards with ergonomic heuristics (e.g., avoid heavy lateral travel on ring/pinky).

## Proposed Milestones

1) Skeleton single-file app: screens, state machine, localStorage.
2) Multitouch capture + visualization with homing posture.
3) Finger travel measurements with quality checks and redo.
4) Candidate generator for grids (rows/columns, stagger, thumb shapes).
5) Comfort scoring model + usage presets and paste-in corpus.
6) Results UI, quick tweaks, and exports (KLE/JSON/SVG; QMK/VIA later).
7) Presets for switches and spacing (done): choose MX/Choc/LP, with spacing presets or custom mm.

## Detailed Current UX and Features

- Constraints & Presets
  - Main-finger key count (per hand) and thumb-cluster key count (per hand).
  - Column style: ortholinear vs column-staggered (auto-detected during measurement; overridable in review).
  - Dominant hand and mirror/asymmetry preference.
  - Switch presets: Cherry MX, Kailh Choc v1, Gateron LP, Redragon LP, Other.
  - Keycap spacing presets (pitch): MX 1u (19.05×19.05 mm), Choc 1u (18×17 mm), LP (~18.8×18.0 mm), Custom (edit X/Y mm).
  - Switch footprint (body keepout) with “lock to preset”; defaults include MX ≈14×14 mm, Choc v1 ≈15×15 mm.
  - Optional DPI calibration using credit card width (85.60 mm) to improve mm accuracy.

- Homing Capture
  - Stable capture after ~2 seconds; snapshot persists after lifting the hand.
  - Auto-labeling: thumb=farthest from centroid; others by x-order with dominant-hand direction.
  - iPad Safari fixes: Touch Events fallback and canvas resize when the screen becomes visible; desktop “Mouse mode” available.

- Measurement (“Add Samples”)
  - Each touch-down adds a sample for the current finger only (others may rest on-screen).
  - Envelope computed from samples in mm; sample count shown.
  - Keycap overlay: columns for index/middle/ring/pinky; thumb-cluster keycaps as an arc using `thumbCount` and dominant hand.
  - Optimized anchors recompute live from samples (vertical center, lateral median) with bounded shifts; overlay follows; status shows X/Y offset.

- Candidate Generation & Results
  - Uses optimized anchors when available (falls back to anchors).
  - Heuristic column distribution and style-dependent vertical stagger; thumb cluster arc.
  - Comfort scoring normalized by per-finger travel and finger strength; results canvas visualizes comfort.
  - Review controls: tweak rows/style/switch & spacing presets; KLE/JSON exports.

## Problems Tackled & UX Improvements

- iPad Safari: canvas sizing + event handling → resize on screen entry; Touch Events fallback.
- Lifting hand reset → stable snapshot (capturedPoints) persists; Continue stays enabled.
- Inconsistent labeling → single algorithm both times (thumb=farthest from centroid; others by x-order with dominant hand).
- Drag-only measurement → tap-to-capture samples; envelope from multiple samples; sample count.
- Wrong-finger samples → capture only when new touch is nearest to the current finger’s anchor.
- Static overlay → dynamic columns via optimized anchors; visible offset ring.
- Missing thumb overlay → render thumb keycaps (arc) based on `thumbCount`.

## Running & Deploying

- Local server: `make serve` (http://127.0.0.1:5173), `make serve PORT=8080 OPEN=1`, or `./serve 5173 --open`.
- Vercel: repo includes `vercel.json` (project name `ergomaker`).
  - Connect GitHub repo in Vercel for auto-deploys, or use CLI: `npm i -g vercel`, `vercel login`, `vercel --prod --name ergomaker`.
