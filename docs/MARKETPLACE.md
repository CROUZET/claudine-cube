# MARKETPLACE — vision for an animation marketplace

> **Status: design exploration (nothing has been built yet).** This
> document records design thinking for a future public marketplace of
> shareable animations. It commits to no implementation; it fixes the
> threat model, the trust boundaries, and the anticipated architecture,
> so we can start from there rather than redo the reasoning.

Today, an animation is a Ruby file (`lib/animations/<set>/<hook>.rb`)
with its own logic that *renders* to the cube (`render(t, panel)`). We
build them by hand, together. The question: **what if users could
create their own animations and share them with others through a public
marketplace?** Running code written by a stranger is dangerous — here is how
we would make it safe.

---

## 1. The founding insight: an animation is an *almost-pure* function

An animation's contract is tiny:

- **a single input**: `t` (seconds elapsed since the start);
- **a single output**: a pixel grid (`panel.set` / `fill_face`);
- **no dangerous capability required**: no files, no network, no threads,
  no wall clock, nothing from the stdlib except `Math`.

The smaller the legitimate surface, the harder we can lock things down without
losing any expressiveness. So the problem is **not** "how to make Ruby safe,"
it is **"never run foreign Ruby in the host process"**
(Ruby has had no in-process sandbox since `$SAFE` disappeared in
Ruby 3.0).

## 2. The real threat model

What we are protecting is **not the cube**: the stress test
(`diagnostics/cube_stress.rb`, cf. `HARDWARE.md`) showed that even full white
does not damage it, and brightness/current are bounded on the host side. What we
are protecting is **the machine running the daemon**. Today the daemon
`require`s the animation file: downloading + `require`ing an unknown `.rb` =
arbitrary code execution on the host. That is what we eliminate.

## 3. The two worlds of trust

The distinction that structures everything:

- **Create (local)** — the user runs Claude Code on *their* machine to
  write *their* animation. Running Ruby is perfectly fine here: it is their
  code on their machine. **No sandbox needed to create/preview.**
- **Consume (download)** — playing a *stranger's* animation. The only
  dangerous world.

**Compilation is the bridge — and thus the security checkpoint — between
the two.** The author writes expressive code; what is published is never
"code that runs like the host" but a **capability-less compiled unit**.

## 4. The spectrum of solutions (from safest to most powerful)

1. **Declarative format (zero code)** — the animation is *data*
   (JSON/YAML: layers, gradients, keyframes, easing over the existing
   helpers). The host interprets it. Impossible to execute anything.
   This probably covers the majority of "breathe / rotate / blink" animations.
2. **Restricted DSL / mini-language** — a language whose every opcode we
   control (bounded loops, arithmetic, `set_pixel`). More expressive; you have
   to write and maintain an interpreter.
3. **A real language in an airtight sandbox** — the only capability exposed
   is `set_pixel(face,x,y,r,g,b)`:
   - **WebAssembly (Wasmtime/Wasmer)** — the chosen answer: isolated
     memory, no imports except those provided, deterministic, multi-language,
     native CPU/memory limits. Best safety/power ratio.
   - Embedded Lua, isolated QuickJS/V8 — same properties, other trade-offs.
4. **OS isolation (defense in depth, orthogonal)** — run the guest
   rendering in a separate process with no network and no FS
   (seccomp/landlock/`sandbox-exec` on macOS/container), talking to the daemon
   only through a pixel pipe.

## 5. Anticipated architecture

A **two-tier** model:

- **Tier 1 (default, "verified")**: **declarative** animations (option 1),
  safe by construction. This is what we put forward.
- **Tier 2 (advanced creators)**: **WASM** with the sole import `set_pixel`
  + resource budgets + process isolation + rendering CI at upload.

Structural change to the daemon: **never again `require` a downloaded
file.** It loads either *data* (tier 1) or a guest module in
an isolated runtime (tier 2). Since `render(t, panel)` is already a pure
function `(t) → grid`, the guest interface is tiny.

### Publish the *source*, not the binary

Key decision: the marketplace **distributes the source and compiles server-side**
(reproducible build), like a package registry that *builds from source*.
The distributed binary is a *derivative*, not the truth. This unlocks:

- **review & moderation** (an opaque blob cannot be judged);
- **remix** ("like this one but slower and in green" → fork of the source);
- **retargeting** (recompile the whole catalog when the runtime evolves, or for
  another device);
- **guarantee** that the artifact matches an inspectable source bit-for-bit.

## 6. Cross-cutting protections (whatever the engine)

- **Capability-based API**: we expose *only* `set_pixel`. `t` is passed
  explicitly → no wall clock, no RNG (or a *seeded* RNG provided by
  the host) → **deterministic and replayable**.
- **Resource budgets**: per-frame timeout (~33 ms at 30 fps), memory
  cap, instruction limit → we *kill* the animation that exceeds them.
- **Publication CI**: the server renders the animation headless (like
  `test/animations_smoke_test.rb`) → rejects crash/loop/overrun before
  publication.
- **Physical safety bounded on the host side**: brightness/current cap applied
  by the daemon, never by the animation.
