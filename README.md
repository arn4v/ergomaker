# ErgoMaker — Guided Split Keyboard Layout Finder

Design notes and product vision for a single-file HTML/JS app that helps a person discover an optimal split keyboard key layout for their specific hands and preferences.

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
- Rest hand naturally on canvas; place finger pads (I/M/R/P) and thumb where they feel most neutral.
- Record contact centroids and relative orientation of index→pinky line; optionally use device orientation.
- Save as the “home anchors” for each finger and the thumb.

4) Finger Travel Measurement
- For each finger (index, middle, ring, pinky, thumb), in order:
  - Keep the hand anchored in the homing posture.
  - Slide only the prompted finger “up” and “down” through what feels like comfortable rows.
  - Record maximum comfortable displacement (up/down), plus a “comfortable” midpoint.
  - Optional: capture slight inboard/outboard (lateral) travel to model splay or column rotation.

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

## Comfort Model (Initial Sketch)

- Base cost: distance from each finger’s home anchor to a candidate key center.
- Directional penalty: higher cost for extension vs flexion, and for ulnar vs radial deviation.
- Angle penalty: cost increases as finger travel deviates from the finger’s preferred column direction.
- Finger strength weights: index < middle < ring < pinky cost multipliers; customizable for injuries.
- Thumb model: separate arc/fan; penalize inward/outward rotation beyond neutral.
- Layout score: sum(cost(key) × usage_frequency(key)) over all keys in the target set.

## Output Formats

- KLE JSON (Keyboard Layout Editor) for visualization/import.
- Simple JSON: per-hand key coordinates and metadata (pitchXMM, pitchYMM, stagger, column rotations, switch/cap presets, switch body keepout dims).
- QMK/VIA scaffolds: placeholders mapping physical positions to logical layers.
- Static PNG/SVG preview export of the candidate layout.

## UI & Interaction Notes

- Single-file app (HTML/CSS/JS) with no external network calls; all data stays local (localStorage export/import).
- Multitouch via Pointer Events; visualize touch points with finger labels and trailing arcs.
- Clear prompts, one-finger-at-a-time measurement UI with “Looks Good / Redo” checkpoints.
- “Confidence bands” around measurements; allow quick retakes to refine noisy data.
- Keyboard-agnostic: generate positions first; mapping to letters/layers is out of scope for the core flow (but export helps).

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

---

If this vision looks right, I’ll scaffold the single-file HTML/JS app next and focus first on the measurement flow (multitouch + homing + per-finger travel), then candidate generation and scoring.
