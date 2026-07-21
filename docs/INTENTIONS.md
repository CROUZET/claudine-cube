# INTENTIONS — state vocabulary (source ↔ rendering contract)

> **Status: V1 frozen (design; not yet implemented).** This document
> defines the **intention vocabulary** that decouples event *sources*
> (Claude Code today, others tomorrow) from the *animations* that render them.
> It is the system's public contract: animation packs and sources
> agree on it. See also `MARKETPLACE.md` (packs target
> intentions, not hooks) and `SOFTWARE.md` (EventBus / AnimationManager).

## Why this layer

Today, an animation is named after a Claude Code **hook**
(`user_prompt.rb`, `pre_tool.rb`…). Two problems:

1. `user_prompt` / `pre_tool` only speak to people who know Claude
   Code — unusable for a public marketplace.
2. It locks the cube into the Claude Code interaction. Worse: the **temporal role**
   of an event (background / one-shot / terminal) is today hardcoded *by hook
   name* in the `AnimationManager` (`BACKGROUND_EVENTS`, `CLEAR_EVENTS`) —
   "Claude Code" knowledge leaking into the rendering layer, in
   contradiction with the promise of `CLAUDE.md` §7 ("adding a source never
   touches rendering").

The intention layer solves both. A **"General MIDI" of states**: a
set of neutral state verbs. Animations are indexed by *intention*; a
**profile** (data, not code) maps a source's events to these intentions.
Adding a source = writing a profile, zero lines of rendering.

## Two naming principles

1. **stable id (English) ≠ display label (localizable).** The `id` is the API:
   short, carved in stone, never translated (like the code's class names). The **label**
   is what the creator sees, translatable. "Expressiveness" plays out on the label +
   the description; the id stays the contract.
2. **Neutral state verbs**, not Claude-isms (`think`, not `user_prompt`).

## The 4 kinds (the temporal role lives on the intention)

The `kind` migrates from the `AnimationManager` to the intention → the manager becomes
purely intention-driven, source-agnostic.

| kind | behavior | current manager equivalent |
|---|---|---|
| **ambient** | loops in the background as long as the state lasts | `BACKGROUND_EVENTS` |
| **pulse** | plays once then hands control back to the background | overlay |
| **boundary** | start/end that cuts the background (terminal) | `CLEAR_EVENTS` |
| **dormant** | idle | `system_idle` |

## V1 — 14 intentions

Five pairs that bracket each other + the outcomes of a turn + rest:
`welcome…bye` (session), `start…finish` (action), `fork…join` (delegation),
`save…saved` (memory housekeeping), `stop`/`fail` (successful/failed turn), `sleep`.

| id | label | kind | what it means | fallback |
|---|---|---|---|---|
| `welcome` | Welcome | boundary | waking up, a session begins | `think` |
| `think` | Thinking | **ambient** | working — background state that loops | *(core)* |
| `start` | Start | pulse | an action / a task starts | `think` |
| `finish` | Finish | pulse | an action / a task ends | `think` |
| `fork` | Delegating | pulse | hands off work to an assistant | `start` |
| `join` | Returning | pulse | the assistant comes back, resuming the thread | `finish` |
| `wait` | Waiting | pulse | needs you *now* | `think` |
| `retry` | Retry | pulse | an action failed (recoverable), retrying | `think` |
| `save` | Saving | pulse | starts tidying / compressing its memory | `start` |
| `saved` | Saved | pulse | finished tidying | `finish` |
| `stop` | Stop | boundary | a turn is done, and done well | *(core)* |
| `fail` | Failed | boundary | stopped on an error (failed twin of `stop`) | `stop` |
| `bye` | Goodbye | boundary | the session is over | `stop` |
| `sleep` | Sleeping | **dormant** | nothing for a while, at rest | *(core)* |

The staircase of "endings," from smallest to largest: `finish` (an action) →
`stop` (a turn) → `bye` (the session), with `fail` as the failed twin of `stop`.

## Coverage & fallback

- **Mandatory core = 3 intentions**: `think`, `stop`, `sleep` (a background, an
  ending, a rest). A pack that only defines these is already valid and playable.
- **The other 11 are optional**: an intention not provided *degrades
  gracefully* along the fallback chain (right-hand column), which always ends
  at the core. E.g. a pack without `fork` replays `start` (then `think`); without
  `fail`, replays `stop`.

A pack **declares the intentions it covers**; a source **declares those
it emits**; compatibility = overlap. (Resolves the open point "pack
with 10 of 16 hooks" from `MARKETPLACE.md`.)

## Claude Code profile (hook → intention)

The only Claude Code-specific artifact — *data*, not code. The 16
hooks map with no leftovers, with two groupings (`start`, `finish` merge
task and tool granularity).

```
welcome  ← session_start
think    ← user_prompt                 (ambient)
start    ← task_new, pre_tool           (many-to-one)
finish   ← task_done, post_tool         (many-to-one)
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

- **`start`/`finish` merge**: `pre_tool`/`post_tool` (frequent, micro-actions)
  share the visual of `task_new`/`task_done` (rare, milestones). More readable;
  we lose the micro-action vs milestone distinction. Re-separable if a "milestone"
  rhythm becomes desirable.
- **`save`/`saved` as `pulse`**: possible future evolution → `save` as `ambient`
  ("tidying phase") closed by `saved`, if compaction deserves a dedicated background
  state.
- **`retry` ≠ `fail`**: a tool that fails mid-way (pulse, we come back
  to work) is NOT the session dying (boundary, terminal). Different kinds
  → two intentions. Never re-merge.

## Versioning

`intentions.v1`. Adding an intention is backward-compatible (old packs
ignore it, old sources don't emit it). Renaming/removing an id
or changing a `kind` = **breaking**, requires a new version of the vocabulary.
