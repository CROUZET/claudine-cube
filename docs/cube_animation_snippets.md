# Snippets d'animations cube (mis de côté)

Bouts d'effets utiles, non branchés, à réutiliser dans un futur hook du set
`lib/animations/cube/`. Ces fichiers ne sont **pas** chargés par l'AnimationManager
(seuls les `.rb` de `lib/animations/cube/` le sont).

---

## Dessus qui « se remplit » derrière un balayage (accumulation)

Variante initiale de `pre_tool` : derrière la colonne qui tourne, les 2 anneaux
extérieurs du dessus se **peignent progressivement et restent allumés** (l'action
« se referme par le haut »), plafonné à un tour complet puis maintenu.

Remplacée dans `pre_tool` par un marqueur mobile qui s'éteint derrière la colonne,
mais l'effet « remplissage/rémanent » peut convenir à un event de type
accomplissement/verrouillage (p.ex. une variante de `task_done` ou `post_compact`).

S'utilise avec les helpers de `CubeBase` (`top_edge_px`, `px`, `LATERAL`, `RING`,
`SIDE`). `head = t * SPEED` est la position de tête du balayage (en colonnes).

```ruby
# Dessus : bordure (anneau 0) + anneau 1 peints derrière la tête du balayage,
# au fil de la progression (plafonné à un tour complet, puis maintenu).
painted = [head.floor, RING - 1].min
(0..painted).each do |col|
  face = LATERAL[(col % RING) / SIDE]
  x    = col % SIDE
  [0, 1].each do |ring|
    tx, ty = top_edge_px(face, x, ring)
    px(panel, :top, tx, ty, COLOR)
  end
end
```
