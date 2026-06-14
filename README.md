# arche-rpg

A tiny hot-reloadable graphics app built on the [arche](../arche) language — a driver that opens a window
and a **reloadable game device** you edit while it runs.

## Layout

```
arche.toml      # [lib] paths → the arche repo's extras (gfx) + stdlib; [select] gfx = "x11"
rpg.arche       # the DRIVER / HOST: owns the window + loop + state; never reloaded
game/
  game.ds.arche # marks game a device (behavior-only; the driver owns all state)
  game.arche    # the HOT logic: draw(win, t) — edit this live
```

The driver owns the persistent state (the window, the frame counter); the `game` device holds only
behavior. That split is what makes hot reload work for free: the device's *code* can be swapped while the
driver's *state* lives on untouched.

## Run it (dev — hot reload)

```sh
arche run rpg.arche
```

A 640×480 window opens with a sliding amber circle. While it runs, edit `game/game.arche` (change a color,
the radius, the motion) — the window updates live, no restart, the window stays open. There is no flag and
no function-pointer type: `arche run` *is* the dev loop; the reload indirection is a compiler-internal
detail of this mode only.

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
