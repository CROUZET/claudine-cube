# Cube animation snippets (set aside)

Useful effect fragments, not wired up, to reuse in a future hook of the
`lib/animations/cube/` set. These files are **not** loaded by the AnimationManager
(only the `.rb` files in `lib/animations/cube/` are).

---

## Top face that "fills in" behind a sweep (accumulation)

Initial variant of `pre_tool`: behind the rotating column, the 2 outer rings of
the top face **paint in progressively and stay lit** (the action "closes up from
the top"), capped at one full turn then held.

Replaced in `pre_tool` by a moving marker that turns off behind the column, but
the "fill/persistent" effect can suit an accomplishment/locking type event
(e.g. a variant of `task_done` or `post_compact`).

Used with the `CubeBase` helpers (`top_edge_px`, `px`, `LATERAL`, `RING`,
`SIDE`). `head = t * SPEED` is the head position of the sweep (in columns).

```ruby
# Top face: border (ring 0) + ring 1 painted behind the head of the sweep,
# as the progression advances (capped at one full turn, then held).
painted = [head.floor, RING - 1].min
(0..painted).each do |col|
  face = LATERAL[(col % RING) / SIDE]
  x = col % SIDE
  [0, 1].each do |ring|
    tx, ty = top_edge_px(face, x, ring)
    px(panel, :top, tx, ty, COLOR)
  end
end
```
