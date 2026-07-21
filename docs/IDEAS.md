# IDEAS — planned evolutions

> **Status: ideas, not implemented.** This document is the **single index** of
> evolution tracks, organized by maturity. It contains no reality (that's what
> `SOFTWARE.md` / `HARDWARE.md` are for, the sole source of truth for the
> present). The large work items have their own file and are linked here; the
> small ideas stay inline. **Every evolution idea lives here** — do not scatter it
> across the README or `SOFTWARE.md` (that's what had made the docs diverge).

## Structural work items (dedicated files)

- **Intention vocabulary** — ✅ *shipped* (no longer a backlog item; kept here as
  a pointer). Decouples the cube from Claude Code: animations target neutral
  states (`think`, `start`, `fork`…), a profile (data) maps the hooks onto them,
  and the temporal role (`kind`) lives on the intention. → **[`INTENTIONS.md`](INTENTIONS.md)**
- **Animation marketplace** — *vision.* Public marketplace of shareable
  animations: safe third-party code execution (compilation to WASM,
  capabilities, photosensitivity/color-blindness lints), local creation studio,
  creator journey. → **[`MARKETPLACE.md`](MARKETPLACE.md)**

## One-off ideas (near-term)

- **Random variants** for frequent events (`post_tool_2.rb`, …) — the manager
  already picks a random variant per hook.
- **Cross-face effects**: liquid flowing down from the top along the sides,
  propagation by category around the ring, etc.
- **New event sources** (GitHub, Slack, …): same shape as `ClaudeCode` — a file
  in `lib/connectors/` that pushes an `Event`. With the intention layer (see
  above), a new source = one connector + one **profile** (data), zero lines of
  rendering.
- **Payload-driven animations**: the connector today passes along a payload
  (empty); a hook could read fields (tool name, task title) if the hook script
  POSTs them. This ties into the "payload-conditioned mapping" track of
  [`INTENTIONS.md`](INTENTIONS.md) (a source that emits a single `stop` with a
  success/failure flag → `stop` vs `fail`).
- **Scrolling text around the ring** — a short word or message scrolling across
  the 32-column lateral ring (`ring_px`), the only text format legible on a cube
  this small (a static 3×5 glyph on one 8×8 face is unreadable). The 3×5 bitmap
  font in `lib/text/font_3x5.rb` is the reusable starting point (height 5 fits in
  8 rows); `lib/text/renderer.rb` would need porting from its old positional
  `panel.set(x, y, …)` signature to the ring/per-face API. A natural basis for a
  text-driven animation set.

## Reconsidered / obsolete (kept for the record)

- ~~**"Build the cube simulator first"**~~ — *reversed.* We settled it: the
  physical cube **is** the creation preview; only a **server-side headless
  rendering** (catalog thumbnails/GIFs, lints) is useful — no interactive local
  3D simulator to build. Isolating animations under test goes through a **build
  mode** (exclusive lock + suspending the manager), not through a simulation.
  Details in [`MARKETPLACE.md`](MARKETPLACE.md) §7.
- ~~**Declarative animation format**~~ — *absorbed* by tier 1 of the marketplace
  (animation = data, safe by construction).
- ~~**Align the 3 other side↔top edges**~~ — *done.* The 8 edges are validated on
  hardware, no offset to apply (cf. `CLAUDE.md` §4).
