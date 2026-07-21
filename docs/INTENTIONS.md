# INTENTIONS — state vocabulary (source ↔ rendering contract)

> **Status: V1 — implemented.** This document defines the **intention
> vocabulary** that decouples event *sources* (Claude Code today, others
> tomorrow) from the *animations* that render them. It is the system's public
> contract: animation packs and sources agree on it. See also `MARKETPLACE.md`
> (packs target intentions, not hooks) and `SOFTWARE.md` (EventBus /
> AnimationManager). Implementation: `lib/intentions.rb`,
> `lib/profiles/claude_code.rb`, `lib/animation_manager.rb`.

## Why this layer

Before this layer, an animation was named after a Claude Code **hook**
(`user_prompt.rb`, `pre_tool.rb`…). Two problems:

1. `user_prompt` / `pre_tool` only speak to people who know Claude Code —
   unusable for a public marketplace.
2. It locked the cube into the Claude Code interaction. Worse: the **temporal
   role** of an event (background / one-shot / terminal) was hardcoded *by hook
   name* in the `AnimationManager` (`BACKGROUND_EVENTS`, `CLEAR_EVENTS`) —
   "Claude Code" knowledge leaking into the rendering layer, contradicting the
   promise of `CLAUDE.md` §7 ("adding a source never touches rendering").

The intention layer solves both. A **"General MIDI" of states**: a set of
neutral state verbs. Animations are indexed by *intention*; a **profile** (data,
not code) maps a source's events onto these intentions. Adding a source = writing
a profile, zero lines of rendering.

## Two naming principles

1. **stable id (English) ≠ display label (localizable).** The `id` is the API:
   short, carved in stone, never translated (like the code's class names). The
   **label** is what the creator sees, translatable. "Expressiveness" plays out
   on the label + the description; the id stays the contract.
2. **Neutral state verbs**, not Claude-isms (`think`, not `user_prompt`).

## The 4 kinds (the temporal role lives on the intention)

The `kind` lives on the intention (`Intentions.kind`), not in the
`AnimationManager` → the manager is purely intention-driven, source-agnostic.

| kind | behavior | current manager equivalent |
|---|---|---|
| **ambient** | loops in the background as long as the state lasts | `BACKGROUND_EVENTS` |
| **pulse** | plays once then hands control back to the background | overlay |
| **boundary** | start/end that cuts the background (terminal) | `CLEAR_EVENTS` |
| **dormant** | idle | `system_idle` |

## V1 — 16 intentions

Six pairs that bracket each other + the outcomes of a turn + rest:
`welcome…bye` (session), `start…finish` (tool action), `handle…handled` (task),
`fork…join` (delegation), `save…saved` (memory housekeeping), `stop`/`fail`
(successful/failed turn), `sleep`.

| id | label | kind | what it means | fallback |
|---|---|---|---|---|
| `welcome` | Welcome | boundary | waking up, a session begins | `think` |
| `think` | Thinking | **ambient** | working — background state that loops | *(core)* |
| `start` | Start | pulse | a **tool** action begins | `think` |
| `finish` | Finish | pulse | a **tool** action ends | `think` |
| `handle` | Handle | pulse | a **task** (work item) begins | `start` |
| `handled` | Handled | pulse | a **task** completes | `finish` |
| `fork` | Delegating | pulse | hands off work to a sub-agent | `start` |
| `join` | Returning | pulse | the sub-agent comes back, resuming the thread | `finish` |
| `wait` | Waiting | pulse | needs you *now* | `think` |
| `retry` | Retry | pulse | a tool action failed (recoverable), retrying | `think` |
| `save` | Saving | pulse | starts tidying / compressing its memory | `start` |
| `saved` | Saved | pulse | finished tidying | `finish` |
| `stop` | Stop | boundary | a turn is done, and done well | *(core)* |
| `fail` | Failed | boundary | stopped on an error (failed twin of `stop`) | `stop` |
| `bye` | Goodbye | boundary | the session is over | `stop` |
| `sleep` | Sleeping | **dormant** | nothing for a while, at rest | *(core)* |

The staircase of "endings," from smallest to largest: `finish` (a tool action) →
`stop` (a turn) → `bye` (the session), with `fail` as the failed twin of `stop`.

## Coverage & fallback

- **Mandatory core = 3 intentions**: `think`, `stop`, `sleep` (a background, an
  ending, a rest). A pack that only defines these is already valid and playable.
- **The other 13 are optional**: an intention not provided *degrades gracefully*
  along the fallback chain (right-hand column), which always ends at the core.
  E.g. a pack without `fork` replays `start` (then `think`); without `fail`,
  replays `stop`.

A pack **declares the intentions it covers**; a source **declares those it
emits**; compatibility = overlap. (Resolves the open point "pack with N of 16
hooks" from `MARKETPLACE.md`.)

## Claude Code profile (hook → intention)

The only Claude Code-specific artifact — *data*, not code
(`lib/profiles/claude_code.rb`). The 16 hooks map 1:1 onto the 16 intentions.

```
welcome  ← session_start
think    ← user_prompt
start    ← pre_tool
finish   ← post_tool
handle   ← task_new
handled  ← task_done
fork     ← subagent_start
join     ← subagent_stop
wait     ← notification
retry    ← post_tool_fail
save     ← pre_compact
saved    ← post_compact
stop     ← stop
fail     ← stop_failure
bye      ← session_end
sleep    ← system_idle
```

## Accepted trade-offs (V1)

- **Tool vs task split**: `start`/`finish` are the fine-grained **tool** level
  (`pre_tool`/`post_tool`, frequent); `handle`/`handled` the coarse **task**
  level (`task_new`/`task_done`, milestones). Kept as two distinct pairs so a
  milestone doesn't blur into the frequent tool beat — helps the "distinguishable
  without color" constraint.
- **`save`/`saved` as `pulse`**: possible future evolution → `save` as `ambient`
  ("tidying phase") closed by `saved`, if compaction deserves a dedicated
  background state.
- **`retry` ≠ `fail`**: a tool that fails mid-way (pulse, we come back to work)
  is NOT the session dying (boundary, terminal). Different kinds → two
  intentions. Never re-merge.

## Implementation

- **Vocabulary**: `lib/intentions.rb` — `VOCAB` (kind + fallback), `CORE`, and
  `kind` / `fallback` / `resolve` (walks the fallback chain, cycle-safe).
- **Profile**: `lib/profiles/claude_code.rb` — the hook → intention table.
- **`AnimationManager`**: registry keyed by intention; `handle` resolves
  event → intention (profile) → provided intention (fallback chain), then reads
  the temporal role from `Intentions.kind`. Animation files are named by
  intention (`think.rb`, `start.rb`, …); `sleep` is the idle animation
  (triggered internally on `IDLE_TIMEOUT`). Loading warns on unknown intentions
  or a missing core.
- Both sets (`cube`, `bunny`) are migrated. Verified by
  `test/test_cube_animations.rb` (both sets) and `test/test_manager_states.rb`.

## Versioning

`intentions.v1`. Adding an intention is backward-compatible (old packs ignore it,
old sources don't emit it) — that is how V1 grew from 14 to 16 (`handle`/`handled`).
Renaming/removing an id or changing a `kind` = **breaking**, requires a new
version of the vocabulary.