- **Provenance & moderation**: author signature, versioning, reporting,
  reputation, "verified" vs "community" tiers.

### Two specific lints to enforce

Determinism makes automatic auditing possible:

1. **Photosensitive (epilepsy) safety** — full-field flashing > ~3 Hz = real
   epileptic risk → reject/flag (frequency × surface × contrast).
2. **Colorblind accessibility** — simulate a deficiency, verify that
   information comes through via **motion/shape/brightness** and not just
   color. The personal constraint (slightly colorblind user) becomes
   a **quality label** for the catalog.

## 7. No 3D simulator — the physical cube is the preview

We distinguish two objects that are easily confused:

- **Interactive 3D simulator in the local studio** → **abandoned.** Costly, and
  never as convincing as the real cube the user has in front of them.
  For creation, **the physical cube IS the best preview.**
- **Headless rendering engine** → kept, but **server-side only**:
  replay the pure function `(t) → grid` and dump the pixels. Almost free
  (the foundation is already there with `animations_smoke_test.rb`). Serves the
  catalog's **thumbnails/GIFs** (a visitor browsing is on their phone, not in
  front of their cube), the **lints**, and the **CI**.

### The "build mode" (isolation, not simulation)

The real need — not mixing the animation under test with the current
animations triggered by events — is solved with an **exclusive mode on
the real cube**, not with a simulator. It builds on the existing `AnimationManager`
(two-layer model, terminal events, display lock): the local studio takes an
**exclusive lock**, **suspends** the event-driven manager, **streams only**
the animation being edited; on exit, the manager takes back control.

*Optional in-between, not a priority*: a **flat 2D preview** (the 5 faces
unfolded into a cross, pixel grid + time slider) for per-frame debugging
("why this pixel at `t=5.2s`?"), which the cube does poorly. A simple `<canvas>`,
no 3D.

## 8. A creator's complete journey

Persona: Léa creates a "pouring coffee" animation for the `pre_tool` event.

0. **Setup (once)** — local app installed (TCP daemon + local web server).
   On first launch, **explicit pairing** with the site (exchange of a
   token). The official site, and it alone, can reach the local studio → neutralizes
   the "public site → localhost" trap (CSRF / DNS-rebinding). The local server
   runs nothing on a mere incoming request; it opens a UI that the user
   drives.
1. **Entry** — from the public catalog, a **"Create your own"** button →
   opening of the **local studio** (Claude dialogue on the left, metadata on the right).
   *Boundary: we move from the public world to the local trusted world.*
2. **Build mode** — the studio takes the **exclusive lock**, the daemon
   suspends the `AnimationManager`; the cube becomes a dedicated screen.
3. **Creative dialogue** — Léa describes the intention; Claude produces the **source**
   (uses `Cube::CubeBase`, `ring_px`, etc.), played **immediately on the real
   cube** in a loop. A tight say → see → fix loop. A "play it as
   `pre_tool`" button to test in context (real duration of the overlay).
4. **Metadata** — name, description, event(s) or **pack** (16 hooks), **exposed
   params** (color, speed… adjustable within safe bounds), **geometry
   compat** (5×8×8 cube).
5. **Compilation (the security checkpoint)** — the source **descends** to the safe
   artifact (WASM, sole import `set_pixel`). If the source tries file/network/clock,
   it does not compile. The studio replays the *compiled* artifact → **parity**: what
   we publish == what we see.
6. **Pre-publication checks (local, replayed by the server)** — budgets,
   photosensitive safety, colorblind score, headless rendering → thumbnail/GIF.
7. **Publication** — Léa **uploads the source**; the server **recompiles**
   (reproducible), **replays the lints**, regenerates the preview, **signs**,
   **versions**, publishes (community or verified tier).
8. **Return to normal** — the studio releases the lock, the daemon reactivates
   the `AnimationManager`.
9. **The other end** — Marc browses the catalog from his phone (he sees the
   GIF), downloads the animation, his daemon **loads the WASM into the isolated
   runtime** (never a `require`) with `set_pixel` as its sole capability, sets a
   param, binds it to his `pre_tool`. *Léa's code never got to touch Marc's
   machine.*

Throughline: **physical cube = preview**; **build mode = isolation**;
**compilation = security checkpoint**; **source (not binary) = published truth**;
**lints = consumer protection** (of which colorblind accessibility has
become a label).

## 9. Open questions to settle

- **Author language**: what the source written with Claude concretely looks
  like, and how it "descends" to WASM.
- **Universal geometry**: the cube is only one device among others (the
  original Claudine's 16×16 panel, a bigger cube, a sphere…); the guest API
  then receives a **geometry descriptor**, and animations declare
  the supported topologies.
- **Pack edge cases**: ~~a pack that provides only 10 hooks out of 16?~~
  → resolved by the intentions layer (`INTENTIONS.md`): a pack declares the
  intentions it covers, the rest falls back on a fallback chain. Remaining:
  two animations that want the same event? the author without a cube at the moment
  of creating?
- **Sharing the prompt**: publish the *recipe* (the dialogue that generated
  the animation), not just the artifact — a marketplace of recipes as much as
  of artifacts.
