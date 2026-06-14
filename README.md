# arche-rpg

A tiny hot-reloadable graphics app built on the [arche](../arche) language — a driver that opens a window
and a **reloadable game device** you edit while it runs.

## Layout

```
arche.toml      # [lib] paths → the arche repo's extras (gfx) + stdlib; [select] gfx = "wayland"|"x11"
rpg.arche       # the DRIVER / HOST: owns the window + the Player pool (world state); never reloaded
game/
  game.ds.arche # the device datasheet: component types (x,y,vx,vy) + the storage requirement
  game.arche    # the HOT logic: the `Player` shape, a `step` physics SYSTEM, a per-ball draw proc
```

The driver owns the persistent state — the window **and the `Player` pool** (every ball's position +
velocity). The `game` device holds only behavior (the physics + drawing). That split is what makes hot
reload work for free: the device's *code* swaps while the driver's *pool* lives on untouched — so you can
edit the physics and watch it take effect on balls that are **already in motion**.

## Run it (dev — hot reload)

```sh
arche run rpg.arche
```

A 640×480 window opens with five balls springing toward the center, weaving through each other. While it
runs, edit `game/game.arche` and save — the window updates live, the host never restarts, and the balls
**keep their current position and velocity**. Things to try in `step`:

- **stiffness**: the `/ 24` divisor — smaller is snappier, larger is looser.
- **center**: the `320` / `240` the balls are pulled toward.
- **damping**: add `vx = vx * 31 / 32;` to make them settle; remove it for perpetual motion.
- **drawing**: change the radius/color in `draw_ball`.

There is no flag and no function-pointer type: `arche run` *is* the dev loop; the reload indirection is a
compiler-internal detail of this mode only.

### A note on systems

`step` is a **system** — it runs over every row of the driver's pool. arche systems are *data-parallel
column transforms*: each `col = expr` is auto-looped across all rows. They're branch-free by design, which
is why the motion is a **spring** (a restoring force, pure arithmetic) rather than a hard wall bounce — a
per-row `if` inside a system isn't supported yet. A spring needs no conditionals and gives lively motion.

## Build it (release — static)

```sh
arche build rpg.arche -o rpg
./rpg
```

One static binary. Every device call is a direct call; the reload indirection is compiled out entirely
(no `dlopen`, no runtime function pointers).

## Requirements

- The `arche` compiler on `PATH` (or call it by full path).
- An X11 display for the default `gfx = "x11"` backend (flip to `"wayland"` in `arche.toml` on Wayland).
- The arche repo checked out at `../arche` (or edit the `[lib] paths` in `arche.toml`).
